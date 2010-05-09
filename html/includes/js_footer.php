<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-05-08
 *
 * Changelog:
 * 2009-12-08 - created
 *
 */

//------------------------------------------------------------------------------
// All javascript code should go in this file
// This allows you to place the code in the head or the body using an include();
// The recommended method for best performance
// is to place all js code just before the closing </body> tag, 
// but some js may need to be in the head (there's also a js_header.php file)
//------------------------------------------------------------------------------

?>
<!-- BEGIN JqGrid -->
<script src="includes/js/jquery/plugins/grid.i18n/grid.locale-en.js" type="text/javascript"></script>
<script src="includes/js/jquery/plugins/jquery.jqGrid.min.js" type="text/javascript"></script>
<!-- END JqGrid -->

<!-- BEGIN Table Sorter -->
<script src="includes/js/tablesort.js" type="text/javascript"></script>
<script src="includes/js/paginate.js" type="text/javascript"></script>
<!-- END Table Sorter -->

<!-- BEGIN BGI Frame support -->
<script src="includes/js/jquery/bgiframe-2.1.1.js" type="text/javascript"></script>
<!-- END BGI Frame support -->

<!-- BEGIN Flash Detection -->
<script type="text/javascript">
function getFlashVersion(){
  // ie
  try {
    try {
      // avoid fp6 minor version lookup issues
      // see: http://blog.deconcept.com/2006/01/11/getvariable-setvariable-crash-internet-explorer-flash-6/
      var axo = new ActiveXObject('ShockwaveFlash.ShockwaveFlash.6');
      try { axo.AllowScriptAccess = 'always'; }
      catch(e) { return '6,0,0'; }
    } catch(e) {}
    return new ActiveXObject('ShockwaveFlash.ShockwaveFlash').GetVariable('$version').replace(/\D+/g, ',').match(/^,?(.+),?$/)[1];
  // other browsers
  } catch(e) {
    try {
      if(navigator.mimeTypes["application/x-shockwave-flash"].enabledPlugin){
        return (navigator.plugins["Shockwave Flash 2.0"] || navigator.plugins["Shockwave Flash"]).description.replace(/\D+/g, ",").match(/^,?(.+),?$/)[1];
      }
    } catch(e) {}
  }
  return '0,0,0';
}
 
var version = getFlashVersion().split(',').shift();
if(version < 10){
  alert("No Flash Player Detected (or your version is too old)!");
        $("#footer").html("<font color=\"red\" size=\"5\" <br>Please download the latest flash player from <a href=\"http://get.adobe.com/flashplayer/\">Adobe</a>");
}
</script>
<!-- END Flash Detection -->

<!-- BEGIN Help Modal -->
<div class="dialog_hide">
    <div id="help_dialog" title="Help">
            <span id="help_text" class="text ui-corner-all"></span>
    </div>
</div>
<!-- END Help Modal -->

<!-- BEGIN JQuery Portlets -->
<script type="text/javascript">
$(document).ready(function(){
		$(".column").sortable({
		connectWith: ".column",
        opacity: "0.8",
		update: savelayout
		});
		$(".portlet").addClass("ui-widget ui-widget-content ui-helper-clearfix ui-corner-all")
	   	.find(".portlet-header")
	   	.addClass("ui-widget-header ui-corner-all")
	   	// .prepend('<span class="ui-icon ui-icon-plusthick"></span>')
	   	.prepend('<span class="ui-icon ui-icon-help"></span>')
	   	.end()
	   	.find(".portlet-content");
        //---------------------------------------------------------------
        // BEGIN: Context sensitive help
        //---------------------------------------------------------------
        $(".portlet-header .ui-icon-help").click(function() {
            var pname = $(this).closest("div").attr("id");
            pname = pname.replace("portlet-header_", "");
            pname = pname.replace(/_/g, " ");
            $("#help_dialog").dialog({
                        bgiframe: true,
                        resizable: true,
                        height: '600',
                        width: '80%',
                        position: [100,100],
                        autoOpen:false,
                        modal: false,
                        show: "blind",
                        hide: "clip",
                        title: pname+ " help",
                        open: function() {
                           $.get("includes/ajax/json.help.php?pname="+pname, function(data){
                               if (data !== '') {
                         $("#help_text").html(data);
                         } else {
                         $("#help_text").text("No Help Available");
                         }
                           });
                         },
                        overlay: {
                                backgroundColor: '#000',
                                opacity: 0.5
                        },
                        buttons: {
                                'Close': function() {
                                        $(this).dialog('close');
                                },
                        }
                });
                $("#help_dialog").dialog('open');     
		   	});
        //---------------------------------------------------------------
        // END: Context sensitive help
        //---------------------------------------------------------------
		/*
           $(".portlet-header .ui-icon").click(function() {
		   	$(this).toggleClass("ui-icon-minusthick");
		   	$(this).parents(".portlet:first").find(".portlet-content").toggle();
		   	});
            */
		$(".column").disableSelection();
});
function savelayout(){
	var positions = "";
	var rowindex = 0;
	$(".portlet").each(function(){rowindex++;positions+=(this.id + "=" + this.parentNode.id + "|" + rowindex + "&");});
	$.ajax({
		type: "POST",
		url: "includes/savelayout.php",
		data: positions
});
    // $('#msgbox_br').jGrowl('Portlet positions saved...');
}
//----------------------------------------------------------------
// This function appends a refresh link to the header of the portlet
// It's tied to the div id of that header, but note that
// the id replaces spaces with underscores
// for example: <div id="Top_Messages"> instead of "Top Messages"
//----------------------------------------------------------------
var mph_done;
if( !mph_done ) {
    $('#portlet-header_Messages_Per_Hour').append('&nbsp;&nbsp;&nbsp;<a href="javascript:reload_chart(\'chart_mph\',\'includes/ajax/json.charts.php?chartId=chart_mph\')">[Refresh]</a>');
    mph = true;
}
var mpw_done;
if( !mpw_done ) {
    $('#portlet-header_Messages_Per_Week').append('&nbsp;&nbsp;&nbsp;<a href="javascript:reload_chart(\'chart_mpw\',\'includes/ajax/json.charts.php?chartId=chart_mpw\')">[Refresh]</a>');
    mpw_done = true;
}
var mpd_done;
if( !mpd_done ) {
    $('#portlet-header_Messages_Per_Day').append('&nbsp;&nbsp;&nbsp;<a href="javascript:reload_chart(\'chart_mpd\',\'includes/ajax/json.charts.php?chartId=chart_mpd\')">[Refresh]</a>');
    mpd_done = true;
}
var mpm_done;
if( !mpm_done ) {
    $('#portlet-header_Messages_Per_Minute').append('&nbsp;&nbsp;&nbsp;<a href="javascript:reload_chart(\'chart_mpm\',\'includes/ajax/json.charts.php?chartId=chart_mpm\')">[Refresh]</a>');
    mpm_done = true;
}
var mps_done;
if( !mps_done ) {
    $('#portlet-header_Messages_Per_Second').append('&nbsp;&nbsp;&nbsp;<a href="javascript:reload_chart(\'chart_mps\',\'includes/ajax/json.charts.php?chartId=chart_mps\')">[Refresh]</a>');
    mps_done = true;
}
var mmo_done;
if( !mmo_done ) {
    $('#portlet-header_Messages_Per_Month').append('&nbsp;&nbsp;&nbsp;<a href="javascript:reload_chart(\'chart_mmo\',\'includes/ajax/json.charts.php?chartId=chart_mmo\')">[Refresh]</a>');
    mmo_done = true;
}
var tm_done;
if( !tm_done ) {
    $('#portlet-header_Top_Messages').append('&nbsp;&nbsp;&nbsp;<a href="javascript:reload_chart(\'chart_topmsgs\',\'includes/ajax/json.charts.php?chartId=chart_topmsgs\')">[Refresh]</a>');
    tm_done = true;
}
</script>
<!-- END JQuery Portlets -->

