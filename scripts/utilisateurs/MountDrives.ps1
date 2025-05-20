#Requires -Version 3.0
<#
.SYNOPSIS
  Monte des lecteurs réseau spécifiés de manière persistante.
.DESCRIPTION
  Ce script permet de monter deux lecteurs réseau (W: et P:) vers des partages sur un serveur distant.
  Les lecteurs montés seront persistants (visibles dans l'Explorateur et tenteront de se reconnecter au démarrage).
  Il peut utiliser des identifiants pré-configurés ou les demander à l'utilisateur si non définis.
  Des messages colorés informent l'utilisateur de la progression et des éventuels problèmes.
.NOTES
  Auteur: VotreNom/Société
  Version: 1.2
  Date: 20/05/2025

  ATTENTION : Ce script peut contenir des identifiants (nom d'utilisateur et mot de passe)
  en clair. C'est une pratique non sécurisée pour des environnements de production.
  Elle est utilisée ici à des fins pédagogiques pour des débutants.
  Il est fortement recommandé de sécuriser les accès dès que possible.
#>

# --- Configuration ---
# Adresse IP du serveur. Laisser vide pour que le script la demande.
$AdresseIPServeur = "192.168.56.50" # Exemple, à adapter ou laisser vide ""

# Identifiants de connexion.
# ATTENTION : Stocker des mots de passe en clair dans un script est une mauvaise pratique de sécurité.
# Si $NomUtilisateurConfig OU $MotDePasseEnClairConfig sont vides, le script demandera les identifiants.
$NomUtilisateurConfig = "etudiant"
$MotDePasseEnClairConfig = "netlab123" # LAISSER VIDE "" POUR FORCER LA DEMANDE INTERACTIVE

# Définition des lecteurs à monter
$Lecteurs = @(
    @{Lettre = "W"; CheminPartage = "web"   ; Description = "Dossier Web"}
    @{Lettre = "P"; CheminPartage = "public"; Description = "Dossier Public"}
)

# --- Fonctions Utilitaires ---

function Write-ColoredMessage {
    param (
        [string]$Message,
        [System.ConsoleColor]$Color = "White",
        [switch]$NewLine = $true
    )
    if ($NewLine) {
        Write-Host $Message -ForegroundColor $Color
    } else {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    }
}

# --- Début du Script ---

Clear-Host
Write-ColoredMessage "===============================================" -Color Cyan
Write-ColoredMessage "   Assistant de Montage des Lecteurs Réseau    " -Color Cyan
Write-ColoredMessage "===============================================" -Color Cyan
Write-Host # Ligne vide

# Demander l'adresse IP du serveur si non configurée
if ([string]::IsNullOrWhiteSpace($AdresseIPServeur)) {
    while ([string]::IsNullOrWhiteSpace($AdresseIPServeur)) {
        $AdresseIPServeur = Read-Host "Veuillez entrer l'adresse IP du serveur (ex: 192.168.56.50)"
        if (-not ($AdresseIPServeur -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$")) {
            Write-ColoredMessage "L'adresse IP '$AdresseIPServeur' ne semble pas valide. Veuillez réessayer." -Color Red
            $AdresseIPServeur = "" # Réinitialiser pour redemander
        }
    }
} else {
    Write-ColoredMessage "Utilisation de l'adresse IP configurée : $AdresseIPServeur" -Color Yellow
}

# Gestion des identifiants
Write-Host # Ligne vide
$Credential = $null

if ([string]::IsNullOrWhiteSpace($NomUtilisateurConfig) -or [string]::IsNullOrWhiteSpace($MotDePasseEnClairConfig)) {
    Write-ColoredMessage "Identifiants non configurés ou partiellement configurés dans le script." -Color Yellow
    Write-ColoredMessage "Demande interactive des identifiants pour le serveur $AdresseIPServeur..." -Color Yellow
    $NomTemp = if ([string]::IsNullOrWhiteSpace($NomUtilisateurConfig)) { $null } else { $NomUtilisateurConfig }
    $Credential = Get-Credential -UserName $NomTemp -Message "Entrez vos identifiants pour le serveur $AdresseIPServeur"

    if (-not $Credential) {
        Write-ColoredMessage "Aucun identifiant fourni. Le script va s'arrêter." -Color Red
        Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1
    }
} else {
    Write-ColoredMessage "Utilisation des identifiants configurés dans le script pour '$NomUtilisateurConfig'." -Color Yellow
    Write-ColoredMessage "ATTENTION : Le mot de passe est stocké en clair dans ce script." -Color Magenta
    try {
        $SecureMotDePasse = ConvertTo-SecureString -String $MotDePasseEnClairConfig -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($NomUtilisateurConfig, $SecureMotDePasse)
    } catch {
        Write-ColoredMessage "ERREUR : Impossible de créer l'objet Credential à partir des identifiants configurés. $($_.Exception.Message)" -Color Red
        Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1
    }
}

Write-Host # Ligne vide
Write-ColoredMessage "Début du montage des lecteurs..." -Color Cyan

# Traiter chaque lecteur défini
foreach ($LecteurInfo in $Lecteurs) {
    $LettreLecteur = $LecteurInfo.Lettre
    $CheminPartageComplet = "\\$AdresseIPServeur\$($LecteurInfo.CheminPartage)"
    $DescriptionLecteur = $LecteurInfo.Description

    Write-ColoredMessage ("-" * 40) -Color Gray
    Write-ColoredMessage "Traitement du lecteur $LettreLecteur`: ($DescriptionLecteur) vers $CheminPartageComplet" -Color White

    # 1. Démontage préventif (plus robuste)
    Write-ColoredMessage "  Vérification et tentative de démontage du lecteur $LettreLecteur`: ..." -NoNewline -Color Yellow
    # Essayer de supprimer un PSDrive s'il existe
    $existingPSDrive = Get-PSDrive $LettreLecteur -ErrorAction SilentlyContinue
    if ($existingPSDrive) {
        try {
            Remove-PSDrive -Name $LettreLecteur -Force -ErrorAction SilentlyContinue # SilentlyContinue ici car net use suivra
            Write-Host -NoNewline "." -ForegroundColor Yellow
        } catch {
            # Ignorer l'erreur ici, net use s'en chargera
            Write-Host -NoNewline "x" -ForegroundColor Yellow
        }
    }
    
    # Utiliser 'net use /delete' pour une suppression plus complète des mappages existants
    net use $LettreLecteur /delete /Y > $null 2>&1
    $exitCodeNetUseDelete = $LASTEXITCODE
    
    if ($exitCodeNetUseDelete -eq 0) {
        Write-ColoredMessage " Démontage réussi (ou pas de mappage existant via net use)." -Color Green
    } elseif ($exitCodeNetUseDelete -eq 2) { # Code 2 = lecteur non mappé, ce qui est OK.
        Write-ColoredMessage " OK (lecteur non trouvé, donc pas besoin de démonter via net use)." -Color Cyan
    } else {
        Write-ColoredMessage " AVERTISSEMENT lors du démontage via net use (Code: $exitCodeNetUseDelete). Conflit possible." -Color Yellow
    }

    # 2. Tentative de montage du nouveau lecteur
    Write-ColoredMessage "  Montage du lecteur $LettreLecteur`: vers $CheminPartageComplet..." -NoNewline -Color Yellow
    try {
        # Utilisation de -Persist pour rendre le lecteur visible dans l'Explorateur et persistant
        New-PSDrive -Name $LettreLecteur -PSProvider FileSystem -Root $CheminPartageComplet -Credential $Credential -Scope Global -Persist -ErrorAction Stop
        Write-ColoredMessage " RÉUSSI !" -Color Green

        # Vérification après montage
        # Pour Test-Path sur un lecteur, il est préférable d'utiliser "X:\"
        if (Test-Path "${LettreLecteur}:\") {
            Write-ColoredMessage "  Vérification : Le lecteur $LettreLecteur`: est accessible." -Color Green
        } else {
            Write-ColoredMessage "  AVERTISSEMENT : Le lecteur $LettreLecteur`: semble monté mais Test-Path n'y accède pas. Vérifiez manuellement." -Color Yellow
        }

    } catch {
        Write-ColoredMessage " ÉCHEC !" -Color Red
        $ErrorMessage = $_.Exception.Message
        Write-ColoredMessage "  ERREUR : Impossible de monter le lecteur $LettreLecteur`:. $ErrorMessage" -Color Red
        
        # Gestion de l'erreur commune "multiple connections"
        if ($ErrorMessage -like "*multiple connections to a server or shared resource by the same user*") {
            Write-ColoredMessage "  CAUSE POSSIBLE : Connexion existante au serveur '$AdresseIPServeur' avec des identifiants différents." -Color Magenta
            Write-ColoredMessage "  SOLUTION SUGGÉRÉE : Déconnectez toutes les connexions à ce serveur (via 'net use * /delete' ou l'Explorateur) et réessayez." -Color Magenta
        } else {
            Write-ColoredMessage "  Vérifiez l'adresse IP, le nom du partage, vos identifiants et votre connexion réseau." -Color Red
        }
    }
}

Write-ColoredMessage ("-" * 40) -Color Gray
Write-Host # Ligne vide
Write-ColoredMessage "Opération terminée." -Color Cyan
Write-ColoredMessage "Veuillez vérifier la présence des lecteurs dans l'Explorateur de fichiers." -Color White
Read-Host "Appuyez sur la touche Entrée pour fermer cette fenêtre."
