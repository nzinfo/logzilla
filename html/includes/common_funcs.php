<?php
// Copyright (C) 2010 Clayton Dukes, cdukes@cdukes.com

error_reporting(E_ALL & ~E_NOTICE);
# ini_set("display_errors", 1);

$basePath = dirname( __FILE__ );
require_once ($basePath ."/../config/config.php");
require_once ($basePath ."/modules/authentication.php");

// ------------------------------
// Grab all settings from the settings table in the database
// ------------------------------
getsettings();

//------------------------------------------------------------------------
// This function returns the current microtime.
//------------------------------------------------------------------------
function get_microtime() {
	list($usec, $sec) = explode(" ", microtime());
	return ((float)$usec + (float)$sec);
}


//------------------------------------------------------------------------
// Function used to retrieve input values and if neccessary add slashes.
//------------------------------------------------------------------------
function get_input($varName, $check_session=true) {
   	$value="";
   	if(isset($_COOKIE[$varName])) {
	   	$value = $_COOKIE[$varName];
   	} elseif(isset($_GET[$varName])) {
	   	$value = $_GET[$varName];
   	} elseif(isset($_POST[$varName])) {
	   	$value = $_POST[$varName];
	/** 
	 * BPK: we can't always use this, else checkboxes never get unset, 
	 * rather let js reload the form at the end of index.php
	 */
   	} elseif($check_session && isset($_SESSION[$varName])) {
	   	$value = $_SESSION[$varName];
   	} 
	if($value && !get_magic_quotes_gpc()) {
	   	if(!is_array($value)) {
		   	$value = addslashes($value);
	   	}
	   	else {
		   	foreach($value as $key => $arrValue) {
			   	$value[$key] = addslashes($arrValue);
		   	}
	   	}
   	}
   	return $value;
}


//------------------------------------------------------------------------
// Function used to validate user supplied variables.
//------------------------------------------------------------------------
function validate_input($value, $regExpName) {
	global $regExpArray;

	if(!$regExpArray[$regExpName]) {
		return FALSE;
	}

	if(is_array($value)) {
		foreach($value as $arrval) {
			if(!preg_match("$regExpArray[$regExpName]", $arrval)) {
				return FALSE;
			}
		}
		return TRUE;
	}
	elseif(preg_match("$regExpArray[$regExpName]", $value)) {
		return TRUE;
	}
	else {
		return FALSE;
	}
}


//========================================================================
// BEGIN DATABASE FUNCTIONS
//========================================================================
//------------------------------------------------------------------------
// This function connects to the MySQL server and selects the database
// specified in the DBNAME parameter. If an error occurs then return
// FALSE.
//------------------------------------------------------------------------
function db_connect_syslog($dbUser, $dbPassword, $connType = 'P') {
	$server_string = DBHOST.":".DBPORT;
	$link = "";
    /* removed pconnect so that LZ uses standard connections that will close more gracefully
	if(function_exists('mysql_pconnect') && $connType == 'P') {
		$link = @mysql_pconnect($server_string, $dbUser, $dbPassword);
	}
	elseif(function_exists('mysql_connect')) {
    */
		$link = @mysql_connect($server_string, $dbUser, $dbPassword);
	// }
	if(!$link) {
		return FALSE;
	}

	$result = mysql_select_db(DBNAME, $link);
	if(!$result) {
		return FALSE;
	}

	return $link;
}


//------------------------------------------------------------------------
// This functions performs the SQL query and returns a result resource. If
// an error occurs then execution is halted an the MySQL error is
// displayed.
// CDUKES: 12-10-09 - Added an optional filename parameter for query logging
//------------------------------------------------------------------------
function perform_query($query, $link, $filename='') {
	if($link) {
		$result = mysql_query($query, $link); 
			if (!$result) {
			print ("Error in \"function perform_query()\" <br>Mysql_error: " .mysql_error() ."<br>Query was: $query<br>"); 
			return ("Error in \"function perform_query()\" <br>Mysql_error: " .mysql_error()); 
			}
	}
	else {
		die("Error in perform_query function<br> No DB link for query: $query<br>Mysql_error: " .mysql_error());
    }
	list($usec, $sec) = explode(" ", microtime());
	$ms = ltrim(round($usec, 4), "0.");
    if (LOG_QUERIES == 'TRUE') {
    $myFile = MYSQL_QUERY_LOG;
    $fh = fopen($myFile, 'a') or die("can't open file $myFile");
	if ($filename) {
    fwrite($fh, date("h:i:s") .".$ms - $filename - " .$query."\n");
	} else {
    fwrite($fh, date("h:i:s") .".$ms - " .$query."\n");
	}
    fclose($fh);
    }
    return $result;
}

