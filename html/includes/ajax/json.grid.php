<?php
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

$page = $_POST['page']; // get the requested page 
$limit = $_POST['rows']; // get how many rows we want to have into the grid 
$sidx = $_POST['sidx']; // get index row - i.e. user click to sort 
$sord = $_POST['sord']; // get the direction 
$searchField = $_POST['searchField'];
$searchString = $_POST['searchString'];
$grid = $_GET['grid']; // get the requested page

if(!$sidx) $sidx =1; // connect to the database


if(isset($_GET["host_mask"]) && $_GET["host_mask"] !== "null" && $_GET["host_mask"] !== "undefined" && $_GET["host_mask"] !== "Host Filter") $host_mask = $_GET['host_mask']; 
else $host_mask = ""; 
if(isset($_GET["facility_mask"]) && $_GET["facility_mask"] !== "null" && $_GET["facility_mask"] !== "undefined" && $_GET["facility_mask"] !== "Facility Filter") $facility_mask = $_GET['facility_mask']; 
else $facility_mask = ""; 
if(isset($_GET["priority_mask"]) && $_GET["priority_mask"] !== "null" && $_GET["priority_mask"] !== "undefined" && $_GET["priority_mask"] !== "Priority Filter") $priority_mask = $_GET['priority_mask']; 
else $priority_mask = ""; 
if(isset($_GET["program_mask"]) && $_GET["program_mask"] !== "null" && $_GET["program_mask"] !== "undefined" && $_GET["program_mask"] !== "Program Filter") $program_mask = $_GET['program_mask']; 
else $program_mask = ""; 
if(isset($_GET["msg_mask"]) && $_GET["msg_mask"] !== "null" && $_GET["msg_mask"] !== "undefined" && $_GET["msg_mask"] !== "Message Filter") $msg_mask = msg_encode($_GET['msg_mask']); 
else $msg_mask = ""; 
if(isset($_GET["fo_mask"]) && $_GET["fo_mask"] !== "null" && $_GET["fo_mask"] !== "undefined" && $_GET["fo_mask"] !== "FO Filter") $fo_mask = $_GET['fo_mask']; 
else $fo_mask = ""; 
if(isset($_GET["lo_mask"]) && $_GET["lo_mask"] !== "null" && $_GET["lo_mask"] !== "undefined" && $_GET["lo_mask"] !== "LO Filter") $lo_mask = $_GET['lo_mask']; 
else $lo_mask = ""; 
if(isset($_GET["counter_mask"]) && $_GET["counter_mask"] !== "null" && $_GET["counter_mask"] !== "undefined" && $_GET["counter_mask"] !== "Count Filter") $counter_mask = $_GET['counter_mask']; 
else $counter_mask = ""; 
if(isset($_GET["notes_mask"]) && $_GET["notes_mask"] !== "null" && $_GET["notes_mask"] !== "undefined" && $_GET["notes_mask"] !== "Notes Filter") $notes_mask = $_GET['notes_mask']; 
else $notes_mask = ""; 
if(isset($_GET["dupop"]) && $_GET["dupop"] !== "null" && $_GET["dupop"] !== "undefined") $dupop = $_GET['dupop']; 
if(isset($_GET["fo_date_mask"]) && $_GET["fo_date_mask"] !== "null" && $_GET["fo_date_mask"] !== "undefined") $fo_date_mask = $_GET['fo_date_mask']; 
if(isset($_GET["fo_time_start"]) && $_GET["fo_time_start"] !== "null" && $_GET["fo_time_start"] !== "undefined") $fo_time_start = $_GET['fo_time_start']; 
if(isset($_GET["fo_time_end"]) && $_GET["fo_time_end"] !== "null" && $_GET["fo_time_end"] !== "undefined") $fo_time_end = $_GET['fo_time_end']; 
else $fo_time_end = "";
if(isset($_GET["lo_date_mask"]) && $_GET["lo_date_mask"] !== "null" && $_GET["lo_date_mask"] !== "undefined") $lo_date_mask = $_GET['lo_date_mask']; 
if(isset($_GET["lo_time_start"]) && $_GET["lo_time_start"] !== "null" && $_GET["lo_time_start"] !== "undefined") $lo_time_start = $_GET['lo_time_start']; 
if(isset($_GET["lo_time_end"]) && $_GET["lo_time_end"] !== "null" && $_GET["lo_time_end"] !== "undefined") $lo_time_end = $_GET['lo_time_end']; 
else $lo_time_end = "";
if(isset($_GET["date_andor"])) $date_andor = $_GET['date_andor']; 
if(isset($_GET["program_andor"])) $program_andor = $_GET['program_andor']; 
if(isset($_GET["priorities_andor"])) $priorities_andor = $_GET['priorities_andor']; 
if(isset($_GET["facilities_andor"])) $facilities_andor = $_GET['facilities_andor']; 
if(isset($_GET["fo_check"])) $fo_check = $_GET['fo_check']; 
if(isset($_GET["lo_check"])) $lo_check = $_GET['lo_check']; 
if(isset($_GET["order"])) $sord = $_GET['order']; 
if(isset($_GET["orderby"])) $sidx = $_GET['orderby']; 

