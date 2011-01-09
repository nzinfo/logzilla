<?php
/*
 * portlet-triggers.php
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 *
 * 2010-12-10 - created
 *
 */

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
if ((has_portlet_access($_SESSION['username'], 'Event Triggers') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 
?>

<div id="trigger_wrapper">
    <?php require ($basePath . "/../grid/triggers.php");?> 
</div>

<?php } else { ?>
<script type="text/javascript">
$('#portlet_Event_Triggers').remove()
</script>
<?php } ?>
