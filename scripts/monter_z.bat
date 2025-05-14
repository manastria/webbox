@echo off
set IP=192.168.56.101
set PARTAGE=web
set UTILISATEUR=etudiant
set MDP=etudiant123

net use Z: /delete >nul 2>&1
net use Z: \\%IP%\%PARTAGE% /user:%UTILISATEUR% %MDP%
