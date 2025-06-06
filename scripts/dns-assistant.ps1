<#
.SYNOPSIS
Un assistant pour configurer ou réinitialiser le serveur DNS d'une interface réseau.
.DESCRIPTION
Ce script présente un menu interactif pour définir une adresse de serveur DNS manuelle
ou pour rétablir la configuration automatique (DHCP).
Il suffit de double-cliquer sur le fichier pour le lancer.
#>

# --- GESTION DE LA POLITIQUE D'EXÉCUTION (Commentaire pour les étudiants) ---
# Pour autoriser l'exécution de ce script, ouvrez un terminal PowerShell en admin et exécutez :
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned

[CmdletBinding()]
param() # Pas de paramètres externes, tout se fait via le menu

# --- Vérification des privilèges d'administrateur ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Ce script nécessite des privilèges d'administrateur."
    Write-Host "⏫ Tentative de redémarrage en mode administrateur..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- PARAMÈTRES MODIFIABLES ---
[string]$dnsServerIP_preset = "192.168.56.50" # Adresse pré-remplie pour le prompt

# =====================================================================================
# == MENU INTERACTIF ==
# =====================================================================================
Clear-Host
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Assistant de Configuration DNS"
Write-Host "========================================" -ForegroundColor Green
Write-Host
Write-Host "Que souhaitez-vous faire ?" -ForegroundColor Yellow
Write-Host "  [1] Configurer le DNS pour le Labo (utiliser le serveur local)"
Write-Host "  [2] Réinitialiser le DNS (revenir en mode automatique/DHCP)"
Write-Host "  [Q] Quitter"
Write-Host

$choice = Read-Host -Prompt "Votre choix"

# --- SÉLECTION DE L'INTERFACE (COMMUN AUX DEUX ACTIONS) ---
if ($choice -eq '1' -or $choice -eq '2') {
    Write-Host "`n🔎 Recherche des interfaces réseau actives..." -ForegroundColor Cyan
    $interfaces = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

    if (-not $interfaces) {
        Write-Error "Aucune interface réseau active trouvée."
        exit
    }

    Write-Host "Veuillez choisir l'interface réseau à configurer :" -ForegroundColor Yellow
    for ($i = 0; $i -lt $interfaces.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $interfaces[$i].Name)
    }

    $interfaceChoice = Read-Host -Prompt "Entrez le numéro de l'interface"
    try {
        $selectedInterface = $interfaces[[int]$interfaceChoice - 1]
        $interfaceAlias = $selectedInterface.Name
        Write-Host ("Interface sélectionnée : '{0}'" -f $interfaceAlias) -ForegroundColor Green
    }
    catch {
        Write-Error "Sélection invalide."
        # On attend avant de quitter pour que l'utilisateur voie l'erreur
        Start-Sleep -Seconds 3
        exit
    }
}


# --- ACTIONS SELON LE CHOIX DU MENU ---
switch ($choice) {
    '1' {
        # --- Mode Configuration ---
        $dnsServerIP_input = Read-Host -Prompt "Veuillez saisir l'adresse IP du serveur DNS (laissez vide pour utiliser $dnsServerIP_preset)"
        if ([string]::IsNullOrWhiteSpace($dnsServerIP_input)) {
            $dnsServerIP_input = $dnsServerIP_preset
        }
        
        Write-Host "`n🛠️  Configuration du DNS sur '$dnsServerIP_input' pour l'interface '$interfaceAlias'..." -ForegroundColor Cyan
        Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses ($dnsServerIP_input)
        
        Write-Host "🔍 Vérification..."
        Start-Sleep -Seconds 1
        $newConfig = Get-DnsClientServerAddress -InterfaceAlias $interfaceAlias
        
        if ($newConfig.ServerAddresses -contains $dnsServerIP_input) {
            Write-Host "✅ Succès ! Le DNS '$dnsServerIP_input' est bien configuré." -ForegroundColor Green
        } else {
            Write-Error "❌ Échec ! La configuration du DNS a échoué."
        }
    }
    '2' {
        # --- Mode Réinitialisation ---
        Write-Host "`n🔄 Réinitialisation de la configuration DNS pour l'interface '$interfaceAlias'..." -ForegroundColor Cyan
        Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ResetServerAddresses
        
        Write-Host "🔍 Vérification..."
        $newConfig = Get-DnsClientServerAddress -InterfaceAlias $interfaceAlias
        
        if ($newConfig.ServerAddresses.Count -gt 0) {
            Write-Host "✅ DNS réinitialisé. Les serveurs suivants sont maintenant actifs (via DHCP) :" -ForegroundColor Green
            $newConfig.ServerAddresses | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
        } else {
            Write-Host "✅ DNS réinitialisé (configuration automatique)." -ForegroundColor Green
        }
    }
    default {
        Write-Host "Opération annulée."
    }
}

Write-Host "`nAppuyez sur une touche pour quitter."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
