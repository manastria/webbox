# Guide étudiant — WebBox

Ce guide explique comment configurer ton poste Windows et accéder à ton environnement de développement.

## Ce dont tu as besoin

- Ton poste Windows connecté au réseau du labo
- VS Code installé avec l'extension **Remote - SSH**
- Le nom du projet fourni par ton enseignant (ex : `tp-formulaires`)

---

## Étape 1 — Configurer le DNS (à faire une fois par session)

Pour que ton navigateur trouve `*.webbox.vm`, ton poste doit utiliser le serveur DNS de la VM.

1. Ouvre l'explorateur de fichiers Windows
2. Accède à `\\192.168.56.50\web\scripts\`
   > Si Windows demande un nom d'utilisateur et un mot de passe, saisis :
   > - Utilisateur : `etudiant`
   > - Mot de passe : `netlab123`
3. Fais un clic droit sur `dns-config.ps1` → **Exécuter avec PowerShell**
4. Accepte l'élévation en administrateur — la configuration se fait automatiquement

**Vérification :** ouvre un navigateur et va sur `http://traefik.webbox.vm`.
Tu dois voir le dashboard Traefik. Si la page s'affiche, le DNS fonctionne.

> **Important :** tape toujours `http://` devant l'adresse. Sans ce préfixe, le navigateur
> envoie `NOM_PROJET.webbox.vm` dans un moteur de recherche au lieu de contacter le DNS local.

---

## Étape 2 — Configurer la connexion SSH pour VS Code (à faire une fois par poste)

1. Dans l'explorateur, accède à `\\192.168.56.50\web\scripts\`
2. Fais un clic droit sur `setup-vscode-ssh.ps1` → **Exécuter avec PowerShell**
3. Appuie sur Entrée pour valider les valeurs par défaut (IP et utilisateur)
4. Le script crée automatiquement la clé SSH et configure `~/.ssh/config`

**Vérification dans VS Code :**

1. Ouvre VS Code
2. Appuie sur `F1` → tape `Remote-SSH: Connect to Host`
3. Sélectionne `webbox`
4. Une nouvelle fenêtre VS Code s'ouvre connectée à la VM

---

## Étape 3 — Créer ton projet

Si ton enseignant te demande de créer toi-même le projet, connecte-toi à la VM via SSH (voir étape 2) et ouvre un terminal. Trois modes sont disponibles.

### Mode 1 — Template WebBox (recommandé pour débuter)

Le script copie une structure PHP/MySQL/Node prête à l'emploi et démarre les conteneurs Docker.

```bash
sudo bash /home/etudiant/webbox/scripts/install/06_create_project.sh NOM_PROJET
```

À la fin, ton projet est immédiatement accessible sur `http://NOM_PROJET.webbox.vm`.

### Mode 2 — Cloner un dépôt Git existant

Utilise cette option si tu pars d'un dépôt existant (template fourni par l'enseignant, dépôt GitHub…).

```bash
# 1. Créer la structure d'accueil sans copier le template webbox
sudo bash /home/etudiant/webbox/scripts/install/06_create_project.sh --no-template NOM_PROJET

# 2. Cloner ton dépôt dans le dossier public/
git clone URL_DEPOT /home/etudiant/projets/NOM_PROJET/public/
```

Pour que l'application soit accessible via `http://NOM_PROJET.webbox.vm`, deux fichiers sont nécessaires **à la racine du projet** (pas dans `public/`) :

