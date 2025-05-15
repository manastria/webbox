#!/bin/bash

# Clé publique à autoriser
read -r -d '' PUB_KEY <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG/GbOz9gfH+F3f96xRN6GieKa6Eyj1kkvzSa86/i+wr WebBox
EOF

# Dossier .ssh
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Ajout de la clé si elle n’existe pas déjà
if ! grep -qF "$PUB_KEY" ~/.ssh/authorized_keys 2>/dev/null; then
    echo "$PUB_KEY" >> ~/.ssh/authorized_keys
    echo "[OK] Clé ajoutée à ~/.ssh/authorized_keys"
else
    echo "[INFO] Clé déjà présente dans ~/.ssh/authorized_keys"
fi

chmod 600 ~/.ssh/authorized_keys
