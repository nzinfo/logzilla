<?php
/*
 * portlet-table.php
 *
 * Developed by Clayton Dukes <cdukes@logzilla.pro>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-06-15
 *
 * Changelog:
 * 2010-02-28 - created
 *
 */

// session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
require_once ($basePath . "/portlet_header.php");
if ((has_portlet_access($_SESSION['username'], 'Search Results') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) {
    $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);


    // $error gets set in portlets/portlet_header.php
    if (!$error) {

        // echo "<pre>";
        // die(print_r($sphinx_results));

        //------------------------------------------------------------
        // CDUKES
        // Note: Meta info is appended to search results, so the metadata 
        // can be found at position $limit (e.g: if user sets limit = 100, then "total" is found at $result[100]
        // Note: Have to get first occurrence of total, total_found and time because of the RBAC hosts being appended to the query.
        // When the hosts are appended, these totals show for those as well in the meta info
        //------------------------------------------------------------
        // echo "<pre>";
        // die(print_r($sphinx_results));

        // Remove any warnings if they exist
        $meta = array_slice($sphinx_results, $limit); 
        while ($meta[0]['Variable_name'] !== 'total') {
            array_shift($meta);
        }
        $meta['total'] = $meta[0]['Value'];
        $meta['total_found'] = $meta[1]['Value'];
        $meta['time'] = $meta[2]['Value'];
        // Get totals
        $total = $meta['total'];
        $total_found = $meta['total_found'];
        $time = $meta['time'];
        for ($i = $limit; $i <= count($sphinx_results, COUNT_RECURSIVE); $i++) {
            if (!preg_match("/^total|time/", $sphinx_results[$i]['Variable_name'])) {
                $meta[$sphinx_results[$i]['Variable_name']] = $sphinx_results[$i]['Value'];
            }
            // Remove the meta info from the results so that we can do our mysql now.
            unset($sphinx_results[$i]);
        }

        if (sizeof($sphinx_results) > 0) {
            $where = " where id IN (";
            foreach ( $sphinx_results as $result ) {
                $where .= "'$result[0]',";
            }
            $where = rtrim($where, ",");
            $where .= ")";

        } else {
            // Negate search since sphinx returned 0 hits
            $where = "WHERE 1<1";
        }


        if ($orderby) {
            $where.= " ORDER BY $orderby";  
        }
        if ($order) {
            $where.= " $order";  
        }

    }

    if (!$error) {
        $sql_fac = "(SELECT name FROM facilities WHERE code=facility) AS facility";
        $sql_sev = "(SELECT name FROM severities WHERE code=severity) AS severity";
        $sql_prg = "(SELECT name FROM programs WHERE crc=program) AS program";
        $sql_mne = "(SELECT name FROM mne WHERE crc=mne) AS mne";
        $select_columns = "id,host,$sql_fac,$sql_sev,$sql_prg,$sql_mne,msg,eid,suppress,counter,fo,lo,notes";
        $_SESSION['select_columns'] = $select_columns;

        // Generate a random name for the view so they don't overlap. We'll cleanup these views in the nightly cleanup from LZTool
        // TH: small bug-fix: use Hour in 24h format; views were only deleted once a day
        $uname_clean = preg_replace('/[^a-zA-Z0-9\s]/', '', $_SESSION['username']);

        // CD: #466 - Cleanup of views kills tail table when users run tail mode > 24 hours
        // As a result, we'll use unix ts to set when the view should expire. This way LZTool will
        // only delete views that are expired
        if ($tail > 0) {
            $exp = time() + (365 * 24 * 60 * 60);
        } else {
            $exp = time() + (24 * 60 * 60);
        }
        $_SESSION['viewname'] = "${exp}_${uname_clean}_search_results";

        switch ($show_suppressed):
        case "suppressed":
            $sql = "CREATE OR REPLACE VIEW ".$_SESSION['viewname']." AS SELECT $select_columns FROM ".$_SESSION['TBL_MAIN']."_suppressed $where LIMIT $limit";
            // $sql = "SELECT * FROM ".$_SESSION['TBL_MAIN']."_suppressed $where LIMIT $limit";
            break;
        case "unsuppressed":
            $sql = "CREATE OR REPLACE VIEW ".$_SESSION['viewname']." AS SELECT $select_columns FROM ".$_SESSION['TBL_MAIN']."_unsuppressed $where LIMIT $limit";
            // $sql = "SELECT * FROM ".$_SESSION['TBL_MAIN']."_unsuppressed $where LIMIT $limit";
            break;
        default:
            $sql = "CREATE OR REPLACE VIEW ".$_SESSION['viewname']." AS SELECT $select_columns FROM ".$_SESSION['TBL_MAIN']." $where LIMIT $limit";
            // $sql = "SELECT * FROM ".$_SESSION['TBL_MAIN'] ." $where LIMIT $limit";
            endswitch;

            $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']); 

            if ($total_found == 'unknown') {

                switch ($show_suppressed):
                case "suppressed":
                    $sql = "SELECT count(*) as tots FROM ".$_SESSION['TBL_MAIN']."_suppressed $where";
                    break;
                case "unsuppressed":
                    $sql = "SELECT count(*) as tots FROM ".$_SESSION['TBL_MAIN']."_unsuppressed $where";
                    break;
                default:
                    $sql = "SELECT count(*) as tots FROM ".$_SESSION['TBL_MAIN'] ." $where";
                    endswitch;

                    $tots =perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
                    while($row = fetch_array($tots)) {
                        $total_found = $row['tots'];
                    }
            }

            ?>
                <script type="text/javascript" charset="utf-8">
                $(document).ready(function() {
                        $('#results').dataTable( {
			"bProcessing": true,
                	"bServerSide": true,
                	"sScrollX": "95%",
                            "bServerSide": true,
			     // Don't use scrollxinnner - it will autowidth
                             //"sScrollXInner": "100%",
                            "aoColumns":[
                            { "sWidth": "0%" }, // ID
                            { "sWidth": "1%" }, // EID
                            { "sWidth": "2%" }, // Host
                            { "sWidth": "2%" }, // Fac
                            { "sWidth": "2%" }, // Sev
                            { "sWidth": "2%" }, // Program
                            { "sWidth": "2%" }, // Mne
                            { "sWidth": "50%" }, // MSG
<?php if ($_SESSION['DEDUP'] == "1") {?>
                            { "sWidth": "10%" }, // FO
                            { "sWidth": "10%" }, // LO
                            { "sWidth": "5%" }, // Counter
                            <?php } else { ?>
                            { "sWidth": "20%" }, // LO
                            <?php } ?>
                            // disabled in this version since there is currently no way to enter notes
                            // { "sWidth": "15%" }, // Notes
                            ],
			    "fnDrawCallback": function(oSettings) {
				    for ( var i=0, iLen=oSettings.aoData.length ; i<iLen ; i++ ) {
					    var sev = oSettings.aoData[i]._aData[4];
					    var colorCSS;
					    if(sev === 'emerg') {
						    colorCSS = 'TBL_SEV_0_EMERG';
					    } else if(sev === 'crit') {
						    colorCSS = 'TBL_SEV_1_CRIT';
					    } else if(sev === 'alert') {
						    colorCSS = 'TBL_SEV_2_ALERT';
					    } else if(sev === 'err') {
						    colorCSS = 'TBL_SEV_3_ERROR';
					    } else if(sev === 'warning') {
						    colorCSS = 'TBL_SEV_4_WARN';
					    } else if(sev === 'notice') {
						    colorCSS = 'TBL_SEV_5_NOTICE';
					    } else if(sev === 'info') {
						    colorCSS = 'TBL_SEV_6_INFO';
					    } else if(sev === 'debug') {
						    colorCSS = 'TBL_SEV_7_DEBUG';
					    }
					    oSettings.aoData[i].nTr.className += " "+colorCSS;
                                            $("tr td:nth-child(7)").addClass('msg');
				    }
                                    // #499 - BEGIN: context menu search function
                                    function getSelectionText() {
                                        var text = "";
                                        if (window.getSelection) {
                                            text = window.getSelection().toString();
                                        } else if (document.selection && document.selection.type != "Control") {
                                            text = document.selection.createRange().text;
                                        }
                                        return text;
                                    }
                                    $(document).ready(function (){
                                        // http://medialize.github.io/jQuery-contextMenu/
                                        $.contextMenu({
                                            selector: '.msg', 
                                                className: 'css-title',
                                                callback: function(key, options) {
                                                    var m = "clicked: " + key;
                                                    // window.console && console.log(m) || alert(m); 
                                                    if (key == "search") {
                                                        var searchText = getSelectionText();
                                                        if(searchText !== "") {
                                                            if (searchText.length > 2) {
                                                                var qstring = '<?php echo $qstring?>';
                                                                var url = qstring.replace(/msg_mask=(.*?)&/im, "msg_mask=*" + searchText + "*&");
                                                                window.location = url;
                                                            } else {
                                                                error("Searches must be > 2 characters.");
                                                            }
                                                        } else {
                                                            error("No text selected!<br>Please highlight a word in the Message column before clicking Search.");
                                                        }
                                                    }
                                                },
                                                    items: {
                                                        "search": {
                                                            name: "<span>Click here to perform a NEW search for highlighted text</span><BR /><span style='font-size: 9px; font-style:italic'>Or use ctrl-c/apple-c if you meant to copy the selected text into your clipboard</span>", icon: "search"},
/*
                                                                // <input type="text">
                                                                name: {
                                                                    name: "Or, enter a new search word here:", 
                                                                        type: 'text', 
                                                                        value: getSelectionText(), 
                events: {
                    keyup: function(e) {
                        // add some fancy key handling here?
                        window.console && console.log('key: '+ e.keyCode); 
                    }
                }
                                                                },
*/
                                                                    sep1: "---------",
                                                                    "quit": {name: "Quit", icon: "quit"},
                                                    }
                                        });
                                    });
                                    // #499 - END: Added context menu search function
                            },
                                "aaSorting": [[ 0, "desc" ]],
                                "fnServerParams": function ( aoData ) {
                                    var $slider = $('#slider');
                                    if ($slider[0].hasChildNodes()) {
                                        var values = $slider.slider('values');
                                        var startTime = $slider.data('startTime');
                                        aoData.push( { "name": "startTime", "value": startTime + values[0] } );
                                        // #466 - extend time window to 1 year, tail doesn't use slider, so just extend it out, 
                                        // otherwise tail mode stops showing data after 2 hours
                                        var tail = '<?php echo $tail?>';
                                        if (tail > 0) {
                                            var end = values[1];
                                            end += 31557600; // 1 Year
                                            aoData.push( { "name": "endTime", "value": startTime + end } );
                                        } else {
                                            aoData.push( { "name": "endTime", "value": startTime + values[1] } );
                                        }
                                    }
                                },

                                    "fnServerData": function ( sSource, aoData, fnCallback ) {
                                        $.ajax({
                                            "dataType": 'json',
                                                "type": 'GET',
                                                "url": sSource,
                                                "data": aoData,
                                                "success": function (data, textStatus, jqXHR) {
                                                    if (data.startTime && data.endTime) {
                                                        // create the slider
                                                        var $slider = $('#slider');
                                                        var startTime = parseInt(data.startTime);
                                                        var endTime = parseInt(data.endTime);
                                                        $slider.data('startTime', startTime);
                                                        var min = 0;
                                                        var max = endTime - startTime;
                                                        $slider.slider({
                                                            range: true,
                                                                min: min,
                                                                max: max,
                                                                values: [min, max],
                                                                change: function (event, ui) {
                                                                    var values = $slider.slider('values');

                                                                    // refresh the table
                                                                    var table = $('#results').dataTable();
                                                                    table.fnDraw(true);

                                                                }
                                                        });

                                                        if (data.startTimeFormatted && data.endTimeFormatted) {
                                                            $('#sliderStart').html(data.startTimeFormatted);
                                                            $('#sliderEnd').html(data.endTimeFormatted);
                                                        }
                                                    } 

                                                    if (data.startTimeFormatted && data.endTimeFormatted) {
                                                        $('#sliderValues').html('Slide below to filter by time.<br>Current range: ' + data.startTimeFormatted + ' - ' + data.endTimeFormatted);
                                                    }

                                                    fnCallback(data, textStatus, jqXHR);
                                                }
                                        });
                                    },
                                        "sAjaxSource": "includes/ajax/json.results.php"
                        } );
                        function fnShowHide( iCol )
                        {
                            /* Get the DataTables object again - this is not a recreation, just a get of the object */
                            var oTable = $('#results').dataTable();

                            var bVis = oTable.fnSettings().aoColumns[iCol].bVisible;
                            oTable.fnSetColumnVis( iCol, bVis ? false : true );
                        }
                        // Hide the Database ID column - we only use it to sort on
                        fnShowHide(0);
                        <?php if($_SESSION['SNARE'] == "0") {?>
                        // hide the EID column
                        fnShowHide(1);
                        <?php } ?>

                        //------------------------------------
                        // BEGIN auto-refresh 
                        //------------------------------------
                        var tail = '<?php echo $tail?>';
                        if (tail > 0) {
                            $('#results_filter').html('<button id="btnPause">Pause</button>');
                            $("button").button();

                            var time = tail;
                            var timerID;
                            if (time == tail) {
                                startIt();
                                time = 99999;
                            }
                            $("#btnPause").click( function() { 
                                if (time == tail) {
                                    $('#btnPause').text('Running');
                                    startIt();
                                    time = 99999;
                                } else {
                                    $('#btnPause').text('Click to Resume');
                                    stopIt();
                                    time = tail;
                                }
                            });
                            $("button").button();
                            $("#sliderValues").hide();
                            $("#slider").hide();
                            //$("#results_length").hide();
                            $("#results_processing").hide();
                            $("#results_paginate").hide();
                        } else {
                            $("#results_filter").append($('#results_paginate'));
                            $("#results_processing").hide();
                        }

                }); // end doc ready

            var tail = '<?php echo $tail?>';
            function fireIt() {
<?php
            if ($tail > 0) {
                $tail_where = preg_replace('/host_crc/','crc32(host)',$tail_where); 
                $sql = "CREATE OR REPLACE VIEW ".$_SESSION['viewname']." AS SELECT ".$select_columns." FROM ".$_SESSION['TBL_MAIN']." ".$tail_where." ORDER BY lo DESC LIMIT ".$limit;
                logmsg($sql);
                $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
                if(!$result){
?>
                    var err = '<?php echo mysql_error($dbLink)?>';
                    error("MySQL error in table refresh  for Tail mode" + err);
                    stopIt();
                    <?php }} ?>
                    var table = $('#results').dataTable();
                    table.fnDraw(true);
            };
            function startIt () { 
                timerID = setInterval("fireIt()", tail); 
            } 
            function stopIt() { 
                clearInterval(timerID); 
            } 
            //------------------------------------
            // END auto-refresh 
            //------------------------------------

            </script>

<div id="sliderValues"></div>
<div id="slider" style="width: 99.7%;"></div>
<!-- <div id="sliderStart" style="float: left;"></div>
<div id="sliderEnd" style="float: right;"></div> -->
<br />
<div id="table_container">
<div id="dynamic">
<table style="width: 98%" cellpadding="0" cellspacing="0" border="0" class="display" id="results">
<thead>
<tr>
<th>ID</th>
<th>EID</th>
<th>Host</th>
<th>Facility</th>
<th>Severity</th>
<th>Program</th>
<th>Mnemonic</th>
<th>Message</th>
<?php
                    if ($_SESSION['DEDUP'] == "1") {
                        echo "<th>First Seen</th>";
                        echo "<th>Last Seen</th>";
                        echo "<th>Count</th>";
                    } else {
                        echo "<th>Received</th>";
                    }
?>
<!-- Notes disable for now 
<th>Notes</th>
-->
</tr>
</thead>
<tbody>
<tr>
<?php if ($total < 1) {
    $msg = 'No results found for date range';
} else {
    $msg = "Loading results...";
}
    echo "<td colspan='9' class='dataTables_empty'>$msg</td>";
?>
</tr>
</tbody>
<tfoot>
<tr>
<th>ID</th>
<th>EID</th>
<th>Host</th>
<th>Facility</th>
<th>Severity</th>
<th>Program</th>
<th>Mnemonic</th>
<th>Message</th>
<?php
                    if ($_SESSION['DEDUP'] == "1") {
                        echo "<th>First Seen</th>";
                        echo "<th>Last Seen</th>";
                        echo "<th>Count</th>";
                    } else {
                        echo "<th>Received</th>";
                    }
?>
<!-- Notes disable for now 
<th>Notes</th>
-->
</tr>
</tfoot>
</table>

                    <script type="text/javascript">
                    $(function(){
                        $.contextMenu({
                            selector: '#esults td', 
                                items: {
                                    key: {
                                        name: "Menu Clickable", 
                                            callback: function (key, opt) {
                                                alert(opt.$trigger.html());
                                            }
                                    }
                                }, 
                                    events: {
                                        show: function(opt) {
                                            // this is the trigger element
                                            var $this = this;
                                            // import states from data store 
                                            $.contextMenu.setInputValues(opt, $this.data());
                                            // this basically fills the input commands from an object
                                            // like {name: "foo", yesno: true, radio: "3", …}
                                        }, 
                                            hide: function(opt) {
                                                // this is the trigger element
                                                var $this = this;
                                                // export states to data store
                                                $.contextMenu.getInputValues(opt, $this.data());
                                                // this basically dumps the input commands' values to an object
                                                // like {name: "foo", yesno: true, radio: "3", …}
                                            }
                                    }
                        });
                    });
                    </script>

</div>
</div>
<div class="spacer"></div>
                    <script type="text/javascript">
                    //------------------------------------------------------------
                    // Display the total matching DB entries along with the X of X entries
                    //------------------------------------------------------------
<?php
                    if ($total_found < $limit) {
                        $limit = $total_found;
                    }
?>
                    var total = '<?php echo $total?>'
                        // console.log("Total = " + total);
                        if (total < 1) {
                            total = 'No results found for date range <?php echo "$start - $end<br>Time to search: $time seconds";?>'
                        } else {
                            total = '<?php echo "Displaying Top ".commify($limit)." Matches of ".commify($total_found)." possible<br>Date Range: $start - $end<br>Time to search: $time seconds";?>';
                        }

                    $("#portlet-header_Search_Results").html("<div style='text-align: center'>" + total + "</div>");
                    </script>

<!-- BEGIN Add Save URL icon to search results -->
                    <script type="text/javascript">
                    $("#portlet-header_Search_Results").prepend('<span id="export" class="ui-icon ui-icon-print"></span>');
                    $("#portlet-header_Search_Results").prepend('<span id="span_results_save_icon" class="ui-icon ui-icon-disk"></span>');
                    //---------------------------------------------------------------
                    // END: Save URL function
                    //---------------------------------------------------------------
                    </script>
<?php
                    require_once ($basePath . "/portlet_footer.php");
    } 

} else { 
    //------------------------------------------------------------
    // This 'else' is from the top of the file for checking portlet 
    // access. If the user does not have permission, we remove the 
    // portlet
    //------------------------------------------------------------
?>
    <script type="text/javascript">
    $('#portlet_Search_Results').remove()
        </script>
        <?php } ?>
