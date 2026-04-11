#!/bin/bash

set -e

# --- Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/vars.sh"

DOMAIN="internal"
FQDN="$VM_HOSTNAME.$DOMAIN"

log STEP "Configuration du hostname en '$FQDN'"

# Configuration du hostname
hostnamectl set-hostname "$VM_HOSTNAME"

# Mise à jour de /etc/hosts
if grep -q "127.0.1.1" /etc/hosts; then
    sudo sed -i "s/^127.0.1.1.*/127.0.1.1       $FQDN $VM_HOSTNAME/" /etc/hosts
else
    echo "127.0.1.1       $FQDN $VM_HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
fi

log OK "Nom d'hôte configuré : $FQDN"
