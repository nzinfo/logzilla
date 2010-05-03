<?php
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
?>
<img style='float: left; border: 0 none; padding-right: 1.5em; padding-left: 1.5em; width: 250px; height: 250px;' src='images/LogZilla_Logo_smoothfont_300x300_transparent.png' alt='Go Go LogZilla!'/>
<table class="header">
<tr><td>
	<h2 class="logo"><?php echo $_SESSION['PROGNAME'] ." v".$_SESSION['VERSION']."".$_SESSION['VERSION_SUB']." by Clayton Dukes (cdukes@cdukes.com)";?></h2>
</td><td class="headerright">
</td></tr></table>
<table class="headerbottom"><tr><td>
</table>
<table class="pagecontent">
<tr><td><span class="longtext">
<h3 class="title">Overview</h3>
LogZilla is a front-end for viewing syslog messages logged to MySQL in real-time. It lets you quickly and easily manage event logs from many hosts. LogZilla features customized searches based on host, facility, priority, date, time and the content of the log messages. The latest version of LogZilla requires MySQL 5.1, any recent version of syslog-ng, Apache and PHP.

<h3 class="title">License</h3>
This software is made available to end users under two licenses: a free, open-source version and a commercial version.  For inquiries about purchasing a commercial license, please email <a href="mailto:cdukes@cdukes.com?subject=LogZilla License">cdukes@cdukes.com.</a>

<h3 class="title">Local License Information</h3>
<ul>
<li>The license for this copy of LogZilla will expire on <?php echo $_SESSION['LZ_LIC_EXPIRES']?></li>
<li>Maximum number of messages per day: <?php echo commify($_SESSION['LZ_LIC_MSGLIMIT'])?></li>
<li>Maximum number of hosts: <?php echo commify($_SESSION['LZ_LIC_HOSTS'])?></li>
<li>Authentication modules: <?php echo $_SESSION['LZ_LIC_AUTH']?></li>
<li>Adhoc Charts: <?php echo $_SESSION['LZ_LIC_ADHOC']?></li>
</ul>
