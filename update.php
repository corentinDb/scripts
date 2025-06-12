<?php
// Chemin vers le répertoire où le script PHP est situé
$directory = __DIR__;

// Commande git pull
$command = 'git pull';

// Exécuter la commande
$output = shell_exec("cd $directory && $command 2>&1");

// Afficher la sortie
echo "
<!DOCTYPE html>
<html>
<head>
    <title>Update scripts</title>
    <meta http-equiv=\"refresh\" content=\"10;url=./\">
</head>
<body>
    <pre>$output</pre>
    <button onclick=\"window.location.href='/scripts/'\">Retour aux Scripts</button>
</body>
</html>";
exit;
?>
