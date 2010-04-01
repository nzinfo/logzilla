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
if ((has_portlet_access($_SESSION['username'], 'Priorities') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) {
?>
<TABLE BORDER="0" WIDTH="100%">
    <TR>
        <TD width="70%">
            <select style="width:99%" name="priorities[]" id="priorities" multiple size=8>
            <option>debug</option>
            <option>info</option>
            <option>notice</option>
            <option>warning</option>
            <option>err</option>
            <option>crit</option>
            <option>alert</option>
            <option>emerg</option>
            </select>
        </TD>
<!--
     <th width="10%">
            <span id="priorities_andor_text">AND</span>
     </th>
        <TD width="20%">
            <div id="slide_wrapper">
            <div class="ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all" id="priorities_andor"></div>
            </div>
        </TD>
-->
    </TR>
</table>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Priorities').remove()
</script>
<?php } ?>