//------------------------------------------------------------------------
// This function allows logging debug messages to file
//------------------------------------------------------------------------
function logmsg ($msg) {
   	list($usec, $sec) = explode(" ", microtime());
   	$ms = ltrim(round($usec, 4), "0.");
   	$myFile = LOG_PATH . "/logzilla.log";
   	$fh = fopen($myFile, 'a') or die("can't open file $myFile");
   	fwrite($fh, date("h:i:s") .".$ms: $msg \n");
   	fclose($fh);
} 

//------------------------------------------------------------------------
// This functions returns a result row as an array.
// The type can be BOTH, ASSOC or NUM.
//------------------------------------------------------------------------
function fetch_array($result, $type = 'BOTH') {
	if($type == 'BOTH') {
		return mysql_fetch_array($result);
	}
	elseif($type == 'ASSOC') {
		return mysql_fetch_assoc($result);
	}
	elseif($type == 'NUM') {
		return mysql_fetch_row($result);
	}
	else {
		die('Wrong type for fetch_array()');
	}
}


//------------------------------------------------------------------------
// This functions sets the row offset for a result resource
//------------------------------------------------------------------------
function result_seek($result, $rowNumber) {
	mysql_data_seek($result, $rowNumber);
}


//------------------------------------------------------------------------
// This functions returns a result row as an array
//------------------------------------------------------------------------
function num_rows($result) {
	return mysql_num_rows($result);
}


//------------------------------------------------------------------------
// This function checks if a particular table exists.
//------------------------------------------------------------------------
function table_exists($tableName, $link) {
	$tables = get_tables($link);
	if(array_search($tableName, $tables) !== FALSE) {
		return TRUE;
	}
	else {
		return FALSE;
	}
}


//------------------------------------------------------------------------
// This function returns an array of the names of all tables in the
// database.
//------------------------------------------------------------------------
function get_tables($link) {
	$tableList = array();
	$query = "SHOW TABLES";
	$result = perform_query($query, $link, "common_funcs.php");
	while($row = fetch_array($result)) {
		array_push($tableList, $row[0]);
	}

	return $tableList;
}


//------------------------------------------------------------------------
// This function returns an array with the names of tables with log data.
//------------------------------------------------------------------------
function get_logtables($link) {
	// Create an array of the column names in the default table
	$query = "DESCRIBE ".$_SESSION["TBL_MAIN"];
	$result = perform_query($query, $link, "common_funcs.php");
	$defaultFieldArray = array();
	while($row = mysql_fetch_array($result)) {
		array_push($defaultFieldArray, $row['Field']);
	}

	// Create an array with the names of all the log tables
	$logTableArray = array();
	$allTablesArray = get_tables($link);

	foreach($allTablesArray as $value) {
		// Create an array of the column names in the current table
		$query = "DESCRIBE ".$value;
		$result = perform_query($query, $link, "common_funcs.php");
		// Get the names of columns in current table
		$fieldArray = array();
		while ($row = mysql_fetch_array($result)) {
			array_push($fieldArray, $row['Field']);
		}

		// If the current array is identical to the one from the
		// $_SESSION["TBL_MAIN"] then the name is added to the result
		// array.
		$diffArray = array_diff_assoc($defaultFieldArray, $fieldArray);
		if(!$diffArray) {
			array_push($logTableArray, $value);
		}
	}
	return $logTableArray;
}
//========================================================================
// END DATABASE FUNCTIONS
//========================================================================

//========================================================================
// BEGIN REDIRECT FUNCTION
//========================================================================

function g_redirect($url,$mode)
/*  It redirects to a page specified by "$url".
 *  $mode can be:
 *    LOCATION:  Redirect via Header "Location".
 *    REFRESH:  Redirect via Header "Refresh".
 *    META:      Redirect via HTML META tag
 *    JS:        Redirect via JavaScript command
 */
{
  if (strncmp('http:',$url,5) && strncmp('https:',$url,6)) {
      if (!isset($_SERVER["HTTPS"])) {
          $_SERVER["HTTPS"] = "undefine";
      }  
      $starturl = ($_SERVER["HTTPS"] == 'on' ? 'https' : 'http') . '://'.
                 (empty($_SERVER['HTTP_HOST'])? $_SERVER['SERVER_NAME'] :
                 $_SERVER['HTTP_HOST']);

     if ($url[0] != '/') $starturl .= dirname($_SERVER['PHP_SELF']).'/';

     $url = "$starturl$url";
  }

  switch($mode) {

     case 'LOCATION': 

       if (headers_sent()) exit("Headers already sent. Can not redirect to $url");

       header("Location: $url");
       exit;

     case 'REFRESH': 

       if (headers_sent()) exit("Headers already sent. Can not redirect to $url");

       header("Refresh: 0; URL=\"$url\""); 
       exit;

     case 'META': 

       ?><meta http-equiv="refresh" content="0;url=<?php echo $url?>" /><?php
       exit;

     case 'JS': 

       ?><script type="text/javascript">
       window.location.href='<?php echo $url?>';
       </script><?php
       exit;

     default: /* -- Java Script */

       ?><script type="text/javascript">
       window.location.href='<?php echo $url?>';
       </script><?php
  }
  exit;
}