<!-- BEGIN Time Range Selector -->
<script type="text/javascript" src="includes/js/jquery/plugins/jquery.timePicker.js"></script>
<!-- END Time Range Selector -->

<!-- BEGIN Multiselect -->
<script type="text/javascript" src="includes/js/jquery/plugins/ui.multiselect.js"></script>
<!-- END Multiselect -->

<!-- BEGIN menu -->
<script type="text/javascript" src="includes/js/jquery/menu.js"></script>
<!-- END menu -->

<!-- BEGIN jqgrid resize -->
<script type="text/javascript" src="includes/js/jquery/plugins/jquery.jqGrid.fluid.js"></script>
<!-- END jqgrid resize -->

<!-- BEGIN jGrowl -->
<script type="text/javascript" src="includes/js/jquery/plugins/jgrowl/jquery.jgrowl_minimized.js"></script>
<!-- END jGrowl -->

<!-- BEGIN Selectbox -->
<script type="text/javascript" src="includes/js/jquery/plugins/jquery.selectbox-1.2.js"></script>
<!-- END Selectbox -->

<!-- BEGIN Top Menu -->
<script type="text/javascript">
/*
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-1754321-4']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(ga);
  })();
  */
</script>
<!-- END Top Menu -->

<!-- BEGIN Tabs -->
<script type="text/javascript">
$(document).ready(function(){
        var $tabs = $('#tabs').tabs({
        tabTemplate: '<li><a href="#{href}">#{label}</a> <span class="ui-icon ui-icon-close">Remove Tab</span></li>'
});

// close icon: removing the tab on click
// note: closable tabs gonna be an option in the future - see http://dev.jqueryui.com/ticket/3924
$('#tabs span.ui-icon-close').live('click', function() {
        var index = $('li',$tabs).index($(this).parent());
        // var tabName =  $("#tabs").find("li>a").eq(index).attr("href") 
        var tabName = $("#tabs>ul>li>a").eq(index).attr("href")
        $(tabName).css("display","none");
        $("a[href^="+ tabName +"]").parent().remove();
        var sindex = getSelectedTabIndex();
        // if the user is on the same tab he/she deletes, then select the previous tab
        if ( index == sindex ) {
        $("#tabs").tabs('select',index-1);
        } else {
        // else, stay on the selected tab
        $("#tabs").tabs('select',sindex);
        }
        tabName = tabName.replace("#tab-", "");
        tabName = tabName.replace(/_/g, " ");
        $('#msgbox_br').jGrowl('Deleted the ' + tabName + ' tab');
        });
});

$(function() {
        //-----------------------------------------------------------------------------------
        // BEGIN Tab Bookmarking
        // This allows someone to email you a direct URL to a specific tab
        // Code borrowed from http://www.insideria.com/2009/03/playing-with-jquery-tabs.html
        $("#tabs").bind('tabsselect', function(event, ui) {
            document.location='#'+(ui.index+1);
            });
        if(document.location.hash!='') {
        //get the index
        indexToLoad = document.location.hash.substr(1,document.location.hash.length);
        $("#tabs").tabs('select',indexToLoad-1);
        }
        // END Tab Bookmarking
        //-----------------------------------------------------------------------------------
});
//-----------------------------------------------------------------------------------
// BEGIN Functions to add and remove tabs
// This really just hides them
// If I remove them using the tabs(remove) function, I can't get the content back
// because it destroys it completely.
//-----------------------------------------------------------------------------------
function getIndexForId( tabsDivId, searchedId )
{
        var index = -1;
        var i = 0, els = $(tabsDivId).find("a");
        var l = els.length, e;

        while ( i < l && index == -1 )
        {
                e = els[i];

                if ( searchedId == $(e).attr('href') )
                {
                        index = i;
                }
                i++;
        };

        return index;
} 
function getSelectedTabIndex() { 
    return $('#tabs').tabs('option', 'selected');
}
function addTabFromFile(fileName, tabName)
{
    $("#tabs").tabs("add", fileName , tabName);

}
// http://blog.qumsieh.ca/2009/10/27/building-jquery-tabs-that-open-close/
function showTab(tabID, tabName)
{
    tabID = tabID.replace(/ /g, "_");
    var index = getIndexForId('#tabs', '#tab-' + tabID);
    if (index != "-1") {
    // if the tab was removed, re-add it so we can show the results
    $("#tabs").tabs("select",index);
    $('#msgbox_br').jGrowl(tabName + ' tab already exists...');
    } else {
    // this will add a tab via the standard method
    $("#tabs").tabs("add","#tab-" + tabID, tabName);
    $("#tab-" + tabID).css("display","list-item");

    $("#tabs").tabs('select', tabID);
    $('#msgbox_br').jGrowl('Added the ' + tabName + ' tab');
    }
}

function hideTab(tabName) 
{
    $("#tab-" + tabName).css("display","none");
    $("a[href^=#tab-"+ tabName +"]").parent().remove();
    $("#tabs").tabs('select', 0);
}

//-----------------------------------------------------------------------------------
// END Functions to add and remove tabs
//-----------------------------------------------------------------------------------
</script>
<!-- END Tabs -->

