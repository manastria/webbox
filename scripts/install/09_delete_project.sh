#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/vars.sh"

# --- Argument
PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
    log ERROR "Usage: $0 NOM_PROJET"
    log ERROR "Exemple: $0 tp-formulaires"
    exit 1
fi

if ! [[ "$PROJECT_NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
    log ERROR "Nom invalide : '$PROJECT_NAME'"
    log ERROR "Noms acceptés : lettres minuscules, chiffres, tirets (pas de tiret en début/fin)"
    exit 1
fi

DEST="$PROJECTS_PATH/$PROJECT_NAME"

if [ ! -d "$DEST" ]; then
    log ERROR "Le projet '$PROJECT_NAME' n'existe pas dans $PROJECTS_PATH"
    exit 1
fi

# --- Confirmation
log WARN "Suppression du projet '$PROJECT_NAME'"
log WARN "  Dossier          : $DEST"
log WARN "  Partage Samba    : [$PROJECT_NAME]"
log WARN "  Conteneurs Docker: ${PROJECT_NAME}-web, ${PROJECT_NAME}-db, ${PROJECT_NAME}-node"
log WARN "  Volumes Docker   : supprimés définitivement"
echo ""
read -r -p "Confirmer la suppression ? [y/N] " response
if [[ ! "$response" =~ ^[yY]$ ]]; then
    log INFO "Suppression annulée."
    exit 0
fi

# --- 1. Arrêt et suppression des conteneurs + volumes Docker
log STEP "Arrêt et suppression des conteneurs Docker..."
if [ -f "$DEST/docker-compose.yml" ]; then
    sudo -u "$USERNAME" bash -c "cd '$DEST' && docker compose down -v" \
        || log WARN "Impossible d'arrêter les conteneurs (déjà arrêtés ?)"
else
    log WARN "Pas de docker-compose.yml dans $DEST — conteneurs ignorés"
fi

# --- 2. Suppression du partage Samba
log STEP "Suppression du partage Samba '[$PROJECT_NAME]'..."
if grep -q "^\[$PROJECT_NAME\]" /etc/samba/smb.conf; then
    # Supprime la section du projet (du header jusqu'au prochain header ou EOF)
    sudo awk -v section="$PROJECT_NAME" '
        $0 ~ "^\\[" section "\\]" { skip=1; next }
        skip && /^\[/             { skip=0 }
        !skip
    ' /etc/samba/smb.conf | sudo tee /tmp/smb_tmp.conf > /dev/null
    sudo mv /tmp/smb_tmp.conf /etc/samba/smb.conf
    sudo systemctl restart smbd
    log OK "Partage Samba '$PROJECT_NAME' supprimé"
else
    log WARN "Partage Samba '$PROJECT_NAME' non trouvé dans smb.conf"
fi

# --- 3. Suppression du dossier projet
log STEP "Suppression du dossier $DEST..."
sudo rm -rf "$DEST"
log OK "Dossier supprimé"

# --- Résumé
echo ""
log OK "Projet '$PROJECT_NAME' supprimé."
