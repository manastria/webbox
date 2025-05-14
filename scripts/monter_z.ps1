# Script : monter_z.ps1
# Monte le lecteur réseau Z: vers le partage Samba d'une VM Debian

# Configuration
$vmIp = "192.168.56.101"     # Adresse IP de la VM (fixe en Host-Only)
$partage = "web"             # Nom du partage Samba défini dans smb.conf
$lecteur = "Z:"

# Vérification si déjà monté
if (Test-Path "$lecteur\") {
    Write-Host "✅ Le lecteur $lecteur est déjà monté." -ForegroundColor Green
    exit
}

# Création du chemin UNC
$chemin = "\\$vmIp\$partage"

# Montage du lecteur
try {
    Write-Host "⏳ Montage du partage $chemin sur $lecteur ..."
    net use $lecteur $chemin /persistent:no
    Write-Host "✅ Partage monté avec succès sur $lecteur." -ForegroundColor Green
}
catch {
    Write-Host "❌ Échec du montage. Vérifie l'adresse IP ou le partage Samba." -ForegroundColor Red
}
