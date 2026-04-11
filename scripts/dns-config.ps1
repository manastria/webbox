#Requires -Version 3.0
<#
.SYNOPSIS
  Configure le DNS Windows pour le labo WebBox.
.DESCRIPTION
  Detecte automatiquement l'interface VirtualBox Host-Only, lui affecte
  le serveur DNS de la VM (192.168.56.50) et lui donne une priorite
  haute (metrique basse). Les autres interfaces conservent le DNS
  automatique (DHCP) avec une priorite basse.
  Lance automatiquement une elevation UAC si necessaire.
.NOTES
  Usage pedagogique — executer en debut de TP.
#>

# --- Auto-elevation en Administrateur ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- Configuration ---
$DnsServer = "192.168.56.50"

# --- En-tete ---
Clear-Host
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host "   Configuration DNS - WebBox Labo" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host

# --- 1. Detection de l'interface VirtualBox Host-Only ---
$HostOnlyInterface = Get-NetAdapter | Where-Object {
    $_.InterfaceDescription -like "*VirtualBox Host-Only*"
}

if (-not $HostOnlyInterface) {
    Write-Host "ERREUR : Aucune interface VirtualBox Host-Only trouvee." -ForegroundColor Red
    Write-Host "Verifiez que VirtualBox est installe et que la VM est en cours d'execution." -ForegroundColor Yellow
    Read-Host "`nAppuyez sur Entree pour quitter"
    exit 1
}

# --- 2. Configuration de toutes les interfaces actives ---
$AllInterfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

Write-Host "Interfaces reseau actives detectees :" -ForegroundColor White
Write-Host

foreach ($Interface in $AllInterfaces) {
    $Alias = $Interface.Name

    # Reinitialisation DNS (IPv4 + IPv6 simultanement)
    Set-DnsClientServerAddress -InterfaceAlias $Alias -ResetServerAddresses

    if ($Alias -eq $HostOnlyInterface.Name) {
        # Interface Host-Only : DNS VM + priorite haute (metrique 5)
        Set-DnsClientServerAddress -InterfaceAlias $Alias -ServerAddresses $DnsServer
        Set-NetIPInterface -InterfaceAlias $Alias -AddressFamily IPv4 -InterfaceMetric 5 -ErrorAction SilentlyContinue
        Set-NetIPInterface -InterfaceAlias $Alias -AddressFamily IPv6 -InterfaceMetric 5 -ErrorAction SilentlyContinue
        Write-Host "  [OK] $Alias" -ForegroundColor Green
        Write-Host "       DNS : $DnsServer  |  Priorite : HAUTE (metrique 5)" -ForegroundColor Green
    } else {
        # Autres interfaces : DNS automatique + priorite basse (metrique 20)
        Set-NetIPInterface -InterfaceAlias $Alias -AddressFamily IPv4 -InterfaceMetric 20 -ErrorAction SilentlyContinue
        Set-NetIPInterface -InterfaceAlias $Alias -AddressFamily IPv6 -InterfaceMetric 20 -ErrorAction SilentlyContinue
        Write-Host "  [--] $Alias" -ForegroundColor Gray
        Write-Host "       DNS : automatique  |  Priorite : basse (metrique 20)" -ForegroundColor Gray
    }
    Write-Host
}

# --- 3. Vider le cache DNS ---
Clear-DnsClientCache

# --- 4. Verification ---
$verif = Get-DnsClientServerAddress -InterfaceAlias $HostOnlyInterface.Name -AddressFamily IPv4
if ($verif.ServerAddresses -contains $DnsServer) {
    Write-Host ("=" * 50) -ForegroundColor Green
    Write-Host "  DNS configure avec succes !" -ForegroundColor Green
    Write-Host ("=" * 50) -ForegroundColor Green
    Write-Host
    Write-Host "  Les URL *.webbox.vm sont maintenant accessibles." -ForegroundColor Green
    Write-Host "  Rappel : toujours ecrire http:// devant l'adresse." -ForegroundColor Yellow
} else {
    Write-Host "ERREUR : la configuration DNS n'a pas ete appliquee." -ForegroundColor Red
}

Write-Host
Read-Host "Appuyez sur Entree pour fermer"
