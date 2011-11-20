<?php
/*
 * portlet-table.php
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-06-15
 *
 * Pagination and table formatting created using 
 * http://www.frequency-decoder.com/2007/10/19/client-side-table-pagination-script/
 * Changelog:
 * 2010-02-28 - created
 *
 */

// session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
if ((has_portlet_access($_SESSION['username'], 'Graph Results') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 
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
$total = 'unknown';
$qstring = '';
$page = get_input('page');
$qstring .= "&page=$page";
$show_suppressed = get_input('show_suppressed');
$qstring .= "&show_suppressed=$show_suppressed";
$spx_max = get_input('spx_max');
$spx_max = (!empty($spx_max)) ? $spx_max : $_SESSION['SPX_MAX_MATCHES'];
$qstring .= "&spx_max=$spx_max";
$spx_ip = get_input('spx_ip');
$spx_ip = (!empty($spx_ip)) ? $spx_ip : $_SESSION['SPX_SRV'];
$qstring .= "&spx_ip=$spx_ip";
$spx_port = get_input('spx_port');
$spx_port = (!empty($spx_port)) ? $spx_port : $_SESSION['SPX_PORT'];
$qstring .= "&spx_port=$spx_port";
$qstring .= "&spx_max=$spx_max";
$spx_port = intval($spx_port);
$spx_max = intval($spx_max);
$groupby = get_input('groupby');
$qstring .= "&groupby=$groupby";
$chart_type = get_input('chart_type');
$qstring .= "&chart_type=$chart_type";

//------------------------------------------------------------
// START date/time
//------------------------------------------------------------
// portlet-datepicker 
$fo_checkbox = get_input('fo_checkbox');
    $qstring .= "&fo_checkbox=$fo_checkbox";
$fo_date = get_input('fo_date');
    $qstring .= "&fo_date=".urlencode($fo_date);
$fo_time_start = get_input('fo_time_start');
    $qstring .= "&fo_time_start=$fo_time_start";
$fo_time_end = get_input('fo_time_end');
    $qstring .= "&fo_time_end=$fo_time_end";
$lo_checkbox = get_input('lo_checkbox');
    $qstring .= "&lo_checkbox=$lo_checkbox";
$lo = get_input('lo');
    $qstring .= "&lo=$lo";
if (!$lo) {
    $lo_date = get_input('lo_date');
    $qstring .= "&lo_date=".urlencode($lo_date);
    $lo_time_start = get_input('lo_time_start');
    $qstring .= "&lo_time_start=$lo_time_start";
    $lo_time_end = get_input('lo_time_end');
    $qstring .= "&lo_time_end=$lo_time_end";
} else {
    $lo_checkbox = "on";
}
// FO
$filter_fo_start = "";
$filter_fo_end = "";

if ($fo_checkbox == "on") {
    if($fo_date!='') {
        list($start,$end) = explode(' to ', $fo_date);
	if($end=='') $end = "$start" ; 
        if(($start==$end) and ($fo_time_start>$fo_time_end)) {
	 	$endx = strtotime($end);
		$endx = $endx+24*3600;
         	$end = date('Y-m-d', mktime(0,0,0,date('m',$endx),date('d',$endx),date('Y',$endx))); }
	$start .= " $fo_time_start"; 
        $end .= " $fo_time_end"; 
        $where.= " AND fo BETWEEN '$start' AND '$end'";
	$filter_fo_start = "$start" ;
	$filter_fo_end = "$end" ;
    }
}
// LO
$filter_lo_start = "";
$filter_lo_end = "";
$start = "";
$end = "";
if (preg_match("/^\w+/", $lo)) {
    if ($lo == "thismonth") {
        $lo_date = date('Y-m-01');
    } else {
        $lo_date = date('Y-m-d', strtotime($lo));
    }
    if (($lo !== "yesterday") && ($lo !== "today")) {
        $lo_date .= " to ".date('Y-m-d', strtotime("today"));
    }
    $lo_time_start = "00:00:00";
    $lo_time_end = "23:59:59";
    $qstring .= "&lo_checkbox=on&lo_date=$lo_date";
    $qstring .= "&lo_time_start=$lo_time_start";
    $qstring .= "&lo_time_end=$lo_time_end";
}
if (($lo_checkbox == "on") or ($lo)){
    if($lo_date!='') {
        list($start,$end) = explode(' to ', $lo_date);
	if($end=='') $end = "$start" ; 
        if(($start==$end) and ($lo_time_start>$lo_time_end)) {
                $endx = strtotime($end);
                $endx = $endx+24*3600;
                $end = date('Y-m-d', mktime(0,0,0,date('m',$endx),date('d',$endx),date('Y',$endx))); }

	$start .= " $lo_time_start"; 
        $end .= " $lo_time_end"; 

	if ($date_andor=='') $date_andor = 'AND';
        $where.= " ".strtoupper($date_andor)." lo BETWEEN '$start' AND '$end'";
        $filter_lo_start = "$start" ;
	$filter_lo_end = "$end" ;
    }
}
//------------------------------------------------------------
// END date/time
//------------------------------------------------------------

$q_type = get_input('q_type');
$q_type = (!empty($qtype)) ? $qtype : "boolean";
    $qstring .= "&q_type=$q_type";

// see if we are tailing
$tail = get_input('tail');
$tail = (!empty($tail)) ? $tail : "off";
$qstring .= "&tail=$tail";
$limit = get_input('limit');
$limit = (!empty($limit)) ? $limit : "10";
$qstring .= "&limit=$limit";
if (($tail > 0) && ($limit > 25)) {
    ?>
    <script type="text/javascript">
        $(document).ready(function(){
                $( "<div id='tail_error'><center><br><br>The Maximum result set for the auto refresh page is 25.<br>Any more than that would simply scroll off the page before being seen.<br>Please check your 'limit' setting in the 'Search Options' portlet.</div></center>" ).dialog({
                    modal: true,
                    width: "50%", 
                    height: 240, 
                    buttons: {
                    Ok: function() {
                        $( this ).dialog( "close" );
                        }
                    }
                 });
        }); // end doc ready
    </script>
    <?php
    $limit = 25;
};

// portlet-programs
$programs = get_input('programs');
if ($programs) {
    foreach ($programs as $program) {
        if (!preg_match("/^\d+/m", $program)) {
            $arr[] .= prg2crc($program);
        }
        $qstring .= "&programs[]=".urlencode($program);
    }
    $programs = $arr;
}

$severities = get_input('severities');
if ($severities) {
    foreach ($severities as $sev) {
        if (!preg_match("/^\d/", $sev)) {
            $arr[] .= sev2int($sev);
        }
        $qstring .= "&severities[]=".urlencode($sev);
    }
    $severities = $arr;
}

$facilities = get_input('facilities');
if ($facilities) {
    foreach ($facilities as $fac) {
        if (!preg_match("/^\d/", $fac)) {
            $arr[] .= fac2int($fac);
        }
        $qstring .= "&facilities[]=".urlencode($fac);
    }
    $facilities = $arr;
}


$searchText = get_input('msg_mask');
$qstring .= "&msg_mask=$searchText";

$notes_mask = get_input('notes_mask');
$qstring .= "&notes_mask=$notes_mask";

$orderby = get_input('orderby');
$qstring .= "&orderby=$orderby";

$order = get_input('order');
$qstring .= "&order=$order";

$dupop = get_input('dupop');
$qstring .= "&dupop=$dupop";

$filter_dup_min = "0";
$filter_dup_max = "999";
$dupop_orig = $dupop;
$dupcount = get_input('dupcount');
$qstring .= "&dupcount=$dupcount";

if (($dupop) && ($dupop != 'undefined')) {
    switch ($dupop) {
        case "gt":
            $dupop = ">";
            $filter_dup_min = $dupcount + 1;
        break;

        case "lt":
            $dupop = "<";
            $filter_dup_max = $dupcount - 1;
        break;

        case "eq":
            $dupop = "=";
            $filter_dup_min = $dupcount;
            $filter_dup_max = $dupcount;
        break;

        case "gte":
            $dupop = ">=";
            $filter_dup_min = $dupcount;
        break;
            $filter_dup_min = $dupcount;
        case "lte":
            $dupop = "<=";
            
        break;
    }
    $where.= " AND counter $dupop '$dupcount'"; 
}
    
if ($_SESSION['SPX_ENABLE'] == "1") {
    $searchArr['chart_type'] = $chart_type;
    $searchArr['lo_checkbox'] = $lo_checkbox;
    $searchArr['lo_date'] = $lo_date;
    $searchArr['lo_time_start'] = $lo_time_start;
    $searchArr['lo_time_end'] = $lo_time_end;
    $searchArr['orderby'] = $orderby;
    $searchArr['order'] = $order;
    $searchArr['limit'] = $limit;
    $searchArr['groupby'] = $groupby;
    $searchArr['tail'] = $tail;
    $searchArr['show_suppressed'] = $show_suppressed;
    $searchArr['q_type'] = $q_type;
    $searchArr['page'] = $page;
    if ($programs) {$searchArr['programs'] = $programs;}
    $searchArr['severities'] = $severities;
    $searchArr['facilities'] = $facilities;
    $searchArr['dupop'] = $dupop_orig;
    $searchArr['dupcount'] = $dupcount;

    // Get the search operator - default is or (|) set in the search() function
    if (preg_match("/\||&|!/", "$searchText")) {
        $searchArr['search_op'] = preg_replace ('/.*(\||&|!).*/', '$1', $searchText);
        $op = $searchArr['search_op'];
    }

    $hosts = get_input('hosts');
    if (preg_match("/^@host/i", "$searchText")) {
        $searchText = preg_replace('/^@[Hh][Oo][Ss][Tt][Ss]?(.*)/', '$1', $searchText);
        if ($op) {
            $h = explode("$op", $searchText);
            foreach ($h as $host) {
                $host = preg_replace('/\s+/', '',$host);
                $hosts[] .= $host;
                $searchText = preg_replace("/$host/", '', $searchText);
            }
            $searchText = preg_replace("/\\$op/", '', $searchText);
        } else {
            $hosts[] .= $searchText;
            $searchText = preg_replace("/$searchText/", '', $searchText);
        }
    }

    if (preg_match("/^@notes/i", "$searchText")) {
        $searchText = preg_replace('/^@[Nn][Oo][Tt][Ee][Ss]?(.*)/', '$1', $searchText);
        if ($op) {
            $h = explode("$op", $searchText);
            foreach ($h as $note) {
                $note = preg_replace('/\s+/', '',$note);
                $notes_mask[] .= $note;
                $searchText = preg_replace("/$note/", '', $searchText);
            }
            $searchText = preg_replace("/\\$op/", '', $searchText);
        } else {
            $notes_mask[] .= $searchText;
            $searchText = preg_replace("/$searchText/", '', $searchText);
        }
    }



    // Set these after the matches on hosts and notes above so that the mask is cleaned up by them
    if ($searchText) { $searchArr['msg_mask'] = $searchText;}
    if ($notes_mask) { $searchArr['notes_mask'] = $notes_mask;}

    if ($hosts) {
        if (!is_array($hosts)) {
            $hosts = explode(",", $hosts);
        }
        $searchArr['hosts'] = $hosts;
    }

    $sel_hosts = get_input('sel_hosts');
    if ($sel_hosts) {
        foreach ($sel_hosts as $host) {
            $hosts[] .= $host;
            $qstring .= "&hosts[]=$host";
        }
        $searchArr['hosts'] = array_merge($sel_hosts, $hosts);
    }

    $eids = get_input('eids');
    if ($eids) {
        if (!is_array($eids)) {
            $eids = explode(",", $eids);
        }
        $searchArr['eids'] = $eids;
    }

    $sel_eids = get_input('sel_eid');
    if ($sel_eids) {
        foreach ($sel_eids as $eid) {
            $eids[] .= $eid;
            $qstring .= "&eids[]=$eid";
        }
        $searchArr['eids'] = array_merge($sel_eids, $eids);
    }


    $mnemonics = get_input('mnemonics');
    if ($mnemonics) {
        $mnemonics = explode(",", $mnemonics);
        $searchArr['mnemonics'] = $mnemonics;
    }
    $sel_mne = get_input('sel_mne');
    if ($sel_mne) {
        if ($mnemonics) {
            $searchArr['mnemonics'] = array_merge($sel_mne, $mnemonics);
        } else {
            $searchArr['mnemonics'] = $sel_mne;
        }
    }



    unset($searchArr['sel_hosts']);
    unset($searchArr['sel_eid']);
    unset($searchArr['sel_mne']);

    if ($_POST) {
        foreach ($_POST as $i => $value) {
            if (preg_match("/^jqg_/", "$i")) {
                $name_val = preg_replace('/jqg_(\w+grid)_(.*)/', '$1,$2', $i);
                $array = explode(',', $name_val);
                switch ($array[0]) {
                    case "mnegrid":
                        $searchArr['mnemonics'][] .= $array[1];
                    break;
                    case "eidgrid":
                        $searchArr['eids'][] .= $array[1];
                    break;
                    case "hostsgrid":
                        $array[1] = preg_replace('/_/', '.', $array[1]);
                    $searchArr['hosts'][] .= $array[1];
                    break;
                }
            }
        }
    }
    if(is_array($searchArr['mnemonics'])) {
        $searchArr['mnemonics'] = array_unique($searchArr['mnemonics']);
        foreach ($searchArr['mnemonics'] as $mne) {
            $qstring .= "&mnemonics[]=$mne";
        }
    }
    if(is_array($searchArr['hosts'])) {
        $searchArr['hosts'] = array_unique($searchArr['hosts']);
        foreach ($searchArr['hosts'] as $host) {
            $qstring .= "&hosts[]=$host";
        }
    }
    if(is_array($searchArr['eids'])) {
        $searchArr['eids'] = array_unique($searchArr['eids']);
        foreach ($searchArr['eids'] as $eid) {
            $qstring .= "&eids[]=$eid";
        }
    }
    if(is_array($searchArr['programs'])) {
        $searchArr['programs'] = array_unique($searchArr['programs']);
        foreach ($searchArr['programs'] as $program) {
            $qstring .= "&programs[]=$program";
        }
    }


    $json_o = search(json_encode($searchArr), $spx_max,$index="idx_logs idx_delta_logs",$spx_ip,$spx_port);


    // If something goes wrong, search() will return an error
    if (!preg_match("/^Sphinx Error:/", "$json_o")) {

    // Decode returned json object into an array:
    $sphinx_results = json_decode($json_o, true);

    $total = $sphinx_results['total_found'];

    if ($sphinx_results['total_found'] > 0) {
        $where = " where id IN (";
        foreach ( $sphinx_results["matches"] as $doc => $docinfo ) {
            $where .= "'$doc',";
            $counters[] .= $sphinx_results["matches"]["$doc"]['attrs']['@count'];
        }
        $where = rtrim($where, ",");
        $where .= ")";
    } else {
        // Negate search since sphinx returned 0 hits
        $where = "WHERE 1<1";
    }
    } else {
        $lzbase = str_replace("html/includes/portlets", "", dirname( __FILE__ ));
        $dlg_start = '<div id="error_dialog" title="Error!">';
        $dlg_end = "<br><br>Any results displayed are taken directly from MySQL which are significantly slower!";
        $dlg_end .= "</div>";
        if (preg_match("/.*failed to open.*spd/", "$json_o")) {
            $error = "The Sphinx indexes are missing!<br>\n";
            $error .= "Please be sure you have run the indexer on your server by typing:<br><br>\n";
            $error .= "sudo ${lzbase}sphinx/indexer.sh full<br><br>";
        } elseif (preg_match("/.*connection to.*failed.*/", "$json_o")) {
            $error = "The Sphinx daemon is not running!<br>\n";
            $error .= "Please be sure you have started the daemon on your server by typing:<br><br>\n";
            $error .= "sudo ${lzbase}sphinx/bin/searchd -c ${lzbase}sphinx/sphinx.conf<br><br>";
    } else {
        $error = $json_o;
    }
        echo $dlg_start;
        echo $error;
        echo $dlg_end;
            ?>
        <script type="text/javascript">
        $(document).ready(function(){
                $( "#error_dialog" ).dialog({
                    modal: true,
                    width: "50%", 
                    height: 240, 
                    buttons: {
                    Ok: function() {
                        $( this ).dialog( "close" );
                        }
                    }
                 });
        }); // end doc ready
        </script>
        <?php
    }
} else {
    $msg_mask = mysql_real_escape_string($searchText);
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


if ($orderby) {
    $where.= " ORDER BY FIELD($orderby, id)";  
}
if ($order) {
    $where.= " $order";  
}

?>

  <?php

switch ($show_suppressed): 
	case "suppressed":
		$sql = "SELECT * FROM ".$_SESSION['TBL_MAIN']."_suppressed $where LIMIT $limit";
	break;
        case "unsuppressed":
		$sql = "SELECT * FROM ".$_SESSION['TBL_MAIN']."_unsuppressed $where LIMIT $limit";
        break;
	default:
                $sql = "SELECT * FROM ".$_SESSION['TBL_MAIN'] ." $where LIMIT $limit";
endswitch;

  $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']); 

  if ($total == 'unknown') {

	switch ($show_suppressed):
        	case "suppressed":
                	$sql = "SELECT count(*) as tots FROM ".$_SESSION['TBL_MAIN']."_suppressed $where";
        	break;
        	case "unsuppressed":
                	$sql = "SELECT count(*) as tots FROM ".$_SESSION['TBL_MAIN']."_unsuppressed $where";
        	break;
        	default:
                	$sql = "SELECT count(*) as tots FROM ".$_SESSION['TBL_MAIN'] ." $where";
	endswitch;

	$tots =perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	while($row = fetch_array($tots)) {
        $total = $row['tots'];
	}
}


$count = mysql_num_rows($result);
if ($count > 0) {
    $info = "<center>Displaying $count of ".commify($total)." Possible Results</center>";
} else {
    // CDUKES: Added error check to see if Sphinx is working
    $file = $_SESSION['PATH_LOGS'] . "/sphinx_indexer.log";
    if (is_file($file)) {
        $line = `tail $file | grep "and completed on "`;
        $spx_lastupdate = getRelativeTime(preg_replace('/.*and completed on (\d+-\d+-\d+) at (\d+:\d+:\d+).*/', '$1 $2', $line));
        if (preg_match("/1969/", "$spx_lastupdate")) {
            $info = "Unable to determine the last Sphinx index time, please make sure that /etc/cron.d/logzilla exists and contains the entry for indexer.sh";
        }
    } else {
        $info = "Your Sphinx indexes have not been set up, please verify that CRON is running properly and that $file exists!";
    }
    if (!$info) {
        if ($_SESSION['SPX_ENABLE'] == "1") {
            echo "<br><br><b><u>Results</u></b><br>\n";
            echo "Found ".$sphinx_results['total_found']." documents in ".$sphinx_results['time']." seconds<br>\n";
            echo count($sphinx_results['words'])." search terms:<br>\n";
            if (is_array($sphinx_results['words'])) {
                foreach ($sphinx_results['words'] as $key=>$word) {
                    echo "&nbsp;&nbsp;&nbsp;&nbsp;\"$key\" found ".commify($sphinx_results['words'][$key]['hits'])." times in all possible log tables and date ranges.<br>\n";
                }
            }
            echo "<br>\n";
        }
        // echo "<pre>\n";
        // die(print_r($sphinx_results));
        // echo "</pre>\n";
        $info = "No results to display. Please try refining your search (such as the date of the event).<br />Sphinx Information: Your indexes were last updated $spx_lastupdate";
    }
    ?>
        <script type="text/javascript">
        $("#theTable").replaceWith('<br /><br /><font color="red"><?php echo "<br />$info"?></font>');
    </script>
        <?php
}
// ------------------------------------------------------
// BEGIN Chart Generation
// ------------------------------------------------------
$chart_type = (!empty($chart_type)) ? $chart_type : "pie";
$group_by = preg_replace ('/_crc/m', '', $groupby);
switch ($group_by) {
    case "host":
        $propername = "Hosts";
    break;
    case "msg":
        $propername = "Messages";
    break;
    case "program":
        $propername = "Programs";
    break;
    case "facility":
        $propername = "Facilities";
    break;
    case "severity":
        $propername = "Severities";
    break;
    case "mne":
        $propername = "Mnemonics";
    break;
    case "eid":
        $propername = "EventId";
    break;
}
$order_by = preg_replace ('/_crc/m', '', $order_by);
switch ($orderby) {
    case "id":
        $sortname = "ID";
    break;
    case "counter":
        $sortname = "Count";
    break;
    case "facility":
        $sortname = "Facility";
    break;
    case "severity":
        $sortname = "Severity";
    break;
    case "fo":
        $sortname = "First Occurrence";
    break;
    case "lo":
        $sortname = "Last Occurrence";
    break;
}
if ($order == 'DESC') { 
    $topx = "Top"; 
} else {
    $topx = "Bottom";
}
if ($start) {
    $title = new title( "$topx $limit $propername (by $sortname) Report\nGenerated on " .date("D M d Y")."\n<br>(Date Range: $start - $end)" );
} else {
    $title = new title( "$topx $limit $propername (by $sortname) Report\nGenerated on " .date("D M d Y")."\n" );
}
if (($group_by == "msg") && ($chart_type !== "pie")) {
    $dlg_start = '<div id="error_dialog" title="Warning">';
    $dlg_end = "<center><br><br>When grouping by Message, Pie charts should be used.<br>Most often, messages are too long to place across the X labels on line and bar charts.<br>The results will be shown using a Pie</center>";
    $dlg_end .= "</div>";
    echo $dlg_start;
    echo $dlg_end;
    ?>
        <script type="text/javascript">
        $(document).ready(function(){
                $( "#error_dialog" ).dialog({
                    modal: true,
                    width: "50%", 
                    height: 240, 
                    buttons: {
                    Ok: function() {
                        $( this ).dialog( "close" );
                        }
                    }
                 });
        }); // end doc ready
        </script>
            <?php
            $chart_type="pie";
}
if ($chart_type == "pie") {
    $pievalues = array();
    $ctype = new pie();
    if(num_rows($result) >= 1) {
        $i=0;
        while ($line = fetch_array($result)) {
            $name = $line[$group_by];
            if ($group_by == "program") { $name = crc2prg($name); }
            if ($group_by == "facility") { $name = int2fac($name); }
            if ($group_by == "severity") { $name = int2sev($name); }
            if ($group_by == "mne") { $name = crc2mne($name); }
            // die(print_r($line));
            $pievalues[] = new pie_value(intval($counters[$i]),  $name);
            $ids[] = $line['id'];
            $i++;
        }
    } else {
        $pievalues[] = new pie_value(intval(0),  "No results found"); 
        $title = new title( "$topx $limit $propername Report\nNo results match your search criteria"."\n" );
    }
    // Generate random pie colors
    for($i = 0; $i<=count($pievalues) ; $i++) {
        $colors[] = '#'.random_hex_color(); // 09B826
    }
    // $colors = array('#FA0000','#00FF00','#0000FF');

    $ctype->set_alpha(0.5);
    $ctype->add_animation( new pie_fade() );
    $ctype->add_animation( new pie_bounce(5) );
    // $ctype->start_angle( 270 )
    $ctype->start_angle( 0 );
    $ctype->set_tooltip( "#label#<br>#val# of #total#<br>#percent# of $topx $limit $propername" );
    $ctype->radius(180);
    $ctype->set_colours( $colors );
    switch ($propername) {
        case "Hosts":
            $ctype->on_click('pclick_host');
        break;
        case "Messages":
            $ctype->on_click('pclick_msg');
        break;
        case "Programs":
            $ctype->on_click('pclick_prg');
        break;
        case "Facilities":
            $ctype->on_click('pclick_fac');
        break;
        case "Severities":
            $ctype->on_click('pclick_sev');
        break;
        case "Mnemonics":
            $ctype->on_click('pclick_mne');
        break;
        case "EventId":
            $ctype->on_click('pclick_eid');
        break;
    }
    $ctype->set_values( $pievalues );
    $chart = new open_flash_chart();
    $chart->set_title( $title );
    $chart->add_element( $ctype );
} else {

    if( $chart_type == "line") {
        $bar = new line();
    } else {
        $bar = new bar_rounded_glass();
    }
    if(num_rows($result) >= 1) {
        $i=0;
        while ($line = fetch_array($result)) {
            $ids[] = $line['id'];
            $dotValues[] = intval($counters[$i]);
            $d = new dot(intval($counters[$i]));
            $dotLabels[] = $d->tooltip($line['host']."<br>#val#");
            $name = $line[$group_by];
            if ($group_by == "program") { $name = crc2prg($name); }
            if ($group_by == "facility") { $name = int2fac($name); }
            if ($group_by == "severity") { $name = int2sev($name); }
            if ($group_by == "mne") { $name = crc2mne($name); }
            $x_horiz_labels[] = ($name);
            $i++;
        }
        // echo "<pre>";
        // die(print_r($dotLabels));
    } else {
        $dotValues[] = 0;
        $x_horiz_labels[] =  "No results found"; 
        $title = new title( "$topx $limit $propername Report\nNo results match your search criteria"."\n" );
    }
    // Set bar values
    // echo "<pre>";
    // die(print_r($dotValues));
    $bar->set_values( $dotValues );
    $chart = new open_flash_chart();
    $chart->set_title( $title );
    $chart->add_element( $bar );
    //
    // create a Y Axis object
    //
    $y = new y_axis();
    // grid steps:
    $y->set_range( 0, max($dotValues), round(max($dotValues)/10));
    $chart->set_y_axis( $y );

    $x_labels = new x_axis_labels();
    $x_labels->set_vertical();
    $x_labels->set_labels( $x_horiz_labels );
    $x = new x_axis();
    $x->set_labels( $x_labels );
    $chart->set_x_axis( $x );

}

// ------------------------------------------------------
// END Chart Generation
// ------------------------------------------------------
?>

<script type="text/javascript">

OFC = {};
 
OFC.jquery = {
    name: "jQuery",
    version: function(src) { return $('#'+ src)[0].get_version() },
    rasterize: function (src, dst) { $('#'+ dst).replaceWith(OFC.jquery.image(src)) },
    image: function(src) { return "<img src='data:image/png;base64," + $('#'+src)[0].get_img_binary() + "' />"},
    popup: function(src) {
        var img_win = window.open('', 'Charts: Export as Image')
        with(img_win.document) {
            write('<html><head><title>Charts: Export as Image<\/title><\/head><body>' + OFC.jquery.image(src) + '<\/body><\/html>') }
        // stop the 'loading...' message
        img_win.document.close();
     }
}
if (typeof(Control == "undefined")) {var Control = {OFC: OFC.jquery}}
function save_image() { OFC.jquery.popup('chart_adhoc') }


//----------------------------------------------
// Pie clicks
// There's a better way to do this, I'm sure
// Just don't know how :-)
//----------------------------------------------
function pclick_host(index)
{
    var value = JSON.stringify(data['elements'][0]['values'][index]['label']);
    // alert(JSON.stringify(data['elements'][0]['values'][index]['label']));
    value = value.replace(/"/g, "");
    var postvars = $("#postvars").val();
    postvars = postvars.replace(/&hosts=/g, "");
    postvars = postvars.replace(/&groupby=\w+/g, "");
    var url = (postvars + "&sel_hosts[]=" + value);
    url = url.replace(/Graph/g, "Results");
    self.location=url;
}
function pclick_msg(index)
{
    var value = JSON.stringify(data['elements'][0]['values'][index]['label']);
    value = value.replace(/"/g, "");
    var postvars = $("#postvars").val();
    postvars = postvars.replace(/&msg_mask=/g, "");
    postvars = postvars.replace(/&groupby=\w+/g, "");
    var url = (postvars + "&msg_mask=" + value);
    url = url.replace(/Graph/g, "Results");
    self.location=url;
}
function pclick_prg(index)
{
    var value = JSON.stringify(data['elements'][0]['values'][index]['label']);
    value = value.replace(/"/g, "");
    var postvars = $("#postvars").val();
    postvars = postvars.replace(/&programs[]=/g, "");
    postvars = postvars.replace(/&groupby=\w+/g, "");
    var url = (postvars + "&programs[]=" + value);
    url = url.replace(/Graph/g, "Results");
    self.location=url;
}
function pclick_fac(index)
{
    var value = JSON.stringify(data['elements'][0]['values'][index]['label']);
    value = value.replace(/"/g, "");
    var postvars = $("#postvars").val();
    postvars = postvars.replace(/&facilities[]=/g, "");
    postvars = postvars.replace(/&groupby=\w+/g, "");
    var url = (postvars + "&facilities[]=" + value);
    url = url.replace(/Graph/g, "Results");
    self.location=url;
}
function pclick_sev(index)
{
    var value = JSON.stringify(data['elements'][0]['values'][index]['label']);
    value = value.replace(/"/g, "");
    var postvars = $("#postvars").val();
    postvars = postvars.replace(/&severities[]=/g, "");
    postvars = postvars.replace(/&groupby=\w+/g, "");
    var url = (postvars + "&severities[]=" + value);
    url = url.replace(/Graph/g, "Results");
    self.location=url;
}
function pclick_mne(index)
{
    var value = JSON.stringify(data['elements'][0]['values'][index]['label']);
    value = value.replace(/"/g, "");
    var postvars = $("#postvars").val();
    postvars = postvars.replace(/&mnemonics[]=/g, "");
    postvars = postvars.replace(/&groupby=\w+/g, "");
    var url = (postvars + "&sel_mne[]=" + value);
    url = url.replace(/Graph/g, "Results");
    self.location=url;
}
function pclick_eid(index)
{
    var value = JSON.stringify(data['elements'][0]['values'][index]['label']);
    // alert(JSON.stringify(data['elements'][0]['values'][index]['label']));
    value = value.replace(/"/g, "");
    var postvars = $("#postvars").val();
    postvars = postvars.replace(/&eids=/g, "");
    postvars = postvars.replace(/&groupby=\w+/g, "");
    var url = (postvars + "&sel_eid[]=" + value);
    url = url.replace(/Graph/g, "Results");
    self.location=url;
}



function open_flash_chart_data()
{
    return JSON.stringify(data);
}
var full_graph_width = $(document).width()-125;
var full_graph_height = $(document).height()-200;
var data = <?php echo $chart->toPrettyString(); ?>;

swfobject.embedSWF("includes/ofc/open-flash-chart.swf", "chart_adhoc", "100%", full_graph_height, "9.0.0", "expressInstall.swf", {}, {"wmode":"transparent"});
</script>

<script type="text/javascript">
$("#portlet-header_Graph_Results").prepend('<div id="btn"></div><span class="ui-icon ui-icon-disk"></span>');

//---------------------------------------------------------------
// BEGIN: Save URL function
//---------------------------------------------------------------
$(".portlet-header .ui-icon-disk").click(function() {
 var url = $("#q_hist").val();
    $("#chart_history_dialog").dialog({
                        bgiframe: true,
                        resizable: true,
                        height: 'auto',
                        width: '75%',
                        autoOpen:false,
                        modal: true,
                        open: function() {
                         $("#url").val(url);
                         },
                        overlay: {
                                backgroundColor: '#000',
                                opacity: 0.5
                        },
                        buttons: {
                                'Save to Favorites': function() {
                                        $(this).dialog('close');
                                        var urlname = $("#urlname").val();
                                        var show_suppressed = $('#show_suppressed :selected').val();
                                        var sel_usave_tail = $('#sel_usave_tail :selected').val();
                                        var sel_usave_limit = $('#sel_usave_limit :selected').val();
                                        var hosts = $("#usave_hosts").val();
                                        // alert("hosts = " +hosts);
                                        var dupop = $('#dupop :selected').val()
                                            // alert("dupop = "+ dupop);
                                        var dupcount = $("#dupcount").val();
                                            // alert("dupcount = "+ dupcount);
                                        var orderby = $('#orderby :selected').val();
                                            // alert("orderby = "+ orderby);
                                        var order = $('#order :selected').val();
                                            // alert("order = "+ order);
                                        var fo_checkbox = $('input:checkbox[name=fo_checkbox]:checked').val();
                                             // alert("focheck = "+ fo_checkbox);
                                        var fo_date = $("#fo_date").val();
                                            // alert("fo_date = "+ fo_date);
                                        var fo_time_start_usave = $("#fo_time_start_usave").val();
                                            // alert("fo_time_start_usave = "+ fo_time_start_usave);
                                        var fo_time_end_usave = $("#fo_time_end_usave").val();
                                            // alert("fo_time_end_usave = "+ fo_time_end_usave);
                                        var lo_date = $("#lo_date").val();
                                            // alert("lo_date = "+ lo_date);
                                        var lo_checkbox = $('input:checkbox[name=lo_checkbox]:checked').val();
                                            // alert("locheck = "+ lo_checkbox);
                                        var lo_time_start_usave = $("#lo_time_start_usave").val();
                                            // alert("lo_time_start_usave = "+ lo_time_start_usave);
                                        var lo_time_end_usave = $("#lo_time_end_usave").val();
                                            // alert("lo_time_end_usave = "+ lo_time_end_usave);
                                        var date_andor = $('#date_andor :selected').val();
                                            // alert("dar = "+ date_andor);
                                        url = url.replace(/show_suppressed=\w*&/, "show_suppressed="+ show_suppressed + "&");
                                        url = url.replace(/tail=\w*&/, "tail="+ sel_usave_tail + "&");
                                        url = url.replace(/limit=\w*&/, "limit="+ sel_usave_limit + "&");
                                        url = url.replace(/hosts=\w*&/, "hosts="+ hosts + "&");
                                        url = url.replace(/dupop=\w*&/, "dupop="+ dupop + "&");
                                        url = url.replace(/dupcount=\w*&/, "dupcount="+ dupcount + "&");
                                        url = url.replace(/orderby=\w*&/, "orderby="+ orderby + "&");
                                        url = url.replace(/order=\w*&/, "order="+ order + "&");
                                        if (fo_checkbox == 'on') {
                                        url = url.replace(/fo_checkbox=\w*&/, "fo_checkbox="+ fo_checkbox + "&");
                                        } else {
                                        url = url.replace(/fo_checkbox=\w*&/, "fo_checkbox=&");
                                        }
                                        if (lo_checkbox == 'on') {
                                        url = url.replace(/lo_checkbox=\w*&/, "lo_checkbox="+ lo_checkbox + "&");
                                        } else {
                                        url = url.replace(/lo_checkbox=\w*&/, "lo_checkbox=&");
                                        }
                                        url = url.replace(/fo_date=\S*?&/, "fo_date="+ fo_date + "&");
                                        url = url.replace(/lo_date=\S*?&/, "lo_date="+ lo_date + "&");
                                        url = url.replace(/date_andor=\w*?&/, "date_andor="+ date_andor + "&");
                                        url = url.replace(/fo_time_start=\S*?&/, "fo_time_start="+ fo_time_start_usave + "&");
                                        url = url.replace(/fo_time_end=\S*?&/, "fo_time_end="+ fo_time_end_usave + "&");
                                        url = url.replace(/lo_time_start=\S*?&/, "lo_time_start="+ lo_time_start_usave + "&");
                                        url = url.replace(/lo_time_end=\S*?&/, "lo_time_end="+ lo_time_end_usave + "&");
                                        if (urlname !== '') {
                                        $.get("includes/ajax/qhistory.php?action=save&url="+ escape(url) +"&urlname="+urlname+"&spanid=chart_history", function(data){
                                            $('#msgbox_br').jGrowl(data);
                                            $("#chart_history").append("<li><a href='"+url+"'>" + urlname + "</a></li>\n");
                                           });
                                        } else {
                                            $('#msgbox_br').jGrowl("Unable to save URL: no name entered");
                                        }
                                },
                                Cancel: function() {
                                        $(this).dialog('close');
                                }
                        }
                });
                $("#chart_history_dialog").dialog('open');     
                //return false;
     });
//---------------------------------------------------------------
// END: Save URL function
//---------------------------------------------------------------
</script>

<div id="chart_adhoc"></div>

<?php 
$qstring = preg_replace('/^&(.*)/', '?$1', $qstring);
$postvars = $qstring;
$qstring = myURL().$qstring;
if ($_SESSION['DEBUG'] > 0 ) {
    if (($_SESSION['SPX_ENABLE'] == "1") && ($searchText !== '')) {
        echo "<pre  class=\"code\">";
        echo "<b><u>Sphinx Query</u></b><pre class=\"code\">$searchText</pre><br>\n";
        echo "</pre><br><br>\n";
    }
    if ($_SESSION['SPX_ENABLE'] == "1") {
        echo "<b><u>Query type</u></b><br>";
        echo "<pre  class=\"code\">";
        echo "$q_type<br><br>\n";
        echo "</pre><br><br>\n";
        echo "<b><u>Results</u></b><br>\n";
        echo "<pre  class=\"code\">";
        echo "Found ".$sphinx_results['total_found']." documents in ".$sphinx_results['time']." seconds<br>\n";
        echo count($sphinx_results['words'])." search terms:<br>\n";
        if (is_array($sphinx_results['words'])) {
            foreach ($sphinx_results['words'] as $key=>$word) {
                echo "&nbsp;&nbsp;&nbsp;&nbsp;\"$key\" found ".$sphinx_results['words'][$key]['hits']." times<br>\n";
            }
        }
        echo "</pre><br><br>\n";
        echo "<br>\n";
    }
    // echo "<pre>\n";
    // die(print_r($sphinx_results));
    // echo "</pre>\n";
    echo "<u><b>The SQL query:</u></b><br>\n";
    $sql = str_replace("AND", "<br>AND", $sql);
    $sql = str_replace("OR", "<br>OR", $sql);
    echo "<pre  class=\"code\">";
    echo "$sql\n"; 
    echo "</pre><br><br>\n";
    echo "<br><br><u><b>Search Array Variables (".count($searchArr)."):</u></b><br>\n";
    echo "<pre  class=\"code\">";
    print_r($searchArr);
    echo "</pre><br><br>\n";
    echo "<br><br><u><b>Post Variables (".count($_POST)."):</u></b><br>\n";
    echo "<pre  class=\"code\">";
    print_r($_POST);
    echo "</pre><br><br>\n";
    if ($_GET) {
        echo "<br><br><u><b>GET Variables (".count($_GET)."):</u></b><br>\n";
        echo "<pre  class=\"code\">";
        print_r($_GET);
        echo "<br><br>\n";
    }
    echo "</pre><br><br>\n";
    echo "<br><br><u><b>Array formatted response from Sphinx search()</u></b><br>\n";
    echo "<pre  class=\"code\">";
    print_r($sphinx_results);
    echo "</pre><br><br>\n";
    echo "<br><br><u><b>JSON formatted response from Sphinx search()</u></b><br>\n";
    echo "<pre  class=\"code\">";
    echo "$json_o<br><br>\n";
    echo "</pre><br><br>\n";
    $end_time = microtime(true);
    echo "Page generated in " . round(($end_time - $start_time),5) . " seconds\n";
}
if (($_SESSION['SPX_ENABLE'] == "1") && ($tail == "off")) {
    if ($sphinx_results['total'] > 0) {
        echo "&nbsp;&nbsp;&nbsp;&nbsp;".commify($total)." matches found in " . $sphinx_results['time']. " seconds\n";
    }
    if ($limit > 500) {
        ?>
            <script type="text/javascript">
            $(document).ready(function(){
                    $( "<div id='limit_warning'><center><br><br>Setting the result set higher than 500 may cause your browser to timeout.<br>Note that this is a client side browser limitation and not a server issue.<br>(The server returned <?php echo commify($total)." matches in " . $sphinx_results['time']?> seconds.)</div></center>" ).dialog({
                    modal: true,
                    width: "50%", 
                    height: 240, 
                    buttons: {
                    Ok: function() {
                        $( this ).dialog( "close" );
                        }
                    }
                 });
        }); // end doc ready
    </script>
    <?php
    }
}
?>
<input type="hidden" name="tail" id="tail" value="<?php echo $tail?>">
<input type="hidden" name="q_hist" id="q_hist" value="<?php echo $qstring?>">
<input type="hidden" name="postvars" id="postvars" value="<?php echo $postvars?>">

<div class='XLButtons'>
<form name="export" method="POST" action= "includes/excel.php" name="checkboxes[]">
<?php
if ($ids) {
    foreach ($ids as $id) {
    echo "<input type=\"hidden\" name=\"dbid[]\" value=\"$id\">\n";
    }
}
?>
<input class='ui-state-default ui-corner-all' type='submit' id='btnExport' value='Export to'>
<select name="rpt_type">
<option selected value="xls">XLS</option>
<option value="xml">XLSX</option>
<option value="csv">CSV</option>
<option value="pdf">PDF</option>
</select>
<input type="hidden" name="table" value="<?php echo $_SESSION['TBL_MAIN']?>">
<input type="hidden" name="q_hist" id="q_hist" value="<?php echo $qstring?>">
<input type="hidden" name="postvars" id="postvars" value="<?php echo $postvars?>">
</div>
</form>
<script type="text/javascript">
$(".XLButtons").appendTo("#portlet-header_Graph_Results");
</script>

<div class="dialog_hide">
    <div id="chart_history_dialog" title='Save Chart Query:<br>Results will be saved to the "Charts" menu.'>
        <form>
        <fieldset>
            <label for="urlname">Enter a short name for this search:</label>
            <input type="text" name="urlname" id="urlname" class="text ui-widget-content ui-corner-all" />
            <br>
            <label for="url">Here is the full URL  that was captured:</label>
            <input type="text" name="url" id="url" class="text ui-widget-content ui-corner-all" />
        </fieldset>
        <hr>
        <b>You may either click "Save to Favorites" now, or modify individual parameters below before saving.</b>
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
                    <option <?php if ($orderby_orig == 'id') echo "selected"; ?> value="id">Database ID</option>
                    <option <?php if ($orderby_orig == 'counter') echo "selected"; ?> value="counter">Count</option>
                    <option <?php if ($orderby_orig == 'facility') echo "selected"; ?> value="facility">Facility</option>
                    <option <?php if ($orderby_orig == 'severity') echo "selected"; ?> value="severity">Severity</option>
                    <?php  if ( $_SESSION["DEDUP"] == "1" ) { ?>
                    <option <?php if ($orderby_orig == 'fo') echo "selected"; ?> value="fo">First Occurrence</option>
                    <?php  } ?>
                    <option <?php if ($orderby_orig == 'lo') echo "selected"; ?> value="lo">Last Occurrence</option>
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

                    <?php  if ( $_SESSION["DEDUP"] == "1" ) { ?>
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
                    <?php } ?>

                <TR>
                    <TD WIDTH="10%">
                    <input type="checkbox" name="lo_checkbox" id="lo_checkbox" <?php if ($lo_checkbox == 'on') echo "checked"; ?>>
                    <?php  if ( $_SESSION["DEDUP"] == "1" ) { ?>
                    <b>LO</b>
                    <?php } else { ?>
                    <b>Last Occurrence</b>
                    <?php } ?>
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


<?php } else { ?>
<script type="text/javascript">
$('#portlet_Search_Results').remove()
</script>
<?php } ?>
