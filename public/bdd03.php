<!-- Fichier : bdd03.php -->
<?php
// Connexion à la base (paramètres centralisés)
include("connexion.php");

// Initialisation
$services = [];

if ($connexion) {
  mysqli_set_charset($connexion, "utf8");
  $requete = "SELECT * FROM service ORDER BY designation;";
  $resultat = mysqli_query($connexion, $requete);

  while ($ligne = mysqli_fetch_assoc($resultat)) {
    $services[] = $ligne;
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
  <title>Sélection du service</title>
</head>
<body>

<?php if (isset($erreur)): ?>
  <p><?= $erreur ?></p>
<?php else: ?>
  <h2>Liste des employés par service</h2>

  <form action="bdd03a.php" method="post">
    <p>Sélectionnez le service souhaité :</p>

    <select name="service" size="5">
      <?php foreach ($services as $index => $s): ?>
        <option <?= $index === 0 ? 'selected' : '' ?> value="<?= $s["code"] ?>">
          <?= $s["code"] ?> <?= $s["designation"] ?>
        </option>
      <?php endforeach; ?>
    </select>

    <p><input type="submit" value="Afficher la liste"></p>
  </form>
<?php endif; ?>

</body>
</html>
