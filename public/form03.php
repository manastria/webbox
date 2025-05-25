<!-- Fichier : form03.php -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <title>Un petit bonjour</title>
</head>
<body>

<?php
// On récupère le prénom envoyé par le formulaire
$prenom = $_POST["prenom"];

// On vérifie si la case "familier" a été cochée.
// La fonction empty() renvoie true si la case n'est pas cochée (valeur vide).
// L’opérateur conditionnel (ternaire) permet ici d’écrire un if simple sur une seule ligne.
// ⚠ À expliquer : (condition) ? valeur_si_vrai : valeur_si_faux;
$message = (!empty($_POST["familier"])) ? "Salut " : "Bonjour ";

// On récupère le choix de politesse (1 = Mademoiselle, 2 = Madame, 3 = Monsieur)
// et on l’ajoute au message en utilisant un switch
switch ($_POST["politesse"]) {
  case 1:
    $message .= "Mademoiselle ";
    break;
  case 2:
    $message .= "Madame ";
    break;
  case 3:
    $message .= "Monsieur ";
    break;
  // Optionnel : un default permettrait de gérer un oubli ou une erreur
}
?>

<!-- On affiche le message complet suivi du prénom -->
<p><?= $message . $prenom ?></p>

</body>
</html>
