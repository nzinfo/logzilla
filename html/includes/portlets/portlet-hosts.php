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
if ((has_portlet_access($_SESSION['username'], 'Hosts') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 
?>
<div id="hosts_grid_wrapper" class="ui-corner-all floatLeft">
<table id="hostsTable" class="scroll" cellpadding="0" cellspacing="0"></table>
<div id="hostsPager" class="scroll" style="text-align:left;"></div> 
</div>
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Hosts').remove()
</script>
<?php } ?>
