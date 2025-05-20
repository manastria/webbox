<!-- Fichier bdd02.php -->
<html>
<head>
  <meta charset="UTF-8">
  <title>Liste des employés</title>
</head>
<body>
  <?php
  // Paramètres de connexion
  $hote = "db";
  $utilisateur = "etudiant";
  $motdepasse = "etudiant";
  $base = "empScePhp";
  // Connexion
  $connexion = mysqli_connect($hote, $utilisateur, $motdepasse, $base);
  if ($connexion) {
    // connexion réussie
    mysqli_set_charset($connexion, "utf8");
    $requete = "select nom,prenom from employe;";
    $nb = 0;
    echo "<h1>Liste nominative des employés</h1>";
    echo '<p /><table border="2" width="75%">';
    echo "<tr><th>NOM</th><th>PRENOM</th></tr>";
    $resultat = mysqli_query($connexion, $requete);
    $ligne = mysqli_fetch_assoc($resultat);
    while ($ligne) {
      echo "<tr><td>" . $ligne["nom"] . "</td><td>" . $ligne["prenom"] . "</td></tr>";
      $nb++;
      $ligne = mysqli_fetch_assoc($resultat);
    }
    echo "</table><p />";
    echo "Il y a " . $nb . " employés.";
  } else {
    echo "problème à la connexion <br />";
  }
  mysqli_close($connexion);
  ?>
</body>
</html>