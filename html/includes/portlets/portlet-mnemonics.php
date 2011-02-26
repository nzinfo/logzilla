<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-06-15
 *
 * Changelog:
 * 2009-12-13 - created
 *
 */

session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
if ((has_portlet_access($_SESSION['username'], 'Mnemonics') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) {
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
// -------------------------
// Get Mnemonics
// -------------------------
$sql = "SELECT COUNT(*) FROM (SELECT crc FROM mne) AS result";
$result = perform_query($sql, $dbLink, $_REQUEST['pageId']);
$total = mysql_fetch_row($result);
$count = $total[0];
if( $count >0 ) { 
?>
<script type="text/javascript">
var cnt = <?php echo $count?>;
if (cnt < 11) {
    $('#portlet-header_Mnemonics').prepend("Last " + cnt + " ");
    } else {
    $('#portlet-header_Mnemonics').prepend("Last 10 ");
    $('#portlet-header_Mnemonics').append(" (<?php echo commify($count)?> total)")
};
</script>
<table id="tbl_mne" cellpadding="0" cellspacing="0" width="100%" border="0">
<thead class="ui-widget-header">
  <tr>
    <th width="5%" style="text-align:left"></th>
    <th width="50%" style="text-align:left">Mnemonic</th>
    <th width="15%" style="text-align:left">Seen</th>
    <th width="30%" style="text-align:left">Last Seen</th>
  </tr>
</thead>
  <tbody>
<?php
        $sql = "SELECT * FROM (SELECT * FROM mne ORDER BY lastseen DESC) AS result LIMIT ". $_SESSION['PORTLET_HOSTS_LIMIT']; 
        $result = perform_query($sql, $dbLink, "portlet-mnemonics.php"); 
        $i=0; 
        while($row = fetch_array($result)) { 
        echo "<tr>";
        echo "<td id='mne_sel'>";
          echo "<input type=\"checkbox\" name=\"sel_mne[]\" value=\"$row[name]\"";
        echo "</td>";
        echo "<td id='mne'>";
        if (strlen($row['name']) < 26) {
            echo "$row[name]";
        } else {
            if (strlen($row['name']) > 39) {
                echo "<span style=\"font-size: xx-small\">$row[name]</span>";
            } else {
                echo "<span style=\"font-size: x-small\">$row[name]</span>";
            }
        }
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
    echo "<b><u>No Mnemonics</u></b><br>";
    echo "Either wait for caches to update, or restart your syslog daemon.\n<br>";
} 
?>

<!-- BEGIN Mnemonics Selector Modal -->
<div class="dialog_hide">
    <div id="mne_dialog" title="Mnemonic Selector">
          <?php require ($basePath . "/../grid/mne.php");?> 
    </div>
</div>
<!-- END Mnemonics Selector Modal -->


<?php
} else { ?>
<script type="text/javascript">
$('#portlet_Mnemonics').remove()
</script>
<?php } ?>
