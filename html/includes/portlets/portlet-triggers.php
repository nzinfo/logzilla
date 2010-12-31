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
          <td class="s_td"><?php echo $row['description']?></td>
          <td class="s_td"><?php echo $row['pattern']?></td>
          <td class="s_td"><?php echo $row['to']?></td>
          <td class="s_td"><?php echo $row['from']?></td>
          <td class="s_td"><?php echo $row['subject']?></td>
          <td class="s_td"><?php echo $row['body']?></td>
          <td class="s_td"><?php if ($row['disable'] == "Yes") echo "Yes"; ?></td>
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
                        var to = data.to
                        var from = data.from
                        var subject = data.subject
                        var body = data.body
                        var disable = data.disable
                        /*
                        alert (description);
                        alert (pattern);
                        alert (to);
                        alert (from);
                        alert (subject);
                        alert (body);
                        alert (disable);
                        */
                        $("#name").html('Trigger Pattern Editor');
                        $("#description").html('<input type="text" value="'+ description +'" id="description" class="text ui-widget-content ui-corner-all">');
                        $("#pattern").html('<input type="text" value="'+ pattern +'" id="pattern" class="text ui-widget-content ui-corner-all">');
                        $("#to").html('<input type="text" value="'+ to +'" id="to" class="text ui-widget-content ui-corner-all">');
                        $("#from").html('<input type="text" value="'+ from +'" id="from" class="text ui-widget-content ui-corner-all">');
                        $("#subject").html('<input type="text" value="'+ subject +'" id="subject" class="text ui-widget-content ui-corner-all">');
                        $("#body").html('<input type="text" value="'+ body +'" id="body" class="text ui-widget-content ui-corner-all">');
                        var temp = new Array();
                        temp = disable.split(',');
                        var val = '<select id="disable">';
                        var opts = '';
                        $.each( temp, function(i, option){
                                if (option == value) {
                                opts = opts +'<option selected>'+ option;
                                } else {
                                opts = opts +'<option>'+ option;
                                }
                                });
                        val = val + opts + '</select>';
                         alert(val);
                            $("#disable").html(val + '<input type="hidden" value="'+ value +'" id="select_val" class="text ui-widget-content ui-corner-all">');
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
                                        var name = $('#name_val').val();
                                        var value = $('#value_val').val();
                                        if (!value) {
                                            var value = $('#select_val').val();
                                        }
                                        $.get("includes/ajax/json.triggers.php?action=save&dbid="+dbid+"&value="+value+"&name="+name, function(data){
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
<table id="tbl_edit_triggers" cellpadding="0" cellspacing="0" width="100%" border="1">
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
            <td><div style="text-align:left;" id="to" class="portlet-content"></div></td>
        </tr>
        <tr>
            <td>Mail From: </td>
            <td><div style="text-align:left;" id="from" class="portlet-content"></div></td>
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
            <td><div style="text-align:left;" id="disable" class="portlet-content"></div></td>
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
