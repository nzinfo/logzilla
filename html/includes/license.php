<?php                   
/* License Downloader       
   */                   
$basePath = dirname( __FILE__ );
require_once ($basePath . "/html_header.php");
$err = get_input('err');
$license_url = "<a href='http://www.logzilla.net/licensing'> Click here </a> to order a new license or upgrade.<br>";
switch ($err) {
    case "hosts":
        $err = "You have reached the maximum number of hosts for your license.<br>$license_url";
        break;
    case "msg":
        $err = "You have reached the maximum number of messages for your license.<br>$license_url";
        break;
    case "auth":
        $err = "You are not licensed for this authentication type.<br>$license_url";
        break;
    case "charts":
        $err = "You are not licensed for Charts.<br>$license_url";
        break;
    case "alerts":
        $err = "You are not licensed for Email Alerts.<br>$license_url";
        break;
    case "rbac":
        $err = "You are not licensed for Role-Based Access Controls (RBAC).<br>$license_url";
        break;
default:
$err = "Your license is either expired or invalid.<br>$license_url";
}

//require_once ($basePath . "/js_footer.php");
?>
	<!-- BEGIN JQUERY This needs to be first -->
	<script type="text/javascript" src="includes/js/jquery/jquery-1.7.1.min.js"></script>
	
	<!-- BEGIN JqGrid -->
	<script src="<?php echo $_SESSION['SITE_URL']?>includes/grid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
	<script src="<?php echo $_SESSION['SITE_URL']?>includes/grid/js/jquery.jqGrid.min.js" type="text/javascript"></script>
	<script src="<?php echo $_SESSION['SITE_URL']?>includes/grid/js/jquery.jqChart.js" type="text/javascript"></script>
	<!-- END JqGrid -->
	
	<!-- BEGIN JQuery UI -->
	<script src="<?php echo $_SESSION['SITE_URL']?>includes/js/jquery/ui/js/jquery-ui-1.8.16.custom.min.js" type="text/javascript"></script>
	<!-- END JQuery UI -->
	
	<script type="text/javascript" language="javascript">
	$(document).ready(function()
	{
		$(window).scroll(function()
		{
			$('#message_box').animate({top:$(window).scrollTop()+"px" },{queue: false, duration: 3350});  
		});
		
		
    	});
 	</script>

	<style>
		#vworkerSimon-install-button{width: 160px;margin: 0px auto;text-align: center;margin-top: 30px;}
		#vworkerSimon-submit-button, #vworkerSimon-next-button{float: right;margin-top: 8px;width: 60px;text-align: center;}
		#vworkerSimon-submit-button{width:100px;}
		#install-report{color:#f00;}
		#vworkerSimon-install-report{width:100%;}
		.vworkerSimon-btnStyle{ 
		margin: .5em .4em .5em 0;
		cursor: pointer;
		padding: .2em .6em .3em .6em;
		line-height: 1.4em;
		width: 200px;
		overflow: visible;
		padding:10px; display:block; color: #333; height:20px; line-height:20px; text-decoration: none;
		border: 1px solid #D19405;
		background: #FECE2F;
		font-weight: bold;
		color: #4C3000;
		outline: none;
		}
		.clear{clear:both;}
		#message_box {
			position: absolute;
			top: 0; left: 0;
			z-index: 10;
			background:#ffc;
			padding:5px;
			border:1px solid #CCCCCC;
			text-align:center;
			font-weight:bold;
			width:99%;
			font-size:15px; 
			font-family:Trebuchet MS; 
			color: black;
		}
	</style>
	
	<div id="message_box"><?php echo $err?>If you have already ordered a license, please run the following command on this server, then refresh this page:<BR />(cd /var/www/logzilla/scripts && ./install install_license)</div>
