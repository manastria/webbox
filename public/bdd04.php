<!-- Fichier : bdd04.php -->
<?php
// Connexion à la base (paramètres centralisés)
include("connexion.php");

// Initialisation
$services = [];

if ($connexion) {
  mysqli_set_charset($connexion, "utf8");

  // Requête pour récupérer les services
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
  <title>Saisie</title>
</head>
<body>

<?php if (isset($erreur)): ?>
  <p><?= $erreur ?></p>
<?php else: ?>
  <h2>Saisie d’un employé</h2>

  <form action="bdd04a.php" method="post">
    <p>Matricule : <input type="text" name="matricule" size="3" /></p>
    <p>Nom : <input type="text" name="nom" size="25" /></p>
    <p>Prénom : <input type="text" name="prenom" size="20" /></p>
    <p><label><input type="checkbox" name="cadre" /> Cadre</label></p>

    <p>Service :</p>
    <select name="service" size="5">
      <?php foreach ($services as $index => $s): ?>
        <option <?= $index === 0 ? 'selected' : '' ?> value="<?= $s["code"] ?>">
          <?= $s["code"] ?> <?= $s["designation"] ?>
        </option>
      <?php endforeach; ?>
    </select>

    <p>
      <input type="submit" value="Enregistrer" />
      <input type="reset" value="Annuler" />
    </p>
  </form>
<?php endif; ?>

</body>
</html>
