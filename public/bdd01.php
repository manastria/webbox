<!-- Fichier : bdd01.php -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Liste des employés</title>
</head>
<?php
$connexion = mysqli_connect("db","etudiant","etudiant","empScePhp");
if ($connexion)
{
  // connexion réussie
  mysqli_set_charset ($connexion,"utf8");
  $requete="select * from employe;";
  $resultat= mysqli_query($connexion, $requete);
  $ligne=mysqli_fetch_assoc($resultat);
  while($ligne)
  {
     echo $ligne["matricule"];echo ", ";
     echo $ligne["nom"];echo ", ";
     echo $ligne["prenom"];echo ", ";
     echo $ligne["cadre"];echo ", ";
     echo $ligne["service"];echo "<br />";
    $ligne=mysqli_fetch_assoc($resultat);
  }
}
else
{
  echo "problème à la connexion <br />";
}
mysqli_close($connexion);
?>
</body>
</html>
