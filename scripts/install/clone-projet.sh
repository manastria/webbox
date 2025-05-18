#!/bin/bash

set -e

# --- Variables
# Source les variables communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vars.sh"

# --- 1. Cloner le dépôt WebBox dans le répertoire de l'utilisateur
echo "[+] Clonage du dépôt dans $PROJECT_PATH"

# 1. Créer le répertoire s'il n'existe pas
if [ ! -d "$PROJECT_PATH" ]; then
    sudo -u "$USERNAME" mkdir -p "$PROJECT_PATH"
fi

# 2. Cloner le dépôt dans un répertoire temporaire
TMP_CLONE="/tmp/projet-temp"
rm -rf "$TMP_CLONE"
git clone "$REPO_URL" "$TMP_CLONE"

# 3. Copier le contenu dans le dossier final (sans sous-dossier .git)
cp -r "$TMP_CLONE"/* "$PROJECT_PATH"
cp -r "$TMP_CLONE"/.[!.]* "$PROJECT_PATH" || true  # copie les fichiers cachés sauf . et ..

# 4. Nettoyer
rm -rf "$TMP_CLONE"

# 5. Droits
chown -R "$USERNAME:$USERNAME" "$PROJECT_PATH"

echo "[✔] Projet cloné et prêt dans $PROJECT_PATH"
