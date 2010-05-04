<?php
/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-05-04
 *
 * Changelog:
 * 2009-12-06 - created
 *
 */

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

// -------------------------
// Get Messages Per Second and return to JSON
// -------------------------
$sql = "SELECT value as count FROM cache WHERE name LIKE 'chart_mps_%' AND updatetime BETWEEN NOW() - INTERVAL 59 SECOND and NOW() -  INTERVAL 0 SECOND ORDER BY updatetime ASC";
$queryresult = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
while ($line = fetch_array($queryresult)) {
    $num[] = $line['count'];
}
echo json_encode($num);
?>
