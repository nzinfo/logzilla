<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2009 gdd.net
 * All rights reserved.
 *
 * Changelog:
 * 2009-12-07 - created
 *
 */

// set manually for command line debugging:
// $chartId = "chart_mpw";

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
require_once ($basePath . "/../ofc/php/open-flash-chart.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
$chartId = get_input('chartId');

// ------------------------------------------------------
// BEGIN Ad-hoc chart variables
// ------------------------------------------------------
//---------------------------------------------------
// The get_input statements below are used to get
// POST, GET, COOKIE or SESSION variables.
// Note that PLURAL words below are arrays.
//---------------------------------------------------

//construct where clause 
$where = "WHERE 1=1";

$qstring = '';

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
    foreach ($programs as $mask) {
        $where.= "'$mask',";  
        $qstring .= "&programs[]=$mask";
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
        $qstring .= "&priorities[]=$mask";
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
        $qstring .= "&facilities[]=$mask";
    }
    $where = rtrim($where, ",");
    $where .= ")";
}

// portlet-sphinxquery
$msg_mask = get_input('msg_mask');
$msg_mask = preg_replace ('/^Search through .*\sMessages/m', '', $msg_mask);
$msg_mask_oper = get_input('msg_mask_oper');
$qstring .= "&msg_mask=$msg_mask&msg_mask_oper=$msg_mask_oper";
if($msg_mask) {
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
    $qstring .= "&limit=$limit";
$dupop = get_input('dupop');
    $qstring .= "&dupop=$dupop";
$dupcount = get_input('dupcount');
    $qstring .= "&dupcount=$dupcount";
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
    $qstring .= "&orderby=$orderby";
$groupby = get_input('groupby');
    $qstring .= "&groupby=$groupby";
$groupby = (!empty($groupby)) ? $groupby : "host";
$order = get_input('order');
    $qstring .= "&order=$order";
if ($orderby) {
    $where.= " ORDER BY $orderby";  
}
if ($order) {
    $where.= " $order";  
}

$graphtype = get_input('graphtype');
    $qstring .= "&graphtype=$graphtype";

// ------------------------------------------------------
// END Ad-hoc chart variables
// ------------------------------------------------------

// ------------------------------------------------------
// BEGIN Chart Generation
// ------------------------------------------------------
switch ($chartId) {

    case "chart_mpm":
    $title = new title( "Last Hour" );
    $bar = new line();
    $bar2 = new line();
    // -------------------------
    // Get Messages Per Minute 
    // -------------------------
    $array = array(1);
    $avg = array();
    $hm = array();
    $sql = "SELECT name,value,updatetime, (SELECT ROUND(SUM(value)/60) FROM cache WHERE name LIKE 'chart_mpm_%') AS avg FROM cache WHERE name LIKE 'chart_mpm_%' AND updatetime BETWEEN NOW() - INTERVAL 59 MINUTE and NOW() - INTERVAL 0 MINUTE ORDER BY updatetime ASC";
    $queryresult = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    while ($line = fetch_array($queryresult)) {
        $hms[] = preg_replace('/.*(\d\d):(\d\d):\d\d$/m', "$1:$2", $line['updatetime']);
        $count = intval($line['value']);
        if (!is_int($count)) {
            $count = 0;
        }
        $array[] = $count;
        $v = intval($line['avg']);
        if (is_int($v)){
            $avg[] = $v;
        }
    }
    if (empty($array)) $array[] = 0;
    $bar->set_values( $array );
    // Not sure why tooltip isn't working...
    $bar->set_tooltip("#val#<br>Average [#x_label#]");
    $bar2->set_values( ($avg) );
    $bar2->set_colour( "#40FF40" );
    $bar2->set_tooltip("#val#<br>Average [#x_label#]");
    $chart = new open_flash_chart();
    $chart->set_title( $title );
    $chart->add_element( $bar );
    $chart->add_element( $bar2 );
    //
    // create a Y Axis object
    //
    $y = new y_axis();
    // grid steps:
    $y->set_range( 0, max($array), round(max($array)/10));
    $chart->set_y_axis( $y );
    $x_labels = new x_axis_labels();
    $x_labels->set_vertical();
    $x_labels->set_labels( $hms );
    $x = new x_axis();
    $x->set_labels( $x_labels );
    $chart->set_x_axis( $x );
    echo $chart->toPrettyString();
    break;

    case "chart_mps":
        $title = new title( "Last Minute" );
    $bar = new line();
    $bar2 = new line();
    // -------------------------
    // Get Messages Per Second 
    // Alternate method - this will smooth out all the spikes:
    // select round(SUM(counter)/30) as count from logs where lo BETWEEN NOW() - INTERVAL 30 SECOND and NOW() - INTERVAL 0 SECOND;
    // -------------------------
    $array = array(1);
    $avg = array();
    $hms = array();
    $sql = "SELECT name,value,updatetime, (SELECT ROUND(SUM(value)/(SELECT count(*) FROM cache WHERE name LIKE 'chart_mps_%')) FROM cache WHERE name LIKE 'chart_mps_%') AS avg FROM cache WHERE name LIKE 'chart_mps_%' AND updatetime BETWEEN NOW() - INTERVAL 59 SECOND and NOW() - INTERVAL 0 SECOND ORDER BY updatetime ASC";
    $queryresult = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    while ($line = fetch_array($queryresult)) {
        $hms[] = preg_replace('/.*(\d\d):(\d\d):(\d\d)$/m', "$1:$2:$3", $line['updatetime']);
        $count = intval($line['value']);
        if (!is_int($count)) {
            $count = 0;
        }
        $array[] = $count;
        $v = intval($line['avg']);
        if (is_int($v)){
            $avg[] = $v;
        }
    }
    if (empty($array)) $array[] = 0;
    $bar->set_values( $array );
    // Not sure why tooltip isn't working...
    $bar->set_tooltip("#val#<br>Average [#x_label#]");
    $bar2->set_values( ($avg) );
    $bar2->set_colour( "#40FF40" );
    $bar2->set_tooltip("#val#<br>Average [#x_label#]");
    $chart = new open_flash_chart();
    $chart->set_title( $title );
    $chart->add_element( $bar );
    $chart->add_element( $bar2 );
    //
    // create a Y Axis object
    //
    $y = new y_axis();
    // grid steps:
    $y->set_range( 0, max($array), round(max($array)/10));
    $chart->set_y_axis( $y );
    $x_labels = new x_axis_labels();
    $x_labels->set_vertical();
    $x_labels->set_labels( $hms );
    $x = new x_axis();
    $x->set_labels( $x_labels );
    $chart->set_x_axis( $x );
    echo $chart->toPrettyString();
    break;

    case "chart_mmo":
        $title = new title( date("D M d Y") );
    $bar = new bar_rounded_glass();
   	// -------------------------
   	// Get Messages Per Month
   	// -------------------------
   	$array = array();
    // Below will update today every time the page is refreshed, otherwise we get stale data
    $sql = "REPLACE INTO cache (name,value,updatetime)  SELECT CONCAT('chart_mmo_',DATE_FORMAT(NOW(), '%Y-%m_%b')), SUM(counter), NOW() from ".$_SESSION['TBL_MAIN']." where lo BETWEEN CONCAT(CURDATE(), ' 00:00:00') - INTERVAL 1 MONTH AND CONCAT(CURDATE(), ' 23:59:59');";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
   	for($i = 0; $i<=12 ; $i++) {
		// Check cache first
		$sql = "SELECT name, value, updatetime FROM cache WHERE name=CONCAT('chart_mmo_',DATE_FORMAT(NOW() - INTERVAL $i MONTH, '%Y-%m_%b'))";
	   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	   	if(num_rows($result) > 0) {
		   	while ($line = fetch_array($result)) {
			   	$pieces = explode("_", $line['name']);
				$date = explode("-", $pieces[2]);
			   	$days[] = $pieces[3].", ".$date[0];
			   	$array[] = intval($line['value']);
		   	}
	   	} else {
		   	// Insert into cache if it doesn't exist, then select the data from cache
		   	$sql = "INSERT INTO cache (name,value,updatetime)  SELECT CONCAT('chart_mmo_',DATE_FORMAT(NOW() - INTERVAL $i MONTH, '%Y-%m_%b')), SUM(counter) as count, NOW() from ".$_SESSION['TBL_MAIN']." where lo BETWEEN CONCAT(CURDATE(), ' 00:00:00') - INTERVAL $i MONTH and CONCAT(CURDATE(), ' 23:59:59') - INTERVAL $i MONTH ON duplicate KEY UPDATE updatetime=NOW()";
		   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
		$sql = "SELECT name, value, updatetime FROM cache WHERE name=CONCAT('chart_mmo_',DATE_FORMAT(NOW() - INTERVAL $i MONTH, '%Y-%m_%b'))";
		   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
		   	while ($line = fetch_array($result)) {
			   	$pieces = explode("_", $line['name']);
				$date = explode("-", $pieces[2]);
			   	$days[] = $pieces[3].", ".$date[0];
			   	$array[] = intval($line['value']);
		   	}
	   	}
	}
	// Delete any old entries
   	$sql = "DELETE FROM cache WHERE name like 'chart_mmo%' AND updatetime< NOW() - INTERVAL ".$_SESSION['CHART_MPD_DAYS']." MONTH";
   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	// Set bar values
   	$bar->set_values( array_reverse($array) );
   	$chart = new open_flash_chart();
   	$chart->set_title( $title );
   	$chart->add_element( $bar );
   	//
   	// create a Y Axis object
   	//
   	$y = new y_axis();
   	// grid steps:
   	$y->set_range( 0, max($array), round(max($array)/10));
   	$chart->set_y_axis( $y );

	$x_labels = new x_axis_labels();
   	$x_labels->set_vertical();
   	$x_labels->set_labels( array_reverse($days) );
   	$x = new x_axis();
   	$x->set_labels( $x_labels );
   	$chart->set_x_axis( $x );
	/*
   	$m = new ofc_menu("#E0E0ff", "#707070");
   	$m->values(array(new ofc_menu_item_camera('Save Image','save_image')));
   	$chart->set_menu($m);
	*/
	echo $chart->toPrettyString();
    break;

    case "chart_mpd":
        $title = new title( date("D M d Y") );
    $bar = new bar_rounded_glass();
   	// -------------------------
   	// Get Messages Per Day
   	// -------------------------
   	$array = array();
    // Below will update today every time the page is refreshed, otherwise we get stale data
    $sql = "REPLACE INTO cache (name,value,updatetime)  SELECT CONCAT('chart_mpd_',DATE_FORMAT(NOW(), '%Y-%m-%d_%a')), SUM(counter), NOW() from ".$_SESSION['TBL_MAIN']." where lo BETWEEN CONCAT(CURDATE(), ' 00:00:00') AND CONCAT(CURDATE(), ' 23:59:59');";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
   	for($i = 0; $i<=$_SESSION['CHART_MPD_DAYS'] ; $i++) {
		// Check cache first
		$sql = "SELECT name, value, updatetime FROM cache WHERE name=CONCAT('chart_mpd_',DATE_FORMAT(NOW() - INTERVAL $i DAY, '%Y-%m-%d_%a'))";
	   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	   	if(num_rows($result) > 0) {
		   	while ($line = fetch_array($result)) {
			   	$pieces = explode("_", $line['name']);
				$date = explode("-", $pieces[2]);
			   	$days[] = $pieces[3].", ".$date[2];
			   	$array[] = intval($line['value']);
		   	}
	   	} else {
		   	// Insert into cache if it doesn't exist, then select the data from cache
		   	$sql = "INSERT INTO cache (name,value,updatetime)  SELECT CONCAT('chart_mpd_',DATE_FORMAT(NOW() - INTERVAL $i DAY, '%Y-%m-%d_%a')), SUM(counter) as count, NOW() from ".$_SESSION['TBL_MAIN']." where lo BETWEEN CONCAT(CURDATE(), ' 00:00:00') - INTERVAL $i DAY and CONCAT(CURDATE(), ' 23:59:59') - INTERVAL $i DAY ON duplicate KEY UPDATE updatetime=NOW()";
		   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
		$sql = "SELECT name, value, updatetime FROM cache WHERE name=CONCAT('chart_mpd_',DATE_FORMAT(NOW() - INTERVAL $i DAY, '%Y-%m-%d_%a'))";
		   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
		   	while ($line = fetch_array($result)) {
			   	$pieces = explode("_", $line['name']);
				$date = explode("-", $pieces[2]);
			   	$days[] = $pieces[3].", ".$date[2];
			   	$array[] = intval($line['value']);
		   	}
	   	}
	}
	// Delete any old entries
   	$sql = "DELETE FROM cache WHERE name like 'chart_mpd%' AND updatetime< NOW() - INTERVAL ".$_SESSION['CHART_MPD_DAYS']." DAY";
   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	// Set bar values
   	$bar->set_values( array_reverse($array) );
   	$chart = new open_flash_chart();
   	$chart->set_title( $title );
   	$chart->add_element( $bar );
   	//
   	// create a Y Axis object
   	//
   	$y = new y_axis();
   	// grid steps:
   	$y->set_range( 0, max($array), round(max($array)/10));
   	$chart->set_y_axis( $y );

	$x_labels = new x_axis_labels();
   	$x_labels->set_vertical();
   	$x_labels->set_labels( array_reverse($days) );
   	$x = new x_axis();
   	$x->set_labels( $x_labels );
   	$chart->set_x_axis( $x );
	/*
   	$m = new ofc_menu("#E0E0ff", "#707070");
   	$m->values(array(new ofc_menu_item_camera('Save Image','save_image')));
   	$chart->set_menu($m);
	*/
	echo $chart->toPrettyString();
    break;

    case "chart_mpw":
        $title = new title( date("D M d Y") );
    $bar = new bar_rounded_glass();
    // -------------------------
    // Get Messages Per Week
    // -------------------------
    $array = array();
    // Get the starting day of the week for your region
    $SoW = $_SESSION['CHART_SOW'];
    if ($SoW == "Sun") {
        $SoW = 1;
    } else {
        $SoW = 2;
    }
    // Below will update this week every time the page is refreshed, otherwise we get stale data
    $sql = "REPLACE INTO cache (name,value,updatetime) SELECT CONCAT('chart_mpw_',(DATE_ADD(CURDATE(),INTERVAL($SoW-DAYOFWEEK(CURDATE()))DAY))), SUM(counter), NOW() from $_SESSION[TBL_MAIN] where lo>=(DATE_ADD(CURDATE(),INTERVAL($SoW-DAYOFWEEK(CURDATE()))DAY))";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);

    // Now process the rest
    for($i = 0; $i<=$_SESSION['CACHE_CHART_MPW'] ; $i++) {
        // Check cache first
		$sql = "SELECT name, value, updatetime FROM cache WHERE name=CONCAT('chart_mpw_',(DATE_ADD(CURDATE() - INTERVAL $i WEEK,INTERVAL($SoW-DAYOFWEEK(CURDATE() - INTERVAL $i WEEK))DAY)))";
	   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	   	if(num_rows($result) > 0) {
		   	while ($line = fetch_array($result)) {
			   	$pieces = explode("_", $line['name']);
				$date = $pieces[2];
                // Below sets X labels
			   	$xlabels[] = $date;
			   	$array[] = intval($line['value']);
		   	}
        } else {
            // Insert into cache if it doesn't exist, then select the data from cache
            $sql = "INSERT INTO cache (name,value,updatetime) SELECT CONCAT('chart_mpw_',(DATE_ADD(CURDATE() - INTERVAL $i WEEK,INTERVAL($SoW-DAYOFWEEK(CURDATE() - INTERVAL $i WEEK))DAY))), SUM(counter), NOW() from $_SESSION[TBL_MAIN] where lo BETWEEN (DATE_ADD(CURDATE() - INTERVAL $i WEEK,INTERVAL($SoW-DAYOFWEEK(CURDATE() - INTERVAL $i WEEK))DAY)) AND (DATE_ADD(CURDATE() - INTERVAL ".$i++." WEEK,INTERVAL($SoW-DAYOFWEEK(CURDATE() - INTERVAL ".$i++." WEEK))DAY)) ON duplicate KEY UPDATE updatetime=NOW()";
                $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
		$sql = "SELECT name, value, updatetime FROM cache WHERE name=CONCAT('chart_mpw_',(DATE_ADD(CURDATE() - INTERVAL $i WEEK,INTERVAL($SoW-DAYOFWEEK(CURDATE() - INTERVAL $i WEEK))DAY)))";
		   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
		   	while ($line = fetch_array($result)) {
			   	$pieces = explode("_", $line['name']);
				$date = $pieces[3];
                // Below sets X labels
			   	$xlabels[] = $date;
			   	$array[] = intval($line['value']);
		   	}
	   	}
	}
	// Delete any old entries
   	$sql = "DELETE FROM cache WHERE name like 'chart_mpw%' AND updatetime< NOW() - INTERVAL ".$_SESSION['CACHE_CHART_MPW']." WEEK";
   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	// Set bar values
   	$bar->set_values( array_reverse($array) );
   	$chart = new open_flash_chart();
   	$chart->set_title( $title );
   	$chart->add_element( $bar );
   	//
   	// create a Y Axis object
   	//
   	$y = new y_axis();
   	// grid steps:
   	$y->set_range( 0, max($array), round(max($array)/10));
   	$chart->set_y_axis( $y );

	$x_labels = new x_axis_labels();
   	$x_labels->set_vertical();
   	$x_labels->set_labels( array_reverse($xlabels) );
   	$x = new x_axis();
   	$x->set_labels( $x_labels );
   	$chart->set_x_axis( $x );
	/*
   	$m = new ofc_menu("#E0E0ff", "#707070");
   	$m->values(array(new ofc_menu_item_camera('Save Image','save_image')));
   	$chart->set_menu($m);
	*/
	echo $chart->toPrettyString();
    break;

    case "chart_mph":
        $title = new title( "Last Day" );
    $bar = new bar_rounded_glass();
    $bar2 = new line();
   	// -------------------------
    // Get Messages Per Hour
    // -------------------------
    $array = array();
    $avg = array();
    $hms = array();
    $sql = "SELECT name,value,updatetime, (SELECT ROUND(SUM(value)/24) FROM cache WHERE name LIKE 'chart_mph_%') AS avg, DATE_FORMAT(updatetime, '%a-%h%p') as DH FROM cache WHERE name LIKE 'chart_mph_%' AND updatetime BETWEEN NOW() - INTERVAL 23 HOUR and NOW() - INTERVAL 0 HOUR ORDER BY updatetime ASC";
    $queryresult = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    while ($line = fetch_array($queryresult)) {
        // $hms[] = preg_replace('/.*(\d\d):\d\d:\d\d$/m', "$1", $line['updatetime']);
        $hms[] = $line['DH'];
        $count = intval($line['value']);
        if (!is_int($count)) {
            $count = 0;
        }
        $array[] = $count;
        $v = intval($line['avg']);
        if (is_int($v)){
            $avg[] = $v;
        }
    }
    if (empty($array)) $array[] = 0;
    $bar->set_values( $array );
    // $bar->set_tooltip("#val#<br>Average MPS = ".commify($avg[0]));
    $bar2->set_values( ($avg) );
    $bar2->set_colour( "#40FF40" );
    $bar2->set_tooltip("#val#<br>Average [#x_label#]");
    $chart = new open_flash_chart();
    $chart->set_title( $title );
    $chart->add_element( $bar );
    $chart->add_element( $bar2 );
    //
    // create a Y Axis object
    //
    $y = new y_axis();
    // grid steps:
    $y->set_range( 0, max($array), round(max($array)/10));
    $chart->set_y_axis( $y );
    $x_labels = new x_axis_labels();
    $x_labels->set_vertical();
    $x_labels->set_labels( $hms );
    $x = new x_axis();
    $x->set_labels( $x_labels );
    $chart->set_x_axis( $x );
    echo $chart->toPrettyString();
    break;

    case "chart_tophosts":
        $title = new title( date("D M d Y") );
   	// -------------------------
   	// Get Top 10 hosts
   	// -------------------------
   	$pie = new pie();
   	// Check cache first
   	$sql = "SELECT name, value, updatetime FROM cache WHERE name like 'chart_tophosts%' AND updatetime> NOW() - INTERVAL ".$_SESSION['CACHE_CHART_TOPHOSTS']." MINUTE";
   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
   	if(num_rows($result) >= 1) {
	   	while ($line = fetch_array($result)) {
		   	$pieces = explode("_", $line['name']);
		   	$hosts[] = explode("-", $pieces[2]);
		   	$count[] = intval($line['value']);
		   	$array[] = new pie_value(intval($line['value']),  $pieces[2]);
	   	}
   	} else {
	   	// Insert into cache if it doesn't exist, then select the data from cache
	   	$sql = "INSERT INTO cache (name,value,updatetime) SELECT CONCAT('chart_tophosts_',host), SUM(counter) as count, NOW() from ".$_SESSION['TBL_MAIN']." GROUP BY host ORDER BY count DESC LIMIT 10 ON duplicate KEY UPDATE updatetime=NOW()";
	   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	   	$sql = "SELECT name, value, updatetime FROM cache WHERE name like 'chart_tophosts%' AND updatetime> NOW() - INTERVAL ".$_SESSION['CACHE_CHART_TOPHOSTS']." MINUTE";
	   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	   	while ($line = fetch_array($result)) {
		   	$pieces = explode("_", $line['name']);
		   	$hosts[] = explode("-", $pieces[2]);
		   	$count[] = intval($line['value']);
		   	$array[] = new pie_value(intval($line['value']),  $pieces[2]);
	   	}
   	}
	// Delete any old entries
   	$sql = "DELETE FROM cache WHERE name like 'chart_tophosts%' AND updatetime< NOW() - INTERVAL ".$_SESSION['CACHE_CHART_TOPHOSTS']." MINUTE";
   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	// Set random pie colors
   	for($i = 0; $i<=count($array) ; $i++) {
	$colors[] = '#'.random_hex_color(); // 09B826
	}

   	$pie->set_alpha(0.5);
	$pie->add_animation( new pie_fade() );
	$pie->add_animation( new pie_bounce(5) );
	// $pie->start_angle( 270 )
	$pie->start_angle( 0 );
	$pie->set_tooltip( '#label#<br>#val# of #total#<br>#percent# of top 10 hosts' );
	$pie->radius(80);
	$pie->set_colours( $colors );
    $pie->on_click('pie_slice_clicked');
	$pie->set_values( $array );
	$chart = new open_flash_chart();
	// $chart->set_title( $title );
	$chart->add_element( $pie );
	echo $chart->toPrettyString();
    break;

    case "chart_topmsgs":
        $title = new title( date("D M d Y") );
   	// -------------------------
   	// Get Top 10 Messages
   	// -------------------------
   	$pie = new pie();
   	$sql = "SELECT name, value, updatetime FROM cache WHERE name like 'chart_topmsgs%' AND updatetime> NOW() - INTERVAL ".$_SESSION['CACHE_CHART_TOPMSGS']." MINUTE";
   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
   	if(num_rows($result) >= 1) {
	   	while ($line = fetch_array($result)) {
			$msg = ltrim($line['name'], "chart_topmsgs_");
		   	$count[] = intval($line['value']);
		   	$wrapmsg = wordwrap($msg, 60, "\n");
		   	$array[] = new pie_value(intval($line['value']),  $wrapmsg);
	   	}
   	} else {
	   	// Insert into cache if it doesn't exist, then select the data from cache
   	$sql = "INSERT INTO cache (name,value,updatetime) SELECT CONCAT('chart_topmsgs_',msg), SUM(counter) AS count, NOW() FROM ".$_SESSION['TBL_MAIN']." GROUP BY msg ORDER BY count DESC LIMIT 10 ON duplicate KEY UPDATE updatetime=NOW()";
	   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	   	$sql = "SELECT name, value, updatetime FROM cache WHERE name like 'chart_topmsgs%' AND updatetime> NOW() - INTERVAL ".$_SESSION['CACHE_CHART_TOPMSGS']." MINUTE";
	   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	   	while ($line = fetch_array($result)) {
			$msg = ltrim($line['name'], "chart_topmsgs_");
		   	$count[] = intval($line['value']);
		   	$wrapmsg = wordwrap($msg, 60, "\n");
		   	$array[] = new pie_value(intval($line['value']),  $wrapmsg);
	   	}
   	}
	// Delete any old entries
   	$sql = "DELETE FROM cache WHERE name like 'chart_topmsgs%' AND updatetime< NOW() - INTERVAL ".$_SESSION['CACHE_CHART_TOPMSGS']." MINUTE";
   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	// Generate random pie colors
   	for($i = 0; $i<=count($array) ; $i++) {
	$colors[] = '#'.random_hex_color(); // 09B826
	}

   	$pie->set_alpha(0.5);
	$pie->add_animation( new pie_fade() );
	$pie->add_animation( new pie_bounce(5) );
	// $pie->start_angle( 270 )
	$pie->start_angle( 0 );
	$pie->set_tooltip( '#label#<br>#val# of #total#<br>#percent# of top 10 messages' );
	$pie->radius(80);
	$pie->set_colours( $colors );
	$pie->set_values( $array );
	$chart = new open_flash_chart();
	// $chart->set_title( $title );
	$chart->add_element( $pie );
	echo $chart->toPrettyString();
    break;

    // Default is to generate an Ad-hoc chart
    default:
    $chartType = get_input('chartType');
    $chartType = (!empty($chartType)) ? $chartType : "pie";
    $sql = "SELECT id, host, facility, priority, tag, program, msg, counter, fo, lo, notes, SUM(counter) as count FROM ".$_SESSION['TBL_MAIN']." $where GROUP BY $groupby ORDER BY count LIMIT $limit";
    $title = new title( date("D M d Y") );
    $ctype = new pie();
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    if(num_rows($result) >= 1) {
        while ($line = fetch_array($result)) {
            $hosts[] = $line['host'];
            $pievalues[] = new pie_value(intval($line['count']),  $line['host']);
        }
    }
    // Generate random pie colors
    for($i = 0; $i<=count($pievalues) ; $i++) {
        $colors[] = '#'.random_hex_color(); // 09B826
    }

    $ctype->set_alpha(0.5);
    $ctype->add_animation( new pie_fade() );
    $ctype->add_animation( new pie_bounce(5) );
    // $ctype->start_angle( 270 )
    $ctype->start_angle( 0 );
	$ctype->set_tooltip( "#label#<br>#val# of #total#<br>#percent# of top $limit hosts" );
	$ctype->radius(80);
	$ctype->set_colours( $colors );
	$ctype->set_values( $pievalues );
	$chart = new open_flash_chart();
	// $chart->set_title( $title );
	$chart->add_element( $ctype );
	echo $chart->toPrettyString();
}

// ------------------------------------------------------
// END Chart Generation
// ------------------------------------------------------
?>
