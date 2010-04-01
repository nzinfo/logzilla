<?php
/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2009 gdd.net
 * All rights reserved.
 *
 * Changelog:
 * 2009-12-13 - created
 *

 */
session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

$varqty = count($_POST); // count how many portlets are we passing
$varnames = array_keys($_POST); // Obtain variable names
$varvalues = array_values($_POST);// Obtain variable values
// Used for debug while building
//  $myFile = "/tmp/foo";
//  $fh = fopen($myFile, 'a') or die("can't open file $myFile");
//  $vars = "\n";
//      fwrite($fh, "Count: $varqty\n");
//  foreach ($_POST as $key=>$value) {
//  	$vars .= "\tKey = $key, Value = $value\n";
//    fwrite($fh, "\tKey = $key, Value = $value\n");
//  }

for($i=0;$i<$varqty;$i++){  // For each variable
$semivalue = explode("|", $varvalues[$i]);  // Split variable when "|" is found and save it in $semivalue
// $arr = str_split($semivalue[0], 4);
$header = str_replace("portlet_", "", $varnames[$i]);
$header = str_replace("_", " ", $header);
//  fwrite($fh, "Header Name $i = ".$header."\n");
//  fwrite($fh, "Var Values $i = ".$varvalues[$i]."\n");
$pagename = str_replace("tab-", "", $semivalue[0]);
$sql = ("UPDATE ui_layout SET col='$semivalue[1]', rowindex='$semivalue[2]' WHERE userid=(SELECT id FROM users WHERE username='".$_SESSION['username']."') AND pagename='$semivalue[0]' AND header='$header'");
//  fwrite($fh, "SQL = $sql\n");
$queryresult = perform_query($sql, $dbLink, $vars);
}
//fclose($fh);
?>
