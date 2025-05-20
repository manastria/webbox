<html><head><title>Ajout d'un employé</title></head><body>
<?php
$connexion = mysqli_connect("db","etudiant","etudiant","empScePhp");
if ($connexion) 
{
  // connexion réussie
  mysqli_set_charset ($connexion,"utf8");
  if (empty($_POST["cadre"]))
  {
     $charCadre='n';
  }
  else
  {
     $charCadre='o';
  }
  $requete="insert into employe values ('".$_POST["matricule"]."','".$_POST["nom"]."','"
.$_POST["prenom"]."','".$charCadre."','".$_POST["service"]."');";
  $ok= mysqli_query($connexion, $requete);
  if ($ok)
  {
    echo "L'employé a été correctement ajouté";
  }
  else
  {
    echo "Attention, l'ajout de l'employé a échoué !!!";
  }
}
else
{
  echo "problème à la connexion <br />";
}
mysqli_close($connexion);
?>
</body></html>
