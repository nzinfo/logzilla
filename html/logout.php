<?php
require_once ("config/config.php");
	session_start();
	foreach ($_SESSION as $key => $value) {
		unset($_SESSION[$key]);
		session_unregister($key);
	}
	session_unset();
	session_destroy();
header("Location: " . $site_url."index.php");
exit;
?> 
