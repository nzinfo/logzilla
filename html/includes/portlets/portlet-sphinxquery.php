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
if ((has_portlet_access($_SESSION['username'], 'Messages') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) {
?>
<table border="0" width="100%">
<thead>
</thead>
<tr>
<th>Operators</th>
<th></th>
<tr>

<tr>
    <td width="5%">
        <select name="msg_mask_oper" id="msg_mask_oper">
        <option>=
        <option>!=
        <option selected>LIKE
        <option>! LIKE
        <option>RLIKE
        <option>! RLIKE
        </select>
    </td>
    <td width="95%">
        <input type="text" style="width: 80%;" class="rounded_textbox watermark ui-widget ui-corner-all" name="msg_mask" id="msg_mask" size=30>
    </td>
</tr>

<tr>
    <td width="5%">
        <select name="notes_andor" id="notes_andor">
        <option>AND
        <option>OR
        </select>
    </td>
    <td width="95%">
    </td>
</tr>

<tr>
    <td width="5%">
        <select name="notes_mask_oper" id="notes_mask_oper">
        <option>=
        <option>!=
        <option selected>LIKE
        <option>! LIKE
        <option>RLIKE
        <option>! RLIKE
        <option>EMPTY
        <option>! EMPTY
        </select>
    </td>
    <td>
        <input type="text" style="width: 80%;" class="rounded_textbox watermark ui-widget ui-corner-all" name="notes_mask" id="notes_mask" size=30>
    </td>
</tr>

</table>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Messages').remove()
</script>
<?php } ?>
