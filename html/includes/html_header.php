<?php
// Copyright (C) 2011 LogZilla, LLC - Clayton Dukes, cdukes@logzilla.info

$basePath = dirname( __FILE__ );
require_once ($basePath . "/common_funcs.php");
require_once ($basePath . "/ofc/php/open-flash-chart.php");

// Load DB settings into SESSION variables
getsettings();

?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<link rel="shortcut icon" type="image/x-icon" href="favicon.ico" />
<?php echo "<title>".$addTitle.": ".$_SESSION['PROGNAME']." ".$_SESSION['VERSION']."</title>\n"; ?>
<meta name="Description" "<?php echo $_SESSION['PROGNAME']?>">
<meta name="Keywords" 'LogZilla', 'Syslog', 'Syslog Tool', 'Syslog Analysis', 'Syslog Analyzer'>
<meta name="Copyright" 'LogZilla, LLC'>
<meta name="Author" 'Clayton Dukes - cdukes@logzilla.info'>
<meta http-equiv="Content-Language" content="EN">
<meta name="ROBOTS" content="NOINDEX, NOFOLLOW" />
<meta http-equiv="content-type" content="application/xhtml+xml; charset=UTF-8" />
<meta http-equiv="X-UA-Compatible" content="chrome=1">

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
