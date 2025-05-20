<!-- Fichier : form03.php -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Un petit bonjour</title>
</head>
<body>
<?php
$message = (!empty($_POST["familier"])) ? "Salut " : "Bonjour ";
switch ($_POST["politesse"]) {
  case 1: $message .= "Mademoiselle "; break;
  case 2: $message .= "Madame "; break;
  case 3: $message .= "Monsieur "; break;
}
echo $message . $_POST["prenom"];
?>
</body>
</html>
