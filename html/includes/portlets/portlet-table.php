<?php
/*
 * portlet-table.php
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-05-05
 *
 * Pagination and table formatting created using 
 * http://www.frequency-decoder.com/2007/10/19/client-side-table-pagination-script/
 * Changelog:
 * 2010-02-28 - created
 *
 */

session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
if ((has_portlet_access($_SESSION['username'], 'Search Results') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) {
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
$start_time = microtime(true);
//---------------------------------------------------
// The get_input statements below are used to get
// POST, GET, COOKIE or SESSION variables.
// Note that PLURAL words below are arrays.
//---------------------------------------------------

$today = date("Y-m-d");
//construct where clause 
$where = "WHERE 1=1";

$qstring = '';
$page = get_input('page');
$qstring .= "?page=$page";

$show_suppressed = get_input('show_suppressed');
$qstring .= "&show_suppressed=$show_suppressed";
    switch ($show_suppressed) {
        case "suppressed":
        $where.= " AND suppress > NOW()";  
        $where .= " OR host IN (SELECT name from suppress where col='host' AND expire>NOW())";
        $where .= " OR facility IN (SELECT name from suppress where col='facility' AND expire>NOW())";
        $where .= " OR severity IN (SELECT name from suppress where col='severity' AND expire>NOW())";
        $where .= " OR program IN (SELECT name from suppress where col='program' AND expire>NOW())";
        $where .= " OR mne IN (SELECT name from suppress where col='mnemonic' AND expire>NOW())";
        $where .= " OR msg IN (SELECT name from suppress where col='msg' AND expire>NOW())";
        $where .= " OR counter IN (SELECT name from suppress where col='counter' AND expire>NOW())";
        $where .= " OR notes IN (SELECT name from suppress where col='notes' AND expire>NOW())";
            break;
        case "unsuppressed":
        $where.= " AND suppress < NOW()";  
        $where .= " AND host NOT IN (SELECT name from suppress where col='host' AND expire>NOW())";
        $where .= " AND facility NOT IN (SELECT name from suppress where col='facility' AND expire>NOW())";
        $where .= " AND severity NOT IN (SELECT name from suppress where col='severity' AND expire>NOW())";
        $where .= " AND program NOT IN (SELECT name from suppress where col='program' AND expire>NOW())";
        $where .= " AND mne NOT IN (SELECT name from suppress where col='mnemonic' AND expire>NOW())";
        $where .= " AND msg NOT IN (SELECT name from suppress where col='msg' AND expire>NOW())";
        $where .= " AND counter NOT IN (SELECT name from suppress where col='counter' AND expire>NOW())";
        $where .= " AND notes NOT IN (SELECT name from suppress where col='notes' AND expire>NOW())";
        break;
}

//------------------------------------------------------------
// START date/time
//------------------------------------------------------------
// portlet-datepicker 
$fo_checkbox = get_input('fo_checkbox');
    $qstring .= "&fo_checkbox=$fo_checkbox";
$fo_date = get_input('fo_date');
    $qstring .= "&fo_date=$fo_date";
$fo_time_start = get_input('fo_time_start');
    $qstring .= "&fo_time_start=$fo_time_start";
$fo_time_end = get_input('fo_time_end');
    $qstring .= "&fo_time_end=$fo_time_end";
$date_andor = get_input('date_andor');
    $qstring .= "&date_andor=$date_andor";
$lo_checkbox = get_input('lo_checkbox');
    $qstring .= "&lo_checkbox=$lo_checkbox";
$lo_date = get_input('lo_date');
    $qstring .= "&lo_date=$lo_date";
$lo_time_start = get_input('lo_time_start');
    $qstring .= "&lo_time_start=$lo_time_start";
$lo_time_end = get_input('lo_time_end');
    $qstring .= "&lo_time_end=$lo_time_end";
// FO
if ($fo_checkbox == "on") {
    if($fo_date!='') {
        list($start,$end) = explode(' to ', $fo_date);
        if($end=='') $end = "$start" ; 
        if($fo_time_start!=$fo_time_end) {
            $start .= " $fo_time_start"; 
            $end .= " $fo_time_end"; 
        }
            $where.= " AND fo BETWEEN '$start' AND '$end'";
    }
}
// LO
$start = "";
$end = "";
if ($lo_checkbox == "on") {
    if($lo_date!='') {
        list($start,$end) = explode(' to ', $lo_date);
        if($end=='') $end = "$start" ; 
        if($lo_time_start!=$lo_time_end) {
            $start .= " $lo_time_start"; 
            $end .= " $lo_time_end"; 
        }
        if (($start !== "$today 00:00:00") && ($end !== "$today 23:59:59")) {
            $where.= " ".strtoupper($date_andor)." lo BETWEEN '$start' AND '$end'";
        }
    }
}
//------------------------------------------------------------
// END date/time
//------------------------------------------------------------


// see if we are tailing
$tail = get_input('tail');
if (!$tail) { $tail = "off"; }
$qstring .= "&tail=$tail";

// Special - this gets posted via javascript since it comes from the hosts grid
// Form code is somewhere near line 843 of js_footer.php
$hosts = get_input('hosts');
$qstring .= "&hosts=$hosts";
if ($hosts) {
    $pieces = explode(",", $hosts);
    $where .= " AND host IN (";
    foreach ($pieces as $mask) {
        $where.= "'$mask',";  
    }
    $where = rtrim($where, ",");
    $where .= ")";
}
// portlet-programs
$programs = get_input('programs');
if ($programs) {
    $where .= " AND program IN (";
    foreach ($programs as $program) {
        if (!preg_match("/^\d+/m", $program)) {
            $program = prg2crc($program);
        }
            $where.= "'$program',";
        $qstring .= "&programs[]=$program";
    }
    $where = rtrim($where, ",");
    $where .= ")";
}

// portlet-severities
$severities = get_input('severities');
if ($severities) {
    $where .= " AND severity IN (";
    foreach ($severities as $severity) {
        if (!preg_match("/^\d+/m", $severity)) {
            $severity = sev2int($severity);
        }
            $where.= "'$severity',";
        $qstring .= "&severities[]=$severity";
    }
    $where = rtrim($where, ",");
    $where .= ")";
}


// portlet-facilities
$facilities = get_input('facilities');
if ($facilities) {
    $where .= " AND facility IN (";
    foreach ($facilities as $facility) {
        if (!preg_match("/^\d+/m", $facility)) {
            $facility = fac2int($facility);
        }
            $where.= "'$facility',";
        $qstring .= "&facilities[]=$facility";
    }
    $where = rtrim($where, ",");
    $where .= ")";
}
$mnemonics = get_input('mnemonics');
if ($mnemonics) {
    $where .= " AND mne IN (";
    foreach ($mnemonics as $mnemonic) {
        if (!preg_match("/^\d+/m", $mnemonic)) {
            $mnemonic = mne2crc($mnemonic);
        }
        $where.= "'$mnemonic',";
        $qstring .= "&mnemonics[]=$mnemonic";
    }
    $where = rtrim($where, ",");
    $where .= ")";
}

$limit = get_input('limit');
$limit = (!empty($limit)) ? $limit : "10";
$qstring .= "&limit=$limit";

// portlet-sphinxquery
$msg_mask = get_input('msg_mask');
$msg_mask = preg_replace ('/^Search through .*\sMessages/m', '', $msg_mask);
$msg_mask_oper = get_input('msg_mask_oper');
$qstring .= "&msg_mask=$msg_mask&msg_mask_oper=$msg_mask_oper";

$orderby = get_input('orderby');
$qstring .= "&orderby=$orderby";

$order = get_input('order');
$qstring .= "&order=$order";

if($msg_mask !== '') {
    if ($_SESSION['SPX_ENABLE'] == "1") {
        //---------------BEGIN SPHINX
        require_once ($basePath . "/../SPHINX.class.php");
        $index = "idx_logs idx_delta_logs";
        $cl = new SphinxClient ();
        $hostip = $_SESSION['SPX_SRV'];
        $port = intval($_SESSION['SPX_PORT']);
        $cl->SetServer ( $hostip, $port );
        $cl->SetMatchMode ( SPH_MATCH_ANY );
           if ($order == 'DESC') {
           $cl->SetSortMode(SPH_SORT_ATTR_DESC, "$orderby");
           } else {
           $cl->SetSortMode(SPH_SORT_ATTR_ASC, "$orderby");
           }
            // $cl->SetSortMode(SPH_SORT_EXTENDED2, "$orderby $order");
        $cl->SetLimits(0, intval($_SESSION['SPX_MAX_MATCHES']));
        $escaped = $cl->EscapeString ( "$msg_mask" );
        $res = $cl->Query ($escaped, $index);

        if ( !$res )
        {
      $info = "<font size=\"3\" color=\"white\"><br><br>Sphinx - Error in query: ";
            die ( "$info" . $cl->GetLastError() . ".\n</font>" );
        } else
        {
            if ($res['total_found'] > 0) {
                $where .= " AND id IN (";
                   // $orby .= " ORDER BY FIELD($orderby,";
                foreach ( $res["matches"] as $doc => $docinfo ) {
                    $where .= "'$doc',";
                       // $orby .= "'$doc',";
                    // echo "$doc<br>\n";
                }
                $where = rtrim($where, ",");
                   // $orby = rtrim($orby, ",");
                $where .= ")";
                  // $orby .= ")";
            } else {
                // Negate search since sphinx returned 0 hits
                $where = "WHERE 1<1";
                //  die(print_r($res));
            }
        }
        //---------------END SPHINX
    } else {
        $msg_mask = mysql_real_escape_string($msg_mask);
        switch ($msg_mask_oper) {
            case "=":
                $where.= " AND msg='$msg_mask'";  
            break;

            case "!=":
                $where.= " AND msg='$msg_mask'";  
            break;

            case "LIKE":
                $where.= " AND msg LIKE '%$msg_mask%'";  
            break;

            case "! LIKE":
                $where.= " AND msg NOT LIKE '%$msg_mask%'";  
            break;

            case "RLIKE":
                $where.= " AND msg RLIKE '$msg_mask'";  
            break;

            case "! RLIKE":
                $where.= " AND msg NOT LIKE '$msg_mask'";  
            break;
        }
    }
}
$notes_mask = get_input('notes_mask');
$notes_mask = preg_replace ('/^Search through .*\sNotes/m', '', $notes_mask);
$notes_mask_oper = get_input('notes_mask_oper');
$notes_andor = get_input('notes_andor');
$qstring .= "&notes_mask=$notes_mask&notes_mask_oper=$notes_mask_oper&notes_andor=$notes_andor";
if($notes_mask) {
    switch ($notes_mask_oper) {
        case "=":
            $where.= " AND notes='$notes_mask'";  
        break;

        case "!=":
            $where.= " AND notes='$notes_mask'";  
        break;

        case "LIKE":
            $where.= " AND notes LIKE '%$notes_mask%'";  
        break;

        case "! LIKE":
            $where.= " AND notes NOT LIKE '%$notes_mask%'";  
        break;

        case "RLIKE":
            $where.= " AND notes RLIKE '$notes_mask'";  
        break;

        case "! RLIKE":
            $where.= " AND notes NOT LIKE '$notes_mask'";  
        break;

        case "EMPTY":
            $where.= " AND notes = ''";  
        break;

        case "! EMPTY":
            $where.= " AND notes != ''";  
        break;
    }
} else {
    if($notes_mask_oper) {
        switch ($notes_mask_oper) {
            case "EMPTY":
                $where.= " AND notes = ''";  
            break;

            case "! EMPTY":
                $where.= " AND notes != ''";  
            break;
        }
    }
}

// portlet-search_options
$dupop = get_input('dupop');
$qstring .= "&dupop=$dupop";
$dupop_orig = $dupop;
$dupcount = get_input('dupcount');
$qstring .= "&dupcount=$dupcount";
if (($dupop) && ($dupop != 'undefined')) {
    switch ($dupop) {
        case "gt":
            $dupop = ">";
        break;

        case "lt":
            $dupop = "<";
        break;

        case "eq":
            $dupop = "=";
        break;

        case "gte":
            $dupop = ">=";
        break;

        case "lte":
            $dupop = "<=";
        break;
    }
    $where.= " AND counter $dupop '$dupcount'"; 
}
// Not implemented yet (for graph generation)
$topx = get_input('topx');
$qstring .= "&topx=$topx";
$graphtype = get_input('graphtype');
$qstring .= "&graphtype=$graphtype";

if ($orderby) {
    $where.= " ORDER BY $orderby";  
}
if ($order) {
    $where.= " $order";  
}

?>

<div id="refresh_content">
<form name="export" method="POST" action= "includes/excel.php" name="checkboxes[]">
<span class="sev7 sev_filter"><a href="#" onclick="filter('sev7');return false;">DEBUG</a></span>&nbsp;
<span class="sev6 sev_filter"><a href="#" onclick="filter('sev6');return false;">INFO</a></span>&nbsp;
<span class="sev5 sev_filter"><a href="#" onclick="filter('sev5');return false;">NOTICE</a></span>&nbsp;
<span class="sev4 sev_filter"><a href="#" onclick="filter('sev4');return false;">WARNING</a></span>&nbsp;
<span class="sev3 sev_filter"><a href="#" onclick="filter('sev3');return false;">ERROR</a></span>&nbsp;
<span class="sev2 sev_filter"><a href="#" onclick="filter('sev2');return false;">CRIT</a></span>&nbsp;
<span class="sev1 sev_filter"><a href="#" onclick="filter('sev1');return false;">ALERT</a></span>&nbsp;
<span class="sev0 sev_filter"><a href="#" onclick="filter('sev0');return false;">EMERG</a></span>&nbsp;
<span class="sev_filter" id='sev_filter_last'><a href="#" onclick="showAll();return false;">ALL</a></span>&nbsp;
<div class='XLButtons'>
<input class='ui-state-default ui-corner-all' type='submit' id='btnExport' value='Export to'>
<select name="rpt_type">
<option selected value="xls">XLS</option>
<option value="xml">XLSX</option>
<option value="csv">CSV</option>
<option value="pdf">PDF</option>
</select>
<input type="hidden" name="table" value="<?php echo $_SESSION['TBL_MAIN']?>">
</div>

<table style="float: center; margin-top: 1%; width: 98%;" id="theTable" cellpadding="0" cellspacing="0" class="no-arrow paginate-<?php echo $_SESSION['PAGINATE']?> max-pages-7 paginationcallback-callbackTest-calculateTotalRating paginationcallback-callbackTest-displayTextInfo sortcompletecallback-callbackTest-calculateTotalRating s_table">
<thead class="ui-widget-header">
  <tr class='HeaderRow'>
    <th class="s_th">Edit</th>
    <th class="s_th"><input type="checkbox" onclick="toggleCheck(this.checked);"/></th>
    <th class="s_th sortable-sortIPAddress">Host</th>
    <th class="s_th sortable-text">Facility</th>
    <th class="s_th sortable-text">Severity</th>
    <th class="s_th sortable-text">Program</th>
    <th class="s_th sortable-text">Mnemonic</th>
    <th class="s_th sortable-text">Message</th>
    <?php if ($_SESSION['DEDUP'] == 1) { 
        echo '<th class="s_th sortable-sortEnglishDateTime">FO</th>'; 
        echo '<th class="s_th sortable-sortEnglishDateTime">LO</th>';
        echo '<th class="s_th sortable-numeric">Count</th>';
    } else {
        echo '<th class="s_th sortable-sortEnglishDateTime">Received</th>';
    }
    ?>
    <th class="s_th sortable-text">Notes</th>
  </tr>
</thead>

  <tbody>
  <?php
  // $total = get_total_rows($_SESSION['TBL_MAIN'], $dbLink);

  $sql = "SELECT value from cache where name='msg_sum'";
  $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']); 
  $row = fetch_array($result);        
  $total = $row['value'];

  $sql = "SELECT * FROM ".$_SESSION['TBL_MAIN'] ." $where LIMIT $limit";
  $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']); 
  $count = mysql_num_rows($result);
  if ($count > 0) {
      $info = "<center>Showing $count of ".commify($total)." entries</center>";
      ?>
          <script type="text/javascript">
          $("#portlet-header_Search_Results").html('<?php echo "$info"?>');
      </script>
          <?php
  } else {
      $info = "<font color=\"red\">No results match your search criteria</font>";
      ?>
          <script type="text/javascript">
          $("#theTable").html('<?php echo "$info"?>');
      </script>
          <?php
  }
  ?>
<?php
  while($row = fetch_array($result)) { 
      $msg = htmlentities($row['msg']);
        switch ($row['severity']) {
            case '7':
                $sev = 'sev7';
                $sev_text = "DEBUG";
                break;
            case '6':
                $sev = 'sev6';
                $sev_text = "INFO";
                break;
            case '5':
                $sev = 'sev5';
                $sev_text = "NOTICE";
                break;
            case '4':
                $sev = 'sev4';
                $sev_text = "WARNING";
                break;
            case '3':
                $sev = 'sev3';
                $sev_text = "ERROR";
                break;
            case '2':
                $sev = 'sev2';
                $sev_text = "CRIT";
                break;
            case '1':
                $sev = 'sev1';
                $sev_text = "ALERT";
                break;
            case '0':
                $sev = 'sev0';
                $sev_text = "EMERG";
                break;
            default:
        }
        echo "<tr id=\"$sev\">\n";
        // Icon downloaded from http://icons.mysitemyway.com
        echo "<td class=\"s_td\">\n";
        echo "<a href=\"#\" onclick=\"edit_note(this);return false;\" id=\"edit_$row[id]\"><img style=\"border-style: none; width: 30px; height: 30px;\" src=\"$_SESSION[SITE_URL]images/edit_sm.png\" /></a>\n";
        echo "</td>\n";
        echo "<td class=\"s_td\"><input class=\"checkbox\" type='checkbox' name='dbid[]' value='$row[id]'></td>";
        //$qstring = preg_replace ('/&hosts=(.*)&/', "$1", $qstring);
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&hosts=$row[host]>$row[host]</a></td>\n";
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&facilities[]=$row[facility]>".int2fac($row['facility'])."</a></td>\n";
        echo "<td class=\"s_td $sev\"><a href=$_SESSION[SITE_URL]$qstring&severities[]=$row[severity]>$sev_text</a></td>\n";
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&programs[]=$row[program]>".crc2prg($row['program'])."</a></td>\n";
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&mnemonics[]=$row[mne]>".crc2mne($row['mne'])."</a></td>\n";
        if ($_SESSION['CISCO_MNE_PARSE'] == "1" ) {
            // $msg = preg_replace('/\s:/', ':', $msg);
            $msg = preg_replace('/.*%(\w+-.*\d-\w+)\s?:/', '$1', $msg);
        }
        if($_SESSION['MSG_EXPLODE'] == "1") {
            $explode_url = "";
            $pieces = explode(" ", $msg);
            foreach($pieces as $value) {
                $explode_url .= " <a href=\"$_SESSION[SITE_URL]$qstring&msg_mask=".urlencode($value)."\"> ".$value." </a> ";
            }
        }
        // Link to LZECS if info is available
            if($_SESSION['MSG_EXPLODE'] == "1") {
                 // echo "<td class=\"s_td wide\"><a onclick=\"lzecs(this); return false\" id='$msg' href=\"javascript:void(0);\">[LZECS]&nbsp;&nbsp;</a>$explode_url</td>\n";
                 echo "<td class=\"s_td wide\">$explode_url</td>\n";
            } else {
                //  echo "<td class=\"s_td wide\"><a onclick=\"lzecs(this); return false\" id='$msg' href=\"javascript:void(0);\">[LZECS]&nbsp;&nbsp;</a>$msg</td>\n";
                 echo "<td class=\"s_td wide\">$msg</td>\n";
            }
            if ($_SESSION['DEDUP'] == 1) { 
                echo "<td class=\"s_td\">$row[fo]</td>\n";
                echo "<td class=\"s_td\">$row[lo]</td>\n";
                echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&dupop=eq&dupcount=$row[counter]>$row[counter]</a></td>\n";
            } else {
                echo "<td class=\"s_td\">$row[lo]</td>\n";
            }
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&notes_mask=$row[notes]>$row[notes]</a></td>\n";
        echo "</tr>\n";
    }
  ?>
  </tbody>
  </table>
</div> <!-- end div for "refresh_content"-->

<?php 
$postvars = $qstring;
$qstring = myURL().$qstring;
if ($_SESSION['DEBUG'] > 0 ) {
echo "<u><b>The SQL query:</u></b><br>\n";
$sql = str_replace("AND", "<br>AND", $sql);
$sql = str_replace("OR", "<br>OR", $sql);
echo "$sql\n"; 
echo "<br><br><u><b>Post Variables:</u></b><br>\n";
$str = str_replace("&", "<br>&", $postvars);
echo "$str<br>\n";
$end_time = microtime(true);
echo "Page generated in " . round(($end_time - $start_time),5) . " seconds\n";
}
?>
  <input type="hidden" name="tail" id="tail" value="<?php echo $tail?>">
  <input type="hidden" name="q_hist" id="q_hist" value="<?php echo $qstring?>">
  <input type="hidden" name="postvars" id="postvars" value="<?php echo $postvars?>">

  </form>


<!-- From here down is the modal dialog for editing the record notes
Adapted from http://stackoverflow.com/questions/394491/passing-data-to-a-jquery-ui-dialog
-->
<script type= "text/javascript">/*<![CDATA[*/
function edit_note(link){
    var dbid = link.id.replace('edit_', '');
    $("#edit_dialog").dialog({
                        bgiframe: true,
                        resizable: true,
                        height: 'auto',
                        width: '50%',
                        autoOpen:false,
                        modal: true,
                        open: function() {
                           $.get("includes/ajax/json.db_update.php?action=get&dbid="+dbid, function(data){
                         $("#note").val(data);
                           });
                         },
                        overlay: {
                                backgroundColor: '#000',
                                opacity: 0.5
                        },
                        buttons: {
                                'Save to Database': function() {
                                        $(this).dialog('close');
                                        var text = $('#note').val();
                                        var sup_date = $('#inp_suppress_date').val();
                                        var sup_time = $('#inp_suppress_time').val();
                                        var sup_field = $('#sel_suppress_field').val();
                                        $.get("includes/ajax/json.db_update.php?action=save&dbid="+dbid+"&note="+text+"&sup_date="+sup_date+"&sup_time="+sup_time+"&sup_field="+sup_field, function(data){
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
// Modal for LZECS reports
function lzecs(msg){
    var msg = msg.id;
    var values = '';
    $("#lzecs_dialog").dialog({
                        bgiframe: true,
                        resizable: true,
                        height: 'auto',
                        width: '80%',
                        position: [100,100],
                        autoOpen:false,
                        modal: true,
                        open: function() {
                        $.ajax({
                        url: 'includes/ajax/json.lzecs.php?action=get&msg='+msg, 
                        dataType: 'json',
                        success: function(data) {
                        var name = data.name
                         $.each(data, function(index, value) { 
                                // alert(index + ': ' + value); 
                             values += value;
                                });
                        if (name !== 'LZECS_ERR_MISSING') {
                            var table = '<table id="tbl_lzecs" cellpadding="0" cellspacing="0" border="0" width="100%"><thead class="ui-widget-header"> <tr> <th style="text-align: left; width="20%">Field</th> <th style="text-align: left; width="33%">Value</th> </tr> </thead> <tbody> <tr>';
                            var endtable = '</tr></table>';
                         $("#lzecs_info").html(table + values + endtable + '<form method="post" id="lzecs_submit" name="results" action="http://lzecs.logzilla.info?action=auditmsg&systemid=<?php echo $_SESSION['LZECS_SYSID']?>&msg='+ msg +'"><br><br><br><input style="float: right; height: 30px; width: 80px;" class="ui-state-default ui-corner-all" type="submit" id="btnLZECS_audit" value="Audit"></form>');
                         } else {
                         $("#lzecs_info").html('<form method="post" id="lzecs_submit" name="results" action="http://lzecs.logzilla.info?action=newmsg&systemid=<?php echo $_SESSION['LZECS_SYSID']?>&msg='+ msg +'">The LZECS does not know about this message.<br>Would you like to submit this as a new event to the the LogZilla Error Classification System online?<br><br><br><input style="float: right; height: 30px; width: 80px;" class="ui-state-default ui-corner-all" type="submit" id="btnLZECS" value="Confirm"></form>');
                         }
                        }
                           });
                         },
                        overlay: {
                                backgroundColor: '#000',
                                opacity: 0.5
                        },
                        buttons: {
                                Cancel: function() {
                                        $(this).dialog('close');
                                }
                        }
                });
                $("#lzecs_dialog").dialog('open');     
                //return false;
     }
    /*]]>*/
</script>
<div class="dialog_hide">
    <div id="search_history_dialog" title='Save Search Results:<br>Results will be saved to the "History" menu.'>
        <form>
        <fieldset>
            <label for="urlname">Enter a short name for this search:</label>
            <input type="text" name="urlname" id="urlname" class="text ui-widget-content ui-corner-all" />
            <br>
            <label for="url">Here is the full URL  that was captured:</label>
            <input type="text" name="url" id="url" class="text ui-widget-content ui-corner-all" />
        </fieldset>
        <hr>
        <b>You may either click "Save to History" now, or modify individual parameters below before saving.</b>
        <hr>

            <table id="tbl_usave" cellpadding="0" cellspacing="0" border="0" width="100%">
            <thead class="ui-widget-header">
                <tr>
                    <th style="text-align: left;" width="25%">Field</th>
                    <th style="text-align: left;" width="75%">Value</th>
                </tr>
            </thead>
            <tbody>

                <tr>
                    <td>Show</td>
                    <td>
                    <select style="width: 40%" name="show_suppressed" id="show_suppressed">
                    <option <?php if ($show_suppressed == 'suppressed') echo "selected"; ?> value='suppressed'>Suppressed Events</option>
                    <option <?php if ($show_suppressed == 'all') echo "selected"; ?> value='all'>All Events</option>
                    <option <?php if ($show_suppressed == 'unsuppressed') echo "selected"; ?> value='unsuppressed'>Unsuppressed Events</option>
                    </select>
                    </td>
                </tr>

                <tr>
                <td>
                Auto Refresh
                </td>
                <td>
                    <select style="width: 40%" id="sel_usave_tail">
                    <option <?php if ($tail == 'off') echo "selected"; ?> value="off">off</option>
                    <option <?php if ($tail == '1000') echo "selected"; ?> value="1000">1 Second
                    <option <?php if ($tail == '5000') echo "selected"; ?> value="5000">5 Seconds
                    <option <?php if ($tail == '15000') echo "selected"; ?> value="15000">15 Seconds
                    <option <?php if ($tail == '30000') echo "selected"; ?> value="30000">30 Seconds
                    <option <?php if ($tail == '60000') echo "selected"; ?> value="60000">1 Minute
                    <option <?php if ($tail == '300000') echo "selected"; ?> value="300000">5 Minutes
                    </select>
                </td>
                </tr>

                <tr>
                <td>
                Hosts
                </td>
                <td>
                    <input style="width: 39%" type="text" id="usave_hosts" value="<?php echo $hosts?>" />
                </td>
                </tr>

                <tr>
                    <td>Limit</td>
                <td>
                    <select style="width: 40%" id="sel_usave_limit">
                    <option <?php if ($limit == '10') echo "selected"; ?>>10
                    <option <?php if ($limit == '25') echo "selected"; ?>>25
                    <option <?php if ($limit == '50') echo "selected"; ?>>50
                    <option <?php if ($limit == '100') echo "selected"; ?>>100
                    <option <?php if ($limit == '150') echo "selected"; ?>>150
                    <option <?php if ($limit == '250') echo "selected"; ?>>250
                    <option <?php if ($limit == '500') echo "selected"; ?>>500
                    </select>
                </td>
                </tr>

                <?php  if ( $_SESSION["DEDUP"] == "1" ) { ?>
                <tr>
                    <td>Duplicates</td>
                    <td>
                    <select style="width: 10%" name="dupop" id="dupop">
                    <option <?php if ($dupop_orig == '') echo "selected"; ?> value=""></option>
                    <option <?php if ($dupop_orig == 'gt') echo "selected"; ?> value="gt">></option>
                    <option <?php if ($dupop_orig == 'lt') echo "selected"; ?> value="lt"><</option>
                    <option <?php if ($dupop_orig == 'eq') echo "selected"; ?> value="eq">=</option>
                    <option <?php if ($dupop_orig == 'gte') echo "selected"; ?> value="gte">>=</option>
                    <option <?php if ($dupop_orig == 'lte') echo "selected"; ?> value="lte"><=</option>
                    </select>
                    <input type=text id="dupcount" value="<?php echo $dupcount ?>" size="3">
                    </td>
                </tr>
                <?php  } ?>

                <tr>
                    <td>Sort Order</td>
                    <td>
                    <select style="width: 40%" name="orderby" id="orderby">
                    <option <?php if ($orderby == 'id') echo "selected"; ?> value="id">Database ID</option>
                    <?php  if ( $_SESSION["DEDUP"] == "1" ) { ?>
                    <option <?php if ($orderby == 'counter') echo "selected"; ?> value="counter">Count</option>
                    <?php  } ?>
                    <option <?php if ($orderby == 'host') echo "selected"; ?> value="host">Host</option>
                    <option <?php if ($orderby == 'program') echo "selected"; ?> value="program">Program</option>
                    <option <?php if ($orderby == 'mnemonic') echo "selected"; ?> value="mnemonic">Mnemonic</option>
                    <option <?php if ($orderby == 'facility') echo "selected"; ?> value="facility">Facility</option>
                    <option <?php if ($orderby == 'severity') echo "selected"; ?> value="severity">Severity</option>
                    <option <?php if ($orderby == 'msg') echo "selected"; ?> value="msg">Message</option>
                    <option <?php if ($orderby == 'fo') echo "selected"; ?> value="fo">First Occurrence</option>
                    <option <?php if ($orderby == 'lo') echo "selected"; ?> value="lo">Last Occurrence</option>
                    </select>
                    </td>
                </tr>

                <tr>
                    <td>Search Order</td>
                    <td>
                    <select style="width: 40%" name="order" id="order">
                    <option <?php if ($order == 'ASC') echo "selected"; ?> value="ASC">Ascending</option>
                    <option <?php if ($order == 'DESC') echo "selected"; ?> value="DESC">Descending</option>
                    </select>
                    </td>
                </tr>

                <TR>
                    <TD WIDTH="10%">
                    <input type="checkbox" name="fo_checkbox" id="fo_checkbox" <?php if ($fo_checkbox == 'on') echo "checked"; ?>>
                    <b>FO</b>
                    </TD>
                    <TD WIDTH="90%" COLSPAN="2">
                        <div id="fo_date_wrapper">
                        <input type="text" size="25" value="<?php echo $fo_date?>" name="fo_date" id="fo_date">
                        </div>
                        <!--The fo_time_wrapper div is referenced in jquery.timePicker.js -->
                        <div id="fo_time_wrapper_usave"> 
                        <input type="text" id="fo_time_start_usave" size="10" value="<?php echo $fo_time_start?>" /> 
                        <input type="text" id="fo_time_end_usave" size="10" value="<?php echo $fo_time_end?>" />
                        </div>
                    </TD>
                </TR>
            <tr>
                <td width="5%">
                    <select name="date_andor" id="date_andor">
                    <option <?php if ($date_andor == 'AND') echo "selected"; ?> >AND
                    <option <?php if ($date_andor == 'OR') echo "selected"; ?> >OR
                    </select>
                </td>
                <td width="95%">
                </td>
            </tr>
            
                <TR>
                    <TD WIDTH="10%">
                    <input type="checkbox" name="lo_checkbox" id="lo_checkbox" <?php if ($lo_checkbox == 'on') echo "checked"; ?>>
                    <b>LO</b>
                    </TD>
                    <TD WIDTH="90%" COLSPAN="2">
                        <div id="lo_date_wrapper">
                        <input type="text" size="25" value="<?php echo $lo_date?>" name="lo_date" id="lo_date">
                    </div>
                        <!--The lo_time_wrapper div is referenced in jquery.timePicker.js -->
                        <div id="lo_time_wrapper_usave"> 
                        <input type="text" id="lo_time_start_usave" size="10" value="<?php echo $lo_time_start?>" /> 
                        <input type="text" id="lo_time_end_usave" size="10" value="<?php echo $lo_time_end?>" />
                        </div>
                    </TD>
                </TR>
            </tbody>
            </table>
        </form>
    </div>
</div>
<div class="dialog_hide">
    <div id="edit_dialog" title="Event Editor">
        <form>
        <fieldset>
            <label for="note">Edit Note</label>
        <br>
            <textarea cols="75" rows="5" name="note" id="note" class="text ui-corner-all"></textarea>
        </fieldset>
        <br>
            <label for="tbl_suppress">Suppress Event(s) Until:</label>
            <table id="tbl_suppress" cellpadding="0" cellspacing="0" border="0" width="100%">
            <thead class="ui-widget-header">
            <tr>
            <th width="33%">Date</th>
            <th width="33%">Time</th>
            <th width="33%">Match</th>
            </tr>
            </thead>
            <tbody>
            <tr>
            <td>
            <input style="width: 98%" type="text" size="25" value='<?php echo date("Y-m-d")?>' id="inp_suppress_date">
            </td>
            <td>
            <input style="width: 98%" type="text" id="inp_suppress_time" size="10" value='<?php echo date("G:H:s")?>' /> 
            </td>
            <td>
            <select style="width: 98%" id="sel_suppress_field">
            <option selected value=""></option>
            <option value="this single event">This Event Only</option>
            <option value="host">All Matching Hosts</option>
            <option value="facility">All Matching Facilities</option>
            <option value="severity">All Matching Severities</option>
            <option value="program">All Matching Programs</option>
            <option value="mne">All Matching Mnemonics</option>
            <option value="notes">All Matching Notes</option>
            </select>
            </td>
            </tr>
            </tbody>
            </table>
        <br>
            <label for="tbl_current">Current Globally Suppressed Events:</label>
            <table id="tbl_current" cellpadding="0" cellspacing="0" border="0" width="100%">
            <thead class="ui-widget-header">
            <tr>
            <th style='text-align: left;' width="33%">Match Type</th>
            <th style='text-align: left;' width="33%">Name</th>
            <th style='text-align: left;' width="33%">Expires</th>
            </tr>
            </thead>
            <tbody>
            <?php
            $sql = "SELECT * FROM suppress WHERE expire>NOW()";
            $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']); 
            if (mysql_num_rows($result) > 0) {
                while($row = fetch_array($result)) { 
                    $name = $row['name'];
                    $col = $row['col'];
                    $expire = $row['expire'];
                    switch ($col) {
                        case 'mne':
                            $name = crc2mne($name);
                            $col = "Mnemonic";
                            break;
                        case 'facility':
                            $name = int2fac($name);
                            $col = "Facility";
                            break;
                        case 'severity':
                            $name = int2sev($name);
                            $col = "Severity";
                            break;
                        case 'program':
                            $name = crc2prg($name);
                            $col = "Program";
                            break;
                    }
                    echo "<tr>\n";
                    echo "<td>$col</td>\n";
                    echo "<td>$name</td>\n";
                    echo "<td>$expire</td>\n";
                    echo "</tr>\n";
                }
            } else {
                    echo "<tr>\n";
                echo "<td>None</td>\n";
                    echo "</tr>\n";
            }
            ?>
            </tbody>
            </table>
<script type= "text/javascript">
 $("#inp_suppress_date").datepicker({ dateFormat: 'yy-mm-dd' });
</script>
        </form>
    </div>
</div>
<div class="dialog_hide">
    <div id="lzecs_dialog" title="LogZilla Event Classification System">
            <span id="lzecs_info" class="text ui-corner-all"></span>
    </div>
</div>
<script type= "text/javascript">
//------------------------------------
// BEGIN Tail
//------------------------------------
// Tail catcher
var delay = 'off';
delay = jQuery("#tail").val();
var url = jQuery("#postvars").val();
if (delay !== "off") {
        refresh(url, delay); 
}   


var tail_timerID ;
function refresh(source, delay)
{
    if (tail_timerID)
    {
        clearTimeout(tail_timerID);
    }

    // alert(source+","+ delay);
    tail_timerID = setTimeout("refresh('"+ source +"',"+ delay+")",delay);

    var getdata = jQuery.get("includes/ajax/table-refresh.php?"+source, function(data){
            jQuery("#refresh_content").replaceWith(data);
            });
    
}
//------------------------------------
// END Tail
//------------------------------------
</script>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Search_Results').remove()
</script>
<?php } ?>
