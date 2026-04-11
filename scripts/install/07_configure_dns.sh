#!/bin/bash

set -e

# --- Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/vars.sh"

TECHNITIUM_URL="http://localhost:5380"
TECHNITIUM_USER="admin"
TECHNITIUM_PASS="netlab123"
ZONE="${VM_HOSTNAME}.${DOMAIN}"   # webbox.vm

# --- DNS Forwarders
# Format: adresses séparées par des virgules
# Lycée (réseau interne) — à adapter selon l'établissement
DNS_LYCEE="172.25.254.15,172.16.0.1"
# DNS publics de repli (domicile / réseau sans DNS interne)
DNS_PUBLIC="1.1.1.1,9.9.9.9,208.67.222.222"
# Liste complète : lycée en priorité, puis DNS publics
DNS_FORWARDERS="${DNS_LYCEE},${DNS_PUBLIC}"

# --- 1. Attendre que Technitium soit prêt (max 60s)
log STEP "Attente de Technitium DNS..."
for i in $(seq 1 30); do
    if curl -sf "$TECHNITIUM_URL/api/user/login?user=$TECHNITIUM_USER&pass=$TECHNITIUM_PASS" > /dev/null 2>&1; then
        log OK "Technitium DNS prêt"
        break
    fi
    if [ "$i" -eq 30 ]; then
        log ERROR "Technitium DNS ne répond pas après 60s"
        exit 1
    fi
    sleep 2
done

# --- 2. Obtenir le token d'authentification
TOKEN=$(curl -sf "$TECHNITIUM_URL/api/user/login?user=$TECHNITIUM_USER&pass=$TECHNITIUM_PASS" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['token'])" 2>/dev/null)

if [ -z "$TOKEN" ]; then
    log ERROR "Impossible d'obtenir un token Technitium (vérifier le mot de passe)"
    exit 1
fi

log DEBUG "Token obtenu"

# --- 3. Créer la zone primaire webbox (idempotent)
ZONE_RESULT=$(curl -sf "$TECHNITIUM_URL/api/zones/create?token=$TOKEN&zone=$ZONE&type=Primary" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','error'))" 2>/dev/null)

if [ "$ZONE_RESULT" = "ok" ]; then
    log OK "Zone '$ZONE' créée"
else
    log WARN "Zone '$ZONE' déjà existante ou erreur ($ZONE_RESULT) — on continue"
fi

# --- 4. Ajouter l'enregistrement wildcard *.webbox.vm → IP_SITE
RECORD_RESULT=$(curl -sf \
    "$TECHNITIUM_URL/api/zones/records/add?token=$TOKEN&domain=*.$ZONE&type=A&ipAddress=$IP_SITE&ttl=300" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','error'))" 2>/dev/null)

if [ "$RECORD_RESULT" = "ok" ]; then
    log OK "Enregistrement wildcard '*.$ZONE → $IP_SITE' ajouté"
else
    log WARN "Enregistrement wildcard déjà présent ou erreur ($RECORD_RESULT) — on continue"
fi

# --- 5. Configurer les forwarders DNS
FWDR_RESULT=$(curl -sf --get \
    --data-urlencode "forwarders=$DNS_FORWARDERS" \
    "$TECHNITIUM_URL/api/settings/set?token=$TOKEN&forwarderProtocol=Udp" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','error'))" 2>/dev/null)

if [ "$FWDR_RESULT" = "ok" ]; then
    log OK "Forwarders configurés : $DNS_FORWARDERS"
else
    log WARN "Erreur configuration forwarders ($FWDR_RESULT) — on continue"
fi

# --- 6. Installer le plugin Query Logs (Sqlite)
log STEP "Installation du plugin Query Logs (Sqlite)..."
APP_RESULT=$(curl -sf --max-time 120 --get \
    --data-urlencode "token=$TOKEN" \
    --data-urlencode "name=Query Logs (Sqlite)" \
    --data-urlencode "url=https://download.technitium.com/dns/apps/QueryLogsSqliteApp-v8.zip" \
    "$TECHNITIUM_URL/api/apps/downloadAndInstall" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','error'))" 2>/dev/null)

if [ "$APP_RESULT" = "ok" ]; then
    log OK "Plugin 'Query Logs (Sqlite)' installé"
else
    log WARN "Plugin déjà installé ou erreur ($APP_RESULT) — on continue"
fi

log INFO "Tous les sous-domaines '*.${ZONE}' pointent vers $IP_SITE"
log INFO "Forwarders actifs : lycée (${DNS_LYCEE}), puis publics (${DNS_PUBLIC})"
log INFO "Interface admin : http://$IP_SITE:5380  (mdp: $TECHNITIUM_PASS)"
