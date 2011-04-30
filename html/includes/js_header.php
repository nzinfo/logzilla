<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2009 gdd.net
 * All rights reserved.
 *
 * Changelog:
 * 2009-12-08 - created
 *
 */


//------------------------------------------------------------------------------
// Only javascript code should go in this file
// This allows you to place the code in the head or the body using an include();
// The recommended method for best performance
// is to place all js code just before the closing </body> tag.
// However, some JS may require head loading...
//------------------------------------------------------------------------------

?>
<!-- BEGIN JQUERY This needs to be first -->
<script type="text/javascript" src="<?php echo $_SESSION['SITE_URL']?>includes/js/jquery/jquery-1.4.2.min.js"></script>
<!-- END JQUERY -->

<!-- BEGIN JqGrid -->
<script src="<?php echo $_SESSION['SITE_URL']?>includes/grid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
<script src="<?php echo $_SESSION['SITE_URL']?>includes/grid/js/jquery.jqGrid.min.js" type="text/javascript"></script>
<script src="<?php echo $_SESSION['SITE_URL']?>includes/grid/js/jquery.jqChart.js" type="text/javascript"></script>
<!-- END JqGrid -->

<!-- BEGIN JQuery UI -->
<script src="<?php echo $_SESSION['SITE_URL']?>includes/js/jquery/jquery-ui-1.8rc2.custom.min.js" type="text/javascript"></script>
<!-- END JQuery UI -->

<!-- BEGIN Prevent FOUC 
http://www.learningjquery.com/2008/10/1-way-to-avoid-the-flash-of-unstyled-content
http://monc.se/kitchen/152/avoiding-flickering-in-jquery
-->
<script type="text/javascript">
document.write('<style type="text/css">body{display:none}</style>');
jQuery(function($) {
$('body').css('display','block');
});
</script>
<!-- END Prevent FOUC -->

<!-- BEGIN Flash Charts -->
<script type="text/javascript" src="<?php echo $_SESSION['SITE_URL']?>includes/js/swfobject.js"></script>
<!-- END Flash Charts -->

<!-- BEGIN Date Range Selector - moved to head to support event suppression dialog -->
<script type="text/javascript" src="<?php echo $_SESSION['SITE_URL']?>includes/js/jquery/plugins/daterangepicker.jQuery.js"></script>
<!-- END Date Range Selector -->


