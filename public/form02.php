<!-- Fichier : form02.php -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <title>Un petit bonjour</title>
</head>
<body>

<?php
// Récupération des données du formulaire
$prenom = $_POST["prenom"];
$familier = $_POST["familier"];

// Si la case "familier" n'est pas cochée, la variable est vide
if (empty($familier)) {
  echo "<p>Bonjour " . $prenom . "</p>";
} else {
  echo "<p>Salut " . $prenom . "</p>";
}
?>

</body>
</html>
