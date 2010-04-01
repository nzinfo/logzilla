<?php
/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 gdd.net
 * All rights reserved.
 *
 * Changelog:
 * 2010-03-01 - created
 *
 */

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
$dbid = get_input('dbid');
$value = get_input('value');
$name = get_input('name');
$description = get_input('description');
$action = get_input('action');

//---use below to debug from the command line
// $dbid = (!empty($dbid)) ? $dbid : "1";
// $action = (!empty($action)) ? $action : "get";


switch ($action) {
    case "save":
        $sql = "UPDATE settings set value='$value' WHERE id='$dbid'";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    if ($result) {
        echo "Updated $name with:<br>$value";
        $_SESSION["$name"] = $value;
    } else {
        echo "Failed to save $name";
    }
    break;

    case "get":
        $sql = "SELECT * FROM settings WHERE id IN ('$dbid')";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    while($row = fetch_array($result)) { 
        $data->name = $row['name'];
        $data->value = $row['value'];
        $data->type = $row['type'];
        $data->options = $row['options'];
        $data->def = $row['default'];
        $data->description = $row['description'];
    }
    echo json_encode($data);
    break;
}
?>
