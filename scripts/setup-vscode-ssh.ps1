# --- Valeurs par défaut ---
$defaultHost = "192.168.56.50"
$defaultUser = "etudiant"
$keyName     = "id_ed25519"
$keyPath     = "$env:USERPROFILE\.ssh\$keyName"
$configPath  = "$env:USERPROFILE\.ssh\config"
$hostAlias   = "WebBox"

# --- Lecture des infos utilisateur ---
$vmHost = Read-Host "Adresse IP de la VM (par défaut : $defaultHost)"
if ([string]::IsNullOrWhiteSpace($vmHost)) {
    $vmHost = $defaultHost
}

$vmUser = Read-Host "Nom d'utilisateur Linux (par défaut : $defaultUser)"
if ([string]::IsNullOrWhiteSpace($vmUser)) {
    $vmUser = $defaultUser
}

# --- Clé privée SSH intégrée ---
$keyContent = @"
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz
c2gtZWQyNTUxOQAAACBvxmzs/YHx/hd3/esUTehonimuhMo9ZJL80mvOv4vsKwAA
AJDlBbuO5QW7jgAAAAtzc2gtZWQyNTUxOQAAACBvxmzs/YHx/hd3/esUTehonimu
hMo9ZJL80mvOv4vsKwAAAEBUwn5WGodC3d7dkgqERr6JPBw+wOau24EEPMug/pVm
B2/GbOz9gfH+F3f96xRN6GieKa6Eyj1kkvzSa86/i+wrAAAABldlYkJveAECAwQF
Bgc=
-----END OPENSSH PRIVATE KEY-----
"@

# --- Création du dossier .ssh si nécessaire ---
if (-Not (Test-Path "$env:USERPROFILE\.ssh")) {
    New-Item -ItemType Directory -Path "$env:USERPROFILE\.ssh" | Out-Null
}

# --- Écriture de la clé privée ---
Write-Host "`n[1] Copie de la clé SSH..."
$keyContent | Out-File -FilePath $keyPath -Encoding ascii -Force
icacls $keyPath /inheritance:r /grant:r "$($env:USERNAME):R"

# --- Démarrage de l'agent SSH ---
Write-Host "[2] Démarrage de l’agent SSH..."
Start-Service ssh-agent -ErrorAction SilentlyContinue
ssh-add $keyPath | Out-Null

# --- Configuration du fichier ~/.ssh/config ---
Write-Host "[3] Configuration du client SSH..."
$configEntry = @"
Host $hostAlias
    HostName $vmHost
    User $vmUser
    IdentityFile ~/.ssh/$keyName
"@

if (-Not (Test-Path $configPath)) {
    New-Item -ItemType File -Path $configPath -Force | Out-Null
}

# Supprimer ancienne entrée s'il y en a une
$content = Get-Content $configPath -Raw
$content = $content -replace "Host $hostAlias.*?(?=Host |\z)", ""
Set-Content -Path $configPath -Value ($content.Trim() + "`r`n" + $configEntry)

Write-Host "`n[OK] Configuration terminée."
Write-Host ('Vous pouvez maintenant utiliser VS Code > Remote Explorer > SSH Targets > {0}' -f $hostAlias) -ForegroundColor Green
