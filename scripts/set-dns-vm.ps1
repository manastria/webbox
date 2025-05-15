# set-dns-vm.ps1

# Vérifie si on est en admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "⏫ Redémarrage du script en mode administrateur..."
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Définit l'adresse DNS manuellement sur l'interface réseau

# Paramètres
$interface = "Ethernet"
$dnsServer = "192.168.56.50"

# Application
Write-Host "Configuration du DNS sur $dnsServer pour l'interface '$interface'..."
Set-DnsClientServerAddress -InterfaceAlias $interface -ServerAddresses ($dnsServer)
Write-Host "DNS configuré."
