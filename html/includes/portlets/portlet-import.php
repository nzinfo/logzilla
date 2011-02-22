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

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

//---------------------------------------------------
// The get_input statements below are used to get
// POST, GET, COOKIE or SESSION variables.
// Note that PLURAL words below are arrays.
//---------------------------------------------------


if ((TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 


// which dates are online

$sql_online = "SELECT distinct date(lo) FROM  ".$_SESSION['TBL_MAIN'];
$online =  perform_query($sql_online, $dbLink, $_SERVER['PHP_SELF']); 
while ($live = fetch_array($online)) {
$online_array[] = $live['date(lo)']; }

// look where the archives are stored

$sql = "SELECT value FROM settings where name='ARCHIVE_PATH'";
$archive_path = fetch_array( perform_query($sql, $dbLink, $_SERVER['PHP_SELF'])); 

if ($handle = opendir($archive_path['value'])) {
    while (false !== ($file = readdir($handle))) {
        if ( preg_match("/^dumpfile/",$file) ) {
	    $file_array[] = substr($file,9,4)."-".substr($file,13,2)."-".substr($file,15,2);
            
        }
    }
    closedir($handle);
}

// catch all non emty days from the cache table

$sql = "SELECT name, value FROM cache where name like 'chart_mpd%' and value>0 order by name";
$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']); 
$count = mysql_num_rows($result);

?>

<table summary="Import_Table" border="1" cellspacing="2" cellpadding="3">
   <colgroup>
      <col width="100" /><col width="100" />
      <col width="200" />
   </colgroup>
   <caption>Data location information of this system</caption>
   <thead>
      <tr>
         <th colspan="4">Found <?php echo $count; ?> history days in the cache</th>
      </tr>
      <tr>
         <th>Date</th>
         <th>Records</th>
         <th>Online?</th>
      </tr>
   </thead>
   <tfoot>      
      <tr>    
         <td colspan="4"> There are no jobs running for the import </td>   
      </tr>
   </tfoot>
   <tbody>
<?php while ($row = fetch_array($result)) {

  $onl_bool="0";
    // look at the date 
    $date = substr($row['name'],10,4)."-".substr($row['name'],15,2)."-".substr($row['name'],18,2);
    ?>
      <tr>
         <td style="text-align: center;"><?php echo $date; ?></td>
         <td style="text-align: right;"><?php echo commify($row["value"]); ?></td>

 <?php
      	if ( in_array($date,$online_array) ){  $onl_bool="1";  } elseif ( in_array($date,$file_array) ){  $onl_bool="2";  } 

	switch ($onl_bool) {
		case "2":  
		 ?>         <td style="text-align: right;">Online (as archive file)</td> 
<?php  		break;
	 	case "1":  
		 ?>         <td style="text-align: right;">Online (in database)</td> 
<?php  		break;
	 	case "0": 
		 ?>    	    <td style="text-align: right;">Offline</td> 
<?php  		break;  }
?>
         <td style="background: mistyrose;">... here some more to do... </td>
      </tr>
   <?php } ?>
   </tbody>
</table>

<?php


}
/*
    //Run linux command in background and return the PID created by the OS
    function run_in_background($Command, $Priority = 0)
    {
        if($Priority)
           $PID = shell_exec("nohup nice -n $Priority $Command > /dev/null & echo $!");

        else
            $PID = shell_exec("nohup $Command > /dev/null & echo $!");
        return($PID);
    }

    //Verifies if a process is running in linux
    function is_process_running($PID)
    {
        exec("ps $PID", $ProcessState);
        return(count($ProcessState) >= 2);
    }
echo "hello World\n";

  $CopyTaskPid = run_in_background("sleep 10", "+20");
	echo "hello World\n";

    while(is_process_running($CopyTaskPid))
    {
	echo "hello World";
        echo ".";
 
        sleep(2);
    }

*/
 
 ?>