<!-- BEGIN Overlib (deprecated)
<script src="includes/js/overlib.js" language="Javascript" type="text/javascript"></script>
<DIV id=overDiv	style="Z-INDEX: 1000; VISIBILITY: hidden; POSITION: absolute"></DIV>
-->
<!-- END Overlib -->

<!-- BEGIN Themeswitcher -->
<script type="text/javascript" src="includes/js/jquery/themeswitch.js"></script>
<script type="text/javascript">
$(document).ready(function(){
	   	// $.switcher.init({themeBase: 'includes/js/jquery/themes/ui-lightness/', onLoad: reloadIE});
	   	$('#switcher').themeswitcher({themeBase: 'includes/js/jquery/themes/ui-lightness/', onLoad: reloadIE});
	   	// $('#switcher').theme({icons: 'img/themes.png', previews: 'img/themes-preview.png'});
	   	});
var first = true;

// IE doesn't update the display immediately, so reload the page
function reloadIE(id, display, url) {
   	if (!first && $.browser.msie) {
	   	window.location.href = window.location.href;
   	}
   	first = false;
}
</script>
<!-- BEGIN Sparklines 
Removed due to performance issues...
-->
<script type="text/javascript" src="includes/js/jquery/plugins/jquery.sparkline.min.js"></script>
<script type="text/javascript">
average = function(a){
    var r = {mean: 0, variance: 0, deviation: 0}, t = a.length;
    for(var m, s = 0, l = t; l--; s += a[l]);
    for(m = r.mean = s / t, l = t, s = 0; l--; s += Math.pow(a[l] - m, 2));
    return r.deviation = Math.sqrt(r.variance = s / t), r;
}
$(document).ready(function(){
/** 
 ** Draws the Messages per second sparkline
 **/
var average = function(a){
    var r = {mean: 0, variance: 0, deviation: 0}, t = a.length;
    for(var m, s = 0, l = t; l--; s += a[l]);
    for(m = r.mean = s / t, l = t, s = 0; l--; s += Math.pow(a[l] - m, 2));
    return r.deviation = Math.sqrt(r.variance = s / t), r;
}
var refreshinterval = <?php echo ($_SESSION['Q_TIME']*1000)?>; // update display every 1 second
var lasttime;
var travel = 0;
var points = [];
var points_max = 60;
mdraw = function() {
   	var md = new Date();
   	var timenow = md.getTime();
   	if (lasttime && lasttime!=timenow) {
	   	var pps = Math.round(travel / (timenow - lasttime) * 1000);
	   	points.push(pps);
	   	if (points.length > points_max)
		   	points.splice(0,1);
	   	travel = 0;
        $.getJSON('includes/ajax/json.sparkline.mps.php', function(data) {
        // $('.dynamicsparkline').sparkline(data, {width: points.length*20, height: '45px'});
            if(data) {
                // Add sparkline:
                $('.dynamicsparkline').sparkline(data, {width: ((data.length - 1) * 2), height: '30px', type: 'line'});
                // Added average MPS text if data exists:
                var total = 0;
                    for(var i = 0; i < data.length; i++){
                    var thisVal = parseInt(data[i]);
                    if(!isNaN(thisVal)){
                        total += thisVal;
                    };
                };
                var avg = Math.round(total / (data.length - 1));
                if(!isNaN(avg)){
                    $('#spark_mps').text("Average MPS = " + avg);
                } else {
                    $('#spark_mps').text("NaN");
                    };
            } else {
            $('.dynamicsparkline').text("No Data");
            $('#spark_mps').text("");
            };
        });
   	}
   	lasttime = timenow;
   	mtimer = setTimeout(mdraw, refreshinterval);
}
var mtimer = setTimeout(mdraw, refreshinterval); 
$.sparkline_display_visible(); 
// $('#sparkbox').draggable();
});
</script>
<!-- END Sparklines -->

<!-- BEGIN AND/OR Sliders-->
<script type="text/javascript">
// --------------------------------------
// This provides AND/OR logic for queries
// --------------------------------------
/*
$(document).ready(function(){
        $('#date_andor').slider({
        min: 0,
        max: 1,
        change: function(event, ui) {
        //var val = $(this).slider("value");
        var val = $('#date_andor').slider("value");
        if (val == "0") {
        $("#date_andor_text").html("AND");
        } else {
        $("#date_andor_text").html("OR");
        }
        }
        });
        $('#program_andor').slider({
        min: 0,
        max: 1,
        change: function(event, ui) {
        //var val = $(this).slider("value");
        var val = $('#program_andor').slider("value");
        if (val == "0") {
        $("#program_andor_text").html("AND");
        } else {
        $("#program_andor_text").html("OR");
        }
        }
        });
        $('#priorities_andor').slider({
        min: 0,
        max: 1,
        change: function(event, ui) {
        //var val = $(this).slider("value");
        var val = $('#priorities_andor').slider("value");
        if (val == "0") {
        $("#priorities_andor_text").html("AND");
        } else {
        $("#priorities_andor_text").html("OR");
        }
        }
        });
        $('#facilities_andor').slider({
        min: 0,
        max: 1,
        change: function(event, ui) {
        //var val = $(this).slider("value");
        var val = $('#facilities_andor').slider("value");
        if (val == "0") {
        $("#facilities_andor_text").html("AND");
        } else {
        $("#facilities_andor_text").html("OR");
        }
        }
        });
});
*/
</script>
<!-- END AND/OR Sliders-->

