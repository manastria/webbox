#!/bin/bash

set -e

# --- Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/vars.sh"

# Nom de la connexion NetworkManager
CONN_NAME="hostonly-static"
IFACE="eth0"
IP_ADDR="$IP_SITE/24"

log STEP "Création de la connexion statique pour $IFACE avec $IP_ADDR..."

# Supprimer une ancienne connexion éventuellement conflictuelle
nmcli connection delete "$CONN_NAME" 2>/dev/null || true

# Créer une nouvelle connexion Ethernet statique
nmcli connection add type ethernet ifname "$IFACE" con-name "$CONN_NAME" \
    ipv4.method manual ipv4.addresses "$IP_ADDR" \
    ipv4.gateway "" ipv4.dns ""

# Activer immédiatement
nmcli connection up "$CONN_NAME"

log OK "Interface $IFACE configurée avec l'IP statique $IP_ADDR (pas de passerelle, pas de DNS)"
