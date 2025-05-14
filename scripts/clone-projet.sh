#!/bin/bash

set -e

USERNAME="etudiant"
PROJECT_DIR="/home/$USERNAME/mon-projet-web"
REPO_URL="https://github.com/manastria/docker_php_node_env.git"

echo "[+] Clonage du dépôt dans $PROJECT_DIR"

# 1. Créer le répertoire s'il n'existe pas
if [ ! -d "$PROJECT_DIR" ]; then
    sudo -u "$USERNAME" mkdir -p "$PROJECT_DIR"
fi

# 2. Cloner le dépôt dans un répertoire temporaire
TMP_CLONE="/tmp/projet-temp"
rm -rf "$TMP_CLONE"
git clone "$REPO_URL" "$TMP_CLONE"

# 3. Copier le contenu dans le dossier final (sans sous-dossier .git)
cp -r "$TMP_CLONE"/* "$PROJECT_DIR"
cp -r "$TMP_CLONE"/.[!.]* "$PROJECT_DIR" || true  # copie les fichiers cachés sauf . et ..

# 4. Nettoyer
rm -rf "$TMP_CLONE"

# 5. Droits
chown -R "$USERNAME:$USERNAME" "$PROJECT_DIR"

echo "[✔] Projet cloné et prêt dans $PROJECT_DIR"
