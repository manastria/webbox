<!-- Fichier : bdd01.php -->
<?php
// Connexion à la base de données
$hote = "db";
$utilisateur = "etudiant";
$motdepasse = "etudiant";
$base = "empScePhp";

// Connexion MySQL
$connexion = mysqli_connect($hote, $utilisateur, $motdepasse, $base);

// Traitement des données si la connexion a réussi
if ($connexion) {
  mysqli_set_charset($connexion, "utf8");
  $requete = "SELECT * FROM employe;";
  $resultat = mysqli_query($connexion, $requete);

  // On stocke toutes les lignes dans un tableau pour l'affichage plus bas
  $employes = [];
  while ($ligne = mysqli_fetch_assoc($resultat)) {
    $employes[] = $ligne;
  }

  mysqli_close($connexion);
} else {
  $erreur = "Problème à la connexion à la base de données.";
}
?>

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Liste des employés</title>
</head>
<body>

<?php if (isset($erreur)): ?>
  <p><?= $erreur ?></p>
<?php else: ?>
  <h1>Liste des employés</h1>
  <?php foreach ($employes as $emp): ?>
    <p>
      <?= $emp["matricule"] ?>,
      <?= $emp["nom"] ?>,
      <?= $emp["prenom"] ?>,
      <?= $emp["cadre"] ?>,
      <?= $emp["service"] ?>
    </p>
  <?php endforeach; ?>
<?php endif; ?>

</body>
</html>