//========================================================================
// END REDIRECT FUNCTION
//========================================================================

/*  Adds commas to a string of numbers
*/
function commify ($str) { 
        $n = strlen($str); 
        if ($n <= 3) { 
                $return=$str;
        } 
        else { 
                $pre=substr($str,0,$n-3); 
                $post=substr($str,$n-3,3); 
                $pre=commify($pre); 
                $return="$pre,$post"; 
        }
        return($return); 
}

/* Usage:

   $week = get_weekdates($year,$month,$day);

   for($i = 1; $i<=7 ; $i++) {

   echo 'Year: ' . $week[$i]['year'] . '<br>';
   echo 'Month: ' . $week[$i]['month'] . '<br>';
   echo 'Day: ' . $week[$i]['day'] . '<br>';
   echo 'Longname: ' . $week[$i]['dayname'] . '<br>';
   echo 'Shortname: ' . $week[$i]['shortdayname'] . '<br>';
   echo 'Sqldate: ' . $week[$i]['sqldate'] . '<br>';
   echo '<br>';

   }
 */

function get_weekdates($year, $month, $day){
	setlocale(LC_ALL, "C");
	//echo "Year $year<br>";
	//echo "Month $month<br>";
	//echo "Day $day<br>";

	// make unix time
	$searchdate = mktime(0,0,0,$month,$day,$year);
	//echo "Searchdate: $searchdate<br>";

	// let's get the day of week                //    on solaris <8 the first day of week is sunday, not monday
	$day_of_week = strftime("%u", $searchdate);  
	//echo "Debug: $day_of_week <br><br>";

	$days_to_firstday = ($day_of_week - 1);        //    on solaris <8 this may not work
	//echo "Debug: $days_to_firstday <br>";

	$days_to_lastday = (7 - $day_of_week);        //    on solaris <8 this may not work
	//echo "Debug: $days_to_lastday <br>";

	$date_firstday = strtotime("-".$days_to_firstday." days", $searchdate);
	//echo "Debug: $date_firstday <br>";

	$date_lastday = strtotime("+".$days_to_lastday. " days", $searchdate);
	//echo "Debug: $date_lastday <br>";

	$d_result = "";                    // array to return

	// write an array of all dates of this week 
	for($i=0; $i<=6; $i++) {
		$y = $i + 1;
		$d_date = strtotime("+".$i." days", $date_firstday);

		// feel free to add more values to these hashes
		$result[$y]['year'] = strftime("%Y", $d_date);
		$result[$y]['month'] = strftime("%m", $d_date);
		$result[$y]['day'] = strftime("%d", $d_date);
		$result[$y]['dayname'] = strftime("%A", $d_date);
		$result[$y]['shortdayname'] = strftime("%a", $d_date);
		$result[$y]['sqldate'] = strftime("%Y-%m-%d", $d_date);
	}

	return $result;                    // return the array
}

// Use this instead of count(*), it's faster
// CDUKES: 12-10-09 - Added an optional WHERE parameter to limit found rows using a where clause
function get_total_rows ($table,$dbLink,$where='') {
   	$temp = perform_query("SELECT SQL_CALC_FOUND_ROWS * FROM $table $where LIMIT 1", $dbLink, "common_funcs.php");
   	$result = perform_query("SELECT FOUND_ROWS()", $dbLink, "common_funcs.php");
	$total = mysql_fetch_row($result);
	return $total[0];
}

// Added for better cookie handling
function getDomain() {
	if ( isset($_SERVER['HTTP_HOST']) ) {
		// Get domain
		$dom = $_SERVER['HTTP_HOST'];
		// Strip www from the domain
		if (strtolower(substr($dom, 0, 4)) == 'syslog.') { $dom = substr($dom, 4); }
		// Check if a port is used, and if it is, strip that info
		$uses_port = strpos($dom, ':');
		if ($uses_port) { $dom = substr($dom, 0, $uses_port); }
		// Add period to Domain (to work with or without www and on subdomains)
		$dom = '.' . $dom;
	} else {
		$dom = false;
	}
	return $dom;
}

