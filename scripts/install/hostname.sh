#!/bin/bash

HOSTNAME=webbox
DOMAIN=local
FQDN="$HOSTNAME.$DOMAIN"

# Configuration du hostname
hostnamectl set-hostname "$HOSTNAME"

# Mise à jour de /etc/hosts
if grep -q "127.0.2.1" /etc/hosts; then
  sudo sed -i "s/^127.0.2.1.*/127.0.2.1       $FQDN $HOSTNAME/" /etc/hosts
else
  echo "127.0.2.1       $FQDN $HOSTNAME" >> /etc/hosts
fi

echo "Nom d'hôte configuré : $FQDN"