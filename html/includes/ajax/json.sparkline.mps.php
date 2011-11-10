<?php
/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-06-15
 *
 * Changelog:
 * 2009-12-06 - created
 *
 */

@session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

// -------------------------
// Get Messages Per Second and return to JSON
// -------------------------
// $sql = "SELECT value as count FROM cache WHERE name='mps_avg' AND updatetime >= NOW() - INTERVAL 1 SECOND";
$sql = "SELECT value as count FROM cache WHERE name LIKE 'chart_mps_%' AND updatetime >= NOW() - INTERVAL 59 SECOND";
$queryresult = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
while ($line = fetch_array($queryresult)) {
    $num[] = intval($line['count']);
}
if ($num[0] > 0) {
    echo json_encode($num);
}
?>
