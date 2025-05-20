#!/bin/bash

set -e

# --- Variables
# Source les variables communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vars.sh"

# --- 1. Installer Samba
echo "[+] Installation de Samba"
sudo apt update
sudo apt install -y samba

# --- 2. Créer le dossier du projet si besoin
if [ ! -d "$PROJECT_PATH" ]; then
    echo "[+] Création du dossier projet à $PROJECT_PATH"
    sudo -u "$USERNAME" mkdir -p "$PROJECT_PATH"
fi

# --- 3. Sauvegarde de la configuration samba
echo "[*] Sauvegarde de /etc/samba/smb.conf"
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak.$(date +%Y-%m-%dT%H:%M:%S)

# --- 4. Ajouter la section de partage si elle n'existe pas
if ! grep -q "^\[$SHARE_NAME\]" /etc/samba/smb.conf; then
    echo "[+] Ajout du partage [$SHARE_NAME] à smb.conf"
    cat <<EOF | sudo tee -a /etc/samba/smb.conf > /dev/null

[$SHARE_NAME]
   path = $PROJECT_PATH
   browsable = yes
   read only = no
   guest ok = no
   force user = $USERNAME

[public]
   path = $PROJECT_PATH/public
   browsable = yes
   read only = no
   guest ok = no
   force user = etudiant


EOF
fi

# --- 5. Redémarrer Samba
echo "[+] Redémarrage du service Samba"
sudo systemctl restart smbd

# --- 6. Créer un utilisateur Samba pour Windows
echo "[+] Création de l'utilisateur Samba 'etudiant'"
echo -e "netlab123\nnetlab123" | sudo smbpasswd -a etudiant


# --- 7. Résumé
echo "[✔] Partage configuré : \\$(hostname -I | awk '{print $1}')\\$SHARE_NAME"
echo "[ℹ] Pour accéder au projet sous Windows, monte le lecteur :"
echo "    \\\\$(hostname -I | awk '{print $1}')\\$SHARE_NAME"
