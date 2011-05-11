<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-06-15
 *
 * Changelog:
 * 2010-03-06 - created
 *
 */

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
require_once ($basePath . "/../ofc/php/open-flash-chart.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

//---------------------------------------------------
// The get_input statements below are used to get
// POST, GET, COOKIE or SESSION variables.
// Note that PLURAL words below are arrays.
//---------------------------------------------------

if ((has_portlet_access($_SESSION['username'], 'Graph Results') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 
    //construct where clause 
    $where = "WHERE 1=1";

    $qstring = '';
    // If url is pasted without a date/time, assume today.
    if($_GET) {
        if (!in_array('lo_checkbox', $_GET)) {
            $_GET['lo_checkbox'] = "on";
        }
        if (!in_array('lo_date', $_GET)) {
            $_GET['lo_date'] = date("Y-m-d");
        }
        if (!in_array('lo_time_start', $_GET)) {
            $_GET['lo_time_start'] = "00:00:00";
        }
        if (!in_array('lo_time_end', $_GET)) {
            $_GET['lo_time_end'] = "23:59:59";
        }
    }
    $page = get_input('page');
    $qstring .= "?page=$page";

    $show_suppressed = get_input('show_suppressed');
    $qstring .= "&show_suppressed=$show_suppressed";

    // Special - this gets posted via javascript since it comes from the hosts grid
    // Form code is somewhere near line 992 of js_footer.php
    $hosts = get_input('hosts');
    // sel_hosts comes from the main page <select>, whereas 'hosts' above this line comes from the grid select via javascript.
    $sel_hosts = get_input('sel_hosts');
    if ($hosts) {
        $pieces = explode(",", $hosts);
        foreach ($pieces as $host) {
            $sel_hosts[] .= $host;
            $qstring .= "&hosts[]=$host";
        }
    }
    $hosts = $sel_hosts;
    if ($hosts) {
        foreach ($hosts as $host) {
            $where.= "'$host',";
            $qstring .= "&sel_hosts[]=$host";
        }
    }
    // Special - this gets posted via javascript since it comes from the mnemonics grid
    // Form code is somewhere near line 992 of js_footer.php
    $mnemonics = get_input('mnemonics');
    // sel_mne comes from the main page <select>, whereas 'mnemonics' above this line comes from the grid select via javascript.
    $sel_mne = get_input('sel_mne');
    if ($mnemonics) {
        $pieces = explode(",", $mnemonics);
        foreach ($pieces as $mne) {
            $sel_mne[] .= $mne;
            $qstring .= "&mnemonics[]=$mne";
        }
    }
    $mnemonics = $sel_mne;
    if ($mnemonics) {
        if (!in_array(mne2crc('None'), $mnemonics)) {
            $where .= " AND mne !='".mne2crc('None')."'";
        }
        foreach ($mnemonics as $mne) {
            if (!preg_match("/^\d+/m", $mne)) {
                $mne = mne2crc($mne);
            }
            $qstring .= "&sel_mne[]=$mne";
        }
    }
    // Special - this gets posted via javascript since it comes from the Snare EID grid
    // Form code is somewhere near line 992 of js_footer.php
    $eids = get_input('eids');
    // sel_eid comes from the main page <select>, whereas 'eids' above this line comes from the grid select via javascript.
    $sel_eid = get_input('sel_eid');
    if ($eids) {
        $pieces = explode(",", $eids);
        foreach ($pieces as $eid) {
            $sel_eid[] .= $eid;
            $qstring .= "&eids[]=$eid";
        }
    }
    $eids = $sel_eid;
    if ($eids) {
        if (!in_array('0', $eids)) {
            $where .= " AND eid > 0 ";
        }
        foreach ($eids as $eid) {
            $qstring .= "&sel_eid[]=$eid";
        }
    }
    // portlet-programs
    $programs = get_input('programs');
    if ($programs) {
        foreach ($programs as $program) {
            if (!preg_match("/^\d+/m", $program)) {
                $program = prg2crc($program);
            }
            $qstring .= "&programs[]=$program";
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
    $msg_mask = get_input('msg_mask');
    $msg_mask = preg_replace ('/^Search through .*\sMessages/m', '', $msg_mask);
    $msg_mask_oper = get_input('msg_mask_oper');
    $qstring .= "&msg_mask=$msg_mask&msg_mask_oper=$msg_mask_oper";
    $notes_mask = get_input('notes_mask');
    $notes_mask = preg_replace ('/^Search through .*\sNotes/m', '', $notes_mask);
    $notes_mask_oper = get_input('notes_mask_oper');
    $notes_andor = get_input('notes_andor');
    $qstring .= "&notes_mask=$notes_mask&notes_mask_oper=$notes_mask_oper&notes_andor=$notes_andor";
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
            if ($date_andor=='') $date_andor = 'AND';
        }
    }
    //------------------------------------------------------------
    // END date/time
    //------------------------------------------------------------

    // portlet-search_options
    $limit = get_input('limit');
    $limit = (!empty($limit)) ? $limit : "10";
    $qstring .= "&limit=$limit";
    $dupop = get_input('dupop');
    $dupop_orig = $dupop;
    $qstring .= "&dupop=$dupop";
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
    }
    $orderby = get_input('orderby');
    $orderby_orig = $orderby;
    switch ($orderby_orig) {
        case "id":
            $sortname = "Database ID";
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
    $qstring .= "&orderby=$orderby";
    if ($orderby) {
        if ($orderby == "counter") { $orderby = "count"; }
        $orderby = " ORDER BY $orderby";  
    }
    $order = get_input('order');
    $qstring .= "&order=$order";
    $order = (!empty($order)) ? $order : "DESC";
    switch ($order) {
        case "ASC":
            $topx = "bottom";
        break;
        default:
        $topx = "top";
    }
    $groupby = get_input('groupby');
    $qstring .= "&groupby=$groupby";
    $groupby = (!empty($groupby)) ? $groupby : "host";
    $chart_type = get_input('chart_type');
    $qstring .= "&chart_type=$chart_type";
    $chart_type = (!empty($chart_type)) ? $chart_type : "pie";

    // ------------------------------------------------------
    // END Ad-hoc chart variables
    // ------------------------------------------------------

    // ------------------------------------------------------
    // BEGIN Chart Generation
    // ------------------------------------------------------
    $groupby = preg_replace ('/_crc/m', '', $groupby);
    switch ($groupby) {
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
    $ucTopx = ucfirst($topx);


    // Encode POST/GET into json and send it off to search:
    if ($_POST) {
        $json_o = search(json_encode($_POST));
    } else {
        $json_o = search(json_encode($_GET));
    }


    // If something goes wrong, search() will return ^'SPX_ERROR'
    if (!preg_match("/^Sphinx Error:/", "$json_o")) {

        // Decode returned json object into an array:
        $sphinx_results = json_decode($json_o, true);
        //echo "<pre>";
        // die(print_r($sphinx_results));

        $total = $sphinx_results['total_found'];

        if ($sphinx_results['total_found'] > 0) {
            //  echo "<pre>\n";
            //  die(print_r($sphinx_results));
            //  echo "</pre>\n";
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
            //  die(print_r($sphinx_results));
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


    switch ($show_suppressed):
        case "suppressed":
        $sql = "SELECT * FROM ".$_SESSION['TBL_MAIN']."_suppressed $where";
    break;
    case "unsuppressed":
        $sql = "SELECT * FROM ".$_SESSION['TBL_MAIN']."_unsuppressed $where";
    break;
    default:
    $sql = "SELECT * FROM ".$_SESSION['TBL_MAIN'] ." $where";
    endswitch;

    $result = perform_query($sql, $dbLink, "portlet-chart_adhoc");


    if ($start) {
        $title = new title( "$ucTopx $limit $propername (by $sortname) Report\nGenerated on " .date("D M d Y")."\n<br>(Date Range: $start - $end)" );
    } else {
        $title = new title( "$ucTopx $limit $propername (by $sortname) Report\nGenerated on " .date("D M d Y")."\n" );
    }
    if (($groupby == "msg") && ($chart_type !== "pie")) {
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
                $name = $line[$groupby];
                if ($groupby == "program") { $name = crc2prg($name); }
                if ($groupby == "facility") { $name = int2fac($name); }
                if ($groupby == "severity") { $name = int2sev($name); }
                if ($groupby == "mne") { $name = crc2mne($name); }
                // die(print_r($line));
                $pievalues[] = new pie_value(intval($counters[$i]),  $name);
                $ids[] = $line['id'];
                $i++;
            }
        } else {
            $pievalues[] = new pie_value(intval(0),  "No results found"); 
            $title = new title( "$ucTopx $limit $propername Report\nNo results match your search criteria"."\n" );
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
        $ctype->set_tooltip( "#label#<br>#val# of #total#<br>#percent# of $ucTopx $limit $propername" );
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
                $name = $line[$groupby];
                if ($groupby == "program") { $name = crc2prg($name); }
                if ($groupby == "facility") { $name = int2fac($name); }
                if ($groupby == "severity") { $name = int2sev($name); }
                if ($groupby == "mne") { $name = crc2mne($name); }
                $x_horiz_labels[] = ($name);
                $i++;
            }
            // echo "<pre>";
            // die(print_r($dotLabels));
        } else {
            $dotValues[] = 0;
            $x_horiz_labels[] =  "No results found"; 
            $title = new title( "$ucTopx $limit $propername Report\nNo results match your search criteria"."\n" );
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
    postvars = postvars.replace(/&groupby=.*&/g, "&");
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
    postvars = postvars.replace(/&groupby=.*&/g, "&");
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
    postvars = postvars.replace(/&groupby=.*&/g, "&");
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
    postvars = postvars.replace(/&groupby=.*&/g, "&");
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
    postvars = postvars.replace(/&groupby=.*&/g, "&");
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
    postvars = postvars.replace(/&groupby=.*&/g, "&");
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
    postvars = postvars.replace(/&groupby=.*&/g, "&");
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
$postvars = $qstring;
$qstring = myURL().$qstring;
if ($_SESSION['DEBUG'] > 0 ) {
        if (($_SESSION['SPX_ENABLE'] == "1") && ($msg_mask !== '')) {
            echo "<pre  class=\"code\">";
            echo "<b><u>Message Text Query</u></b><pre class=\"code\">$msg_mask</pre><br>\n";
            echo "</pre><br><br>\n";
        }
        if ($_SESSION['SPX_ENABLE'] == "1") {
            $qtype = get_input('qtype');
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
        echo "<br><br><u><b>Post Variables:</u></b><br>\n";
        echo "<pre  class=\"code\">";
        print_r($_POST);
        echo "</pre><br><br>\n";
        if ($_GET) {
            echo "<br><br><u><b>GET Variables:</u></b><br>\n";
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
}
?>
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
