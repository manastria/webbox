#!/bin/bash
set -e
set -x


# --- Charger les variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/vars.sh"




echo "[~] SCRIPT_DIR=$SCRIPT_DIR"
echo "[~] Vérification de $SCRIPT_DIR/../lib/log.sh"
echo "[~] Vérification de $SCRIPT_DIR/vars.sh"

ls -l "$SCRIPT_DIR/../lib/log.sh" "$SCRIPT_DIR/vars.sh"







# --- Clé publique à autoriser
read -r -d '' PUB_KEY <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG/GbOz9gfH+F3f96xRN6GieKa6Eyj1kkvzSa86/i+wr webbox
EOF

# --- Dossier .ssh de l'utilisateur
USER_SSH_DIR="$USER_HOME/.ssh"
AUTHORIZED_KEYS="$USER_SSH_DIR/authorized_keys"

echo "[+] Configuration de la clé SSH pour $USERNAME"

# Créer le dossier .ssh avec les bons droits
log STEP "Création du dossier $USER_SSH_DIR"
sudo -u "$USERNAME" HOME="$USER_HOME" mkdir -p "$USER_SSH_DIR"
sudo chmod 700 "$USER_SSH_DIR"
sudo chown "$USERNAME:$USERNAME" "$USER_SSH_DIR"

# Ajouter la clé si elle n'existe pas encore
if ! sudo grep -qF "$PUB_KEY" "$AUTHORIZED_KEYS" 2>/dev/null; then
    echo "$PUB_KEY" | sudo tee -a "$AUTHORIZED_KEYS" > /dev/null
    echo "[✔] Clé ajoutée à $AUTHORIZED_KEYS"
else
    echo "[=] Clé déjà présente dans $AUTHORIZED_KEYS"
fi

# Appliquer les bons droits
sudo chmod 600 "$AUTHORIZED_KEYS"
sudo chown "$USERNAME:$USERNAME" "$AUTHORIZED_KEYS"
