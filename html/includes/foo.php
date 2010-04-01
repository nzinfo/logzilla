<?php
/*
 * foo.php
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 gdd.net
 * Licensed under terms of GNU General Public License.
 * All rights reserved.
 *
 * Changelog:
 * 2010-03-29 - created
 *
 */
$basePath = dirname( __FILE__ );
require_once ($basePath . "/common_funcs.php");
require_once "LZECS.class.php";
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
$lzecs = new LZECS($dbLink);
$msg = "NMS_Replay[4886]: %SYS-5-CONFIG_I: Configured from memory by console (Q1 2009 C U)";

preg_match_all("/%(.*?):/", "NMS_Replay[4886]: %SYS-5-CONFIG_I:  Configured from memory by console (Q1 2009 C U)", $matches);
print_r($matches);
echo $matches[1][0];
?>
