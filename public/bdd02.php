<!-- Fichier : bdd02.php -->
<?php
// Connexion à la base (paramètres centralisés)
include("connexion.php");

// Traitement des données si la connexion a réussi
if ($connexion) {
  mysqli_set_charset($connexion, "utf8");
  $requete = "SELECT nom, prenom FROM employe;";
  $resultat = mysqli_query($connexion, $requete);

  // On stocke les lignes dans un tableau pour simplifier l'affichage ensuite
  $employes = [];
  while ($ligne = mysqli_fetch_assoc($resultat)) {
    $employes[] = $ligne;
  }

  // On compte le nombre d’employés
  $nb = count($employes);

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
  <h1>Liste nominative des employés</h1>

  <table border="2" width="75%">
    <tr>
      <th>NOM</th>
      <th>PRÉNOM</th>
    </tr>
    <?php foreach ($employes as $emp): ?>
      <tr>
        <td><?= $emp["nom"] ?></td>
        <td><?= $emp["prenom"] ?></td>
      </tr>
    <?php endforeach; ?>
  </table>

  <p>Il y a <?= $nb ?> employés.</p>
<?php endif; ?>

</body>
</html>
