<?php
// Copyright (C) 2006 Clayton Dukes, cdukes@cdukes.com

header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
header("Cache-Control: no-store, no-cache, must-revalidate");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
$basePath = dirname( __FILE__ );
require_once ($basePath . "/common_funcs.php");
require_once ($basePath . "/ofc/php/open-flash-chart.php");

// Load DB settings into SESSION variables
getsettings();

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" 
"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">

<head>
<!-- BEGIN favicon -->
<link rel="shortcut icon" type="image/x-icon" href="images/favicon.ico" />
<!-- END favicon -->

<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Expires" content="-1" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
<?php 
echo "<title>".$addTitle.": ".$_SESSION['PROGNAME']." ".$_SESSION['VERSION']."</title>\n"; 
?>

<!-- BEGIN Import CSS -->
<?php include ("css.php");?>
<!-- END Import CSS -->

<!-- BEGIN Import JS Head -->
<?php include ("js_header.php");?>
<!-- END JS Head -->
</head>

<!-- BEGIN Body 
Note: Closing body tag is located in the html_footer.php file
-->
<body class="body gradient">