/*
   if (LOG_QUERIES == 'TRUE') {
   $myFile = MYSQL_QUERY_LOG;
   $fh = fopen($myFile, 'a') or die("can't open file $myFile");
   fwrite($fh, print_r($_GET));
   fclose($fh);
   }
 */

//construct where clause 
$where = "WHERE 1=1";

if (strpos($host_mask, ',') !== false) {
    $where = "WHERE 1<1"; 
    $pieces = explode(",", $host_mask);
    foreach ($pieces as $mask) {
        $where.= " OR host RLIKE '$mask'"; 
    }
} elseif($host_mask!='') {
    $where.= " AND host RLIKE '$host_mask'"; 
}

if (strpos($facility_mask, ',') !== false) {
    $where = "WHERE 1<1"; 
    $pieces = explode(",", $facility_mask);
    foreach ($pieces as $mask) {
        $where.= " OR facility RLIKE '$mask'";  
    }
} elseif($facility_mask!='') {
    $where.= " AND facility RLIKE '$facility_mask'";  
}


if (strpos($priority_mask, ',') !== false) {
    $where = "WHERE 1<1"; 
    $pieces = explode(",", $priority_mask);
    foreach ($pieces as $mask) {
        $where.= " OR priority RLIKE '$mask'";  
    }
} elseif($priority_mask!='') {
    $where.= " AND priority RLIKE '$priority_mask'";  
}

if (strpos($program_mask, ',') !== false) {
    $where = "WHERE 1<1"; 
    $pieces = explode(",", $program_mask);
    foreach ($pieces as $mask) {
        $where.= " OR program RLIKE '$mask'";  
    }
} elseif($program_mask!='') {
    $where.= " AND program RLIKE '$program_mask'";  
}
if(($msg_mask!='') && ($msg_mask!=='00')) $where.= " AND msg RLIKE '".$msg_mask."'"; 

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
if($counter_mask!='') {
    if ($dupop != '') {
        $where.= " AND counter $dupop '$counter_mask'"; 
    }
 }
if($notes_mask!='') $where.= " AND notes RLIKE '$notes_mask'";
//------------------------------------------------------------
// START date/time
//------------------------------------------------------------
if($date_andor == "0") {
    $date_andor = "AND";
} else {
    $date_andor = "OR";
}
// FO
if ($fo_check == "true") {
    if($fo_date_mask!='') {
        list($start,$end) = explode(' to ', $fo_date_mask);
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
if ($lo_check == "true") {
    if($lo_date_mask!='') {
        list($start,$end) = explode(' to ', $lo_date_mask);
        if($end=='') $end = "$start" ; 
        if($lo_time_start!=$lo_time_end) {
            $start .= " $lo_time_start"; 
            $end .= " $lo_time_end"; 
        }
            $where.= " $date_andor lo BETWEEN '$start' AND '$end'";
    }
}
//------------------------------------------------------------
// END date/time
//------------------------------------------------------------

$count = get_total_rows($_SESSION['TBL_MAIN'], $dbLink, "$where");

if( $count >0 ) { 
    $total_pages = ceil($count/$limit); 
    if ($page > $total_pages) $page=$total_pages; 
    $start = $limit*$page - $limit; // do not put $limit*($page - 1) 
    $response->page = $page; 
    $response->total = $total_pages; 
    $response->records = $count;

    if ($grid == "hosts") {
        // $sql = "SELECT DISTINCT(host) FROM ".$_SESSION['TBL_MAIN'] ." $where ORDER BY $sidx $sord LIMIT $start , $limit";  
        $sql = "SELECT * FROM (SELECT DISTINCT host FROM ".$_SESSION['TBL_MAIN'] ." GROUP BY host) AS result $where ORDER BY $sidx $sord LIMIT $start , $limit"; 
    } else {
        $sql = "SELECT * FROM ".$_SESSION['TBL_MAIN'] ." $where ORDER BY $sidx $sord LIMIT $start , $limit";  
    }
    $result = perform_query($sql, $dbLink, $_REQUEST['pageId']); 
    $i=0; 
    while($row = fetch_array($result)) { 
		$msg = msg_decode($row[msg]);
        $response->rows[$i]['id']=$row[id]; 
        $response->rows[$i]['cell']=array($row[host],$row[facility],$row[priority],$row[program],$msg,$row['fo'],$row['lo'],$row['counter'],$row[notes]); 
        $i++; 
    } 
} else { 
    // No results returned, display nothing...
    $total_pages = 0; 
    $response->total = $total_pages; 
} 
echo json_encode($response); 
mysql_close($dbLink);
?>
