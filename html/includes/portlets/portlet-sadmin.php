<?php
/*
 * portlet-table.php
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-05-04
 *
 * Pagination and table formatting created using 
 * http://www.frequency-decoder.com/2007/10/19/client-side-table-pagination-script/
 * Changelog:
 * 2010-02-28 - created
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

if ((has_portlet_access($_SESSION['username'], 'Server Settings') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 
$where = "WHERE hide='no'";

$qstring = '';
$page = get_input('page');
$qstring .= "?page=$page";

// portlet-search_options
$limit = get_input('limit');
$qstring .= "&limit=$limit";
if($limit) { $limit = " LIMIT $limit"; }

$orderby = get_input('orderby');
$qstring .= "&orderby=$orderby";
$orderby = (!empty($orderby)) ? $orderby : "name";
$where.= " ORDER BY $orderby";  
$order = get_input('order');
$qstring .= "&order=$order";
$order = (!empty($order)) ? $order : "ASC";
?>

<table id="theTable" cellpadding="0" cellspacing="0" class="no-arrow paginate-<?php echo $_SESSION['PAGINATE']?> max-pages-7 paginationcallback-callbackTest-calculateTotalRating paginationcallback-callbackTest-displayTextInfo sortcompletecallback-callbackTest-calculateTotalRating s_table">
<thead class="ui-widget-header">
  <tr class='HeaderRow'>
    <th class="s_th"></th>
    <th class="s_th sortable-text">Name</th>
    <th class="s_th sortable-text">Value</th>
    <th class="s_th sortable-text">Description</th>
  </tr>
</thead>

  <tbody>
  <center><font size="4">Changing some of these settings will render your server unusable, proceed with CAUTION!!!</font></center>
  <?php
  $sql = "SELECT * FROM settings $where $limit";
  $result = perform_query($sql, $dbLink, $_REQUEST['pageId']); 
  while($row = fetch_array($result)) { 
      ?>
          <tr>
          <td class="s_td"><a href="#" onclick="edit(<?php echo $row['id']?>);return false;" id="<?php echo $row['id']?>"><img style="border-style: none; width: 30px; height: 30px;" src="<?php echo $_SESSION['SITE_URL']?>images/edit_sm.png" /></a></td>
          <td class="s_td"><?php echo $row['name']?></td>
          <td class="s_td"><?php echo $row['value']?></td>
          <td class="s_td"><?php echo $row['description']?></td>
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
                        url: 'includes/ajax/json.sadmin.php?action=get&dbid='+ dbid,
                        dataType: 'json',
                        success: function(data) {
                        var name = data.name
                        var value = data.value
                        var type = data.type
                        var options = data.options
                        var def = data.def
                        var description = data.description
                        /*
                        alert (name);
                        alert (value);
                        alert (type);
                        alert (options);
                        alert (def);
                        alert (description);
                        */
                        $('#name').html(name + '<input type="hidden" value="'+ name +'" id="name_val">');
                        if (type == "enum") {
                        var temp = new Array();
                        temp = options.split(',');
                        var val = '<select id="select_val">';
                        var opts = '';
                        $.each( temp, function(i, option){
                                if (option == value) {
                                opts = opts +'<option selected>'+ option;
                                } else {
                                opts = opts +'<option>'+ option;
                                }
                                });
                        val = val + opts + '</select>';
                        // alert(val);
                            $("#value").html(val + '<input type="hidden" value="'+ value +'" id="select_val" class="text ui-widget-content ui-corner-all">');
                        } else {
                            $("#value").html('<input type="text" value="'+ value +'" id="value_val" class="text ui-widget-content ui-corner-all">');
                        }
                        $("#default").html('Default: ' + def);
                        $("#description").html(description);
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
                                        $.get("includes/ajax/json.sadmin.php?action=save&dbid="+dbid+"&value="+value+"&name="+name, function(data){
                                        $('#msgbox_br').jGrowl(data);
                                           });
                                        if (name == 'AUTHTYPE') {
                                        window.location.href='<?php echo $_SESSION["SITE_URL"]?>logout.php';
                                        }
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
        <fieldset>
            <div style="text-align:center;" id="name" class="portlet-header"></div>
            <div style="text-align:left;" id="value" class="portlet-content"></div>
            <div style="text-align:left;" id="default" class="portlet-content"></div>
            <div style="text-align:left;" id="description" class="portlet-content"></div>
            <input type="hidden" name="dbid" id="dbid" value="">
        </fieldset>
        </form>
    </div>
</div>
<div class="dialog_hide">
    <div id="cemdb_dialog" title="Error Message Decoder">
      <?php echo $cemdb_info?>
    </div>
</div>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Server_Settings').remove()
</script>
<?php } ?>
