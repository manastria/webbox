# Guide étudiant — WebBox

Ce guide explique comment configurer ton poste Windows et accéder à ton environnement de développement.

## Ce dont tu as besoin

- Ton poste Windows connecté au réseau de la salle
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

## Étape 3 — Monter le lecteur réseau (à chaque TP)

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

## Étape 4 — Accéder à ton application

Une fois le DNS configuré et le projet démarré par ton enseignant :

| Ressource | URL |
| --------- | --- |
| Ton site web | `http://NOM_PROJET.webbox.vm` |
| phpMyAdmin (base de données) | `http://pma.webbox.vm` |

**Connexion phpMyAdmin :**

- Serveur : `NOM_PROJET-db` (ex : `tp-formulaires-db`)
- Utilisateur : `user`
- Mot de passe : `password`

---

## Étape 5 — Travailler sur le code

### Depuis VS Code (recommandé)

1. Connecte-toi à `webbox` via Remote SSH (voir étape 2)
2. Ouvre le dossier `/home/etudiant/projets/NOM_PROJET/`
3. Les fichiers PHP à modifier sont dans `public/`
4. Enregistre → actualise le navigateur → le changement est visible immédiatement

### Depuis l'Explorateur Windows

1. Ouvre le lecteur `W:` (monté à l'étape 3)
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
