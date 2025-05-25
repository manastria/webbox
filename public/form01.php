<!-- Fichier : form01.php -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <title>Un petit bonjour</title>
</head>
<body>

  <?php
  // On récupère le prénom passé dans l’URL avec la méthode GET
  $prenom = $_GET["prenom"];
  ?>

  <p>
    <!-- La balise <?= ... ?> est un raccourci pour afficher du texte -->
    <!-- Elle est équivalente à <?php echo ... ?> -->
    Bonjour <?= $prenom ?>
  </p>

</body>
</html>
