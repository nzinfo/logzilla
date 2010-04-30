<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-04-29
 *
 * Changelog:
 * 2010-01-13 - created
 *
 */
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
session_start();

$username = $_SESSION['username']; 

$data = get_input('data');

switch ($data) {
    case "msgs":
        $sql = "SELECT value FROM cache where name='msg_sum'";
    break;

    case "notes":
        $sql = "SELECT COUNT(*) FROM $_SESSION[TBL_MAIN] WHERE notes!=''";
    break;

    case "prgs":
        $sql = "SELECT COUNT(*) FROM (SELECT DISTINCT name FROM programs) AS result";
    break;

    case "mnes":
        $sql = "SELECT COUNT(*) FROM (SELECT DISTINCT name FROM mne) AS result";
    break;

    case "sevs":
        $sql = "SELECT COUNT(*) FROM (SELECT DISTINCT severity FROM ".$_SESSION['TBL_MAIN'] .") AS result";
    break;

    case "facs":
        $sql = "SELECT COUNT(*) FROM (SELECT DISTINCT facility FROM ".$_SESSION['TBL_MAIN'] .") AS result";
    break;
}
$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
if(num_rows($result)==0){
    echo "ERROR in ajax/counts.php";
} else {
    $line = fetch_array($result);
    echo $line[0];
}
?>
