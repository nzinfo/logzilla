<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-04-23
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
?>
<TABLE BORDER="0" WIDTH="100%">
    <TR>
        <TD width="70%">
            <select style="width:99%" name="mnemonics[]" id="mnemonics" multiple size=3>
            <?php
            $sql = "select DISTINCT(name), crc FROM mne ORDER BY name ASC";
            $queryresult = perform_query($sql, $dbLink, $_REQUEST['pageId']);
            while ($line = fetch_array($queryresult)) {
   	            $mnemonic = $line['name'];
   	            echo "<option value=".$line['crc'].">".htmlentities($mnemonic)."</option>\n";
            }
            ?>
            </select>
        </TD>
    </TR>
</table>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Mnemonics').remove()
</script>
<?php } ?>
