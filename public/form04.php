<!-- Fichier : form04.php -->
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Document</title>
</head>

<body>
  <?php
  echo "Bonjour " . $_POST["prenom"] . "<br />";
  echo "Vous avez cliqué sur le bouton " . $_POST["validation"];
  ?>
</body>

</html>