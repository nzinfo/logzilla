<?php
/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-05-02
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

$today = date("Y-m-d");
//construct where clause 
$where = "WHERE 1=1";

$qstring = '';
// $page = get_input('page');
$qstring .= "?page=Results";

$show_suppressed = get_input('show_suppressed');
$qstring .= "&show_suppressed=$show_suppressed";
    switch ($show_suppressed) {
        case "suppressed":
        $where.= " AND suppress > NOW()";  
        $where .= " OR host IN (SELECT name from suppress where col='host' AND expire>NOW())";
        $where .= " OR facility IN (SELECT name from suppress where col='facility' AND expire>NOW())";
        $where .= " OR severity IN (SELECT name from suppress where col='severity' AND expire>NOW())";
        $where .= " OR program IN (SELECT name from suppress where col='program' AND expire>NOW())";
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

// portlet-sphinxquery
$msg_mask = get_input('msg_mask');
$msg_mask = html_entity_decode($msg_mask);
$msg_mask = preg_replace ('/^Search through .*\sMessages/m', '', $msg_mask);
$msg_mask_oper = get_input('msg_mask_oper');
$qstring .= "&msg_mask=$msg_mask&msg_mask_oper=$msg_mask_oper";

if($msg_mask) {
    if ($_SESSION['SPX_ENABLE'] == "1") {
        //---------------BEGIN SPHINX
        require_once ($basePath . "/../SPHINX.class.php");
        // Get the search variable from URL
        // $var = @$_GET['msg_mask'] ;
        // $trimmed = trim($$msg_mask); //trim whitespace from the stored variable

        // $q = $trimmed;
#$q = "SELECT id ,group_id,title FROM documents where title = 'test one'";
#$q = " SELECT id, group_id, UNIX_TIMESTAMP(date_added) AS date_added, title, content FROM documents";
        $index = "idx_logs";

        $cl = new SphinxClient ();
        $hostip = $_SESSION['SPX_SRV'];
        $port = intval($_SESSION['SPX_PORT']);
        $cl->SetServer ( $hostip, $port );
        $cl->SetMatchMode ( SPH_MATCH_EXTENDED2 );
        $res = $cl->Query ( htmlentities($msg_mask), $index);
        if ( !$res )
        {
            die ( "ERROR: " . $cl->GetLastError() . ".\n" );
        } else
        {
            if ($res['total_found'] > 0) {
                $where .= " AND id IN (";
                foreach ( $res["matches"] as $doc => $docinfo ) {
                    $where .= "'$doc',";
                    // echo "$doc<br>\n";
                }
                $where = rtrim($where, ",");
                $where .= ")";
            } else {
                // Negate search since sphinx returned 0 hits
                $where = "WHERE 1<1";
                //  die(print_r($res));
            }
        }
        //---------------END SPHINX
    } else {
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
$limit = get_input('limit');
$limit = (!empty($limit)) ? $limit : "10";
    $qstring .= "&limit=$limit";
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

$orderby = get_input('orderby');
    $qstring .= "&orderby=$orderby";
$order = get_input('order');
    $qstring .= "&order=$order";
    if ($orderby) {
        if ($orderby == 'lo') {
            $orderby = 'id';
        }
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
    <th class="s_th">Mnemonic</th>
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
  $sql = "SELECT * FROM ".$_SESSION['TBL_MAIN'] ." $where LIMIT $limit";
  $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']); 
  $count = mysql_num_rows($result);
  if ($count < 1) {
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
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&hosts=$row[host]>$row[host]</a></td>\n";
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&facilities[]=$row[facility]>".int2fac($row['facility'])."</a></td>\n";
        echo "<td class=\"s_td $sev\"><a href=$_SESSION[SITE_URL]$qstring&severities[]=$row[severity]>$sev_text</a></td>\n";
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&programs[]=$row[program]>".crc2prg($row['program'])."</a></td>\n";
        echo "<td class=\"s_td\"><a href=$_SESSION[SITE_URL]$qstring&mnemonics[]=$row[mne]>".crc2mne($row['mne'])."</a></td>\n";
        if ($_SESSION['CISCO_MNE_PARSE'] == "1" ) {
            $msg = preg_replace('/\s:/', ':', $msg);
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
