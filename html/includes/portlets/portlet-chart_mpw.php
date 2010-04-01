<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2009 gdd.net
 * All rights reserved.
 *
 * Changelog:
 * 2009-12-13 - created
 *
 */

session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
if ((has_portlet_access($_SESSION['username'], 'Messages Per Week') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 
?>
<div id="chart_mpw"></div>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Messages_Per_Week').remove()
</script>
<?php } ?>