<!-- BEGIN Chart Functions -->
<script type="text/javascript">
//---------------------------------------------------------------------------------------------------
// The vars below provide chart size dimensions.
// the graph_page_w and h options are caculated by dividing the full page width/height by the number of
// columns and rows loaded into the tab. This should help auto-size charts is users decide to add
// more later.
// Setting height below to 100% won't work - something to do with the portlets not being draw yet? I don't know.
//---------------------------------------------------------------------------------------------------
        var full_graph_width = $(document).width()-125;
        var full_graph_height = $(document).height()-200;
        var graph_page_w = (full_graph_width/<?php echo $_SESSION['Main']['maxcols'];?>-10);
        var graph_page_h = (full_graph_height/<?php echo $_SESSION['Main']['maxrows'];?>+20);
        if (graph_page_h < 100) {
            graph_page_h = 175;
        };
		// MPH
	   	swfobject.embedSWF("includes/ofc/open-flash-chart.swf", "chart_mph", "100%", graph_page_h, "9.0.0", "expressInstall.swf", {"data-file":"includes/ajax/json.charts.php?chartId=chart_mph"}, {"wmode":"transparent"});
		// MPW
	   	swfobject.embedSWF("includes/ofc/open-flash-chart.swf", "chart_mpw", "100%", graph_page_h, "9.0.0", "expressInstall.swf", {"data-file":"includes/ajax/json.charts.php?chartId=chart_mpw"}, {"wmode":"transparent"});
		// MPD
	   	swfobject.embedSWF("includes/ofc/open-flash-chart.swf", "chart_mpd", "100%", graph_page_h, "9.0.0", "expressInstall.swf", {"data-file":"includes/ajax/json.charts.php?chartId=chart_mpd"}, {"wmode":"transparent"});
		// MPM
	   	swfobject.embedSWF("includes/ofc/open-flash-chart.swf", "chart_mpm", "100%", graph_page_h, "9.0.0", "expressInstall.swf", {"data-file":"includes/ajax/json.charts.php?chartId=chart_mpm"}, {"wmode":"transparent"});
		// MPS (includes a reload timer for auto updating)
	   	swfobject.embedSWF("includes/ofc/open-flash-chart.swf", "chart_mps", "100%", graph_page_h, "9.0.0", "expressInstall.swf", {"data-file":"includes/ajax/json.charts.php?chartId=chart_mps"}, {"wmode":"transparent"});
		// Top 10 Hosts
	   	swfobject.embedSWF("includes/ofc/open-flash-chart.swf", "chart_mmo", "100%", graph_page_h, "9.0.0", "expressInstall.swf", {"data-file":"includes/ajax/json.charts.php?chartId=chart_mmo"}, {"wmode":"transparent"});
		// Top 10 Messages
	   	swfobject.embedSWF("includes/ofc/open-flash-chart.swf", "chart_topmsgs", "100%", full_graph_height, "9.0.0", "expressInstall.swf", {"data-file":"includes/ajax/json.charts.php?chartId=chart_topmsgs"}, {"wmode":"transparent"});
//------------------------------------
// BEGIN auto-refresh on the mps chart
//------------------------------------
        /* disabled - it was misbehaving
var timerID = 0;
function reload()
{
    if (timerID)
    {
        clearTimeout(timerID);
    }
    var tmp = findSWF("chart_mps");
    if (tmp) {
    var x = tmp.reload("includes/ajax/json.charts.php?chartId=chart_mps");
    }

    timerID = setTimeout("reload()", 10000);
}
*/
//------------------------------------
// END auto-refresh on the mps chart
//------------------------------------

//-----------------------------------------------
// BEGIN locate an SWF (used for dynamic updates)
//-----------------------------------------------
function findSWF(movieName)
{
    if (navigator.appName.indexOf("Microsoft")!= -1)
    {
        return window[movieName];
    }
    else
    {
        return document[movieName];
    }
}
// timerID  = setTimeout("reload()", 5000);

//-----------------------------------------------
// END locate an SWF (used for dynamic updates)
//-----------------------------------------------

//-----------------------------------------------------------
// BEGIN reload the specified chart (used for onclick refreshing)
// Usage example:
// <a align=right href=javascript:reload_chart('chart_mpm','includes/ajax/json.charts.php?chartId=chart_mpm')>[Refresh]</a>
//-----------------------------------------------------------
var timerID2 = 0;
function reload_chart(chart_id,json_file)
{
    if (timerID2)
    {
        clearTimeout(timerID2);
    }
    var tmp = findSWF(chart_id);
    if (tmp) {
    var x = tmp.reload(json_file);
    }

    timerID2 = setTimeout("reload()", 3000);
}
//-----------------------------------------------------------
// END reload the specified chart (used for onclick refresh)
//-----------------------------------------------------------
</script>
<!-- END Chart Functions -->

<!-- BEGIN Date Picker Functions -->
<script type="text/javascript">
$(document).ready(function(){
        if($(window.parent.document).find('iframe').size()){
        var inframe = true;
        }
        $('#fo_date').daterangepicker({
posX: null,
posY: null,
appendTo: '#fo_date_wrapper',
arrows: 'true',
dateFormat: 'yy-mm-dd',
rangeSplitter: 'to',
onOpen:function(){ if(inframe){ $(window.parent.document).find('iframe:eq(0)').width(700).height('35em');} }, 
onClose: function(){ if(inframe){ $(window.parent.document).find('iframe:eq(0)').width('100%').height('5em');} }
});
        $('#lo_date').daterangepicker({
posX: null,
posY: null,
appendTo: '#lo_date_wrapper',
arrows: 'true',
dateFormat: 'yy-mm-dd',
rangeSplitter: 'to',
onOpen:function(){ if(inframe){ $(window.parent.document).find('iframe:eq(0)').width(700).height('35em');} }, 
onClose: function(){ if(inframe){ $(window.parent.document).find('iframe:eq(0)').width('100%').height('5em');} }
});
        });
</script>
<!-- END Date Picker Functions -->

<!-- BEGIN Time Picker Functions -->
<script type="text/javascript">
$(document).ready(function(){
        $("#fo_time_start, #fo_time_end").timePicker();
        // Store time used by duration.
        var oldTime = $.timePicker("#fo_time_start").getTime();

        // Keep the duration between the two inputs.
        $("#fo_time_start").change(function() {
            // Added '!= '23:59:59'' so the time would not cycle to the next day
            if ($("#fo_time_end").val() != '23:59:59') { // Only update when second input has a value.
            // Calculate duration.
            var duration = ($.timePicker("#fo_time_end").getTime() - oldTime);
            var time = $.timePicker("#fo_time_start").getTime();
            // Calculate and update the time in the second input.
            $.timePicker("#fo_time_end").setTime(new Date(new Date(time.getTime() + duration)));
            oldTime = time;
            }
            });
        // Validate.
        $("#fo_time_end").change(function() {
            if($.timePicker("#fo_time_start").getTime() > $.timePicker(this).getTime()) {
            $(this).addClass("error");
            }
            else {
            $(this).removeClass("error");
            }
            });
        // Clear watermark when the user clicks in the time entry field
        $("#fo_time_start").focus(function() {
            $(this).removeClass("watermark");
            });
        $("#fo_time_end").focus(function() {
            $(this).removeClass("watermark");
            });
        });
