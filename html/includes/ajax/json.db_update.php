<?php
/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-06-15
 *
 * Changelog:
 * 2010-03-01 - created
 *
 */

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
$dbid = get_input('dbid');
$note = get_input('note');
$sup_date = get_input('sup_date');
$sup_time = get_input('sup_time');
$sup_field = get_input('sup_field');
$msg_regex = get_input('sup_msg');
// logmsg("pre: $msg_regex");
$msg_regex = stripslashes($msg_regex);
$msg_regex = preg_replace ('/LZLZPLUS/', '+', $msg_regex);
// logmsg("post: $msg_regex");
// logmsg("post: $matchcount");
$action = get_input('action');

if ($sup_field) {
    if ($sup_field == 'this single event') {
        $where = "WHERE id IN ('$dbid')";
        $success .= "Set event suppression for record #$dbid ";
    } else {
        $sql = "SELECT $sup_field FROM ".$_SESSION["TBL_MAIN"]." WHERE id IN ('$dbid')";
        $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
        $line = fetch_array($result);
        $column = $line[0];
        $matchcount = substr_count($msg_regex,"(");
   for($i = 1; $i<=$matchcount ; $i++) {
       $cap .= '$' . $i;
   }
        $column = preg_replace("/$msg_regex/", "$cap", $column);
        $where = "WHERE $sup_field='$column'";
        $sql = "REPLACE INTO suppress (name,col,expire) VALUES ('$column','$sup_field','$sup_date $sup_time')";
        $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
        switch ($sup_field) {
            case 'mne':
                $column = crc2mne($column);
                break;
            case 'facility':
                $column = int2fac($column);
                break;
            case 'severity':
                $column = int2sev($column);
                break;
            case 'program':
                $column = crc2prg($column);
                break;
        }
        $success .= "Set event suppression for $sup_field ($column) ";
    }
} else {
    $where = "WHERE id IN ('$dbid')";
}
switch ($action) {
    case "save":
        if ($sup_field) {
            $sql = "UPDATE ".$_SESSION["TBL_MAIN"]." set suppress='$sup_date $sup_time' $where";
            $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
                $success .= "until $sup_date $sup_time<br>";
        }
    $sql = "UPDATE ".$_SESSION["TBL_MAIN"]." set notes='$note' WHERE id IN ('$dbid')";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    if ($note) {
        $success .= "Updated note to:<br>$note";
    } else {
        $success .= "Removed note<br>";
    }
    if ($success) {
        echo $success;
    } else {
        echo "No update needed";
    }
    break;

    case "get":
        $sql = "SELECT notes FROM $_SESSION[TBL_MAIN] WHERE id IN ('$dbid')";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    while($row = fetch_array($result)) { 
        echo $row['notes'];
    }
    break;
}
?>
