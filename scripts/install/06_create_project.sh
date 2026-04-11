#!/bin/bash

set -e

# --- Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/vars.sh"

# --- Argument
PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
    log ERROR "Usage: $0 NOM_PROJET"
    log ERROR "Exemple: $0 tp-formulaires"
    log ERROR "Noms acceptés : lettres minuscules, chiffres, tirets"
    exit 1
fi

# Valider le nom (lettres minuscules, chiffres, tirets uniquement)
if ! [[ "$PROJECT_NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
    log ERROR "Nom invalide : '$PROJECT_NAME'"
    log ERROR "Noms acceptés : lettres minuscules, chiffres, tirets (pas de tiret en début/fin)"
    exit 1
fi

DEST="$PROJECTS_PATH/$PROJECT_NAME"

if [ -d "$DEST" ]; then
    log ERROR "Le projet '$PROJECT_NAME' existe déjà dans $DEST"
    exit 1
fi

log INFO "Création du projet '$PROJECT_NAME'"
log INFO "  URL    : http://$PROJECT_NAME.$VM_HOSTNAME.$DOMAIN"
log INFO "  Dossier: $DEST"

# --- 1. Créer les dossiers
log STEP "Création des dossiers..."
sudo -u "$USERNAME" mkdir -p "$PROJECTS_PATH"
sudo -u "$USERNAME" mkdir -p "$DEST"

# --- 2. Copier les fichiers du template (webbox)
log STEP "Copie du template depuis $PROJECT_PATH..."
for item in php public db docker-compose.yml gulpfile.js package.json \
            .editorconfig .htmlvalidate.json .vscode; do
    if [ -e "$PROJECT_PATH/$item" ]; then
        sudo -u "$USERNAME" cp -r "$PROJECT_PATH/$item" "$DEST/"
    fi
done

# --- 3. Générer le fichier .env du projet
log STEP "Génération du fichier .env..."
cat <<EOF | sudo -u "$USERNAME" tee "$DEST/.env" > /dev/null
# Projet : $PROJECT_NAME
PROJECT_NAME=$PROJECT_NAME

# Version des images Docker WebBox
WEBBOX_VERSION=$WEBBOX_VERSION

# Xdebug — adresse de la machine Windows (passerelle host-only)
XDEBUG_CLIENT_HOST=$IP_SITE

# Base de données MySQL
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=demo
MYSQL_USER=user
MYSQL_PASSWORD=password
EOF

# --- 4. Créer un .gitignore minimal dans le projet
if [ ! -f "$DEST/.gitignore" ]; then
    cat <<EOF | sudo -u "$USERNAME" tee "$DEST/.gitignore" > /dev/null
.env
node_modules/
EOF
fi

# --- 5. Ajouter le partage Samba
log STEP "Ajout du partage Samba '[$PROJECT_NAME]'..."
if ! grep -q "^\[$PROJECT_NAME\]" /etc/samba/smb.conf; then
    cat <<EOF | sudo tee -a /etc/samba/smb.conf > /dev/null

[$PROJECT_NAME]
   path = $DEST/public
   browsable = yes
   read only = no
   guest ok = no
   force user = $USERNAME
EOF
    sudo systemctl restart smbd
    log OK "Partage Samba '$PROJECT_NAME' créé"
else
    log WARN "Partage Samba '$PROJECT_NAME' déjà présent"
fi

# --- 6. Démarrer les conteneurs Docker du projet
log STEP "Démarrage des conteneurs Docker (build initial, peut prendre quelques minutes)..."
sudo -u "$USERNAME" bash -c "cd '$DEST' && docker compose up -d --build"

# --- Résumé
log OK "Projet '$PROJECT_NAME' prêt !"
echo ""
log INFO "  Application  : http://$PROJECT_NAME.$VM_HOSTNAME.$DOMAIN"
log INFO "  Base de données (phpMyAdmin) :"
log INFO "    URL     : http://pma.$VM_HOSTNAME.$DOMAIN"
log INFO "    Serveur : ${PROJECT_NAME}-db"
log INFO "  Partage réseau Windows : \\\\$IP_SITE\\$PROJECT_NAME"
log INFO "  Dossier sur la VM      : $DEST/public"
