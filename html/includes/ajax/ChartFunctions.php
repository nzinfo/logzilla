<script type="text/javascript">
$(document).ready(function(){
// Get rid of the portlet header for Chart displays
$('.portlet-header').remove()
}); //end doc ready
</script>
<?php 
function mpm(){
	global $dbLink;
    $chartId = "chart_mpm";
	  $title =  "Last Hour" ;
    // -------------------------
    // Get Messages Per Minute 
    // -------------------------
    $array = array(1);
    $avg = array();
    $hm = array();
	$f = FALSE;
    $sql = "SELECT name,value,updatetime, (SELECT ROUND(SUM(value)/60) FROM cache WHERE name LIKE 'chart_mpm_%') AS avg FROM cache WHERE name LIKE 'chart_mpm_%' AND updatetime BETWEEN NOW() - INTERVAL 59 MINUTE and NOW() - INTERVAL 0 MINUTE ORDER BY updatetime ASC";
    $queryresult = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    while ($line = fetch_array($queryresult)) {
    	if($f)$hms[] = "";
		else 			
        	$hms[] = preg_replace('/.*(\d\d):(\d\d):\d\d$/m', "$2", $line['updatetime']);
		$f = !$f;
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
    $hms[] = " ";
	$tchart = new jqNewChart("line",$array,$title,"MPM",$hms);
	$tchart->chartData($avg,"average");
	$tchart->setXAxisData($hms);
	//print_r($hms);
	//$tchart->rotateXLabels(-90,205,-190,'right',"bold 10px");
	
	$tchart->setMarker(false);
	$tchart->setTooltip(" return this.point.y + ' events'");
	echo $tchart->renderChart($chartId);	
}

function mph(){
		global $dbLink;
        $chartId = "chart_mph";	
        $title =  "Last Day" ;    
   	// -------------------------
    // Get Messages Per Hour
    // -------------------------
    $array = array();
    $avg = array();
    $hms = array();
	$d = "";
    $sql = "SELECT name,value,updatetime, (SELECT ROUND(SUM(value)/24) FROM cache WHERE name LIKE 'chart_mph_%') AS avg, DATE_FORMAT(updatetime, '%a-%h%p') as DH FROM cache WHERE name LIKE 'chart_mph_%' AND updatetime BETWEEN NOW() - INTERVAL 23 HOUR and NOW() - INTERVAL 0 HOUR ORDER BY updatetime ASC";
    $queryresult = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    while ($line = fetch_array($queryresult)) {
        // $hms[] = preg_replace('/.*(\d\d):\d\d:\d\d$/m', "$1", $line['updatetime']);
        $s = explode("-",$line['DH']);
		
		//if($s[0] != $d)
		{
			$d = $s[0];
			$o = "<b>".$d."</b><br>" ;			 			
		}
		
		//$o .= str_replace("PM","<br>PM",$s[1]);
		//$o = str_replace("AM","<br>AM",$o);
		
        $hms[] = $o.$s[1];//str_replace("-", "<br>", $line['DH']);
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
    if (empty($hms)) $hms[] = "No Data to Display";

	$tchart = new jqNewChart("column",$array,$title," ",$hms);
    /*echo "<br><br><pre>";
    print_r($hms);
    die();
    */
	$tchart->setXAxisData($hms,"return this.value.replace('PM' , '<br/>PM').replace('AM' , '<br/>AM');");
	//$tchart->rotateXLabels(-45,140,-40,'right',"bold 10px");
	
	$tchart->setTooltip(" return this.x.replace('</b><br>','</b> - ') + ' <br/> '+humanReadable(this.y) ");
	
	echo $tchart->renderChart($chartId);
}
  
 function mps(){
 	global $dbLink;
    $chartId = "chart_mps";
    $title =  "Last Minute" ;
    // -------------------------
    // Get Messages Per Second 
    // Alternate method - this will smooth out all the spikes:
    // select round(SUM(counter)/30) as count from logs where lo BETWEEN NOW() - INTERVAL 30 SECOND and NOW() - INTERVAL 0 SECOND;
    // -------------------------
    $array = array(1);
    $avg = array();
    $hms = array();
	$f=TRUE;
	$i = 0;
    $sql = "SELECT name,value,updatetime, (SELECT ROUND(SUM(value)/(SELECT count(*) FROM cache WHERE name LIKE 'chart_mps_%')) FROM cache WHERE name LIKE 'chart_mps_%') AS avg FROM cache WHERE name LIKE 'chart_mps_%' AND updatetime BETWEEN NOW() - INTERVAL 59 SECOND and NOW() - INTERVAL 0 SECOND ORDER BY updatetime ASC";
    $queryresult = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    while ($line = fetch_array($queryresult)) {
        if($f)	
       		 $hms[] = $i;//preg_replace('/.*(\d\d):(\d\d):(\d\d)$/m', "$3", $line['updatetime']);
		else $hms[] = " ";
		$i++;
		$f=!$f;
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

	$tchart = new jqNewChart("areaspline",$array,$title,"MPS",$hms);
	//$tchart->setChartOptions();
	$tchart->chartData($avg,"average");//alert(this.value); return  this value; 
	$tchart->setXAxisData($hms);
	//$tchart->setInterval(";return this.value;" , "js:Date.UTC(2012,1,1,1,1,37)" , 1000);
	//$tchart->setSeriesOption("average","type","spline");
	$tchart->setSeriesOption("average",array("type"=>"spline"));
	

	//$tchart->rotateXLabels(-90,205,-190,'right',"bold 10px");
	$tchart->setMarker(false);
	$tchart->setTooltip(" return this.point.y + ' events'");
		
	echo $tchart->renderChart($chartId);
    
}

function mmo()
{
 	global $dbLink;
    $chartId = "chart_mmo";
    $title =  date("D M d Y") ;
 
   	// -------------------------
   	// Get Messages Per Month
   	// -------------------------
   	
   	
   	$array = array();
    // Below will update today every time the page is refreshed, otherwise we get stale data
    $sql = "REPLACE INTO cache (name,value,updatetime)  SELECT CONCAT('chart_mmo_',DATE_FORMAT(NOW(), '%Y-%m_%b')), (SELECT value from cache where name='msg_sum') as counter, NOW() from ".$_SESSION['TBL_MAIN']." where lo BETWEEN CONCAT(CURDATE(), ' 00:00:00') - INTERVAL 1 MONTH AND CONCAT(CURDATE(), ' 23:59:59') LIMIT 1";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
   	for($i = 0; $i<=12 ; $i++) {
		// Check cache first
		$sql = "SELECT name, value, updatetime FROM cache WHERE name=CONCAT('chart_mmo_',DATE_FORMAT(NOW() - INTERVAL $i MONTH, '%Y-%m_%b'))";
	   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	   	if(num_rows($result) > 0) {
		   	while ($line = fetch_array($result)) {
			   	$pieces = explode("_", $line['name']);
				$date = explode("-", $pieces[2]);
			   	$days[] = $pieces[3]."<br> ".$date[0];
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
			   	$days[] = $pieces[3]."<br> ".$date[0];
			   	$array[] = intval($line['value']);
		   	}
	   	}
	}
	// Delete any old entries
   	$sql = "DELETE FROM cache WHERE name like 'chart_mmo%' AND updatetime< NOW() - INTERVAL ".$_SESSION['CHART_MPD_DAYS']." MONTH";
   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    
 	$tchart = new jqNewChart("column",array_reverse($array),$title," ",array_reverse($days));
 	$tchart->setXAxisData(array_reverse($days));
	//$tchart->rotateXLabels(-45,140,-40,'right',"bold 10px");
	$tchart->setTooltip(" return this.x.replace('<br>',' ') +'<br/>'+ humanReadable(this.point.y) + ' events' ");
	echo $tchart->renderChart($chartId);
    
}

function mpd()
{
 	global $dbLink;
    $chartId = "chart_mpd";
    $title = date("D M d Y") ;
   	// -------------------------
   	// Get Messages Per Day
   	// -------------------------
   	$array = array();
    // Below will update today every time the page is refreshed, otherwise we get stale data
    $sql = "REPLACE INTO cache (updatetime,name, value) SELECT NOW(), CONCAT('chart_mpd_',DATE_FORMAT(NOW(), '%Y-%m-%d_%a')), (SUM(value)/2) FROM cache WHERE name LIKE 'chart_mph_%'";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
   	for($i = 0; $i<=$_SESSION['CHART_MPD_DAYS'] ; $i++) {
		// Check cache first
		$sql = "SELECT name, value, updatetime, (SELECT ROUND(SUM(value)/".$_SESSION['CHART_MPD_DAYS'].") as avg FROM cache WHERE name LIKE 'chart_mpd_%') AS avg FROM cache WHERE name=CONCAT('chart_mpd_',DATE_FORMAT(NOW() - INTERVAL $i DAY, '%Y-%m-%d_%a'))";
	   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	   	if(num_rows($result) > 0) {
		   	while ($line = fetch_array($result)) {
			   	$pieces = explode("_", $line['name']);
				$date = explode("-", $pieces[2]);
			   	$days[] = $date;//$pieces[3].", ".$date[2];
                $array[] = intval($line['value']);//print_r( $date);
       
            }
	   	} else {
		   	// Insert into cache if it doesn't exist, then select the data from cache
		   	$sql = "INSERT INTO cache (name,value,updatetime)  SELECT CONCAT('chart_mpd_',DATE_FORMAT(NOW() - INTERVAL $i DAY, '%Y-%m-%d_%a')), SUM(counter) as count, NOW() from ".$_SESSION['TBL_MAIN']." where lo BETWEEN CONCAT(CURDATE(), ' 00:00:00') - INTERVAL $i DAY and CONCAT(CURDATE(), ' 23:59:59') - INTERVAL $i DAY ON duplicate KEY UPDATE updatetime=NOW()";
		   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
		$sql = "SELECT name, value, updatetime, (SELECT ROUND(SUM(value)/".$_SESSION['CHART_MPD_DAYS'].") as avg FROM cache WHERE name LIKE 'chart_mpd_%') AS avg FROM cache WHERE name=CONCAT('chart_mpd_',DATE_FORMAT(NOW() - INTERVAL $i DAY, '%Y-%m-%d_%a'))";
		   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
		   	while ($line = fetch_array($result)) {
			   	$pieces = explode("_", $line['name']);
				$date = explode("-", $pieces[2]);
			   	$days[] = $pieces[3].", ".$date[2];
			   	$array[] = intval($line['value']);//print_r( $date);
				

            }
	   	}
	}
	// Delete any old entries
   	$sql = "DELETE FROM cache WHERE name like 'chart_mpd%' AND updatetime< NOW() - INTERVAL ".$_SESSION['CHART_MPD_DAYS']." DAY";
   	$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
	
	$tchart = new jqNewChart("column",array_reverse($array),$title,"MPD",array_reverse($days));//print_r( $days[0]);
	
	$tchart->setInterval( "d = new Date(this.value);return d.getDate()+'<br/>'+weekdaystxt[d.getDay()][0];", "js:Date.UTC({$date[0]}, ".($date[1]-1).",".($date[2]+1)." )"	);
							
	//$tchart->rotateXLabels(-55,0,0,'right',"bold 10px");
	$tchart->setTooltip(" d = new Date(this.x); return weekdaystxt[d.getDay()] + ' ' + d.getDate() + ' <br/> '+humanReadable(this.y) + ' events' ");
	echo $tchart->renderChart($chartId);

}

function  mpw()
{
	global $dbLink;
    $chartId = "chart_mpw";
        $title = date("D M d Y");    
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
    $sql = "REPLACE INTO cache (name,value,updatetime) SELECT CONCAT('chart_mpw_',(DATE_ADD(CURDATE(),INTERVAL($SoW-DAYOFWEEK(CURDATE()))DAY))), (SELECT value from cache where name='msg_sum') as count, NOW() from $_SESSION[TBL_MAIN] where lo>=(DATE_ADD(CURDATE(),INTERVAL($SoW-DAYOFWEEK(CURDATE()))DAY)) LIMIT 1";
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
	
	$tchart = new jqNewChart("column",array_reverse($array),$title,"MPW",array_reverse($xlabels));
	$tchart->setXAxisData(array_reverse($xlabels));
	//-$start = explode("-", $date);	
	//-$tchart->setInterval( "d = new Date(this.value);return d.getFullYear()+'-'+(d.getMonth()+1)+'-'+d.getDate();", "js:Date.UTC({$start[0]}, ".($start[1]-1).",".($start[2]+0)." )", 24*3600*1000*7);
	$tchart->addClick(" d = new Date(this.x); alert((d.getFullYear()+'-'+(d.getMonth()+1)+'-'+(d.getDate()+1))  + '   '+ event.point.y);");
	//$tchart->rotateXLabels(-45,140,-40,'right',"bold 10px");
	$tchart->setTooltip(" d = new Date(this.x); return (d.getFullYear()+'-'+(d.getMonth()+1)+'-'+(d.getDate()+1)) + ' <br/> '+humanReadable(this.y)  + ' events' ");
	echo $tchart->renderChart($chartId);
	
   
   }
?>
