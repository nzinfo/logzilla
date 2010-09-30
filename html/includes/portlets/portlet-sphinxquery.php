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
<?php if ($_SESSION['SPX_ENABLE'] !== "1") {?>
<tr>
<th>Operators</th>
<th></th>
<tr>
<?php } ?>

<tr>
<?php if ($_SESSION['SPX_ENABLE'] !== "1") {?>
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
<?php } ?>
    <td width="95%">
<?php if ($_SESSION['SHOWCOUNTS'] > 0) {?>
        <input autocomplete="off" type="text" style="width: 95%; text-align: left; position: relative; left: 3%;" class="rounded_textbox watermark ui-widget ui-corner-all" name="msg_mask" id="msg_mask" size=30>
            <div style="width: 95%; text-align: left; position: relative; left: 3%;">
            <input type="radio" name="q_type" value="any" /> Any
            <input type="radio" name="q_type" value="all" /> All
            <input type="radio" name="q_type" value="phrase" /> Phrase
            <input checked="checked" type="radio" name="q_type" value="boolean" /> Boolean
            <input type="radio" name="q_type" value="extended" /> Extended
            </div>
<?php } else { ?>
        <input autocomplete="off" type="text" style="width: 95%; text-align: left; position: relative; left: 3%;" class="rounded_textbox ui-widget ui-corner-all" name="msg_mask" id="msg_mask" size=30>
<?php } ?>
    </td>
</tr>

<?php if ($_SESSION['SPX_ENABLE'] !== "1") {?>
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
<?php } ?>

<tr>
<?php if ($_SESSION['SPX_ENABLE'] !== "1") {?>
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
<?php if ($_SESSION['SHOWCOUNTS'] > 0) {?>
        <input autocomplete="off" type="text" style="width: 95%; text-align: left; position: relative; left: 3%;" class="rounded_textbox watermark ui-widget ui-corner-all" name="notes_mask" id="notes_mask" size=30>
<?php } else { ?>
        <input autocomplete="off" type="text" style="width: 95%; text-align: left; position: relative; left: 3%;" class="rounded_textbox ui-widget ui-corner-all" name="notes_mask" id="notes_mask" size=30>
<?php } ?>
    </td>
<?php } ?>
</tr>

</table>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Messages').remove()
</script>
<?php } ?>