function gsearch($s,$fields) {
# e.g.
# gsearch("term", msg)
# would search the msg column for the term


	$st=explode('"',$s);
   	$i=0;
   	while ($i<count($st)) {
	   	$st[$i]=str_replace("+","",$st[$i]);
	   	$st[$i]=preg_replace("@\\s+or\\s+@i"," | ",$st[$i]);
	   	$st[$i]=preg_replace("@\\s+and\\s+@i"," ",$st[$i]);
	   	$st[$i]=preg_replace("@\\s+not\\s+@i"," -",$st[$i]);
	   	$st[$i]=preg_replace("@(-)?($fields):@","@$2 $1",$st[$i]);
	   	$i=$i+2;
   	}

	return implode('"',$st);
}

// -----------------------------
// CDUKES: 11-04-2009
// Added below to grab server settings from database
// -----------------------------
function getsettings() {
   	if (!isset($_SESSION["TBL_MAIN"])) {
	   	$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
	   	$sql = "SELECT name,value, type FROM settings";
	   	$result = perform_query($sql, $dbLink, "common_funcs.php");
	   	while($row = fetch_array($result)) {
            if ($row['type'] == "int") {
		   	$_SESSION[$row["name"]] = intval($row["value"]);
            } else {
		   	$_SESSION[$row["name"]] = $row["value"];
            }
	   	}
   	}
}
function humanReadable($val,$thousands=0){
   	if($val>=1000)
	   	$val=humanReadable($val/1000,++$thousands);
   	else{
	   	$unit=array('','K','M','T','P','E','Z','Y');
	   	$val=round($val,2).$unit[$thousands];
   	}
   	return $val;
}
//------------------------------------------------------------------------------
// Function to include portlet content into a string
//------------------------------------------------------------------------------
function include_contents($filename) {
    if (is_file($filename)) {
        ob_start();
        include $filename;
        $contents = ob_get_contents();
        ob_end_clean();
        return $contents;
    }
    return false;
}
//------------------------------------------------------------------------------
// This function is used to display context sensitive help
//------------------------------------------------------------------------------
function gethelp($name) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
	$sql = "SELECT description FROM help where name='$name' LIMIT 1";
	$result = perform_query($sql, $dbLink, "common_funcs.php");
	while($row = fetch_array($result)) {
        return $row['description'];
    }
    mysql_close($dbLink);
}
//------------------------------------------------------------------------------
// These functions allow storage of messages in a better format.
// This should help speed up message retrieval.
//------------------------------------------------------------------------------
function msg_encode($str) {
   	$hex = "";
   	$i = 0;
   	do {
	   	$hex .= sprintf("%02x", ord($str{$i}));
	   	$i++;
   	} while ($i < strlen($str));
   	return $hex;
}
function msg_decode($str) {
   	$bin = "";
   	$i = 0;
   	do {
	   	$bin .= chr(hexdec($str{$i}.$str{($i + 1)}));
	   	$i += 2;
   	} while ($i < strlen($str));
   	return $bin;
}
//------------------------------------------------------------------------------
// Return the current page URL
//------------------------------------------------------------------------------
function myURL() {
    $pageURL = 'http';
    if (!isset($_SERVER["HTTPS"])) { 
        $_SERVER["HTTPS"] = "undefine";
    }
    if ($_SERVER["HTTPS"] === "on") {
        $pageURL .= "s";
    }
 $pageURL .= "://";
 if ($_SERVER["SERVER_PORT"] != "80") {
  $pageURL .= $_SERVER["SERVER_NAME"].":".$_SERVER["SERVER_PORT"].$_SERVER["REQUEST_URI"];
 } else {
  $pageURL .= $_SERVER["SERVER_NAME"].$_SERVER["REQUEST_URI"];
 }
 return $pageURL;
}

// ------------------------------------------------------
// Used to generate random pie colors in the pie charts
// ------------------------------------------------------
function random_hex_color(){
	// Feel free to alter the RGB value, use (0, 255) to use all colors
	    return sprintf("%02X%02X%02X", mt_rand(0, 115), mt_rand(0, 115), mt_rand(0, 255));
}