$(document).ready(function(){
        $("#lo_time_start, #lo_time_end").timePicker();
        // Store time used by duration.
        var oldTime = $.timePicker("#lo_time_start").getTime();

        // Keep the duration between the two inputs.
        $("#lo_time_start").change(function() {
            // Added '!= '23:59:59'' so the time would not cycle to the next day
            if ($("#lo_time_end").val() != '23:59:59') { // Only update when second input has a value.
            // Calculate duration.
            var duration = ($.timePicker("#lo_time_end").getTime() - oldTime);
            var time = $.timePicker("#lo_time_start").getTime();
            // Calculate and update the time in the second input.
            $.timePicker("#lo_time_end").setTime(new Date(new Date(time.getTime() + duration)));
            oldTime = time;
            }
            });
        // Validate.
        $("#lo_time_end").change(function() {
            if($.timePicker("#lo_time_start").getTime() > $.timePicker(this).getTime()) {
            $(this).addClass("error");
            }
            else {
            $(this).removeClass("error");
            }
            });
        // Clear watermark when the user clicks in the time entry field
        $("#lo_time_start").focus(function() {
            $(this).removeClass("watermark");
            });
        $("#lo_time_end").focus(function() {
            $(this).removeClass("watermark");
            });
        });
</script>
<!-- END Time Picker Functions -->


<!-- BEGIN GRIDS -->

<!-- BEGIN Hosts Grid (called from portlet-hosts.php) -->
<script type="text/javascript">
function resize_hosts_grid()
{
    $('#hostsTable').fluidGrid({base:'#portlet_Hosts', offset:-1});
}
function getWidthInPct(percent){
        screen_res = ($(document).width())*0.99;
        col = parseInt((percent*(screen_res/100)));
            return col;
    } 

// Hosts Grid on main page
var hostgrid = jQuery("#hostsTable").jqGrid({
url:'includes/ajax/json.hostgrid.php',
datatype: "json",
height:'auto',
// autowidth: true, 
width: getWidthInPct(30),
rownumbers: false, 
colNames:[''], // Hide the column name since it's listed in the portlet
colModel:[
{name:'host',index:'host', width:50, editable:false, sortable:true}
],
	gridview: true, 
    emptyrecords: "<font color='red'><b>No Results Found</font></b>",
    forceFit: true,
   	rowNum:10,
   	rowList:[10,20,30,40,50,100,500],
   	sortname: 'host',
   	mtype: "POST",
   	viewrecords: true,
   	sortorder: "desc",
    multiselect: true, 
   	pager: '#hostsPager',
    recordtext: "{0} - {1} of {2} hosts",
    pgtext: "",
    });
// resize_hosts_grid();
$(window).resize(resize_hosts_grid);
// Append host filter text box to portlet header
$('#portlet-header_Hosts').append('&nbsp;&nbsp;<input value="Host Filter" class="rounded_gridfilter watermark ui-widget ui-corner-all" type="text" id="hostsFilter" onkeydown="hostSearch(arguments[0]||event)" />');

// Set pager options
jQuery("#hostsTable").jqGrid('navGrid','#hostsPager',{add:false,edit:false,del:false,search:false,refresh:true}); 
// Remove rollup icon
$('.ui-jqgrid-titlebar-close','#gview_hostsTable').remove();

// Live search
var timeoutHnd;
function hostSearch(ev){
   	if(timeoutHnd) {
	   	clearTimeout(timeoutHnd); }
   	timeoutHnd = setTimeout(hostGridReload,500);
}

// Send the data and refresh the grid
function hostGridReload(){
   	var host_mask = jQuery("#hostsFilter").val();
   	jQuery("#hostsTable").setGridParam({url:"includes/ajax/json.hostgrid.php?host_mask="+host_mask,page:1}).trigger("reloadGrid");
}
// **Special** - this will append to the search form on the main page for any checkboxes clicked on the hosts grid
jQuery("#btnSearch").click( function() { 
        var hosts = jQuery("#hostsTable").jqGrid('getGridParam','selarrrow'); 
        $("#results").append("<input type='hidden' name='hosts' value='"+hosts+"'>");
        $("#results").append("<input type='hidden' name='page' value='Results'>");
        }); 
jQuery("#btnGraph").click( function() { 
        var hosts = jQuery("#hostsTable").jqGrid('getGridParam','selarrrow'); 
        $("#results").append("<input type='hidden' name='hosts' value='"+hosts+"'>");
        $("#results").append("<input type='hidden' name='page' value='Graph'>");
        }); 
$(function(){
        $('input').keydown(function(e){
            if (e.keyCode == 13) {
            if ($("#hostsFilter").val() == "" || $("#hostsFilter").val() == 'Host Filter') {
            $("#results").append("<input type='hidden' name='page' value='Results'>");
            $(this).parents('#results').submit();
            return false;
            };
            };
            });
        });
</script>
<!-- END Hosts Grid -->

<script type="text/javascript">
function resize_sadmin_grid()
{
    $('#sadmin_table').fluidGrid({base:'#portlet_Server_Settings', offset:-1});
}
function getWidthInPct(percent){
        screen_res = ($(document).width())*0.99;
        col = parseInt((percent*(screen_res/100)));
            return col;
    } 

// Admin table
var lastsel; 
var admingrid = jQuery("#sadmin_table").jqGrid({
url:'includes/ajax/json.sadmin.php',
datatype: "json",
height:'auto',
width: getWidthInPct(99),
rownumbers: false, 
 colNames:['Name','Value', 'Type', 'Options','Default','Description'], 
    colModel:[ 
        {name:'name',index:'name', width:40, editrules:{edithidden:false, required:true}, editable:false}, 
        {name:'value',index:'value', width:30, editable:true}, 
        {name:'type',index:'type', width:20,editable:true, edittype:"select",editoptions:{value:"enum:enum;int:int;varchar:varchar"}
}, 
        {name:'options',index:'options', width:20, editable:false}, 
        {name:'default',index:'default', width:30, editable:false}, 
        {name:'description',index:'description', width:280,editable:true,edittype:"textarea", editoptions:{rows:"10",cols:"40"}}
    ], 
	gridview: true, 
    emptyrecords: "No Results Found",
    forceFit: true,
   	rowNum:10,
   	rowList:[10,20,30,40,50],
   	sortname: 'name',
   	viewrecords: true,
   	sortorder: "asc",
    cellEdit: true,
    cellurl: 'includes/ajax/json.sadmin.php',
   	pager: '#sadmin_pager',
    recordtext: "{0} - {1} of {2}",
    pgtext: "",
    });
    jQuery("#sadmin_table").saveRow("rowid", true);
// resize_sadmin_grid();
$(window).resize(resize_sadmin_grid);

// Set pager options
jQuery("#sadmin_table").jqGrid('navGrid','#sadmin_pager',{add:false,edit:false,del:false,search:false,refresh:false}); 
// Remove rollup icon
$('.ui-jqgrid-titlebar-close','#gview_sadmin_table').remove();

