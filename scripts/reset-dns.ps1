# reset-dns.ps1
# Réinitialise le DNS pour qu’il soit géré automatiquement par le système

# Vérifie si on est en admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "⏫ Redémarrage du script en mode administrateur..."
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Paramètres
$interface = "Ethernet"

# Application
Write-Host "Réinitialisation du DNS pour l'interface '$interface'..."
Set-DnsClientServerAddress -InterfaceAlias $interface -ResetServerAddresses
Write-Host "DNS réinitialisé (automatique)."
