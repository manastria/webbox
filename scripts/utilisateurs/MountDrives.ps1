#Requires -Version 3.0
<#
.SYNOPSIS
  Monte un lecteur réseau vers un projet WebBox.
.DESCRIPTION
  Monte le dossier public d'un projet WebBox en lecteur W: (persistant).
  Si aucun nom de projet n'est fourni, le script le demande interactivement.
  Pour revenir aux anciens partages 'web' et 'public', laisser le nom vide.
.NOTES
  ATTENTION : Ce script peut contenir des identifiants en clair.
  Usage pédagogique uniquement.
#>

param(
    # Nom du projet à monter (ex: tp-formulaires). Laisser vide pour mode interactif.
    [string]$ProjectName = ""
)

# --- Configuration ---
$AdresseIPServeur     = "192.168.56.50"
$NomUtilisateurConfig = "etudiant"
$MotDePasseEnClairConfig = "netlab123"

# --- Fonctions ---
function Write-ColoredMessage {
    param(
        [string]$Message,
        [System.ConsoleColor]$Color = "White",
        [bool]$NewLine = $true
    )
    if ($NewLine) { Write-Host $Message -ForegroundColor $Color }
    else          { Write-Host $Message -ForegroundColor $Color -NoNewline }
}

function Mount-Lecteur {
    param(
        [string]$Lettre,
        [string]$CheminPartage,
        [string]$Description,
        [System.Management.Automation.PSCredential]$Credential
    )
    $CheminComplet = "\\$AdresseIPServeur\$CheminPartage"
    Write-ColoredMessage ("-" * 50) -Color Gray
    Write-ColoredMessage "Montage de $Lettre`: → $CheminComplet ($Description)" -Color White

    # Démontage préventif
    $existingPSDrive = Get-PSDrive $Lettre -ErrorAction SilentlyContinue
    if ($existingPSDrive) {
        Remove-PSDrive -Name $Lettre -Force -ErrorAction SilentlyContinue
    }
    net use "${Lettre}:" /delete /Y > $null 2>&1

    try {
        New-PSDrive -Name $Lettre -PSProvider FileSystem -Root $CheminComplet `
                    -Credential $Credential -Scope Global -Persist -ErrorAction Stop
        Write-ColoredMessage "  OK — Lecteur $Lettre`: monté" -Color Green

        if (Test-Path "${Lettre}:\") {
            Write-ColoredMessage "  Vérification : accessible" -Color Green
        } else {
            Write-ColoredMessage "  AVERTISSEMENT : monté mais inaccessible" -Color Yellow
        }
    } catch {
        Write-ColoredMessage "  ECHEC : $($_.Exception.Message)" -Color Red
        if ($_.Exception.Message -like "*multiple connections*") {
            Write-ColoredMessage "  → Exécutez 'net use * /delete' puis relancez le script" -Color Magenta
        }
    }
}

# --- Début ---
Clear-Host
Write-ColoredMessage ("=" * 50) -Color Cyan
Write-ColoredMessage "   Assistant de Montage des Lecteurs Réseau" -Color Cyan
Write-ColoredMessage "   Serveur : $AdresseIPServeur" -Color Cyan
Write-ColoredMessage ("=" * 50) -Color Cyan
Write-Host

# --- Demander le nom du projet si non fourni ---
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    Write-ColoredMessage "Nom du projet à monter (ex: tp-formulaires)" -Color Yellow
    Write-ColoredMessage "Laisser vide pour monter 'web' (W:) et 'public' (P:)" -Color Gray
    $ProjectName = Read-Host "Nom du projet"
}

# --- Définir les lecteurs selon le mode ---
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    # Mode legacy : partages webbox d'origine
    $Lecteurs = @(
        @{Lettre = "W"; CheminPartage = "web";    Description = "Dossier Web"}
        @{Lettre = "P"; CheminPartage = "public"; Description = "Dossier Public"}
    )
    Write-ColoredMessage "Mode : partages par défaut (web + public)" -Color Yellow
} else {
    # Mode projet : partage dédié au projet
    $Lecteurs = @(
        @{Lettre = "W"; CheminPartage = $ProjectName; Description = "Projet $ProjectName"}
    )
    Write-ColoredMessage "Mode : projet '$ProjectName'" -Color Yellow
    Write-ColoredMessage "URL du projet : http://$ProjectName.webbox.vm" -Color Cyan
}

Write-Host

# --- Gestion des identifiants ---
$Credential = $null
if ([string]::IsNullOrWhiteSpace($NomUtilisateurConfig) -or [string]::IsNullOrWhiteSpace($MotDePasseEnClairConfig)) {
    $Credential = Get-Credential -Message "Identifiants pour $AdresseIPServeur"
    if (-not $Credential) {
        Write-ColoredMessage "Aucun identifiant fourni. Annulation." -Color Red
        Read-Host "Appuyez sur Entrée pour quitter"
        Exit 1
    }
} else {
    Write-ColoredMessage "Connexion avec l'utilisateur '$NomUtilisateurConfig'" -Color Yellow
    $SecurePass = ConvertTo-SecureString -String $MotDePasseEnClairConfig -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($NomUtilisateurConfig, $SecurePass)
}

Write-Host
Write-ColoredMessage "Montage en cours..." -Color Cyan

# --- Monter chaque lecteur ---
foreach ($LecteurInfo in $Lecteurs) {
    Mount-Lecteur -Lettre $LecteurInfo.Lettre `
                  -CheminPartage $LecteurInfo.CheminPartage `
                  -Description $LecteurInfo.Description `
                  -Credential $Credential
}

Write-ColoredMessage ("-" * 50) -Color Gray
Write-Host
Write-ColoredMessage "Terminé. Vérifiez vos lecteurs dans l'Explorateur de fichiers." -Color Cyan
Read-Host "Appuyez sur Entrée pour fermer"