// Live search
/*
var timeoutHnd;
function adminSearch(ev){
   	if(timeoutHnd) {
	   	clearTimeout(timeoutHnd); }
   	timeoutHnd = setTimeout(adminGridReload,500);
}

// Send the data and refresh the grid
function adminGridReload(){
   	var host_mask = jQuery("#search_host").val();
   	var facility_mask = jQuery("#search_facility").val();
   	var priority_mask = jQuery("#search_priority").val();
   	var program_mask = jQuery("#search_program").val();
   	var msg_mask = jQuery("#search_msg").val();
   	var fo_mask = jQuery("#search_fo").val();
   	var lo_mask = jQuery("#search_lo").val();
   	var counter_mask = jQuery("#search_counter").val();
   	var notes_mask = jQuery("#search_notes").val();
   	jQuery("#searchtable").setGridParam({url:"includes/ajax/json.grid.php?host_mask="+host_mask+"&facility_mask="+facility_mask+"&priority_mask="+priority_mask+"&program_mask="+program_mask+"&msg_mask="+msg_mask+"&counter_mask="+counter_mask+"&fo_mask="+fo_mask+"&lo_mask="+lo_mask+"&notes_mask="+notes_mask,page:1}).trigger("adminGridReload");
}
*/
</script>
<!-- END Admin Table Grid -->

<!-- END GRIDS -->

<!-- BEGIN Select All Checkboxes -->
<script type="text/javascript">
function toggleCheck(status) {
    // This will toggle inputs with a class of "checkbox"
    // Note that there is not 'css' class defined
    // it is just used to ID checkboxes
    $(".checkbox").each( function() {
            $(this).attr("checked",status);
            })
};
function togglePortlet_Groups(status) {
    // This will toggle inputs with a class of "checkbox"
    // Note that there is not 'css' class defined
    // it is just used to ID checkboxes
    $(".chk_portlet_groups").each( function() {
            $(this).attr("checked",status);
            })
};
function toggleChecked(oElement) 
{ 
    oForm = oElement.form; 
    oElement = oForm.elements[oElement.name]; 
    if(oElement.length) 
    { 
        bChecked = oElement[0].checked; 
        for(i = 1; i < oElement.length; i++) 
            oElement[i].checked = bChecked; 
    } 
}

function toggleController(oElement)
{
    oForm=oElement.form;oElement=oForm.elements[oElement.name];
    if(oElement.length)
    {
        bChecked=true;nChecked=0;for(i=1;i<oElement.length;i++)
            if(oElement[i].checked)
                nChecked++;
        if(nChecked<oElement.length-1)
            bChecked=false;
        oElement[0].checked=bChecked;
    }
}
</script>
<!-- END Select All Checkboxes -->

<!-- BEGIN Commify -->
<script type="text/javascript">
function commify(nStr)
{
    nStr += '';
    x = nStr.split('.');
    x1 = x[0];
    x2 = x.length > 1 ? '.' + x[1] : '';
    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
        x1 = x1.replace(rgx, '$1' + ',' + '$2');
    }
    return x1 + x2;
}
</script>
<!-- END Commify -->

<!-- BEGIN Watermark Function -->
<script type="text/javascript">
//-----------------------------------------------------------
// The following function is used to set a watermark
// in various text inputs.
// usage: watermark("#id_of_target_text_input","Text To Enter Into Field");
// sample input box to use this on:
// <input type="text" value="Host Filter" class="rounded_textbox watermark ui-widget ui-corner-all" 
//    name="hostsFilter" id="hostsFilter" size=30>
//-----------------------------------------------------------

// This function removes the watermark when the field is clicked in
function watermark(target, value) {
    // Set focus
    $(target).focus(function() {
            $(this).filter(function() {
                // We only want this to apply if there's not
                // something actually entered
                return $(this).val() == "" || $(this).val() == value
                }).removeClass("watermark").val("");
            });
// This function adds the watermark when the focus is lost
    $(target).blur(function() {
            $(this).filter(function() {
                // We only want this to apply if there's not
                // something actually entered
                return $(this).val() == ""
                }).addClass("watermark").val(value);
            });
}
// Apply watermarks to various text fields
$(document).ready(function() {
watermark("#hostsFilter","Host Filter");
});
</script>
<!-- END Watermark Function -->

<!-- BEGIN Portal Counts -->
<script type="text/javascript">
$(document).ready(function() {
        var enabled = <?php print $_SESSION['SHOWCOUNTS']; ?>;
        var SPX = <?php print $_SESSION['SPX_ENABLE']; ?>;
        if (enabled == "1") {
        $.get("includes/ajax/counts.php?data=msgs", function(data){
            if (data) {
            var comma = commify(data);
            } else {
            var comma = '0';
            };
            $("#msg_mask").val("Search through "+comma+" Messages");
            watermark("#msg_mask","Search through "+comma+" Messages");
            });
        if (SPX == "0") {
        $.get("includes/ajax/counts.php?data=notes", function(data){
            var comma = commify(data);
            $("#notes_mask").val("Search through "+comma+" Notes");
            watermark("#notes_mask","Search through "+comma+" Notes");
            });
        };
        /*
        $.get("includes/ajax/counts.php?data=prgs", function(data){
            var comma = commify(data);
            $("#portlet-header_Programs").prepend(comma+" ");
            });
         $.get("includes/ajax/counts.php?data=sevs", function(data){
             var comma = commify(data);
             $("#portlet-header_Severities").prepend(comma+" ");
             });
        $.get("includes/ajax/counts.php?data=facs", function(data){
                var comma = commify(data);
                $("#portlet-header_Facilities").prepend(comma+" ");
                });
                */
        // At some point, it occurred to me that I can simply count the <select> element options and use that number rather than querying the DB, duh!
        var count = $("#mnemonics option").size()
            $("#portlet-header_Mnemonics").prepend(commify(count)+" ");
        var count = $("#programs option").size()
            $("#portlet-header_Programs").prepend(commify(count)+" ");
        var count = $("#facilities option").size()
            $("#portlet-header_Facilities").prepend(commify(count)+" ");
        var count = $("#severities option").size()
            $("#portlet-header_Severities").prepend(commify(count)+" ");
        }
            watermark("#dupcount","0");
});
</script>
<!-- END Portal Counts -->


