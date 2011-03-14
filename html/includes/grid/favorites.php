<?php

/*
 * grid/email_alerts.php
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2011 LogZilla, LLC
 * All rights reserved.
 *
 * Changelog:
 * 2011-01-03 - created
 *
 */
define('ABSPATH', dirname(__FILE__).'/');
require_once (ABSPATH . "../common_funcs.php");
define('DB_DSN',"mysql:host=".DBHOST.";dbname=".DBNAME);
define('DB_USER', DBADMIN);    
define('DB_PASSWORD', DBADMINPW); 
// include the jqGrid Class
require_once ABSPATH."php/jqGrid.php";
// include the driver class
require_once ABSPATH."php/jqGridPdo.php";
// include pdf
require_once(ABSPATH.'/php/tcpdf/config/lang/eng.php'); 
// Connection to the server
$conn = new PDO(DB_DSN,DB_USER,DB_PASSWORD);
// Tell the db that we use utf-8
$conn->query("SET NAMES utf8");

// Create the jqGrid instance
$grid = new jqGridRender($conn);
// Write the SQL Query
$grid->SelectCommand = 'SELECT userid,urlname,url,spanid FROM history';
// set the ouput format to json
$grid->dataType = 'json';
$grid->table = 'history';


$labels = array("userid"=>"User ID", "urlname"=>"Favorite Name", "url"=>"URL", "spanid"=>"Menu Location");

// Let the grid create the model
$grid->setColModel(null, null, $labels);

$grid->setColProperty('spanid', array('width'=>'225',"edittype"=>"select"));
$grid->setColProperty('url',array("edittype"=>"textarea","editoptions"=>array("rows"=>6, "cols"=> 100),"width"=>300));

// Set the url from where we obtain the data
$grid->setUrl('includes/grid/favorites.php');

$grid->addCol(array(
    "name"=>"Actions",
    "formatter"=>"actions",
    "editable"=>false,
    "sortable"=>false,
    "resizable"=>false,
    "fixed"=>true,
    "width"=>60,
    "formatoptions"=>array("keys"=>true)
    ), "first"); 


// Set some grid options
$grid->setGridOptions(array(
    "rowNum"=>18,
    "sortname"=>"id",
    "sortorder"=>"asc",
    "altRows"=>true,
    "rowList"=>array(20,40,60,75,100),
    "forceFit" => true
    ));


$grid->setPrimaryKeyId('id');



$choices = array("search_history"=>"Search History", "graph_history"=>"Graph History");
$grid->setSelect("spanid", $choices , false, true, true, array(""=>"All"));



$grid->navigator = true; 
$grid->setNavOptions('navigator', array("pdf"=>true,"excel"=>true,"add"=>true,"edit"=>false,"del"=>false,"view"=>false, "search"=>true)); 
$grid->setNavOptions('edit', array("width"=>"auto","height"=>"auto","dataheight"=>"auto","top"=>200,"left"=>200)); 
$grid->setNavOptions('add', array("width"=>"auto","height"=>"auto","dataheight"=>"auto","top"=>200,"left"=>200)); 

$custom = <<<CUSTOM

$(document).ready(function() {

        var modalWidth = $("#portlet_Edit_Favorites").width();
        var modalHeight = $("#portlet_Edit_Favorites").height() - 52;
        $('#favorites_grid').jqGrid('setGridWidth',modalWidth);
        $('#favorites_grid').jqGrid('setGridHeight',modalHeight);
        $('#favorites_grid').fluidGrid({base:'#portlet_Edit_Favorites', offset:-25});
});

$(window).resize(function()
{
        $('#favorites_grid').fluidGrid({base:'#portlet_Edit_Favorites', offset:-25});
});


CUSTOM;

$grid->setJSCode($custom);

$oper = jqGridUtils::GetParam("oper");
if($oper == "pdf") {
    $grid->setPdfOptions(array(
        "header"=>true,
        "margin_top"=>25,
        "page_orientation"=>"P",
        "header_logo"=>"letterhead.png",
        // set logo image width
        "header_logo_width"=>45,
        //header title
        "header_title"=>"                         Alerts Report"
    ));
} 

// Enjoy
$grid->renderGrid('#favorites_grid','#favorites_pager',true, null, null, true,true);
$conn = null;
?>
