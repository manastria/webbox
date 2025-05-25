<!-- Fichier : php02.php -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Second script PHP</title>
</head>
<body>

<?php
// On récupère la date du jour
$jour = date("d");
$mois = date("m");
$an   = date("Y");

// On récupère des informations sur l'utilisateur
$ip = $_SERVER["REMOTE_ADDR"];
$navigateur = $_SERVER["HTTP_USER_AGENT"];
?>

<p>Bonjour, ici Big Brother...</p>

<p>Nous sommes le <?= $jour ?>/<?= $mois ?>/<?= $an ?></p>
<p>Votre adresse IP est : <?= $ip ?></p>
<p>Vous utilisez le navigateur : <?= $navigateur ?></p>

</body>
</html>