<!-- BEGIN Add Save URL icon to search results -->
<script type="text/javascript">
$("#portlet-header_Search_Results").prepend('<span class="ui-icon ui-icon-disk"></span>');
//---------------------------------------------------------------
// BEGIN: Save URL function
//---------------------------------------------------------------
$(".portlet-header .ui-icon-disk").click(function() {
 var url = $("#q_hist").val();
    $("#search_history_dialog").dialog({
                        bgiframe: true,
                        resizable: true,
                        height: 'auto',
                        width: '75%',
                        autoOpen:false,
                        modal: true,
                        open: function() {
                         $("#url").val(url);
                         },
                        overlay: {
                                backgroundColor: '#000',
                                opacity: 0.5
                        },
                        buttons: {
                                'Save to History': function() {
                                        $(this).dialog('close');
                                        var urlname = $("#urlname").val();
                                        var show_suppressed = $('#show_suppressed :selected').val();
                                        var sel_usave_limit = $('#sel_usave_limit :selected').val();
                                        var hosts = $("#usave_hosts").val();
                                        // alert("hosts = " +hosts);
                                        var dupop = $('#dupop :selected').val()
                                            // alert("dupop = "+ dupop);
                                        var dupcount = $("#dupcount").val();
                                            // alert("dupcount = "+ dupcount);
                                        var orderby = $('#orderby :selected').val();
                                            // alert("orderby = "+ orderby);
                                        var order = $('#order :selected').val();
                                            // alert("order = "+ order);
                                        var fo_checkbox = $('input:checkbox[name=fo_checkbox]:checked').val();
                                             // alert("focheck = "+ fo_checkbox);
                                        var fo_date = $("#fo_date").val();
                                            // alert("fo_date = "+ fo_date);
                                        var fo_time_start_usave = $("#fo_time_start_usave").val();
                                            // alert("fo_time_start_usave = "+ fo_time_start_usave);
                                        var fo_time_end_usave = $("#fo_time_end_usave").val();
                                            // alert("fo_time_end_usave = "+ fo_time_end_usave);
                                        var lo_date = $("#lo_date").val();
                                            // alert("lo_date = "+ lo_date);
                                        var lo_checkbox = $('input:checkbox[name=lo_checkbox]:checked').val();
                                            // alert("locheck = "+ lo_checkbox);
                                        var lo_time_start_usave = $("#lo_time_start_usave").val();
                                            // alert("lo_time_start_usave = "+ lo_time_start_usave);
                                        var lo_time_end_usave = $("#lo_time_end_usave").val();
                                            // alert("lo_time_end_usave = "+ lo_time_end_usave);
                                        var date_andor = $('#date_andor :selected').val();
                                            // alert("dar = "+ date_andor);
                                        url = url.replace(/show_suppressed=\w*&/, "show_suppressed="+ show_suppressed + "&");
                                        url = url.replace(/limit=\w*&/, "limit="+ sel_usave_limit + "&");
                                        url = url.replace(/hosts=\w*&/, "hosts="+ hosts + "&");
                                        url = url.replace(/dupop=\w*&/, "dupop="+ dupop + "&");
                                        url = url.replace(/dupcount=\w*&/, "dupcount="+ dupcount + "&");
                                        url = url.replace(/orderby=\w*&/, "orderby="+ orderby + "&");
                                        url = url.replace(/order=\w*&/, "order="+ order + "&");
                                        if (fo_checkbox == 'on') {
                                        url = url.replace(/fo_checkbox=\w*&/, "fo_checkbox="+ fo_checkbox + "&");
                                        } else {
                                        url = url.replace(/fo_checkbox=\w*&/, "fo_checkbox=&");
                                        }
                                        if (lo_checkbox == 'on') {
                                        url = url.replace(/lo_checkbox=\w*&/, "lo_checkbox="+ lo_checkbox + "&");
                                        } else {
                                        url = url.replace(/lo_checkbox=\w*&/, "lo_checkbox=&");
                                        }
                                        url = url.replace(/fo_date=\S*?&/, "fo_date="+ fo_date + "&");
                                        url = url.replace(/lo_date=\S*?&/, "lo_date="+ lo_date + "&");
                                        url = url.replace(/date_andor=\w*?&/, "date_andor="+ date_andor + "&");
                                        url = url.replace(/fo_time_start=\S*?&/, "fo_time_start="+ fo_time_start_usave + "&");
                                        url = url.replace(/fo_time_end=\S*?&/, "fo_time_end="+ fo_time_end_usave + "&");
                                        url = url.replace(/lo_time_start=\S*?&/, "lo_time_start="+ lo_time_start_usave + "&");
                                        url = url.replace(/lo_time_end=\S*?&/, "lo_time_end="+ lo_time_end_usave + "&");
                                        // alert(url);
                                        if (urlname !== '') {
                                        $.get("includes/ajax/qhistory.php?action=save&url="+escape(url)+"&urlname="+urlname+"&spanid=search_history", function(data){
                                            $('#msgbox_br').jGrowl(data);
                                            $("#search_history").append("<li><a href='"+url+"'>" + urlname + "</a></li>\n");
                                           });
                                        } else {
                                            $('#msgbox_br').jGrowl("Unable to save URL: no name entered");
                                        }
                                },
                                Cancel: function() {
                                        $(this).dialog('close');
                                }
                        }
                });
                $("#search_history_dialog").dialog('open');     
                //return false;
     });
//---------------------------------------------------------------
// END: Save URL function
//---------------------------------------------------------------

//---------------------------------------------------------------
// BEGIN: Get URL function
// Places the output in the menu under "History"
//---------------------------------------------------------------
$.get("includes/ajax/qhistory.php?action=get&spanid=search_history", function(data){
$("#search_history").append(data);
        });
$.get("includes/ajax/qhistory.php?action=get&spanid=chart_history", function(data){
$("#chart_history").append(data);
        });
//---------------------------------------------------------------
// END: Get URL function
// Places the output in the menu under "History"
//---------------------------------------------------------------
</script>
<!-- END Add Save URL icon to search results -->

<!-- BEGIN Style Select Boxes -->
<script type="text/javascript">
/*
$(document).ready(function() {
        $('#msg_mask_oper').selectbox(  
            {  
            inputClass: 'sbox_50', 
            // onChangeCallback: myfunction,  
            // containerClass: 'selectbox-wrapper', // The list container class (a div element)  
            // hoverClass: 'current', // css class for the current element  
            // currentClass: 'selected', // css class for the selected element  
            // debug: false // debug mode on/off  
            }  
        );  
        $('#notes_mask_oper').selectbox(  
            {  
            inputClass: 'sbox_50', 
            }  
        );  
        $('#notes_andor').selectbox(  
            {  
            inputClass: 'sbox_50', 
            }  
        );  
        $('#date_andor').selectbox(  
            {  
            inputClass: 'sbox_50', 
            }  
        );  
        $('#topx').selectbox(  
            {  
            inputClass: 'sbox_50', //css class for the input which will replace the select tag, display the background image  
            }  
        );  
        $('#dupop').selectbox(  
            {  
            inputClass: 'sbox_50', 
            }  
        );  
        $('#orderby').selectbox(  
            {  
            inputClass: 'sbox_100', 
            }  
        );  
        $('#order').selectbox(  
            {  
            inputClass: 'sbox_100', 
            }  
        );  
        $('#limit').selectbox(  
            {  
            inputClass: 'sbox_50', 
            }  
        );  
        $('#tail').selectbox(  
            {  
            inputClass: 'sbox_100', 
            }  
        );  
});
*/
</script>
<!-- END Style Select Boxes -->

