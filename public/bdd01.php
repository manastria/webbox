<!-- Fichier : bdd01.php -->
<html>
<head>
  <meta charset="UTF-8">
  <title>Liste des employés</title>
</head>
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
  $requete = "select * from employe;";
  $resultat = mysqli_query($connexion, $requete);
  $ligne = mysqli_fetch_assoc($resultat);
  while ($ligne) {
    echo $ligne["matricule"] . ", ";
    echo $ligne["nom"] . ", ";
    echo $ligne["prenom"] . ", ";
    echo $ligne["cadre"] . ", ";
    echo $ligne["service"] . ", ";
    echo "<br>";
    $ligne = mysqli_fetch_assoc($resultat);
  }
} else {
  echo "problème à la connexion <br>";
}
mysqli_close($connexion);
?>
</body>
</html>