@echo off
REM Ce script lance le script PowerShell MountDrives.ps1
REM Il contourne la politique d'exécution des scripts pour faciliter l'usage.

REM Trouve le chemin du script actuel
SET CurrentDir=%~dp0

REM Chemin complet vers le script PowerShell
SET PowerShellScriptPath=%CurrentDir%MountDrives.ps1

REM Vérifie si le script PowerShell existe
IF NOT EXIST "%PowerShellScriptPath%" (
    echo ERREUR: Le fichier MountDrives.ps1 est introuvable dans le dossier :
    echo %CurrentDir%
    echo Veuillez vous assurer que les deux fichiers sont dans le meme dossier.
    pause
    exit /b 1
)

REM Lance le script PowerShell
echo Lancement de l'assistant de montage des lecteurs reseau...
powershell.exe -ExecutionPolicy Bypass -File "%PowerShellScriptPath%"

REM La pause dans le script PowerShell suffit, mais si le script PS se ferme trop vite, décommentez la ligne suivante.
REM pause