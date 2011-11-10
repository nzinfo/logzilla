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
if ((has_portlet_access($_SESSION['username'], 'Severities') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) {
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
?>
<TABLE BORDER="0" WIDTH="100%">
    <TR>
        <TD width="70%">
            <select style="width:99%" name="severities[]" id="severities" multiple size=5>
            <?php
            $sql = "SELECT * FROM severities ORDER BY code DESC";
            $queryresult = perform_query($sql, $dbLink, $_REQUEST['pageId']);
            while ($line = fetch_array($queryresult)) {
   	            $severity = $line['name'];
   	            echo "<option value=".$line['code'].">".htmlentities($severity)."</option>\n";
            }
            ?>
            </select>
        </TD>
<!--
     <th width="10%">
            <span id="severities_andor_text">AND</span>
     </th>
        <TD width="20%">
            <div id="slide_wrapper">
            <div class="ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all" id="severities_andor"></div>
            </div>
        </TD>
-->
    </TR>
</table>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Severities').remove()
</script>
<?php } ?>
