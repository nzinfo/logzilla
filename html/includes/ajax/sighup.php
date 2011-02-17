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

$pid = getpid();
    $result = huppid($pid);
    $pieces = explode(",", $result);
    echo "Restarting $pieces[0] at process ID $pieces[1]<br />\n";
?>
