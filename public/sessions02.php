<?php
   session_start();
?>
<html>
<body>
<?php
    $_SESSION["nom"]="Dupont";
    $_SESSION["prenom"]="Paul";
?>
<a href="sessions03.php">sessions03.php</a>
</body>
</html>
