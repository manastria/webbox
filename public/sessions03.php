<!-- Fichier : sessions03.php -->
<?php
// On démarre ou reprend la session
session_start();

// On récupère les données stockées dans la session
$nom = $_SESSION["nom"];
$prenom = $_SESSION["prenom"];
?>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Informations de session</title>
</head>
<body>

<!-- Affichage des données -->
<p>Nom : <?= $nom ?></p>
<p>Prénom : <?= $prenom ?></p>

</body>
</html>
