#!/bin/bash
set -e

# Charger les variables communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vars.sh"

# --- Variables
GROUPS_TO_ADD="sudo,docker,admins"

echo "[~] Script add_user.sh"

# --- 1. Ajouter l'utilisateur s'il n'existe pas
if ! id "$USERNAME" &>/dev/null; then
    echo "[+] Création de l'utilisateur $USERNAME"
    sudo adduser --gecos "" --disabled-password "$USERNAME"
    echo "$USERNAME:netlab123" | sudo chpasswd
else
    echo "[=] L'utilisateur $USERNAME existe déjà"
fi

sudo usermod -aG "$GROUPS_TO_ADD" "$USERNAME"

# --- 2. Cloner le dépôt WebBox + Dotfiles avec yadm
echo "[+] Clonage du dépôt WebBox et configuration avec yadm"

# 1) Installer yadm s'il n'est pas présent
if ! command -v yadm &> /dev/null; then
    echo "[+] Installation de yadm"
    sudo apt install -y yadm
fi

# 2) Cloner le dépôt WebBox dans le home de l'utilisateur
if [ ! -d "$USER_HOME/webbox" ]; then
    sudo -u "$USERNAME" git clone ${REPO_URL} "$USER_HOME/webbox"
else
    echo "[!] Le dossier webbox existe déjà dans $USER_HOME"
fi

# 3) Cloner et appliquer les dotfiles avec yadm
if ! sudo -u "$USERNAME" HOME="$USER_HOME" yadm clone https://github.com/manastria/dotfile.git; then
    echo "[!] Échec du clone YADM, tentative de suppression du dépôt existant..."
    sudo -u "$USERNAME" HOME="$USER_HOME" rm -rf "$USER_HOME/.local/share/yadm/repo.git"
    sudo -u "$USERNAME" HOME="$USER_HOME" yadm clone https://github.com/manastria/dotfile.git
fi

# 4) Forcer l'application des dotfiles depuis la branche master
sudo -u "$USERNAME" HOME="$USER_HOME" yadm reset --hard master


echo "[✔] Dépôts clonés et dotfiles appliqués pour $USERNAME"

