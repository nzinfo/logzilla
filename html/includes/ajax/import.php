<?php

/*
 *
 * Developed by Thomas Honzik (thomas@honzik.at)
 * Copyright (c) 2011 LogZilla, LLC
 * All rights reserved.
 *
 * Changelog:
 * 2011-03-09 - created
 *
 */
$basePath = dirname( __FILE__ );

require_once ($basePath . "/../common_funcs.php");
$idate = get_input('impdate');
$idate = substr($idate,0,4).substr($idate,5,2).substr($idate,8,2);
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
session_start();
$sql = "SELECT value FROM settings where name='PATH_BASE'";
$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
if(num_rows($result)==0){
    echo "ERROR: Unable to determine installed path<br />Please check your database setting for PATH_BASE";
} else {
$line = fetch_array($result);
$path = $line[0];
$sql = "SELECT value FROM settings where name='ARCHIVE_PATH'";
$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
if(num_rows($result)==0){
    echo "ERROR: Unable to determine archive path<br />Please check your database setting for ARCHIVE_PATH";
} else {
    $line = fetch_array($result);
    $apath = $line[0];
    $cmd = "sudo $path/scripts/doimport.sh dumpfile_".$idate.".txt";
    exec($cmd, $out);
    echo  $out[0];
    echo "Import started";
    } }
?>
