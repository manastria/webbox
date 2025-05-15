@echo off
set IP=192.168.56.50
set PARTAGE=web
set UTILISATEUR=etudiant
set MDP=netlab123

net use W: /delete >nul 2>&1
net use W: \\%IP%\%PARTAGE% /user:%UTILISATEUR% %MDP%
