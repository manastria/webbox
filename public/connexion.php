<?php
// Fichier : connexion.php
$hote = "db";
$utilisateur = "etudiant";
$motdepasse = "etudiant";
$base = "empScePhp";
$connexion = mysqli_connect($hote, $utilisateur, $motdepasse, $base);
?>
