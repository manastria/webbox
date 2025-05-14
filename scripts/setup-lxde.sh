#!/bin/bash

set -e

# --- Variables
USERNAME="etudiant"
USER_HOME="/home/$USERNAME"
IP_SITE="192.168.56.101"
SHARE_NAME="www"

# sudo apt update && sudo apt upgrade -y

# --- 1. Créer l'utilisateur s'il n'existe pas
if ! id "$USERNAME" &>/dev/null; then
    echo "[+] Création de l'utilisateur $USERNAME"
    sudo adduser --disabled-password --gecos "" "$USERNAME"
    sudo usermod -aG sudo,docker "$USERNAME"
else
    echo "[*] L'utilisateur $USERNAME existe déjà"
    sudo usermod -aG sudo,docker "$USERNAME"
fi

# --- 2. Installer l'environnement graphique LXDE minimal
echo "[+] Installation de LXDE et des utilitaires"
sudo apt update
sudo apt install --no-install-recommends -y \
    lxde-core \
    lightdm \
    firefox-esr \
    pcmanfm \
    leafpad \
    gvfs-backends \
    samba-client

# --- 3. Créer le raccourci "Mon site" sur le bureau
echo "[+] Création du raccourci Mon site"
sudo -u "$USERNAME" mkdir -p "$USER_HOME/Bureau"

cat <<EOF | sudo tee "$USER_HOME/Bureau/Mon_site.desktop" > /dev/null
[Desktop Entry]
Name=Mon site
Comment=Ouvre le site web local
Exec=firefox-esr http://$IP_SITE
Icon=firefox
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF

sudo chmod +x "$USER_HOME/Bureau/Mon_site.desktop"
sudo chown "$USERNAME:$USERNAME" "$USER_HOME/Bureau/Mon_site.desktop"

# --- 4. Ajouter un favori Samba dans l'explorateur PCManFM
echo "[+] Ajout du favori réseau Samba"
sudo -u "$USERNAME" mkdir -p "$USER_HOME/.config/gtk-3.0"
echo "smb://$IP_SITE/$SHARE_NAME Partage Web" | sudo tee "$USER_HOME/.config/gtk-3.0/bookmarks" > /dev/null
sudo chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config"

# --- 5. Démarrage automatique de Firefox (optionnel)
echo "[+] Ajout de Firefox à l'autostart de LXDE"
AUTOSTART_DIR="$USER_HOME/.config/lxsession/LXDE"
sudo -u "$USERNAME" mkdir -p "$AUTOSTART_DIR"
echo "@firefox-esr http://$IP_SITE" | sudo tee "$AUTOSTART_DIR/autostart" > /dev/null
sudo chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config"

echo "[✔] Installation et configuration terminées pour l'utilisateur $USERNAME"
