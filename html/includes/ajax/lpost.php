<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 *
 * Changelog:
 * 2010-01-13 - created
 *
 */
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
session_start();
$text = get_input('txt');

$text = urldecode($text);
$text = str_replace('PLUS', "+", $text);

// logmsg("$text");
$sql = "SELECT value FROM settings where name='PATH_BASE'";
$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
if(num_rows($result)==0){
    echo "ERROR: Unable to determine installed path<br />Please check your database setting for PATH_BASE";
} else {
    $line = fetch_array($result);
    $bpath = $line[0];
    $path = $line[0] . "/html";
    $file = "$path/license.txt";
    if (!is_dir($path) or !is_writable($path)) {
        echo "Directory $path doesn't exist or isn't writable.";
        exit;
    } elseif (is_file($file) and !is_writable($file)) {
        echo "File $file isn't writable.";
        exit;
    }
    if (is_file($file)) {
            echo "$file exists, cannot overwrite.";
            exit;
    } else {
        $res = file_put_contents("$file", $text);
        if ($res) {
            echo "Success!<br />Due to security reasons, you will need to move $file to $bpath";
        } else {
            echo "Unable to write to $file";
        }
    }
}
?>
