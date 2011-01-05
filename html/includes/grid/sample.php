<?php

/*
 * grid/hosts.php
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2011 LogZilla, LLC.
 * All rights reserved.
 *
 * Changelog:
 * 2011-01-03 - created
 *
 */

session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
require_once ($basePath . "/../grid/tabs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
?> 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"> 
<html> 
  <head> 
    <title>jqGrid PHP Demo</title> 
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" /> 
    <link rel="stylesheet" type="text/css" media="screen" href="../js/jquery/themes/redmond/jquery-ui.css" /> 
    <link rel="stylesheet" type="text/css" media="screen" href="../js/jquery/plugins/ui.jqgrid.css" />
    <link rel="stylesheet" type="text/css" media="screen" href="../js/jquery/plugins/ui.multiselect.css" />
    <style type="text"> 
        html, body { 
        margin: 0;            /* Remove body margin/padding */ 
        padding: 0; 
        overflow: hidden;    /* Remove scroll bars on browser window */ 
        font-size: 75%; 
        } 
    </style> 
    <script src="../js/jquery/jquery-1.4.2.min.js" type="text/javascript"></script> 
    <script src="../js/jquery/plugins/grid.i18n/grid.locale-en.js" type="text/javascript"></script> 
    <script type="text/javascript"> 
    $.jgrid.no_legacy_api = true; 
    $.jgrid.useJSON = true; 
    </script> 
    <script src="../js/jquery/plugins/jquery.jqGrid.min.js" type="text/javascript"></script> 
    <script src="../js/jquery/jquery-ui-1.8rc2.custom.min.js" type="text/javascript"></script> 
  </head> 
  <body> 
      <div> 
          <?php require ("hosts.php");?> 
      </div> 
      <br/> 
   </body> 
</html> 
