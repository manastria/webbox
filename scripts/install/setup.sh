#!/bin/bash

set -e

# --- Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/vars.sh"

# --- 1. Installer l'environnement graphique LXDE minimal
log STEP "Installation de LXDE et des utilitaires"
sudo apt update
sudo apt install -y \
    lxde-core \
    lightdm lxterminal \
    lightdm-gtk-greeter lightdm-gtk-greeter-settings \
    xserver-xorg xserver-xorg-video-all xserver-xorg-input-all \
    console-setup keyboard-configuration \
    firefox-esr \
    pcmanfm \
    mousepad \
    micro \
    gvfs-backends \
    php-cli \
    samba-client

# --- 2. Créer l'utilisateur s'il n'existe pas
"$SCRIPT_DIR/01_add_user.sh"
"$SCRIPT_DIR/05_ajouter_cle_publique.sh"

# --- 3. Configurer le clavier en AZERTY (FR)
log STEP "Configuration du clavier en français (AZERTY)"
sudo sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="fr"/' /etc/default/keyboard
sudo sed -i 's/^XKBMODEL=.*/XKBMODEL="pc105"/' /etc/default/keyboard
sudo sed -i '/^XKBVARIANT=/c\XKBVARIANT=""' /etc/default/keyboard
sudo sed -i '/^XKBOPTIONS=/c\XKBOPTIONS=""' /etc/default/keyboard
sudo systemctl restart keyboard-setup.service

# --- 4. Créer le raccourci "Mon site" sur le bureau
log STEP "Création du raccourci Mon site"
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
log STEP "Ajout du favori réseau Samba"
sudo -u "$USERNAME" mkdir -p "$USER_HOME/.config/gtk-3.0"
echo "smb://$IP_SITE/$SHARE_NAME Partage Web" | sudo tee "$USER_HOME/.config/gtk-3.0/bookmarks" > /dev/null
sudo chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config"

# --- 6. Démarrage automatique : conserver l'autostart LXDE et ajouter clavier + Firefox
log STEP "Configuration de l'autostart LXDE"
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

# --- 7. Configurer le hostname
log STEP "Configuration du hostname"
"$SCRIPT_DIR/02_hostname.sh"

# --- 8. Configurer le réseau
log STEP "Configuration du réseau host-only"
"$SCRIPT_DIR/03_config_network.sh"

# --- 9. Installer et configurer Samba
log STEP "Installation de Samba"
"$SCRIPT_DIR/04_configure_samba.sh"

# --- 10. Démarrer l'infrastructure Docker et configurer le DNS
log STEP "Démarrage de l'infrastructure Docker"
"$SCRIPT_DIR/08_start_infra.sh"

log OK "Installation et configuration terminées pour l'utilisateur $USERNAME"
log INFO "Créer un projet : sudo $SCRIPT_DIR/06_create_project.sh NOM_PROJET"
