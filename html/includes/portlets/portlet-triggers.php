<?php
/*
 * portlet-triggers.php
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 *
 * 2010-12-10 - created
 *
 */

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

//---------------------------------------------------
// The get_input statements below are used to get
// POST, GET, COOKIE or SESSION variables.
// Note that PLURAL words below are arrays.
//---------------------------------------------------

if ((has_portlet_access($_SESSION['username'], 'Event Triggers') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 

$qstring = '';
$page = get_input('page');
$qstring .= "?page=$page";

$limit = get_input('limit');
$qstring .= "&limit=$limit";
if($limit) { $limit = " LIMIT $limit"; }

$orderby = get_input('orderby');
$qstring .= "&orderby=$orderby";
$orderby = (!empty($orderby)) ? $orderby : "id";
$where.= " ORDER BY $orderby";  
$order = get_input('order');
$qstring .= "&order=$order";
$order = (!empty($order)) ? $order : "ASC";
?>

<table id="theTable" cellpadding="0" cellspacing="0" class="no-arrow paginate-<?php echo $_SESSION['PAGINATE']?> max-pages-7 paginationcallback-callbackTest-calculateTotalRating paginationcallback-callbackTest-displayTextInfo sortcompletecallback-callbackTest-calculateTotalRating trigger_table">
<thead class="ui-widget-header">
  <tr class='HeaderRow'>
    <th class="s_th"></th>
    <th class="s_th sortable-text">Description</th>
    <th class="s_th sortable-text">Pattern</th>
    <th class="s_th sortable-text">Mail To</th>
    <th class="s_th sortable-text">Mail From</th>
    <th class="s_th sortable-text">Subject</th>
    <th class="s_th sortable-text">Body</th>
    <th class="s_th sortable-text">Disabled?</th>
  </tr>
</thead>

  <tbody>
  <center><font size="4">NOTE: If you have a VERY large system, please be aware that adding a lot of RegEx patterns will likely slow message processing down.</font></center><BR />
  <?php
  $sql = "SELECT * FROM triggers $where $limit";
  $result = perform_query($sql, $dbLink, $_REQUEST['pageId']); 
  while($row = fetch_array($result)) { 
      ?>
          <tr>
          <td class="s_td"><a href="#" onclick="edit(<?php echo $row['id']?>);return false;" id="<?php echo $row['id']?>"><img style="border-style: none; width: 30px; height: 30px;" src="<?php echo $_SESSION['SITE_URL']?>images/edit_sm.png" /></a></td>
          <?php
          $d = stripslashes($row['description']);
          $p = stripslashes($row['pattern']);
          $t = stripslashes($row['mailto']);
          $f = stripslashes($row['mailfrom']);
          $s = stripslashes($row['subject']);
          $b = stripslashes($row['body']);
          $di = stripslashes($row['disabled']);
          // Replace carriage returns for better display
          $desc_html = preg_replace ('/\r|\n/m', '<br />', $d);
          $body_html = preg_replace ('/\r|\n/m', '<br />', $b);
          ?>
          <td class="s_td"><?php echo $desc_html?></td>
          <td class="s_td"><?php echo $p?></td>
          <td class="s_td"><?php echo $t?></td>
          <td class="s_td"><?php echo $f?></td>
          <td class="s_td"><?php echo $s?></td>
          <td class="s_td"><?php echo $body_html?></td>
          <td class="s_td"><?php if ($row['disabled'] == "Yes") echo "Yes"; ?></td>
          </tr>
          <?php
    }
  ?>
  </tbody>
  </table>

<!-- From here down is the modal dialog for editing the record notes
Adapted from http://stackoverflow.com/questions/394491/passing-data-to-a-jquery-ui-dialog
-->
<script type= "text/javascript">/*<![CDATA[*/
function edit(dbid){
    var items = new Array();
    $("#edit_dialog").dialog({
                        bgiframe: true,
                        resizable: true,
                        height: 'auto',
                        width: '50%',
                        autoOpen:false,
                        modal: true,
                        open: function() {
                        $.ajax({
                        url: 'includes/ajax/json.triggers.php?action=get&dbid='+ dbid,
                        dataType: 'json',
                        success: function(data) {
                        var description = data.description
                        var pattern = data.pattern
                        var mailto = data.mailto
                        var mailfrom = data.mailfrom
                        var subject = data.subject
                        var body = data.body
                        var disabled = data.disabled
                        /*
                        alert (description);
                        alert (pattern);
                        alert (mailto);
                        alert (mailfrom);
                        alert (subject);
                        alert (body);
                        alert (disabled);
                        */
                        $("#name").html('Trigger Pattern Editor');
                        $("#description").html('<input type="text" value="'+ description +'" id="description_val" class="text ui-widget-content ui-corner-all">');
                        $("#pattern").html('<input type="text" value="'+ pattern +'" id="pattern_val" class="text ui-widget-content ui-corner-all">');
                        $("#mailto").html('<input type="text" value="'+ mailto +'" id="mailto_val" class="text ui-widget-content ui-corner-all">');
                        $("#mailfrom").html('<input type="text" value="'+ mailfrom +'" id="mailfrom_val" class="text ui-widget-content ui-corner-all">');
                        $("#subject").html('<input type="text" value="'+ subject +'" id="subject_val" class="text ui-widget-content ui-corner-all">');
                        $("#body").html('<textarea id="body_val" class="text ui-widget-content ui-corner-all" cols="68" rows="5">' + body + '</textarea>');
                        if (disabled == "Yes") {
                        $("#disabled").html('<select id="disabled_val" class="ui-corner-all"><option selected value="Yes">Yes<option value="No">No</select>');
                        } else {
                        $("#disabled").html('<select id="disabled_val" class="ui-corner-all"><option value="Yes">Yes<option selected value="No">No</select>');
                        };
                        }
                        });
                         },
                        overlay: {
                                backgroundColor: '#000',
                                opacity: 0.5
                        },
                        buttons: {
                                     'Save to Database': function() {
                                        $(this).dialog('close');
// Hafta pass the URL string as encoded data because of the regex patterns, etc.
function urlEncodeCharacter (c)
{
    return '%' + c.charCodeAt(0).toString(16);
};

function urlEncode(s){
      return encodeURIComponent( s ).replace( /\%20/g, '+' ).replace( /[!'()*~]/g, urlEncodeCharacter );
};
                                        var description = urlEncode($('#description_val').val());
                                        var pattern = urlEncode($('#pattern_val').val());
                                        var mailto = urlEncode($('#mailto_val').val());
                                        var mailfrom = urlEncode($('#mailfrom_val').val());
                                        var subject = urlEncode($('#subject_val').val());
                                        var body = urlEncode($('#body_val').val());
                                        var disabled = urlEncode($('#disabled_val').val());
                        /*
                        alert (description);
                        alert (pattern);
                        alert (mailto);
                        alert (mailfrom);
                        alert (subject);
                        alert (body);
                        alert (disabled);
                        */
                                        $.get("includes/ajax/json.triggers.php?action=save&dbid="+dbid+"&description="+description+"&pattern="+pattern+"&mailto="+mailto+"&mailfrom="+mailfrom+"&subject="+subject+"&body="+body+"&disabled="+disabled, function(data){
                                        $('#msgbox_br').jGrowl(data);
                                           });
                                },
                                Cancel: function() {
                                        $(this).dialog('close');
                                }
                        }
                });
                $("#edit_dialog").dialog('open');     
                //return false;
     }
    /*]]>*/
</script>
<div class="dialog_hide">
    <div id="edit_dialog" title="Edit Settings">
        <form>
<table id="tbl_edit_triggers" cellpadding="0" cellspacing="0" width="100%" border="0">
    <thead class="ui-widget-header">
        <tr>
            <th width="10%"></th>
            <th width="60%"></th>
        </tr>
    </thead>
    <tbody>
        <div style="text-align:center;" id="name" class="portlet-header"></div>
        <tr>
            <td>Description: </td>
            <td><div style="text-align:left;" id="description" class="portlet-content"></div></td>
        </tr>
        <tr>
            <td>Pattern: </td>
            <td><div style="text-align:left;" id="pattern" class="portlet-content"></div></td>
        </tr>
        <tr>
            <td>Mail To: </td>
            <td><div style="text-align:left;" id="mailto" class="portlet-content"></div></td>
        </tr>
        <tr>
            <td>Mail From: </td>
            <td><div style="text-align:left;" id="mailfrom" class="portlet-content"></div></td>
        </tr>
        <tr>
            <td>Subject: </td>
            <td><div style="text-align:left;" id="subject" class="portlet-content"></div></td>
        </tr>
        <tr>
            <td>Body: </td>
            <td><div style="text-align:left;" id="body" class="portlet-content"></div></td>
        </tr>
        <tr>
            <td>Disable Pattern?</td>
            <td><div style="text-align:left;" id="disabled" class="portlet-content"></div></td>
        </tr>
<input type="hidden" name="dbid" id="dbid" value="">
</tbody>
</table>
        </form>
    </div>
</div>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Event_Triggers').remove()
</script>
<?php } ?>
