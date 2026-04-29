# WebBox - Cartographie des scripts VM et connexion etudiants

Ce document decrit les scripts utilises pour:

- preparer une VM Debian 12 (mode zero friction)
- connecter les postes Windows des etudiants a la VM

## 1) Objectif pedagogique

Le projet fournit un environnement LAMP dans Docker, avec une IP fixe en host-only (`192.168.56.50`).
Chaque projet est accessible via un sous-domaine : `http://NOM_PROJET.webbox.vm`.

Progression visee:

- debut de semestre: automatisation maximale (scripts prets a l'emploi)
- suite de semestre: montee en competence par configuration manuelle progressive

## 2) Architecture multi-projets

### Configuration reseau VirtualBox

La VM necessite deux interfaces reseau :

| Interface | Type VirtualBox | Utilisation |
| --------- | --------------- | ----------- |
| Interface 1 | **Reseau prive hote (Host-Only)** `192.168.56.0/24` | Communication avec les postes etudiants |
| Interface 2 | **NAT** | Acces a Internet (images Docker, paquets apt) |

```text
POSTE ETUDIANT (Windows)
  dns-config.ps1 → DNS = 192.168.56.50

VM (192.168.56.50)
  Technitium DNS  → *.webbox.vm = 192.168.56.50        (port 53)
  Traefik (80)    → tp-formulaires.webbox.vm → conteneur tp-formulaires-web
                  → tp-bdd.webbox.vm         → conteneur tp-bdd-web
                  → pma.webbox.vm            → phpMyAdmin (multi-serveurs)
                  → traefik.webbox.vm        → dashboard Traefik
```

### Deux couches Docker

**Infrastructure** (`infra/docker-compose.yml`) — lancee une fois, toujours active :

| Service        | URL                          | Role                   |
| -------------- | ---------------------------- | ---------------------- |
| Traefik        | `http://traefik.webbox.vm`   | Reverse proxy          |
| Technitium DNS | `192.168.56.50:5380`         | DNS wildcard           |
| phpMyAdmin     | `http://pma.webbox.vm`       | Acces BDD tous projets |

**Projet** (`docker-compose.yml`) — une instance par projet :

| Service     | Role                          |
| ----------- | ----------------------------- |
| `NOM-web`   | PHP/Apache, route via Traefik |
| `NOM-db`    | MySQL dedie au projet         |
| `NOM-node`  | Outils front (Gulp)           |

### Acces a la base de donnees

phpMyAdmin est en mode multi-serveurs (`PMA_ARBITRARY=1`).
Pour acceder a la BDD d'un projet, saisir comme serveur : `NOM_PROJET-db`.

### Partages reseau par projet

Chaque projet dispose d'un partage Samba cree par `06_create_project.sh` :

```text
\\192.168.56.50\NOM_PROJET  →  /home/etudiant/projets/NOM_PROJET/public
```

## 3) Variables communes (source de verite)

Fichier: `scripts/install/vars.sh`

Variables importantes:

- `USERNAME=etudiant`
- `USER_HOME=/home/etudiant`
- `IP_SITE=192.168.56.50`
- `VM_HOSTNAME=webbox`
- `DOMAIN=vm` (TLD DNS interne : `NOM_PROJET.webbox.vm`)
- `SHARE_NAME=web`
- `PROJECT_PATH=/home/etudiant/webbox`
- `PROJECTS_PATH=/home/etudiant/projets`
- `REPO_URL=https://github.com/manastria/webbox.git`
- `DOTFILES_URL=https://github.com/manastria/dotfile.git`
- `WEBBOX_VERSION=1.0.0` (version des images Docker Hub `manastria/webbox-php` et `manastria/webbox-node`)

## 4) Scripts shell de configuration Debian

### 4.1 Journalisation

Fichier: `scripts/lib/log.sh`

Role:

- fonction `log(TYPE, message)` avec niveaux `INFO`, `OK`, `STEP`, `WARN`, `ERROR`, `DEBUG`
- couleurs activees uniquement si sortie terminal interactive (`-t 1`)
- prefixes visuels integres : ne pas les repeter dans le message passe en argument

### 4.2 Installation principale poste etudiant

Fichier: `scripts/install/setup.sh`

Ce script orchestre la configuration machine cote Debian:

1. source `log.sh` et `vars.sh`
2. installe LXDE + utilitaires (LightDM, Firefox, pcmanfm, mousepad, gvfs-backends, php-cli, samba-client, console-setup)
3. appelle `01_add_user.sh`
4. force le clavier FR (AZERTY)
5. cree un raccourci bureau vers `http://192.168.56.50`
6. ajoute un favori samba (`smb://192.168.56.50/web`)
7. configure autostart LXDE (`setxkbmap fr`, lancement Firefox)
8. appelle `02_hostname.sh`
9. appelle `03_config_network.sh`
10. appelle `04_configure_samba.sh`
11. appelle `08_start_infra.sh` (infrastructure Docker + DNS)

Sortie attendue: environnement graphique pret, infrastructure Docker active, DNS configure.

### 4.3 Creation utilisateur + depot + dotfiles

Fichier: `scripts/install/01_add_user.sh`

Role:

- source `log.sh` et `vars.sh`
- cree l'utilisateur `etudiant` (mot de passe `netlab123`) si absent
- ajoute aux groupes `sudo,docker,admins`
- installe `yadm` si necessaire
- clone le depot WebBox (`REPO_URL`) dans `/home/etudiant/webbox`
- clone les dotfiles via `yadm clone $DOTFILES_URL`
- applique les dotfiles via `yadm reset --hard master`

Note: script idempotent partiel (verifie deja plusieurs etapes)

### 4.4 Cle SSH autorisee sur la VM

Fichier: `scripts/install/05_ajouter_cle_publique.sh`

Role:

- source `log.sh` et `vars.sh`
- cree `~/.ssh` pour `etudiant`
- ajoute une cle publique ed25519 predefinie dans `authorized_keys`
- corrige permissions (`700` dossier, `600` fichier)

Fichiers associes:

- `scripts/install/WebBox key` : cle privee OpenSSH
- `scripts/install/WebBox.ppk` : cle privee au format PuTTY (pour clients Windows sans VS Code)

### 4.5 Reseau host-only statique

Fichier: `scripts/install/03_config_network.sh`

Role:

- source `log.sh` et `vars.sh`
- cree une connexion NetworkManager `hostonly-static`
- fixe `eth0` a `$IP_SITE/24`
- sans gateway et sans DNS

Point d'attention: `eth0` hardcode (a valider selon image Debian/VirtualBox)

### 4.6 Nom d'hote

Fichier: `scripts/install/02_hostname.sh`

Role:

- source `log.sh` et `vars.sh`
- definit le hostname a `$VM_HOSTNAME` (`webbox`)
- met a jour `/etc/hosts` avec `webbox` (entree `127.0.1.1`, convention Debian)

### 4.7 Partages Samba initiaux

Fichier: `scripts/install/04_configure_samba.sh`

Role:

- source `vars.sh`
- installe Samba
- sauvegarde `/etc/samba/smb.conf` (horodatage ISO)
- ajoute les partages `[web]` et `[public]` pointant vers `$PROJECT_PATH`
- redemarre `smbd`
- cree utilisateur samba `etudiant` (mot de passe `netlab123`)

Note: ces partages correspondent au depot webbox lui-meme, avant creation de projets.

### 4.8 Demarrage de l'infrastructure Docker

Fichier: `scripts/install/08_start_infra.sh`

Role:

- verifie que Docker est disponible
- se place dans `$PROJECT_PATH/infra` et lance `docker compose up -d`
- appelle `07_configure_dns.sh`

### 4.9 Configuration DNS Technitium

Fichier: `scripts/install/07_configure_dns.sh`

Role:

- attend que Technitium DNS soit pret (port 5380, max 60s)
- obtient un token via l'API REST Technitium
- cree la zone primaire `webbox.vm`
- ajoute l'enregistrement wildcard `*.webbox.vm → $IP_SITE`

Idempotent : si la zone ou l'enregistrement existe deja, continue sans erreur.

### 4.10 Creation d'un nouveau projet

Fichier: `scripts/install/06_create_project.sh [--no-template] NOM_PROJET`

Role:

- valide le nom du projet (minuscules, chiffres, tirets)
- sans `--no-template` : copie le template depuis `$PROJECT_PATH` vers `$PROJECTS_PATH/NOM_PROJET/` et genere `.env`
- avec `--no-template` : cree uniquement les dossiers (dont `public/` pour Samba) sans copier le template ni generer `.env`
- ajoute un partage Samba `[NOM_PROJET]` → `.../NOM_PROJET/public`
- sans `--no-template` : lance `docker compose up -d --build`
- avec `--no-template` : affiche un WARN et les instructions pour lancer Docker manuellement

Sortie attendue (mode normal):

- `http://NOM_PROJET.webbox.vm` accessible depuis les postes etudiants
- `\\192.168.56.50\NOM_PROJET` montable en lecteur W:
- BDD accessible via `http://pma.webbox.vm` (serveur : `NOM_PROJET-db`)

Sortie attendue (mode `--no-template`):

- dossier `$PROJECTS_PATH/NOM_PROJET/public/` cree et partage Samba actif
- Docker non demarre : l'etudiant fournit son propre `docker-compose.yml` et `.env`

## 5) Scripts PowerShell cote Windows (etudiants)

### 5.1 Configuration DNS automatique

Fichier: `scripts/dns-config.ps1`

Role:

- elevation UAC automatique si necessaire
- detecte l'interface VirtualBox Host-Only via `InterfaceDescription`
- remet toutes les interfaces en DNS automatique (DHCP)
- affecte `192.168.56.50` uniquement sur l'interface Host-Only (metrique 5)
- donne une metrique basse (20) aux autres interfaces pour eviter les conflits
- vide le cache DNS et affiche un rapport de verification

Note: pas de reset manuel necessaire — les autres interfaces restent en DNS automatique.

### 5.2 Configuration SSH pour VS Code Remote

Fichier: `scripts/setup-vscode-ssh.ps1`

Role:

- demande interactivement l'IP (defaut `192.168.56.50`) et l'utilisateur (defaut `etudiant`)
- ecrit `~/.ssh/id_ed25519` avec la cle privee integree
- configure `~/.ssh/config` avec l'alias `Host webbox`

### 5.3 Montage lecteur reseau Windows

Fichiers: `scripts/utilisateurs/MountDrives.ps1`, `scripts/utilisateurs/LancerMontageLecteurs.bat`

Role:

- demande le nom du projet a monter (ex: `tp-formulaires`)
- monte `W:` → `\\192.168.56.50\NOM_PROJET`
- mode legacy (nom vide) : monte `W:` → `web` et `P:` → `public`
- gere credentials (`etudiant` / `netlab123` par defaut)

Passage de parametre possible : `MountDrives.ps1 -ProjectName tp-formulaires`

## 6) Workflow

### Cote VM (enseignant / image master)

1. executer `setup.sh` (configure OS + demarre infra Docker + configure DNS)
2. verifier `http://traefik.webbox.vm` (dashboard Traefik)
3. verifier `http://192.168.56.50:5380` (Technitium DNS, zone webbox.vm)
4. creer un premier projet : `sudo scripts/install/06_create_project.sh tp-demo`
   (l'infrastructure doit etre active : `cd ~/webbox/infra && docker compose up -d`)
5. (option) executer `05_ajouter_cle_publique.sh` si SSH sans mot de passe requis

### Cote etudiant (Windows)

1. lancer `dns-config.ps1` (DNS → `192.168.56.50`, detection auto Host-Only)
2. connecter VS Code via `setup-vscode-ssh.ps1`
3. monter le lecteur : `LancerMontageLecteurs.bat` (saisir le nom du projet)
4. travailler sur `W:\` et verifier sur `http://NOM_PROJET.webbox.vm`
5. BDD : `http://pma.webbox.vm` (serveur : `NOM_PROJET-db`)

## 7) Documentation utilisateur

Les guides utilisateurs sont dans le répertoire `docs/` :

- `docs/guide-enseignant.md` — installation VM, creation de projets, maintenance
- `docs/guide-etudiant.md` — configuration DNS, SSH, creation de projet (3 modes : template, git clone, git init), lecteur reseau, workflow quotidien
- `docs/images-docker.md` — build et publication des images Docker Hub (usage enseignant)

## 8) Principes de redaction de la documentation

Deux publics distincts, deux postures d'ecriture.

### 8.1 Documentation enseignant

Public : enseignant qui doit comprendre l'architecture pour concevoir des activites et les proposer aux etudiants.

Posture : **pedagogique et technique**. Expliquer les choix d'architecture, pas seulement les commandes.

Regles :

- Justifier chaque choix technique par son utilite pedagogique ou operationnelle.
  - Exemple : "Traefik permet d'heberger plusieurs projets dans la meme VM sans changer de port — chaque projet est accessible par son sous-domaine."
  - Exemple : "L'interface host-only avec IP fixe `192.168.56.50` supprime toute friction en debut d'annee : tous les etudiants ont la meme adresse, la documentation n'a pas besoin d'etre personnalisee."
- Documenter les decisions non evidentes (pourquoi Technitium plutot que dnsmasq, pourquoi `PMA_ARBITRARY=1`, etc.).
- Inclure les commandes de verification et de diagnostic.
- Le lecteur doit pouvoir modifier, etendre ou deboguer l'environnement sans aide exterieure.

### 8.2 Documentation etudiant

Public : etudiant qui doit accomplir une tache précise dans un environnement qu'il n'a pas installé.

Posture : **operationnelle avec explication du pourquoi**. Dire ce qu'il faut faire ET expliquer la technologie sous-jacente qui justifie cette action.

Regles :

- Ne pas supposer que l'etudiant connait la technologie ; introduire brievement le concept quand il conditionne une action.
  - Exemple : "Pour que ton site soit accessible, tu dois ajouter le label `traefik.enable=true` dans ton `docker-compose.yml`. Traefik est un reverse proxy : il recoit toutes les requetes HTTP et les redirige vers le bon conteneur en lisant le nom de domaine. Sans ce label, Traefik ignore ton conteneur."
- Privilegier les etapes numerotees et les blocs de code copiables.
- Eviter les explications d'architecture globale (Traefik, Technitium, VirtualBox) — se limiter a ce que l'etudiant doit savoir pour realiser l'action.
- Les messages d'erreur courants doivent apparaitre avec leur cause et la correction.

### 8.3 Frontiere entre les deux guides

Si une information repond a "pourquoi la webbox est construite ainsi" → guide enseignant.
Si une information repond a "comment je fais X dans la webbox" avec explication suffisante pour comprendre → guide etudiant.

## 9) Zones a optimiser (pour la suite)

Axes deja traites:

- tous les scripts sourcent `vars.sh` et `log.sh`
- scripts renommes avec prefixe numerique
- `setup-lxde.sh` renomme en `setup.sh`
- architecture multi-projets : Traefik + Technitium DNS + `06_create_project.sh`
- `MountDrives.ps1` parametrable par nom de projet
- secrets en clair conserves intentionnellement (contexte pedagogique)
- documentation utilisateur centralisee dans `docs/`
- images Docker PHP et Node pre-construites et publiees sur Docker Hub (plus de build sur la VM)
- option `--no-template` dans `06_create_project.sh` : creation workspace vierge pour git clone ou git init

Axes encore a traiter:

- robustesse multi-interface : `eth0` hardcode dans `03_config_network.sh`, `Ethernet` dans les scripts PS rapides
- idempotence globale et gestion d'erreurs uniforme
