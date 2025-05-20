#Requires -Version 3.0
<#
.SYNOPSIS
  Monte des lecteurs réseau spécifiés.
.DESCRIPTION
  Ce script permet de monter deux lecteurs réseau (W: et P:) vers des partages sur un serveur distant.
  Il peut utiliser des identifiants pré-configurés ou les demander à l'utilisateur si non définis.
  Des messages colorés informent l'utilisateur de la progression et des éventuels problèmes.
.NOTES
  Auteur: VotreNom/Société
  Version: 1.1
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
# Pour cet exercice pédagogique, ils sont ici. Pour une utilisation réelle, envisagez des solutions plus sûres.
# Si $NomUtilisateur OU $MotDePasseEnClair sont vides, le script demandera les identifiants.
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
    $Credential = Get-Credential -UserName $NomUtilisateurConfig -Message "Entrez vos identifiants pour le serveur $AdresseIPServeur"

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

    # 1. Vérifier si le lecteur est déjà monté
    $LecteurExistant = Get-PSDrive $LettreLecteur -ErrorAction SilentlyContinue
    if ($LecteurExistant) {
        Write-ColoredMessage "  Le lecteur $LettreLecteur`: existe déjà. Tentative de démontage..." -Color Yellow
        try {
            Remove-PSDrive -Name $LettreLecteur -Force -ErrorAction Stop
            Write-ColoredMessage "  Lecteur $LettreLecteur`: démonté avec succès." -Color Green
        } catch {
            Write-ColoredMessage "  ERREUR lors du démontage du lecteur $LettreLecteur`:. $($_.Exception.Message)" -Color Red
            Write-ColoredMessage "  Veuillez vérifier qu'aucun fichier de ce lecteur n'est ouvert et réessayez." -Color Red
            continue
        }
    }

    # 2. Tentative de montage du nouveau lecteur
    Write-ColoredMessage "  Montage du lecteur $LettreLecteur`: vers $CheminPartageComplet..." -NoNewline -Color Yellow
    try {
        New-PSDrive -Name $LettreLecteur -PSProvider FileSystem -Root $CheminPartageComplet -Credential $Credential -Scope Global -ErrorAction Stop # -Persist
        Write-ColoredMessage " RÉUSSI !" -Color Green

        if (Test-Path "${LettreLecteur}:") {
            Write-ColoredMessage "  Vérification : Le lecteur $LettreLecteur`: est accessible." -Color Green
        } else {
            Write-ColoredMessage "  AVERTISSEMENT : Le lecteur $LettreLecteur`: a été monté mais n'est pas immédiatement accessible. Un problème subsiste peut-être." -Color Yellow
        }

    } catch {
        Write-ColoredMessage " ÉCHEC !" -Color Red
        Write-ColoredMessage "  ERREUR : Impossible de monter le lecteur $LettreLecteur`:. $($_.Exception.Message)" -Color Red
        Write-ColoredMessage "  Vérifiez l'adresse IP, le nom du partage, vos identifiants et votre connexion réseau." -Color Red
    }
}

Write-ColoredMessage ("-" * 40) -Color Gray
Write-Host # Ligne vide
Write-ColoredMessage "Opération terminée." -Color Cyan
Read-Host "Appuyez sur la touche Entrée pour fermer cette fenêtre."