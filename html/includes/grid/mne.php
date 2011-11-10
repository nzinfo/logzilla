<?php

/*
 * grid/mne.php
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
$grid->SelectCommand = 'SELECT name as Mnemonic, seen as Seen, lastseen as LastSeen FROM mne';
// set the ouput format to json
$grid->dataType = 'json';
// Let the grid create the model
$grid->setColModel();
// Set the url from where we obtain the data
$grid->setUrl('includes/grid/mne.php');
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
    "loadComplete"=>"js:"
    ));

$grid->setColProperty('Seen', array('width'=>'10'));
$grid->setColProperty('LastSeen', array('width'=>'35','formatter'=>'js:easyDate'));

$grid->navigator = true;
$grid->setNavOptions('navigator', array("pdf"=>true,"excel"=>true,"add"=>false,"edit"=>false,"del"=>false,"view"=>false, "search"=>true));

$gridComplete = <<<ONCOMPLETE
	function ()
	{	
	 setRememberedCheckboxesForDialog('mnemonics','gbox_mnegrid',12,'portlet_Mnemonics');

	}
ONCOMPLETE;
$grid->setGridEvent('loadComplete', $gridComplete); 
$custom = <<<CUSTOM

//---------------------------------------------------------------
// BEGIN: Mnemonic Select Dialog
//---------------------------------------------------------------
$("#portlet-header_Mnemonics .ui-icon-search").click(function() {
    $("#mne_dialog").dialog({
                bgiframe: true,
                resizable: false,
                height: '600',
                width: '90%',
                position: "center",
                autoOpen:false,
                modal: false,
                title: "Mnemonic Selector",
                overlay: {
                        backgroundColor: '#000',
                        opacity: 0.5
                },     
                buttons: {
                        'Add Selected Mnemonic': function() {
                                $(this).dialog('close');
                        },
                },
            open: function(event, ui) { 
	//start code (by abani)
	setRememberedCheckboxesForDialog('mnemonics','gbox_mnegrid',12,'portlet_Mnemonics');
	//end code(by abani)
	$('#mne_dialog').css('overflow','hidden');$('.ui-widget-overlay').css('width','99%') },
            close: function(event, ui) { 
		//start code(by abani)
		setRememberedCheckboxes('mnemonics','portlet_Mnemonics');
		//end code(by abani)
		$('#mne_dialog').css('overflow','auto') }
        });             
        $("#mne_dialog").dialog('open');
        $("#mne_dialog").ready(function(){
        // Some magic to set the proper width of the grid inside a Modal window
        var modalWidth = $("#mne_dialog").width();
        var modalHeight = $("#mne_dialog").height() - 52;
        $('#mnegrid').jqGrid('setGridWidth',modalWidth);
        $('#mnegrid').jqGrid('setGridHeight',modalHeight);
        $('#mnegrid').fluidGrid({base:'#mne_dialog', offset:-25});
        });
//---------------------------------------------------------------
// END: Mnemonic Select Dialog
//---------------------------------------------------------------


});

$(window).resize(function()
{
        $('#mnegrid').fluidGrid({base:'#ui-dialog-title-mne_dialog', offset:-25});
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
        "header_title"=>"                         Mnemonics Report"
    ));
} 

// Enjoy
$summaryrows=array("Seen"=>array("Seen"=>"SUM")); 
$grid->renderGrid('#mnegrid','#mnepager',true, $summaryrows, null, true,true);
$conn = null;
?>
