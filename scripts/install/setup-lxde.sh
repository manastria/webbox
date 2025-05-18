#!/bin/bash

set -e

# --- Variables
USERNAME="etudiant"
USER_HOME="/home/$USERNAME"
IP_SITE="192.168.56.50"
SHARE_NAME="web"

# sudo apt update && sudo apt upgrade -y

# --- 1. Créer l'utilisateur s'il n'existe pas
GROUPS_TO_ADD="sudo,docker,admins"

if ! id "$USERNAME" &>/dev/null; then
    echo "[+] Création de l'utilisateur $USERNAME"
    sudo adduser --gecos "" --disabled-password "$USERNAME"
    echo "$USERNAME:netlab123" | sudo chpasswd
fi

sudo usermod -aG "$GROUPS_TO_ADD" "$USERNAME"


# --- 2. Installer l'environnement graphique LXDE minimal
echo "[+] Installation de LXDE et des utilitaires"
sudo apt update
sudo apt install --no-install-recommends -y \
    lxde-core \
    lightdm lxterminal \
    lightdm-gtk-greeter lightdm-gtk-greeter-settings \
    xserver-xorg xserver-xorg-video-all xserver-xorg-input-all \
    console-setup keyboard-configuration \
    firefox-esr \
    pcmanfm \
    mousepad \
    gvfs-backends \
    php-cli \
    samba-client

# --- 3. Configurer le clavier en AZERTY (FR)
echo "[+] Configuration du clavier en français (AZERTY)"
sudo sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="fr"/' /etc/default/keyboard
sudo sed -i 's/^XKBMODEL=.*/XKBMODEL="pc105"/' /etc/default/keyboard
sudo sed -i '/^XKBVARIANT=/c\XKBVARIANT=""' /etc/default/keyboard
sudo sed -i '/^XKBOPTIONS=/c\XKBOPTIONS=""' /etc/default/keyboard
sudo systemctl restart keyboard-setup.service

# --- 4. Créer le raccourci "Mon site" sur le bureau
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

# --- 5. Ajouter un favori Samba dans l'explorateur PCManFM
echo "[+] Ajout du favori réseau Samba"
sudo -u "$USERNAME" mkdir -p "$USER_HOME/.config/gtk-3.0"
echo "smb://$IP_SITE/$SHARE_NAME Partage Web" | sudo tee "$USER_HOME/.config/gtk-3.0/bookmarks" > /dev/null
sudo chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config"

# --- 6. Démarrage automatique : conserver l'autostart LXDE et ajouter clavier + Firefox
echo "[+] Configuration de l'autostart LXDE"
AUTOSTART_DIR="$USER_HOME/.config/lxsession/LXDE"
sudo -u "$USERNAME" mkdir -p "$AUTOSTART_DIR"

AUTOSTART_FILE="$AUTOSTART_DIR/autostart"

# 1) Copier le fichier modèle si l'utilisateur n'en a pas encore
if [ ! -f "$AUTOSTART_FILE" ]; then
    sudo -u "$USERNAME" cp /etc/xdg/lxsession/LXDE/autostart "$AUTOSTART_FILE"
fi

# 2) Ajouter @setxkbmap fr si absent
grep -qxF '@setxkbmap fr' "$AUTOSTART_FILE" || \
    echo '@setxkbmap fr' | sudo tee -a "$AUTOSTART_FILE" >/dev/null

# 3) Ajouter le lancement de Firefox si absent
grep -qxF "@firefox-esr http://$IP_SITE" "$AUTOSTART_FILE" || \
    echo "@firefox-esr http://$IP_SITE" | sudo tee -a "$AUTOSTART_FILE" >/dev/null

# 4) Droits
sudo chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config"

# --- 7. Cloner le dépôt WebBox + Dotfiles avec yadm
echo "[+] Clonage du dépôt WebBox et configuration avec yadm"

# 1) Installer yadm s'il n'est pas présent
if ! command -v yadm &> /dev/null; then
    echo "[+] Installation de yadm"
    sudo apt install -y yadm
fi

# 2) Cloner le dépôt WebBox dans le home de l'utilisateur
if [ ! -d "$USER_HOME/webbox" ]; then
    sudo -u "$USERNAME" git clone https://github.com/manastria/webbox.git "$USER_HOME/webbox"
else
    echo "[!] Le dossier webbox existe déjà dans $USER_HOME"
fi

# 3) Cloner et appliquer les dotfiles avec yadm
sudo -u "$USERNAME" yadm clone https://github.com/manastria/dotfile.git || {
    echo "[!] Échec du clone YADM, tentative de suppression du dépôt existant..."
    sudo -u "$USERNAME" rm -rf "$USER_HOME/.local/share/yadm/repo.git"
    sudo -u "$USERNAME" yadm clone https://github.com/manastria/dotfile.git
}

# 4) Forcer l'application des dotfiles depuis la branche master
sudo -u "$USERNAME" yadm reset --hard master

echo "[✔] Dépôts clonés et dotfiles appliqués pour $USERNAME"


echo "[✔] Installation et configuration terminées pour l'utilisateur $USERNAME"
