#!/bin/bash

set -e

# --- Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/vars.sh"

INFRA_DIR="$PROJECT_PATH/infra"

# --- 1. Vérifier que Docker est disponible
if ! command -v docker &> /dev/null; then
    log ERROR "Docker n'est pas installé ou pas dans le PATH"
    exit 1
fi

# --- 2. Démarrer l'infrastructure
log STEP "Démarrage de l'infrastructure Docker (Traefik + Technitium DNS + phpMyAdmin)"
(cd "$INFRA_DIR" && sudo -u "$USERNAME" docker compose up -d)

log OK "Conteneurs d'infrastructure démarrés"
log INFO "  Traefik dashboard : http://traefik.$VM_HOSTNAME.$DOMAIN"
log INFO "  phpMyAdmin        : http://pma.$VM_HOSTNAME.$DOMAIN"
log INFO "  Technitium DNS    : http://$IP_SITE:5380  (mdp: netlab123)"

# --- 3. Configurer Technitium DNS (zone webbox.vm + wildcard)
"$SCRIPT_DIR/07_configure_dns.sh"
