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
require_once ($basePath . "/../common_funcs.php");
if ((has_portlet_access($_SESSION['username'], 'Hosts') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

$sql = "SELECT COUNT(*) FROM (SELECT host FROM hosts) AS result";
$result = perform_query($sql, $dbLink, $_REQUEST['pageId']);
$total = mysql_fetch_row($result);
$count = $total[0];
if( $count >0 ) { 
?>
<table id="tbl_hosts" cellpadding="0" cellspacing="0" width="100%" border="0">
<thead class="ui-widget-header">
  <tr>
    <th width="45%" style="text-align:left">Host</th>
    <th width="25%" style="text-align:left">Seen</th>
    <th width="30%" style="text-align:left">Last Seen</th>
  </tr>
</thead>
  <tbody>
<?php
        $sql = "SELECT * FROM (SELECT * FROM hosts ORDER BY lastseen DESC) AS result LIMIT ". $_SESSION['PORTLET_HOSTS_LIMIT']; 
        $result = perform_query($sql, $dbLink, "portlet-hosts.php"); 
        $i=0; 
        while($row = fetch_array($result)) { 
        echo "<tr>";
        echo "<td id='host'>";
          echo "$row[host]";
        echo "</td>";
        echo "<td id='seen'>";
        echo $row['seen'] . " times\n";
        echo "</td>";
        echo "<td id='lastseen'>";
        echo getRelativeTime($row['lastseen']) . "\n";
        echo "</td>";
        echo "</tr>";
            $i++; 
        } 
        echo "</tbody>";
        echo "</table>";
} else { 
    echo "<b><u>No Hosts</u></b><br>";
    echo "Either wait for caches to update, or restart your syslog daemon.\n<br>";

} 
?>
<!-- BEGIN Large Host Selector Modal -->
<div class="dialog_hide">
    <div id="host_dialog" title="Host Selector">
          <?php require ($basePath . "/../grid/hosts.php");?> 
    </div>
</div>
<!-- END Large Host Selector Modal -->


<?php
} else { ?>
<script type="text/javascript">
$('#portlet_Hosts').remove()
</script>
<?php } ?>
