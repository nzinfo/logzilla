<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-05-16
 *
 * Changelog:
 * 2009-12-13 - created
 *
 */

session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
if ((has_portlet_access($_SESSION['username'], 'Date and Time') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 
?>
<TABLE WIDTH="100%" BORDER="0">
    <TR>
        <TD WIDTH="10%">
        <input type="checkbox" name="fo_checkbox" id="fo_checkbox">
        <b>FO</b>
        </TD>
        <TD WIDTH="90%" COLSPAN="2">
            <div id="fo_date_wrapper">
            <input type="text" size="25" value="<?php echo date("Y-m-d")?>" name="fo_date" id="fo_date">
            </div>
            <!--The fo_time_wrapper div is referenced in jquery.timePicker.js -->
            <div id="fo_time_wrapper"> 
            <input type="text" class="rounded_textbox watermark ui-widget ui-corner-all" name="fo_time_start" id="fo_time_start" size="10" value="00:00:00" /> 
            <input type="text" class="rounded_textbox watermark ui-widget ui-corner-all" name="fo_time_end" id="fo_time_end" size="10" value="23:59:59" />
            </div>
        </TD>
    </TR>
<tr>
    <td width="5%">
        <select name="date_andor" id="date_andor">
        <option>AND
        <option>OR
        </select>
    </td>
    <td width="95%">
    </td>
</tr>

    <TR>
        <TD WIDTH="10%">
        <input type="checkbox" name="lo_checkbox" id="lo_checkbox" checked>
        <b>LO</b>
        </TD>
        <TD WIDTH="90%" COLSPAN="2">
            <div id="lo_date_wrapper">
            <input type="text" size="25" value="<?php echo date("Y-m-d")?>" name="lo_date" id="lo_date">
        </div>
            <!--The lo_time_wrapper div is referenced in jquery.timePicker.js -->
            <div id="lo_time_wrapper"> 
            <input type="text" class="rounded_textbox watermark ui-widget ui-corner-all" name="lo_time_start" id="lo_time_start" size="10" value="00:00:00" /> 
            <input type="text" class="rounded_textbox watermark ui-widget ui-corner-all" name="lo_time_end" id="lo_time_end" size="10" value="23:59:59" />
            </div>
        </TD>
    </TR>
</TABLE>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Date_and_Time').remove()
</script>
<?php } ?>
