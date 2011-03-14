<?php

/*
 * grid/hostgrid.php
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
$grid->SelectCommand = 'SELECT host as Host, seen as Seen, lastseen as LastSeen FROM hosts';
// set the ouput format to json
$grid->dataType = 'json';
// Let the grid create the model
$grid->setColModel();
// Set the url from where we obtain the data
$grid->setUrl('includes/grid/hosts.php');
// Set some grid options
$grid->setGridOptions(array(
    "rowNum"=>19,
    "sortname"=>"LastSeen",
    "sortorder"=>"desc",
    "altRows"=>true,
    "multiselect"=>true,
    "scrollOffset"=>25,
    "shrinkToFit"=>true,
    "setGridHeight"=>"100%",
    "rowList"=>array(20,40,60,75,100,500,750,1000),
    ));

$grid->setColProperty('Seen', array('width'=>'10'));
$grid->setColProperty('LastSeen', array('width'=>'35','formatter'=>'js:easyDate'));

$grid->navigator = true;
$grid->setNavOptions('navigator', array("pdf"=>true,"excel"=>true,"add"=>false,"edit"=>false,"del"=>false,"view"=>false, "search"=>true));

$custom = <<<CUSTOM

//---------------------------------------------------------------
// BEGIN: Host Select Dialog
//---------------------------------------------------------------
$("#portlet-header_Hosts .ui-icon-search").click(function() {
    $("#host_dialog").dialog({
                bgiframe: true,
                resizable: false,
                height: '600',
                width: '90%',
                position: "center",
                autoOpen:false,
                modal: false,
                title: "Host Selector",
                overlay: {
                        backgroundColor: '#000',
                        opacity: 0.5
                },     
                buttons: {
                        'Add Selected Hosts': function() {
                                $(this).dialog('close');
                        },
                },
            open: function(event, ui) { $('#host_dialog').css('overflow','hidden');$('.ui-widget-overlay').css('width','99%') },
            close: function(event, ui) { $('#host_dialog').css('overflow','auto') }
        });             
        $("#host_dialog").dialog('open');
        $("#host_dialog").ready(function(){
        // Some magic to set the proper width of the grid inside a Modal window
        var modalWidth = $("#host_dialog").width();
        var modalHeight = $("#host_dialog").height() - 52;
        $('#hostsgrid').jqGrid('setGridWidth',modalWidth);
        $('#hostsgrid').jqGrid('setGridHeight',modalHeight);
        $('#hostsgrid').fluidGrid({base:'#host_dialog', offset:-25});
        });
//---------------------------------------------------------------
// END: Host Select Dialog
//---------------------------------------------------------------


});

$(window).resize(function()
{
        $('#hostsgrid').fluidGrid({base:'#ui-dialog-title-host_dialog', offset:-25});
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
        "header_title"=>"                         Hosts Report"
    ));
} 

// Enjoy
$summaryrows=array("Seen"=>array("Seen"=>"SUM")); 
$grid->renderGrid('#hostsgrid','#hostspager',true, $summaryrows, null, true,true);
$conn = null;
?>
