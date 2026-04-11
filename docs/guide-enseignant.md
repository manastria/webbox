# Guide enseignant — WebBox

Ce guide couvre la préparation de la VM, la création de projets et la maintenance.

## Prérequis

- VirtualBox installé sur le poste enseignant
- VM Debian 12 importée avec Docker pré-installé
- VM configurée avec **deux interfaces réseau** dans VirtualBox :
  - Interface 1 — **Réseau privé hôte (*Host-Only*)** sur `192.168.56.0/24` : communication avec les postes étudiants
  - Interface 2 — **NAT** : accès à Internet pour télécharger les images Docker et les paquets
- Accès à Internet depuis la VM (vérifié via l'interface NAT)
- Vérifier que l'affichage dans VirtualBox utilise le controlleur graphique « **VMSVGA** »

---

## 1. Première installation de la VM

### 1.1 Cloner le dépôt et configurer l'OS

Se connecter à la VM (console ou SSH), cloner le dépôt, puis exécuter le script principal :

```bash
git clone https://github.com/manastria/webbox.git webbox
```

Ensuite :

```bash
sudo bash ./scripts/install/setup.sh
```

Ce script réalise en séquence :

| Étape | Script | Action |
| ----- | ------ | ------ |
| 1 | `01_add_user.sh` | Crée l'utilisateur `etudiant`, clone le dépôt WebBox et les dotfiles |
| 2 | `02_hostname.sh` | Définit le hostname (`webbox`) |
| 3 | `03_config_network.sh` | Configure l'IP fixe `192.168.56.50` sur `eth0` |
| 4 | `04_configure_samba.sh` | Installe Samba, partages `web` et `public` |
| 5 | `08_start_infra.sh` | Démarre Traefik, Technitium DNS, phpMyAdmin et configure le DNS |

Durée estimée : **5 à 15 minutes** selon la connexion Internet.

### 1.2 Vérifications post-installation

Depuis un poste Windows dont le DNS pointe vers `192.168.56.50` :

| URL                                 | Attendu                                      |
| ----------------------------------- | -------------------------------------------- |
| `http://traefik.webbox.vm`          | Dashboard Traefik (liste des routes actives) |
| `http://pma.webbox.vm`              | Interface phpMyAdmin                         |
| `http://192.168.56.50:5380`         | Interface admin Technitium DNS               |

> **Technitium DNS** — identifiants par défaut : `admin` / `netlab123`
> 
>Vérifier que la zone `webbox` existe et contient l'enregistrement `* A 192.168.56.50`.

### 1.3 Ajouter la clé SSH (optionnel)

Pour permettre la connexion SSH sans mot de passe depuis les postes étudiants :

```bash
sudo bash /home/etudiant/webbox/scripts/install/05_ajouter_cle_publique.sh
```

---

## 2. Créer un projet pour un TP

Chaque TP correspond à un **projet indépendant** avec sa propre URL, sa propre base de données et son propre partage réseau.

### 2.1 Commande de création

```bash
sudo bash /home/etudiant/webbox/scripts/install/06_create_project.sh NOM_PROJET
```

**Règles de nommage :** lettres minuscules, chiffres et tirets uniquement.
Exemples valides : `tp-formulaires`, `tp-bdd`, `projet-final`

Ce que le script fait automatiquement :

1. Copie le template dans `/home/etudiant/projets/NOM_PROJET/`
2. Génère le fichier `.env` avec `PROJECT_NAME=NOM_PROJET`
3. Ajoute le partage Samba `\\192.168.56.50\NOM_PROJET`
4. Démarre les conteneurs Docker (`NOM_PROJET-web`, `NOM_PROJET-db`, `NOM_PROJET-node`)

### 2.2 Résultat

| Ressource | Valeur |
| --------- | ------ |
| URL application | `http://NOM_PROJET.webbox.vm` |
| Base de données (phpMyAdmin) | Serveur : `NOM_PROJET-db` |
| Partage réseau Windows | `\\192.168.56.50\NOM_PROJET` |
| Dossier sur la VM | `/home/etudiant/projets/NOM_PROJET/public/` |

### 2.3 Exemple concret

```bash
# Créer un TP sur les formulaires PHP
sudo bash /home/etudiant/webbox/scripts/install/06_create_project.sh tp-formulaires

# Résultat :
#   http://tp-formulaires.webbox.vm
#   \\192.168.56.50\tp-formulaires  (→ lecteur W: sur Windows)
#   BDD : http://pma.webbox.vm, serveur tp-formulaires-db
```

---

## 3. Préparer les postes étudiants

### 3.1 Ce que chaque étudiant doit exécuter

Distribuer les scripts suivants (présents sur `\\192.168.56.50\web\scripts\`, identifiants : `etudiant` / `netlab123`) :

| Script | Rôle | Fréquence |
| ------ | ---- | --------- |
| `dns-config.ps1` | Configure le DNS Windows vers `192.168.56.50` (détection auto) | Une fois par session |
| `setup-vscode-ssh.ps1` | Configure la connexion SSH pour VS Code | Une fois par poste |
| `utilisateurs/LancerMontageLecteurs.bat` | Monte le lecteur réseau `W:` | Chaque TP |

Voir le [guide étudiant](guide-etudiant.md) pour les instructions pas à pas.

### 3.2 Point d'attention réseau

Le DNS étudiant **doit** pointer vers `192.168.56.50` pour que `*.webbox.vm` fonctionne.
`dns-config.ps1` le configure automatiquement. En cas de problème :

```powershell
# Vérifier la résolution DNS depuis Windows
nslookup tp-formulaires.webbox.vm 192.168.56.50
```

---

## 4. Gestion des projets

### 4.1 Lister les projets actifs

```bash
# Conteneurs en cours
docker ps --format "table {{.Names}}\t{{.Status}}"

# Dossiers projets
ls /home/etudiant/projets/

# Partages Samba
sudo smbclient -L localhost -U etudiant
```

### 4.2 Arrêter / relancer un projet

```bash
cd /home/etudiant/projets/NOM_PROJET

# Arrêter
docker compose down

# Relancer
docker compose up -d

# Voir les logs
docker compose logs -f web
```

### 4.3 Accéder à la base de données en ligne de commande

```bash
docker exec -it NOM_PROJET-db mysql -u user -ppassword demo
```

### 4.4 Redémarrer l'infrastructure

```bash
cd /home/etudiant/webbox
docker compose -f docker-compose.infra.yml restart
```

### 4.5 Supprimer un projet

```bash
sudo bash /home/etudiant/webbox/scripts/install/09_delete_project.sh NOM_PROJET
```

Le script demande une confirmation, puis supprime dans l'ordre :

1. Les conteneurs Docker et leurs volumes (`docker compose down -v`)
2. Le partage Samba `[NOM_PROJET]` dans `/etc/samba/smb.conf`
3. Le dossier `/home/etudiant/projets/NOM_PROJET/`

> **Attention :** la suppression des volumes Docker efface définitivement la base de données du projet.

---

## 5. Préparer une image VM master

Pour dupliquer la VM configurée sur plusieurs postes :

1. Exécuter `setup.sh` jusqu'à la fin (ou manuellement jusqu'à l'étape souhaitée)
2. Créer les projets nécessaires avec `06_create_project.sh`
3. Arrêter proprement la VM :
   ```bash
   docker compose -f /home/etudiant/webbox/docker-compose.infra.yml down
   sudo shutdown -h now
   ```
4. Exporter l'appliance VirtualBox (`.ova`)
5. À l'import sur chaque poste, VirtualBox réassigne l'interface réseau host-only automatiquement

> **Important :** après import, vérifier que l'interface réseau est bien configurée en Host-Only
> et que l'adresse IP obtenue est bien `192.168.56.50` (statique via NetworkManager).

---

## 6. Référence rapide

```text
VM IP          : 192.168.56.50
Hostname       : webbox
Utilisateur    : etudiant / netlab123
Samba          : \\192.168.56.50\web  (dépôt webbox)
                 \\192.168.56.50\NOM_PROJET  (par projet)
  Identifiants : etudiant / netlab123

Infrastructure Docker (~/webbox/) :
  http://traefik.webbox.vm     → dashboard routes
  http://pma.webbox.vm         → phpMyAdmin (serveur = NOM_PROJET-db)
  http://192.168.56.50:5380    → Technitium DNS (admin/netlab123)

Par projet (~/projets/NOM_PROJET/) :
  http://NOM_PROJET.webbox.vm  → application PHP
  NOM_PROJET-web               → conteneur Apache/PHP
  NOM_PROJET-db                → conteneur MySQL
```
