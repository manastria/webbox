# Images Docker WebBox — Build et publication

Ce guide concerne la **maintenance des images de base** utilisées par les projets étudiants.
Il s'adresse à l'enseignant qui maintient le dépôt, pas aux étudiants.

## Contexte

Les projets WebBox utilisent deux images pré-construites publiées sur Docker Hub :

| Image | Rôle | Base |
| ----- | ---- | ---- |
| `manastria/webbox-php` | Serveur Apache + PHP 8.2 + extensions + Xdebug | `php:8.2-apache` |
| `manastria/webbox-node` | Outils front Gulp | `node:20-alpine` |

Ces images sont construites **une seule fois** depuis un poste développeur, puis **tirées (pull)** par chaque VM au démarrage d'un projet. Cela évite de recompiler les extensions PHP sur chaque VM.

```
Poste développeur                    VM (Debian)
──────────────────                   ────────────
docker build + push  →  Docker Hub  →  docker pull (06_create_project.sh)
```

---

## Prérequis

- Docker installé sur le poste développeur
- Compte Docker Hub avec accès en écriture à `manastria/webbox-php` et `manastria/webbox-node`
- Être connecté : `docker login`

---

## Structure des sources

```text
images/
  php/
    Dockerfile          ← image PHP/Apache
  node/
    Dockerfile          ← image Node/Gulp
VERSION                 ← numéro de version actuel (ex : 1.0.0)
scripts/
  build-push-images.sh  ← script de build et publication
```

Les fichiers de configuration PHP montés en volume dans les projets sont **indépendants** de l'image :

```text
php/
  xdebug.ini   ← injecté via volume dans chaque projet (xdebug, mode debug)
  99-dev.ini   ← injecté via volume dans chaque projet (display_errors, etc.)
```

---

## Publier une nouvelle version

### 1. Modifier les sources si nécessaire

Les Dockerfiles sont dans `images/php/` et `images/node/`. Exemples de modifications courantes :

- Changer la version PHP : `FROM php:8.3-apache`
- Ajouter une extension : `docker-php-ext-install soap`
- Mettre à jour l'outil Gulp : `npm install -g gulp-cli@latest`

### 2. Incrémenter la version

Le numéro de version suit [Semantic Versioning](https://semver.org/) :

| Changement | Exemple |
| ---------- | ------- |
| Correctif ou mise à jour de sécurité | `1.0.0` → `1.0.1` |
| Nouvelle extension ou outil | `1.0.0` → `1.1.0` |
| Changement de version PHP ou Node majeure | `1.0.0` → `2.0.0` |

Mettre à jour les deux fichiers :

```bash
# Fichier VERSION (source de vérité pour le script de build)
echo "1.1.0" > VERSION

# vars.sh (source de vérité pour les scripts d'installation VM)
# Modifier la ligne : WEBBOX_VERSION="1.1.0"
```

### 3. Builder et publier

```bash
docker login   # si pas encore connecté

bash scripts/build-push-images.sh
```

Le script :
1. Lit la version dans `VERSION`
2. Build chaque image avec le tag `X.Y.Z` et `latest`
3. Pousse les deux tags sur Docker Hub

Sortie attendue :

```text
========================================
  Publication images WebBox v1.1.0
========================================

--- Build manastria/webbox-php ---
[...]
--- Push manastria/webbox-php ---
[...]

Images publiées :
  docker.io/manastria/webbox-php:1.1.0
  docker.io/manastria/webbox-node:1.1.0
```

---

## Mettre à jour les VMs existantes

Après publication d'une nouvelle version, les VMs qui ont déjà des projets actifs continuent
d'utiliser l'ancienne version (les conteneurs en cours ne sont pas affectés).

Pour mettre à jour un projet existant sur la VM :

```bash
cd /home/etudiant/projets/NOM_PROJET

# 1. Mettre à jour le .env avec la nouvelle version
sed -i 's/^WEBBOX_VERSION=.*/WEBBOX_VERSION=1.1.0/' .env

# 2. Tirer les nouvelles images et relancer
docker compose pull web node
docker compose up -d
```

Pour mettre à jour tous les projets d'un coup :

```bash
for dir in /home/etudiant/projets/*/; do
    sed -i 's/^WEBBOX_VERSION=.*/WEBBOX_VERSION=1.1.0/' "$dir/.env"
    (cd "$dir" && docker compose pull web node && docker compose up -d)
done
```

Les **nouveaux projets** créés après la mise à jour de `vars.sh` utilisent automatiquement
la nouvelle version via `06_create_project.sh`.

---

## Référence des images

### `manastria/webbox-php`

Extensions PHP incluses : `zip`, `mysqli`, `pdo_mysql`, `mbstring`, `intl`, `ctype`,
`fileinfo`, `gd`, `opcache`, `bcmath`, Xdebug (via PECL).

Module Apache activé : `mod_rewrite`.

Configuration injectée via volumes depuis `php/` du projet :

| Fichier | Rôle |
| ------- | ---- |
| `xdebug.ini` | Mode debug, `start_with_request=yes`, lien VS Code |
| `99-dev.ini` | `display_errors=On`, `error_reporting=E_ALL` |

### `manastria/webbox-node`

Outil global installé : `gulp-cli`.

Basée sur `node:20-alpine` (~150 Mo vs ~1 Go pour `node:20`).

---

## Dépannage

### L'image ne se télécharge pas sur la VM

```bash
# Vérifier que la VM a accès à internet (interface NAT)
docker pull manastria/webbox-php:1.0.0

# Si timeout : vérifier la route par défaut
ip route
```

### Forcer la mise à jour d'une image

```bash
docker pull manastria/webbox-php:latest
docker compose up -d --force-recreate web
```

### Revenir à une version précédente

```bash
# Dans le .env du projet
WEBBOX_VERSION=1.0.0

docker compose up -d
```
