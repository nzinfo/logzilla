<?php
/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 gdd.net
 * All rights reserved.
 *
 * Changelog:
 * 2010-02-28 - created
 *
 */

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
if ((has_portlet_access($_SESSION['username'], 'Search Results') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) {
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

//---------------------------------------------------
// The get_input statements below are used to get
// POST, GET, COOKIE or SESSION variables.
// Note that PLURAL words below are arrays.
//---------------------------------------------------

//construct where clause 
$where = "WHERE 1=1";

$show_suppressed = get_input('show_suppressed');
$qstring .= "?show_suppressed=$show_suppressed";
    switch ($show_suppressed) {
        case "suppressed":
        $where.= " AND suppress>NOW()";  
        $where .= " OR host IN (SELECT name from suppress where col='host' AND expire>NOW())";
        $where .= " OR facility IN (SELECT name from suppress where col='facility' AND expire>NOW())";
        $where .= " OR priority IN (SELECT name from suppress where col='priority' AND expire>NOW())";
        $where .= " OR program IN (SELECT name from suppress where col='program' AND expire>NOW())";
        $where .= " OR msg IN (SELECT name from suppress where col='msg' AND expire>NOW())";
        $where .= " OR counter IN (SELECT name from suppress where col='counter' AND expire>NOW())";
        $where .= " OR notes IN (SELECT name from suppress where col='notes' AND expire>NOW())";
            break;
        case "unsuppressed":
        $where.= " AND suppress<NOW()";  
        $where .= " AND host NOT IN (SELECT name from suppress where col='host' AND expire>NOW())";
        $where .= " AND facility NOT IN (SELECT name from suppress where col='facility' AND expire>NOW())";
        $where .= " AND priority NOT IN (SELECT name from suppress where col='priority' AND expire>NOW())";
        $where .= " AND program NOT IN (SELECT name from suppress where col='program' AND expire>NOW())";
        $where .= " AND msg NOT IN (SELECT name from suppress where col='msg' AND expire>NOW())";
        $where .= " AND counter NOT IN (SELECT name from suppress where col='counter' AND expire>NOW())";
        $where .= " AND notes NOT IN (SELECT name from suppress where col='notes' AND expire>NOW())";
        break;
}


$hosts = get_input('hosts');
// see if we are tailing
$tail = get_input('tail');

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
    foreach ($programs as $mask) {
        $where.= "'$mask',";  
    }
    $where = rtrim($where, ",");
    $where .= ")";
}

// portlet-priorities
$priorities = get_input('priorities');
if ($priorities) {
    $where .= " AND priority IN (";
    foreach ($priorities as $mask) {
        $where.= "'$mask',";  
    }
    $where = rtrim($where, ",");
    $where .= ")";
}

// portlet-facilities
$facilities = get_input('facilities');
if ($facilities) {
    $where .= " AND facility IN (";
    foreach ($facilities as $mask) {
        $where.= "'$mask',";  
    }
    $where = rtrim($where, ",");
    $where .= ")";
}

// portlet-sphinxquery
$msg_mask = get_input('msg_mask');
if($msg_mask) {
    if (!preg_match ('/^Search through .*\sMessages/m', $msg_mask)) {
        $op = get_input('msg_mask_oper');
        switch ($op) {
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
if($notes_mask) {
    $notes_mask = get_input('notes_mask');
    if (!preg_match ('/^Search through .*\sNotes/m', $notes_mask)) {
        $op = get_input('notes_mask_oper');
        $notes_andor = get_input('notes_andor');
        switch ($op) {
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
        }
    }
}

$fo_checkbox = get_input('fo_checkbox');
$fo_date = get_input('fo_date');
$fo_time_start = get_input('fo_time_start');
$fo_time_end = get_input('fo_time_end');
$date_andor = get_input('date_andor');
$lo_checkbox = get_input('lo_checkbox');
$lo_date = get_input('lo_date');
$lo_time_start = get_input('lo_time_start');
$lo_time_end = get_input('lo_time_end');
//------------------------------------------------------------
// START date/time
//------------------------------------------------------------
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
            $where.= " ".strtoupper($date_andor)." lo BETWEEN '$start' AND '$end'";
    }
}
//------------------------------------------------------------
// END date/time
//------------------------------------------------------------

// portlet-search_options
$limit = get_input('limit');
$limit = (!empty($limit)) ? $limit : "10";
$dupop = get_input('dupop');
$dupcount = get_input('dupcount');
if ($dupop) {
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
$orderby = get_input('orderby');
$order = get_input('order');
if ($orderby) {
    $where.= " ORDER BY $orderby";  
}
if ($order) {
    $where.= " $order";  
}

?>

<script type="text/javascript">
// Remove the header and export button since we're auto-refreshing
$('.portlet-header').remove();
$('.XLButtons').remove();
</script>

<div id="refresh_content">
<table style="float: center; margin-top: 1%;" id="theTable" cellpadding="0" cellspacing="0" class="no-arrow paginate-<?php echo $_SESSION['PAGINATE']?> max-pages-7 paginationcallback-callbackTest-calculateTotalRating paginationcallback-callbackTest-displayTextInfo sortcompletecallback-callbackTest-calculateTotalRating s_table">
<thead class="ui-widget-header">
  <tr class='HeaderRow'>
    <th class="s_th">Host</th>
    <th class="s_th">Facility</th>
    <th class="s_th">Priority</th>
    <th class="s_th">Program</th>
    <th class="s_th">Message</th>
    <?php if ($_SESSION['DEDUP'] == 1) { 
        echo '<th class="s_th sortable-sortEnglishDateTime">FO</th>'; 
        echo '<th class="s_th sortable-sortEnglishDateTime">LO</th>';
        echo '<th class="s_th">Count</th>';
    } else {
        echo '<th class="s_th sortable-sortEnglishDateTime">Received</th>';
    }
    ?>
  </tr>
</thead>

  <tbody>
  <?php
  $total = get_total_rows($_SESSION['TBL_MAIN'], $dbLink, "$where");
  $sql = "SELECT * FROM ".$_SESSION['TBL_MAIN'] ." $where LIMIT $limit";
  $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']); 
  $count = mysql_num_rows($result);
  if ($total > 0) {
      $info = "<center>Showing $count of $total Possible Results</center>";
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
        switch ($row['priority']) {
            case 'debug':
                $sev = 'sev7';
                break;
            case 'info':
                $sev = 'sev6';
                break;
            case 'notice':
                $sev = 'sev5';
                break;
            case 'warning':
                $sev = 'sev4';
                break;
            case 'err':
                $sev = 'sev3';
                break;
            case 'crit':
                $sev = 'sev2';
                break;
            case 'alert':
                $sev = 'sev1';
                break;
            case 'emerg':
                $sev = 'sev0';
                break;
        }
        echo "<tr id=\"$sev\">\n";
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&hosts=$row[host]>$row[host]</a></td>\n";
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&facilities[]=$row[facility]>$row[facility]</a></td>\n";
        echo "<td class=\"s_td $sev\"><a href=$_SESSION[SITE_URL]$qstring&priorities[]=$row[priority]>$row[priority]</a></td>\n";
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&programs[]=$row[program]>$row[program]</a></td>\n";
        if ($_SESSION['CISCO_MNE_PARSE'] == "1" ) {
            $msg = preg_replace('/\s:/', ':', $msg);
            $msg = preg_replace('/.*(%.*?:.*)/', '$1', $msg);
        }
        if($_SESSION['MSG_EXPLODE'] == "1") {
            $explode_url = "";
            $pieces = explode(" ", $msg);
            foreach($pieces as $value) {
                $explode_url .= " <a href=\"$_SESSION[SITE_URL]$qstring&msg_mask=".urlencode($value)."\"> ".htmlentities($value)." </a> ";
            }
        }
        // Link to LZECS if info is available
            if($_SESSION['MSG_EXPLODE'] == "1") {
                // echo "<td class=\"s_td wide\"><a onclick=\"lzecs(this); return false\" id='$msg' href=\"javascript:void(0);\">[LZECS]&nbsp;&nbsp;</a>$explode_url</td>\n";
                echo "<td class=\"s_td wide\">$explode_url</td>\n";
            } else {
                // echo "<td class=\"s_td wide\"><a onclick=\"lzecs(this); return false\" id='$msg' href=\"javascript:void(0);\">[LZECS]&nbsp;&nbsp;</a>$msg</td>\n";
                echo "<td class=\"s_td wide\">$msg</td>\n";
            }
            if ($_SESSION['DEDUP'] == 1) { 
                echo "<td class=\"s_td\">$row[fo]</td>\n";
                echo "<td class=\"s_td\">$row[lo]</td>\n";
                echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&dupop=eq&dupcount=$row[counter]>$row[counter]</a></td>\n";
            } else {
                echo "<td class=\"s_td\">$row[lo]</td>\n";
            }
        echo "</tr>\n";
    }
  ?>
  </tbody>
  </table>
  </div>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Search_Results').remove()
</script>
<?php } ?>
