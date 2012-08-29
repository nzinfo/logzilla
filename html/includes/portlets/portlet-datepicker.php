<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@logzilla.pro>
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
if ((has_portlet_access($_SESSION['username'], 'Date and Time') == trUE) || ($_SESSION['AUTHTYPE'] == "none")) { 
?>
<table width="100%" border="0">
        <?php if ($_SESSION['DEDUP'] == "1") { ?>
    <tr id="fotr">
        <td width="10%">
            <input type="checkbox" name="fo_checkbox" id="fo_checkbox">
            <b>FO</b>
        </td>
        <td width="90%" COLSPAN="2">
            <div id="fo_date_wrapper">
                <input type="text" size="25" value="<?php echo date("Y-m-d")?>" name="fo_date" id="fo_date">
            </div>
            <!--The fo_time_wrapper div is referenced in jquery.timePicker.js -->
            <div id="fo_time_wrapper"> 
                <input type="text" class="rounded_textbox watermark ui-widget ui-corner-all" name="fo_time_start" id="fo_time_start" size="10" value="00:00:00" /> 
                <input type="text" class="rounded_textbox watermark ui-widget ui-corner-all" name="fo_time_end" id="fo_time_end" size="10" value="23:59:59" />
            </div>
        </td>
    </tr>
    <?php } ?>
    <tr>
        <?php if ($_SESSION['DEDUP'] == "1") { ?>
        <td width="10%">
            <?php } else {?>
            <td width="25%">
                <?php } ?>
                <input type="checkbox" name="lo_checkbox" id="lo_checkbox" checked>
                <?php if ($_SESSION['DEDUP'] == "0") { ?>
                Date/Time
                <input type="hidden" name="lo_checkbox" value="on">
                <?php } else {?>
                <b>LO</b>
                <?php } ?>
            </td>
            <td width="90%" COLSPAN="2">
                <div id="lo_date_wrapper">
                    <input type="text" size="25" value="<?php echo date("Y-m-d")?>" name="lo_date" id="lo_date">
                </div>
                <!--The lo_time_wrapper div is referenced in jquery.timePicker.js -->
                <div id="lo_time_wrapper"> 
                    <input type="text" class="rounded_textbox watermark ui-widget ui-corner-all" name="lo_time_start" id="lo_time_start" size="10" value="00:00:00" /> 
                    <input type="text" class="rounded_textbox watermark ui-widget ui-corner-all" name="lo_time_end" id="lo_time_end" size="10" value="23:59:59" />
                </div>
            </td>
        </tr>
    </table>
    <?php } else { ?>
    <script type="text/javascript">
        $('#portlet_Date_and_Time').remove()
        </script>
        <?php } ?>
