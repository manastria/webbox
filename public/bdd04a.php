<!-- Fichier : bdd04a.php -->
<?php
// Connexion à la base (paramètres centralisés)
include("connexion.php");

// Initialisation
$message = "";

// Traitement si la connexion est réussie
if ($connexion) {
  mysqli_set_charset($connexion, "utf8");

  // Récupération et traitement des données du formulaire
  $matricule = $_POST["matricule"];
  $nom = $_POST["nom"];
  $prenom = $_POST["prenom"];
  $service = $_POST["service"];

  // On transforme la case à cocher "cadre" en 'o' ou 'n'
  if (empty($_POST["cadre"])) {
    $cadre = 'n';
  } else {
    $cadre = 'o';
  }

  // Requête SQL d'insertion
  $requete = "INSERT INTO employe VALUES (
    '$matricule',
    '$nom',
    '$prenom',
    '$cadre',
    '$service'
  );";

  // Exécution de la requête
  $ok = mysqli_query($connexion, $requete);

  // Message en fonction du résultat
  if ($ok) {
    $message = "L'employé a été correctement ajouté.";
  } else {
    $message = "❌ L'ajout de l'employé a échoué.";
  }

  mysqli_close($connexion);
} else {
  $message = "Problème à la connexion à la base de données.";
}
?>

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Ajout d'un employé</title>
</head>
<body>

<p><?= $message ?></p>

</body>
</html>
