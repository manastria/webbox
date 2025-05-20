-- Crée un utilisateur 'etudiant' avec mot de passe 'etudiant'
CREATE USER IF NOT EXISTS 'etudiant'@'%' IDENTIFIED BY 'etudiant';

-- Donne tous les droits à l'utilisateur 'etudiant' sur toutes les bases
GRANT ALL PRIVILEGES ON *.* TO 'etudiant'@'%' WITH GRANT OPTION;

-- Recharge les privilèges
FLUSH PRIVILEGES;
