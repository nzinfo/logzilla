<?php
/*
 * portlet-chart_counts.php
 *
 * Developed by Clayton Dukes <cdukes@logzilla.pro>
 * Copyright (c) 2011 logzilla.pro
 * All rights reserved.
 *
 * Changelog:
 * 2011-06-08 - created
 *
 */

if ((has_portlet_access($_SESSION['username'], 'Graph Results') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
$start_time = microtime(true);

$today = date("Y-m-d");
$where = "WHERE 1=1";
$total = 'unknown';
$qstring = '';
$page = get_input('page');
$chart_type = get_input('chart_type');
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
    $searchArr['chart_type'] = $chart_type;

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

//----------------------------
// END HEAD
//----------------------------

$sql = "SELECT * FROM ".$_SESSION['TBL_MAIN'] ." $where LIMIT $limit";
$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']); 
$count = mysql_num_rows($result);
if ($count > 0) {
    $i=0;
    while ($line = fetch_array($result)) {
        $name = $line[$groupby];
        if ($groupby == "program") { $name = crc2prg($name); }
        if ($groupby == "facility") { $name = int2fac($name); }
        if ($groupby == "severity") { $name = int2sev($name); }
        if ($groupby == "mne") { $name = crc2mne($name); }
        $values[] = intval($counters[$i]),  $name);
        $ids[] = $line['id'];
        $i++;
    }
}
//------------------
// Define Chart Data
//------------------
$c_head = <<<EOF
<script type="text/javascript" src="includes/js/hc/js/modules/exporting.js"></script>
EOF;

$c_mps = <<<EOF
<script type="text/javascript">
        var chart; // global
        function requestData() {
            $.ajax({
                url: 'includes/ajax/counts.php?data=mps', 
                success: function(point) {
                    var series = chart.series[0],
                        shift = series.data.length > 20; // shift if the series is longer than 20
        
                    // add the point
                    chart.series[0].addPoint(eval(point), true, shift);
                    
                    // call it again after one second
                    setTimeout(requestData, 1000);  
                },
                cache: false
            });
        }
            
        $(document).ready(function() {
            chart = new Highcharts.Chart({
                chart: {
                    renderTo: 'portlet_Graph_Results',
                    defaultSeriesType: 'spline',
                    events: {
                        load: requestData
                    }
                },
                title: {
                    text: 'Live MPS (Average)'
                },
                xAxis: {
                    type: 'datetime',
                    tickPixelInterval: 150,
                    maxZoom: 20 * 1000
                },
                yAxis: {
                    minPadding: 0.2,
                    maxPadding: 0.2,
                    title: {
                        text: 'Value',
                        margin: 80
                    }
                },
                series: [{
                    name: 'Disable',
                    data: []
                }]
            });     
        });
        </script>
EOF;

$c_pie = <<<EOF
<script type="text/javascript">
var chart; // global

$.getJSON('includes/ajax/counts.php?data=pie', function(data) {
          draw_lb(data)
          });

var vals = <?php $values?>;
function draw_lb(data)
{
chart = new Highcharts.Chart({
  chart: {
 renderTo: 'portlet_Graph_Results',
    defaultSeriesType: 'pie'
  },
  series: [{
    data: data
  }]
});
}
</script>
EOF;



//-------------------------------------
// Get posted chart type and create it
//-------------------------------------
switch ($chart_type) {
    case "pie":
        echo $c_head;
    echo $c_pie;
    break;
    case "bar":
        echo $c_head;
    echo $c_mps;
    break;
    case "line":
        echo $c_head;
    echo $c_mps;
    break;
    case "mps":
        echo $c_head;
    echo $c_mps;
    break;
}


//----------------------------
// BEGIN FOOT
//----------------------------
$postvars = $qstring;
$qstring = myURL().$qstring;
if ($_SESSION['DEBUG'] > 0 ) {
    if (($_SESSION['SPX_ENABLE'] == "1") && ($searchText !== '')) {
    echo "<pre  class=\"code\">";
    echo "<b><u>Sphinx Query</b></u><pre class=\"code\">$searchText</pre><br>\n";
    echo "<br><br>\n";
    }
    if ($_SESSION['SPX_ENABLE'] == "1") {
    echo "<b><u>Query type</u></b><br>";
    echo "<pre  class=\"code\">";
    echo "$q_type<br><br>\n";
    echo "<br><br>\n";
        echo "<b><u>Results</u></b><br>\n";
    echo "<pre  class=\"code\">";
        echo "Found ".$sphinx_results['total_found']." documents in ".$sphinx_results['time']." seconds<br>\n";
        echo count($sphinx_results['words'])." search terms:<br>\n";
        if (is_array($sphinx_results['words'])) {
            foreach ($sphinx_results['words'] as $key=>$word) {
                echo "&nbsp;&nbsp;&nbsp;&nbsp;\"$key\" found ".$sphinx_results['words'][$key]['hits']." times<br>\n";
            }
        }
    echo "<br><br>\n";
        echo "<br>\n";
    }
    // echo "<pre>\n";
    // die(print_r($sphinx_results));
    // echo "</pre>\n";
    echo "<u><b>The SQL query:</b></u><br>\n";
    $sql = str_replace("AND", "<br>AND", $sql);
    $sql = str_replace("OR", "<br>OR", $sql);
    echo "<pre  class=\"code\">";
    echo "$sql\n"; 
    echo "<br><br>\n";
    echo "<br><br><u><b>Search Array Variables (".count($searchArr)."):</b></u><br>\n";
    echo "<pre  class=\"code\">";
    print_r($searchArr);
    echo "<br><br>\n";
    echo "<br><br><u><b>Post Variables (".count($_POST)."):</b></u><br>\n";
    echo "<pre  class=\"code\">";
    print_r($_POST);
    echo "<br><br>\n";
    if ($_GET) {
    echo "<br><br><u><b>GET Variables (".count($_GET)."):</b></u><br>\n";
    echo "<pre  class=\"code\">";
    print_r($_GET);
    echo "<br><br>\n";
    }
    echo "<br><br>\n";
    echo "<br><br><u><b>Array formatted response from Sphinx search()</b></u><br>\n";
    echo "<pre  class=\"code\">";
    print_r($sphinx_results);
    echo "<br><br>\n";
    echo "<br><br><u><b>JSON formatted response from Sphinx search()</b></u><br>\n";
    echo "<pre  class=\"code\">";
    echo "$json_o<br><br>\n";
    echo "<br><br>\n";
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
};
}
?>
  <input type="hidden" name="tail" id="tail" value="<?php echo $tail?>">
  <input type="hidden" name="q_hist" id="q_hist" value="<?php echo $qstring?>">
  <input type="hidden" name="postvars" id="postvars" value="<?php echo $postvars?>">

  </form>


</script>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Graph_Results').remove()
</script>
<?php } ?>
