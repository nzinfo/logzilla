<?php
/*
 * portlet-import.php
 *
 * Developed by Thomas Honzik (thomas@honzik.at)
 * Copyright (c) 2011 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2011-03-09

 * Changelog:
 * 2011-02-28 - created
 *
 */

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
require_once ($basePath ."/../grid/php/jqGrid.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

//---------------------------------------------------
// The get_input statements below are used to get
// POST, GET, COOKIE or SESSION variables.
// Note that PLURAL words below are arrays.
//---------------------------------------------------


if ((has_portlet_access($_SESSION['username'], 'Import') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 


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

$restore_runfile = $archive_path['value'].'/import.running';
$restore_running = is_file($restore_runfile);

// catch all non emty days from the archives table

$sql = "SELECT archive, records FROM archives where records>0 order by archive";
$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']); 
$count = mysql_num_rows($result);

?>
<table summary="Import_Table" border="1" cellspacing="2" cellpadding="3">
   <colgroup>
      <col width="150" /><col width="150" />
      <col width="250" /><col width="250" />
   </colgroup>
   <caption>Data location information of this system</caption>
   <thead>
      <tr>
         <th colspan="4">Found <?php echo $count; ?> history days in the backup log</th>
      </tr>
      <tr>
         <th>Date</th>
         <th>Records</th>
         <th>Online?</th>
      </tr>
   </thead>
   <tfoot>      
      <tr>    
         <td colspan="4" style="text-align: left;"> <?php 
         	if ($restore_running) {
         			 $loghandle = fopen($restore_runfile, rb); 
         			 	while (!feof($loghandle)) {
  							echo fgets($loghandle, 8192)."<br>";
         			 	}
         			 fclose($loghandle);
         	} 
         	else 
         		{ echo "no import running"; }        			 
 ?> </td>   
      </tr>
   </tfoot>
   <tbody>
<?php while ($row = fetch_array($result)) {

  $onl_bool="0";
    // look at the date 
    $date = substr($row['archive'],9,4)."-".substr($row['archive'],13,2)."-".substr($row['archive'],15,2);
    ?>
      <tr>
         <td style="text-align: center;"><?php echo $date; ?></td>
         <td style="text-align: right;"><?php echo commify($row["records"]); ?></td>

 <?php
      	if ( in_array($date,$online_array) ){  $onl_bool="1";  } elseif ( in_array($date,$file_array) ){  $onl_bool="2";  } 

	switch ($onl_bool) {
		case "2":  
				if ($restore_running) { echo "<td style=\"text-align: right;\">Online (as archive file)</td> <td>  There is a import running </td>"; } else {
		 ?>         <td style="text-align: right;">Online (as archive file)</td> <td> <input class='ui-state-default ui-corner-all' type="submit" onclick="doImport('<?php echo $date; ?>')" value="Import into Database"></td>
<?php  }	break;
	 	case "1":  
		 ?>         <td style="text-align: right;">Online (in database)</td> 
		 		
<?php  		break;
	 	case "0": 
		 ?>    	    <td style="text-align: right;">Offline</td> <td> Restore not implemented yet </td>
<?php  		break;  }
    		} ?>
   </tbody>
</table>
<?php

}
?>

<script type="text/javascript">
function doImport(impdate) { 
  $.get("includes/ajax/import.php?&impdate="+impdate, function(data){
    $('#msgbox_br').jGrowl(data, { sticky: false })});     
    setTimeout("location.reload(true);",3000);
 }
</script>

