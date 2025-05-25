<!-- Fichier : form04.php -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Résultat du formulaire</title>
</head>
<body>

<?php
// On récupère les données envoyées par le formulaire
$prenom = $_POST["prenom"];
$validation = $_POST["validation"];
?>

<!-- On affiche les résultats -->
<p>Bonjour <?= $prenom ?></p>
<p>Vous avez cliqué sur le bouton : <?= $validation ?></p>

</body>
</html>