// ------------------------------------------------------
// Used to find out the group for the specified user
// ------------------------------------------------------
function getgroup($username) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
    $sql = "SELECT * FROM groups WHERE userid=(SELECT id FROM users WHERE username='$username')";
    $result = perform_query($sql, $dbLink, "common_funcs.php");
    while($row = fetch_array($result)) {
        $group = $row['groupname'];
        return $group;
    }
}
// ------------------------------------------------------
// Used to find out if the user has access to a portlet
// ------------------------------------------------------
function has_portlet_access($username, $header) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
    $sql = "SELECT group_access FROM ui_layout WHERE userid=(SELECT id FROM users WHERE username='$username') AND header='$header'";
    $result = perform_query($sql, $dbLink, "common_funcs.php");
    while($row = fetch_array($result)) {
        $group = $row['group_access'];
        if ($group == getgroup($username)) {
            return TRUE;
        }
    }
}
// ----------------------------------------------------------------------
// Used to reset layouts
// ----------------------------------------------------------------------
function reset_layout($username) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
    $sql = "DELETE FROM ui_layout WHERE userid=(SELECT id FROM users WHERE username='$username')";
    perform_query($sql, $dbLink, "common_funcs.php");
    if (getgroup($username) == 'admins') {
        $sql = "INSERT INTO ui_layout (userid, pagename, col, rowindex, header, content, group_access) SELECT (SELECT id FROM users WHERE username='$username'),pagename,col,rowindex,header,content, 'admins' FROM ui_layout WHERE userid=0";
    } else {
        $sql = "INSERT INTO ui_layout (userid, pagename, col, rowindex, header, content, group_access) SELECT (SELECT id FROM users WHERE username='$username'),pagename,col,rowindex,header,content, group_access FROM ui_layout WHERE userid=0";
    }
    perform_query($sql, $dbLink, "common_funcs.php");
}

// ----------------------------------------------------------------------
// Used to display friendly names for program crc's
// ----------------------------------------------------------------------
function crc2prg ($crc) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
    $sql = "SELECT name FROM programs WHERE crc='$crc'";
    $result = perform_query($sql, $dbLink, "common_funcs.php");
    $row = fetch_array($result);
    return $row['name'];
}
function prg2crc ($prog) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
    $sql = "SELECT crc FROM programs WHERE name='$prog'";
    $result = perform_query($sql, $dbLink, "common_funcs.php");
    $row = fetch_array($result);
    return $row['crc'];
}
// ----------------------------------------------------------------------
// Used to display friendly names for facility codes
// ----------------------------------------------------------------------
function int2fac ($i) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
    $sql = "SELECT name FROM facilities WHERE code='$i'";
    $result = perform_query($sql, $dbLink, "common_funcs.php");
    $row = fetch_array($result);
    return $row['name'];
}
function fac2int ($fac) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
    $sql = "SELECT code FROM facilities WHERE name='$fac'";
    $result = perform_query($sql, $dbLink, "common_funcs.php");
    $row = fetch_array($result);
    return $row['code'];
}
// ----------------------------------------------------------------------
// Used to display friendly names for severity codes
// ----------------------------------------------------------------------
function int2sev ($i) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
    $sql = "SELECT name FROM severities WHERE code='$i'";
    $result = perform_query($sql, $dbLink, "common_funcs.php");
    $row = fetch_array($result);
    return $row['name'];
}
function sev2int ($sev) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
    $sql = "SELECT code FROM severities WHERE name='$sev'";
    $result = perform_query($sql, $dbLink, "common_funcs.php");
    $row = fetch_array($result);
    return $row['code'];
}
// ----------------------------------------------------------------------
// Used to display friendly names for mnemonic crc's
// ----------------------------------------------------------------------
function crc2mne ($crc) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
    $sql = "SELECT name FROM mne WHERE crc='$crc'";
    $result = perform_query($sql, $dbLink, "common_funcs.php");
    $row = fetch_array($result);
    return $row['name'];
}
function mne2crc ($mne) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
    $sql = "SELECT crc FROM mne WHERE name='$mne'";
    $result = perform_query($sql, $dbLink, "common_funcs.php");
    $row = fetch_array($result);
    return $row['crc'];
}


// ----------------------------------------------------------------------
// Returns type of variable
// Usage: echo is_type(''); 
// ----------------------------------------------------------------------
function is_type($var) {
    # Setup commonly used types (PHP.net warns against using gettype())
    switch ($var) {
        case is_string($var):
            $type='string';
            break;

        case is_array($var):
            $type='array';
            break;

        case is_null($var):
            $type='NULL';
            break;

        case is_bool($var):
            $type='boolean';
            break;

        case is_int($var):
            $type='integer';
            break;

        case is_float($var):
            // $type='float';
            $type='double';
            break;

        case is_object($var):
            $type='object';
            break;

        case is_resource($var):
            $type='resource';
            break;

        default:
            $type='unknown type';
            break;
    }
    return $type;
}
?>
