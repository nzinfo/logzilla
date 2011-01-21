<?php

/*
 * grid/triggers.php
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2011 LogZilla, LLC
 * All rights reserved.
 *
 * Changelog:
 * 2011-01-03 - created
 *
 */

require_once 'jq-config.php';
// include the jqGrid Class
require_once ABSPATH."php/jqGrid.php";
// include the driver class
require_once ABSPATH."php/jqGridPdo.php";
// Connection to the server
$conn = new PDO(DB_DSN,DB_USER,DB_PASSWORD);
// Tell the db that we use utf-8
$conn->query("SET NAMES utf8");

// Create the jqGrid instance
$grid = new jqGridRender($conn);
// Write the SQL Query
$grid->SelectCommand = 'SELECT * FROM triggers';
// set the ouput format to json
$grid->dataType = 'json';
$grid->table = 'triggers';


$labels = array("id"=>"Id", "description"=>"Description", "pattern"=>"Regex Pattern", "mailto"=>"Mail Recipient", "mailfrom"=>"Mail Originator", "subject"=>"Mail Subject", "body"=>"Mail Body", "disabled"=>"Trigger Disabled?");

// Let the grid create the model
$grid->setColModel(null, null, $labels);
// Set the url from where we obtain the data
$grid->setUrl('includes/grid/triggers.php');

$grid->addCol(array(
    "name"=>"actions",
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
    ));


$grid->setColProperty('id', array('width'=>'0','editable'=>false));
$grid->setPrimaryKeyId('id');
$grid->toolbarfilter = true;



$choices = array("Yes"=>"Yes", "No"=>"No");
$grid->setSelect("disabled", $choices , false, false, true, array(""=>"All"));



$grid->navigator = true; 
$grid->setNavOptions('navigator', array("excel"=>true,"add"=>true,"edit"=>false,"del"=>false,"view"=>false, "search"=>true)); 
$grid->setNavOptions('edit', array("height"=>"auto","dataheight"=>"auto")); 
$grid->setNavOptions('add', array("height"=>"auto","dataheight"=>"auto")); 

$custom = <<<CUSTOM

function setWidth(percent){
        screen_res = ($(document).width())*0.99;
        col = parseInt((percent*(screen_res/100)));
        return col;
};
function setHeight(percent){
        screen_res = ($(document).height())*0.99;
        col = parseInt((percent*(screen_res/100)));
        return col;
};


$(document).ready(function() {

        $('#triggergrid').fluidGrid({base:'#ui-dialog-title-host_dialog', offset:-15});
        $('#triggergrid').jqGrid('setGridHeight',setHeight(57));
});

$(window).resize(function()
{
        $('#triggergrid').fluidGrid({base:'#ui-dialog-title-host_dialog', offset:-15});
});


CUSTOM;

$grid->setJSCode($custom);

// Enjoy
$grid->renderGrid('#triggergrid','#triggerpager',true, null, null, true,true);
$conn = null;
?>