| Fichier              | Rôle                                                                                                                                                                                                                                                                      |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `docker-compose.yml` | Décrit les services à lancer : serveur web PHP/Apache (`NOM_PROJET-web`), base de données MySQL (`NOM_PROJET-db`), outils Node (`NOM_PROJET-node`). Il crée aussi la route Traefik qui fait pointer `NOM_PROJET.webbox.vm` vers ton conteneur.                            |
| `.env`               | Fichier de configuration lu par `docker-compose.yml`. Il lui fournit le nom du projet (pour nommer les conteneurs et l'URL), les identifiants de la base de données, etc. Il n'est **pas versionné** (présent dans `.gitignore`) : chaque développeur le crée localement. |

Si ton dépôt n'inclut pas ces fichiers, copie `docker-compose.yml` depuis le template WebBox et crée `.env` manuellement :

```bash
# Copier docker-compose.yml depuis le template
cp /home/etudiant/webbox/docker-compose.yml /home/etudiant/projets/NOM_PROJET/

# Créer le fichier .env (remplace NOM_PROJET par ton nom de projet)
cat <<EOF > /home/etudiant/projets/NOM_PROJET/.env
PROJECT_NAME=NOM_PROJET
WEBBOX_VERSION=1.0.0
XDEBUG_CLIENT_HOST=192.168.56.50
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=demo
MYSQL_USER=user
MYSQL_PASSWORD=password
EOF

# Démarrer les conteneurs
cd /home/etudiant/projets/NOM_PROJET
docker compose up -d --build
```

### Mode 3 — Partir de zéro (git init)

Utilise cette option pour créer un projet entièrement vierge et versionner ton code toi-même.

```bash
# 1. Créer la structure d'accueil sans copier le template
sudo bash /home/etudiant/webbox/scripts/install/06_create_project.sh --no-template NOM_PROJET

# 2. Initialiser un dépôt Git dans le dossier public/
cd /home/etudiant/projets/NOM_PROJET/public
git init
git commit --allow-empty -m "Initial commit"
```

Le dossier `public/` est déjà partagé via Samba (`\\192.168.56.50\NOM_PROJET`, lecteur `W:`).
Tu peux y créer tes fichiers PHP et les versionner au fil de ton travail.

#### Ce qui rend `http://NOM_PROJET.webbox.vm` accessible

L'URL fonctionne grâce à **Traefik**, le reverse proxy de l'infrastructure. Traefik surveille tous les conteneurs connectés au réseau `webbox-net` et les rend accessibles via leur sous-domaine. Pour qu'il redirige `NOM_PROJET.webbox.vm` vers ton conteneur, **trois conditions sont obligatoires** :

1. Le conteneur doit être connecté au réseau `webbox-net`
2. Le conteneur doit exposer un service HTTP sur un port (typiquement 80)
3. Le conteneur doit avoir les trois labels Traefik ci-dessous

PHP, MySQL et Node sont **optionnels** — tu peux utiliser n'importe quelle image qui sert du HTTP.

#### Fichier `docker-compose.yml` minimal annoté

Crée ce fichier à la racine du projet (`/home/etudiant/projets/NOM_PROJET/docker-compose.yml`) :

```yaml
# Réseau partagé par toute l'infrastructure WebBox.
# Traefik surveille ce réseau pour router les requêtes.
# Ne pas modifier ce nom.
networks:
  webbox-net:
    external: true

services:

  web:
    # Image PHP/Apache pré-configurée pour WebBox.
    # Tu peux la remplacer par n'importe quelle image qui sert du HTTP (nginx, node…).
    image: manastria/webbox-php:${WEBBOX_VERSION:-latest}

    # Nom du conteneur dans `docker ps`. OPTIONNEL mais recommandé :
    # sans lui Docker génère un nom aléatoire comme "mon-projet-web-1".
    container_name: ${PROJECT_NAME}-web

    # Monte ton code source (public/) dans le dossier servi par Apache.
    volumes:
      - ./public:/var/www/html

    # OBLIGATOIRE : connecte ce service au réseau Traefik.
    networks:
      - webbox-net

    # OBLIGATOIRE : ces trois labels indiquent à Traefik comment router le trafic.
    labels:
      # Active Traefik pour ce service (sans ça, Traefik l'ignore).
      - "traefik.enable=true"
      # Règle de routage : toute requête pour NOM_PROJET.webbox.vm → ce conteneur.
      - "traefik.http.routers.${PROJECT_NAME}.rule=Host(`${PROJECT_NAME}.webbox.vm`)"
      # Port sur lequel le conteneur écoute (Apache = 80).
      - "traefik.http.services.${PROJECT_NAME}.loadbalancer.server.port=80"

  # ── Base de données MySQL — OPTIONNEL ──────────────────────────────────────
  # Supprime ce bloc entier si ton projet n'utilise pas de base de données.
  # Si tu le gardes, le nom du serveur dans phpMyAdmin sera "${PROJECT_NAME}-db".
  # Le container_name est important ici : c'est lui que tu saisis dans phpMyAdmin.
  db:
    image: mysql:8.0
    container_name: ${PROJECT_NAME}-db
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    networks:
      - webbox-net

volumes:
  db_data:
```

#### Fichier `.env` minimal annoté

Crée ce fichier à la racine du projet (`/home/etudiant/projets/NOM_PROJET/.env`) :

```dotenv
# Ce fichier est lu par docker-compose.yml pour remplacer les variables ${...}.
# Il n'est PAS versionné (.gitignore l'exclut) : chaque développeur le crée localement.

# Nom du projet — utilisé pour :
#   • nommer les conteneurs : NOM_PROJET-web, NOM_PROJET-db
#   • construire l'URL     : http://NOM_PROJET.webbox.vm
PROJECT_NAME=mon-projet

# Version de l'image Docker WebBox (ne pas modifier sauf instruction enseignant).
WEBBOX_VERSION=1.0.0

# ── Variables MySQL — supprimer si pas de service "db" dans docker-compose.yml ──
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=demo
MYSQL_USER=user
MYSQL_PASSWORD=password
```

#### Démarrer les conteneurs

```bash
cd /home/etudiant/projets/NOM_PROJET
docker compose up -d --build
```

---

## Étape 4 — Monter le lecteur réseau (à chaque TP)

Le lecteur `W:` donne accès direct au dossier de ton projet depuis l'Explorateur Windows.

1. Dans l'explorateur, accède à `\\192.168.56.50\web\scripts\utilisateurs\`
2. Double-clique sur `LancerMontageLecteurs.bat`
3. Saisis le nom du projet indiqué par ton enseignant (ex : `tp-formulaires`)
4. Le lecteur `W:` est monté automatiquement

**Alternative PowerShell :**

```powershell
.\MountDrives.ps1 -ProjectName tp-formulaires
```

> Si une erreur *"multiple connections"* apparaît, ouvre un terminal et exécute :
>
> ```cmd
> net use * /delete
> ```
>
> Puis relance le script.

---

## Étape 5 — Accéder à ton application

Une fois le DNS configuré et le projet démarré :

| Ressource                    | URL                           |
| ---------------------------- | ----------------------------- |
| Ton site web                 | `http://NOM_PROJET.webbox.vm` |
| phpMyAdmin (base de données) | `http://pma.webbox.vm`        |

**Connexion phpMyAdmin :**

- Serveur : `NOM_PROJET-db` (ex : `tp-formulaires-db`)
- Utilisateur : `user`
- Mot de passe : `password`

---

## Étape 6 — Travailler sur le code

### Depuis VS Code (recommandé)

1. Connecte-toi à `webbox` via Remote SSH (voir étape 2)
2. Ouvre le dossier `/home/etudiant/projets/NOM_PROJET/`
3. Les fichiers PHP à modifier sont dans `public/`
4. Enregistre → actualise le navigateur → le changement est visible immédiatement

### Depuis l'Explorateur Windows

1. Ouvre le lecteur `W:` (monté à l'étape 4)
2. Modifie les fichiers PHP directement
3. Actualise le navigateur pour voir le résultat

---

## Résumé du workflow quotidien

```text
1. Lancer dns-config.ps1          → DNS = 192.168.56.50
2. Lancer LancerMontageLecteurs   → Lecteur W: = \\192.168.56.50\NOM_PROJET
3. Ouvrir VS Code → Remote SSH → webbox
4. Modifier les fichiers dans public/
5. Vérifier sur http://NOM_PROJET.webbox.vm
6. Base de données sur http://pma.webbox.vm (serveur : NOM_PROJET-db)
```

---

## Dépannage

### Le site ne s'affiche pas

- Vérifie que le DNS est bien configuré (étape 1)
- Vérifie l'URL : le nom du projet doit être exact (`tp-formulaires`, pas `tp_formulaires`)
- Demande à ton enseignant de vérifier que le projet est bien démarré

### Le lecteur W: n'apparaît pas dans l'Explorateur

- Exécute `net use * /delete` dans un terminal, puis relance `LancerMontageLecteurs.bat`
- Vérifie que la VM est bien joignable : `ping 192.168.56.50`

### VS Code ne se connecte pas

- Vérifie que le script `setup-vscode-ssh.ps1` a bien été exécuté sur ce poste
- Essaie la commande `ssh webbox` dans un terminal Windows pour voir l'erreur
- Réexécute `setup-vscode-ssh.ps1` si la clé a été supprimée

### Erreurs PHP s'affichent à l'écran

C'est normal : l'environnement est configuré en mode développement (`display_errors=On`).
Les erreurs sont là pour t'aider à déboguer.
