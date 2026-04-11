#!/bin/bash

# Arrête le script en cas d'erreur
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vars.sh"

echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/90-nopasswd-$USER

echo "--- Mise à jour des listes de paquets ---"
sudo apt-get update

# Liste des paquets définie dans une variable pour plus de clarté
PACKAGES=(
    lxde-core
    lightdm
    lxterminal
    lightdm-gtk-greeter
    lightdm-gtk-greeter-settings
    xserver-xorg
    xserver-xorg-video-all
    xserver-xorg-input-all
    console-setup
    keyboard-configuration
    firefox-esr
    pcmanfm
    mousepad
    micro
    gvfs-backends
    php-cli
    samba-client
    samba
)

echo "--- Téléchargement des paquets (sans installation) ---"
# --download-only : récupère les .deb dans /var/cache/apt/archives/
# --no-install-recommends : évite les paquets optionnels
# -y : répond oui automatiquement
sudo apt-get install --download-only -y "${PACKAGES[@]}"

echo "--- Pré-téléchargement des images Docker ---"

# Images d'infrastructure (docker-compose.infra.yml)
# Images de projet (docker-compose.yml) — version définie dans vars.sh
DOCKER_IMAGES=(
    traefik:v3.6
    technitium/dns-server:14.3.0
    phpmyadmin/phpmyadmin
    manastria/webbox-php:${WEBBOX_VERSION}
    manastria/webbox-node:${WEBBOX_VERSION}
    mysql:8.0
)

for IMAGE in "${DOCKER_IMAGES[@]}"; do
    echo "  → docker pull $IMAGE"
    docker pull "$IMAGE"
done

echo "--- Opération terminée ---"
echo "Le cache apt est prêt dans /var/cache/apt/archives/"
echo "Les images Docker sont disponibles localement."
