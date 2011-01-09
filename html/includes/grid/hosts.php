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
$grid->SelectCommand = 'SELECT host as Host, seen as Seen, lastseen as LastSeen FROM hosts';
// set the ouput format to json
$grid->dataType = 'json';
// Let the grid create the model
$grid->setColModel();
// Set the url from where we obtain the data
$grid->setUrl('includes/grid/hosts.php');
// Set some grid options
$grid->setGridOptions(array(
    "rowNum"=>18,
    "sortname"=>"LastSeen",
    "sortorder"=>"desc",
    "altRows"=>true,
    "multiselect"=>true,
    "rowList"=>array(20,40,60,75,100,500,750,1000),
    ));

$grid->setColProperty('Seen', array('width'=>'10'));
$grid->setColProperty('LastSeen', array('formatter'=>'js:easyDate'));

$grid->navigator = true; 
$grid->setNavOptions('navigator', array("excel"=>true,"add"=>false,"edit"=>false,"del"=>false,"view"=>false, "search"=>true)); 

$custom = <<<CUSTOM

function easyDate (cellValue, options, rowdata) 
{
    var t = jQuery.timeago(cellValue);
    var cellHtml = "<span>" + t + "</span>";
    return cellHtml; 
}

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
//---------------------------------------------------------------
// BEGIN: Host Select Dialog
//---------------------------------------------------------------
$(".portlet-header .ui-icon-plus").click(function() {
    $("#host_dialog").dialog({
                bgiframe: true,
                resizable: false,
                height: '600',
                width: '90%',
                position: [100,100],
                autoOpen:false,
                modal: false,
                show: "slide",
                hide: "clip",
                title: "Host Selector",
                overlay: {
                        backgroundColor: '#000',
                        opacity: 0.5
                },
                buttons: {
                        'Add Selected Hosts': function() {
                                $(this).dialog('close');
                        },
                }
        });
        $("#host_dialog").dialog('open');     
        // Some magic to set the proper width of the grid inside a Modal window
        var modalWidth = $("#ui-dialog-title-host_dialog").width() -1;
        $('#hostsgrid').fluidGrid({base:'#ui-dialog-title-host_dialog', offset:-25});
        $('#hostsgrid').jqGrid('setGridWidth',setWidth(modalWidth));
        $('#hostsgrid').jqGrid('setGridHeight',setHeight(57));
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

// Enjoy
$grid->renderGrid('#hostsgrid','#hostspager',true, null, null, true,true);
$conn = null;
?>
