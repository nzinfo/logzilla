<?php
/*
 *
 */

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
$start_time = microtime(true);

$today = date("Y-m-d");
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
$lo_date = get_input('lo_date');
    $qstring .= "&lo_date=".urlencode($lo_date);
$lo_time_start = get_input('lo_time_start');
    $qstring .= "&lo_time_start=$lo_time_start";
$lo_time_end = get_input('lo_time_end');
    $qstring .= "&lo_time_end=$lo_time_end";
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
if ($lo_checkbox == "on") {
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
        $qstring .= "&programs[]=".urlencode($program);
    }
}

// portlet-severities
$severities = get_input('severities');
if ($severities) {
    foreach ($severities as $severity) {
        if (!preg_match("/^\d+/m", $severity)) {
            $severity = sev2int($severity);
        }
        $qstring .= "&severities[]=$severity";
    }
}


// portlet-facilities
$facilities = get_input('facilities');
if ($facilities) {
    foreach ($facilities as $facility) {
        if (!preg_match("/^\d+/m", $facility)) {
            $facility = fac2int($facility);
        }
        $qstring .= "&facilities[]=$facility";
    }
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


    $json_o = search(json_encode($searchArr));


    // If something goes wrong, search() will return an error
    if (!preg_match("/^Sphinx Error:/", "$json_o")) {

    // Decode returned json object into an array:
    $sphinx_results = json_decode($json_o, true);

    $total = $sphinx_results['total_found'];

    if ($sphinx_results['total_found'] > 0) {
        $where = " where id IN (";
        foreach ( $sphinx_results["matches"] as $doc => $docinfo ) {
            $where .= "'$doc',";
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


