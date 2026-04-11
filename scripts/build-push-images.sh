#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DOCKER_HUB_USER="manastria"
VERSION=$(cat "$ROOT_DIR/VERSION" | tr -d '[:space:]')

if [ -z "$VERSION" ]; then
    echo "Erreur : fichier VERSION manquant ou vide" >&2
    exit 1
fi

echo "========================================"
echo "  Publication images WebBox v$VERSION"
echo "========================================"
echo ""
echo "Vérifier que vous êtes connecté : docker login"
echo ""

for IMAGE in php node; do
    FULL_NAME="$DOCKER_HUB_USER/webbox-$IMAGE"
    echo "--- Build $FULL_NAME ---"
    docker build \
        --platform linux/amd64 \
        -t "$FULL_NAME:$VERSION" \
        -t "$FULL_NAME:latest" \
        "$ROOT_DIR/images/$IMAGE"

    echo "--- Push $FULL_NAME ---"
    docker push "$FULL_NAME:$VERSION"
    docker push "$FULL_NAME:latest"
    echo ""
done

echo "Images publiées :"
echo "  docker.io/$DOCKER_HUB_USER/webbox-php:$VERSION"
echo "  docker.io/$DOCKER_HUB_USER/webbox-node:$VERSION"
echo ""
echo "Mettre à jour VERSION dans vars.sh si nécessaire."
