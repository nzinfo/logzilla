<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-05-12
 *
 * Changelog:
 * 2009-12-13 - created
 *
 */

session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
if ((has_portlet_access($_SESSION['username'], 'Programs') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) {
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
// -------------------------
// Get Programs
// -------------------------
?>
<TABLE BORDER="0" WIDTH="100%">
    <TR>
        <TD width="70%">
            <select style="width:99%" name="programs[]" id="programs" multiple size=3>
            <?php
            $sql = "select DISTINCT(name), crc FROM programs ORDER BY name ASC";
            $queryresult = perform_query($sql, $dbLink, $_REQUEST['pageId']);
            while ($line = fetch_array($queryresult)) {
   	            $program = $line['name'];
   	            echo "<option value=".$line['crc'].">".htmlentities($program)."</option>\n";
            }
            ?>
            </select>
        </TD>
<!--
     <th width="10%">
            <span id="program_andor_text">OR</span>
     </th>
        <TD width="20%">
            <div id="slide_wrapper">
            <div class="ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all" id="program_andor"></div>
            </div>
        </TD>
-->
    </TR>
</table>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Programs').remove()
</script>
<?php } ?>
