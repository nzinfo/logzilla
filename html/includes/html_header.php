<?php
// Copyright (C) 2011 LogZilla, LLC - Clayton Dukes, cdukes@logzilla.pro

$basePath = dirname( __FILE__ );
require_once ($basePath . "/common_funcs.php");

// Load DB settings into SESSION variables
getsettings();

?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="chrome=1">
<link rel="shortcut icon" type="image/x-icon" href="<?php echo $_SESSION['SITE_URL']?>favicon.ico" />
<?php echo "<title>".$addTitle.": ".$_SESSION['PROGNAME']." ".$_SESSION['VERSION']."</title>\n"; ?>
<meta name="Description" "LogZilla (http://www.logzilla.pro)">
<meta name="Keywords" 'LogZilla', 'Syslog', 'Syslog Tool', 'Syslog Analysis', 'Syslog Analyzer', 'Syslog Management'>
<meta name="Copyright" 'LogZilla Corporation'>
<meta name="Author" 'Clayton Dukes - cdukes@logzilla.pro'>
<meta http-equiv="Content-Language" content="EN">
<meta http-equiv="cache-control" content="no-cache,no-store,must-revalidate">
<meta http-equiv="pragma" content="no-cache">
<meta http-equiv="expires" content="0">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

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
<body class="body bg">
<!-- Leave this style tage here, do not move it to css -->
    <img src="images/LogZilla_152x42_transparent_html_head.png" alt="Logo" id="header_logo"  style="top: 0px; height: 42px; display: block; margin-left: auto;  margin-right: auto;" class="reflect" />
