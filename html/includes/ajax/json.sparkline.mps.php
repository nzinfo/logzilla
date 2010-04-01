<?php
/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2009 gdd.net
 * All rights reserved.
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
$array = array();
$n = 1;
for($i = 0; $i<=30 ; $i++) {
   	$sql = "SELECT SUM(counter) as count from ".$_SESSION["TBL_MAIN"]." where lo BETWEEN NOW() - INTERVAL $n SECOND and NOW() - INTERVAL $i SECOND";
   	$queryresult = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
   	while ($line = fetch_array($queryresult)) {
		$array[] = $line['count'];
   	}
	$n++;
}
echo json_encode($array);
/*
if (LOG_QUERIES == 'TRUE') {
   	$myFile = "/tmp/logzilla_query.log";
   	$fh = fopen($myFile, 'a') or die("can't open file $myFile");
   	fwrite($fh, date("h:i:s") ." - json.sparkline.mps.php result: " .json_encode($array)."\n");
   	fclose($fh);
}
*/
?>