<!-- BEGIN Severity Filters -->
<script type="text/javascript">
function showAll()
{
    $('#theTable tr').show()
}
function filter(sev)
{
    $('#theTable tr').hide()

$('#theTable tr').each(function() 
{
        if(this.id == sev)
        {
                $(this).show()
        }
});
//     $('#' + sev).show()
$('.HeaderRow').show();
}
</script>
<!-- END Severity Filters -->

<!-- BEGIN Paginator and Table formatter -->
<!--[if IE]>
<style type="text/css">
ul.fdtablePaginater {display:inline-block;}
ul.fdtablePaginater {display:inline;}
ul.fdtablePaginater li {float:top;}
ul.fdtablePaginater {text-align:center;}
table { border-bottom:1px solid #C1DAD7; }
</style>
<![endif]-->

<script type="text/javascript">
var callbackTest = {
        displayTextInfo:function(opts) {
                if(!("currentPage" in opts)) { return; }
                
                var p = document.createElement('p'),
                    t = document.getElementById('theTable-fdtablePaginaterWrapTop'),
                    b = document.getElementById('theTable-fdtablePaginaterWrapBottom');
                
                p.className = "paginationText";    
                p.appendChild(document.createTextNode("Showing page " + opts.currentPage + " of " + Math.ceil(opts.totalRows / opts.rowsPerPage)));
                
                t.insertBefore(p.cloneNode(true), t.firstChild);
                b.appendChild(p);
        }
};
</script>
<!-- END Paginator and Table formatter -->

<!-- BEGIN Clock -->
<script type="text/javascript">
/***********************************************
* Local Time script- Dynamic Drive (http://www.dynamicdrive.com)
* This notice MUST stay intact for legal use
* Visit http://www.dynamicdrive.com/ for this script and 100s more.
***********************************************/

// CDUKES: Modified for use with 24 hour display

var weekdaystxt=["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"]

function showLocalTime(container, servermode, offsetMinutes, displayversion){
if (!document.getElementById || !document.getElementById(container)) return
this.container=document.getElementById(container)
this.displayversion=displayversion
var servertimestring=(servermode=="server-php")? '<?php print date("F d, Y H:i:s", time())?>' : (servermode=="server-ssi")? '<!--#config timefmt="%B %d, %Y %H:%M:%S"--><!--#echo var="DATE_LOCAL" -->' : '<%= Now() %>'
this.localtime=this.serverdate=new Date(servertimestring)
this.localtime.setTime(this.serverdate.getTime()+offsetMinutes*60*1000) //add user offset to server time
this.updateTime()
this.updateContainer()
}

showLocalTime.prototype.updateTime=function(){
var thisobj=this
this.localtime.setSeconds(this.localtime.getSeconds()+1)
setTimeout(function(){thisobj.updateTime()}, 1000) //update time every second
}

showLocalTime.prototype.updateContainer=function(){
var thisobj=this
if (this.displayversion=="long")
this.container.innerHTML=this.localtime.toLocaleString()
else{
var hour=this.localtime.getHours()
var minutes=this.localtime.getMinutes()
var seconds=this.localtime.getSeconds()
var ampm=(hour>=12)? "PM" : "AM"
var dayofweek=weekdaystxt[this.localtime.getDay()]
// this.container.innerHTML=formatField(hour, 1)+":"+formatField(minutes)+":"+formatField(seconds)+" "+ampm+" ("+dayofweek+")"
this.container.innerHTML=formatField(hour)+":"+formatField(minutes)+":"+formatField(seconds)+" ("+dayofweek+")"
}
setTimeout(function(){thisobj.updateContainer()}, 1000) //update container every second
}

function formatField(num, isHour){
if (typeof isHour!="undefined"){ //if this is the hour field
var hour=(num>12)? num-12 : num
return (hour==0)? 12 : hour
}
return (num<=9)? "0"+num : num//if this is minute or sec field
}
$("#portlet-header_Date_and_Time").replaceWith("<div class=\"portlet-header\" id=\"portlet-header_Date_and_Time\">Current Server Time: <span id=\"timecontainer\"></span></div>");
new showLocalTime("timecontainer", "server-php", 0, "short")

</script>
<!-- END Clock -->

<!-- BEGIN Reset UI Layout -->
<script type="text/javascript">
function reset_layout()
{
    $.get("includes/ajax/json.useradmin.php?action=reset_layout", function(data){
            window.location = window.location;
            $('#msgbox_br').jGrowl(data);
            });
}; 
</script>
<!-- END Reset UI Layout -->
<!-- BEGIN Tip Modal -->
<script type="text/javascript">
<?php if ($_SESSION['TOOLTIP_GLOBAL'] == "1") { ?>
$(document).ready(function() {  
        $("#tipmodal").dialog({
                        bgiframe: true,
                        resizable: true,
                        height: '400',
                        width: '50%',
                        autoOpen:false,
                        modal: true,
                        open: function() {
                           $.get("includes/ajax/totd.php?action=get", function(data){
                         $("#tiptext").html(data);
                           });
                         },
                        overlay: {
                                backgroundColor: '#000',
                                opacity: 0.5
                        },
                        buttons: {
                                'Next Tip': function() {
                                        $.get("includes/ajax/totd.php?action=get", function(data){
                                            if (data != '') {
                                            $("#tiptext").html(data);
                                            } else {
                                            $('#msgbox_br').jGrowl("No more tips available.");
                                            $("#tipmodal").dialog('close');
                                            }
                                           });
                                },
                                'Close': function() {
                                        $(this).dialog('close');
                                },
                                'Disable Tips': function() {
                                        $.get("includes/ajax/totd.php?action=disable", function(data){
                                            $('#msgbox_br').jGrowl(data);
                                            $("#tipmodal").dialog('close');
                                           });
                                },
                        }
                });
                $("#tipmodal").dialog('open');     
        });
<?php } ?>
        </script>
<!-- END Tip Modal -->
<!-- BEGIN Search Param Text -->
<script type="text/javascript">
$(function(){
        $('select#programs').change(function(){
            var prog = $("#programs").val();
            $("#span_prog").text("programs containing the word(s) "+prog);
            });
});
</script>
<!-- END Search Param Text -->
