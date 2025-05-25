<!-- Fichier : bdd03a.php -->
<?php
// Connexion à la base (paramètres centralisés)
include("connexion.php");

// Initialisation
$employes = [];
$nb = 0;

if ($connexion) {
  mysqli_set_charset($connexion, "utf8");

  // On récupère le service sélectionné dans le formulaire précédent
  $code_service = $_POST["service"];

  // On prépare la requête
  $requete = "SELECT nom, prenom FROM employe WHERE service = '$code_service';";

  $resultat = mysqli_query($connexion, $requete);

  while ($ligne = mysqli_fetch_assoc($resultat)) {
    $employes[] = $ligne;
  }

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
