<?php
/*
 * portlet-sadmin.php
 *
 * Developed by Clayton Dukes <cdukes@logzilla.pro>
 * Copyright (c) 2010 LogZilla, LLC
 * All rights reserved.
 * Last updated on 2010-06-15
 *
 * Pagination and table formatting created using 
 * http://www.frequency-decoder.com/2007/10/19/client-side-table-pagination-script/
 * Changelog:
 * 2010-02-28 - created
 *
 */

$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

//---------------------------------------------------
// The get_input statements below are used to get
// POST, GET, COOKIE or SESSION variables.
// Note that PLURAL words below are arrays.
//---------------------------------------------------

if ((has_portlet_access($_SESSION['username'], 'Server Settings') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) { 
?>

    <script>
    $(function() {
        $( "#div_admin_accordian" ).accordion({
            active: false,
                collapsible: true
        });
    });
    </script>

<h3 class="docs">Changing some of these settings will render your server unusable, proceed with CAUTION!!!</h3>

<div id="div_adminMenu" style="padding:2px; width:20%; height:100%;" class="ui-widget-content">

    <div id="div_admin_accordian">
        <h3><a href="#">Basic Settings</a></h3>
        <div>
            <a href="#" class='adminItem' id='ADMIN_NAME'>Admin Name</a><br />
            <a href="#" class='adminItem' id='ADMIN_EMAIL'>Admin Email</a><br />
            <a href="#" class='adminItem' id='FEEDBACK'>Feedback Button (Idea Box)</a><br />
            <a href="#" class='adminItem' id='SESS_EXP'>Login Session Timeout</a><br />
            <a href="#" class='adminItem' id='SITE_NAME'>Website Name</a><br />
            <a href="#" class='adminItem' id='SPARKLINES'>EPS Stock Ticker</a><br />
            <a href="#" class='adminItem' id='TOOLTIP_GLOBAL'>LogZilla Tips</a><br />
            <a href="#" class='adminItem' id='TOOLTIP_REPEAT'>Tip Timer</a><br />
        </div>
        <h3><a href="#">Alerts</a></h3>
        <div>
            <a href="#" class='adminItem' id='MAILHOST'>Mail Host</a><br />
            <a href="#" class='adminItem' id='MAILHOST_PORT'>Mail Host Port</a><br />
            <a href="#" class='adminItem' id='MAILHOST_USER'>Mail Host User (Optional)</a><br />
            <a href="#" class='adminItem' id='MAILHOST_PASS'>Mail Host Password (Optional)</a><br />
            <a href="#" class='adminItem' id='SNMP_SENDTRAPS'>Send Alerts to SNMP Trap Manager</a><br />
            <a href="#" class='adminItem' id='SNMP_COMMUNITY'>SNMP Community</a><br />
            <a href="#" class='adminItem' id='SNMP_TRAPDEST'>SNMP Destination</a><br />
        </div>
        <h3><a href="#">RBAC</a></h3>
        <div>
            <a href="#" class='adminItem' id='RBAC_ALLOW_DEFAULT'>New User Security</a><br />
        </div>
        <h3><a href="#">Timing</a></h3>
        <div>
            <a href="#" class='adminItem' id='Q_LIMIT'>Message Queue Limit</a><br />
            <a href="#" class='adminItem' id='Q_TIME'>Message Queue Time Limit</a><br />
        </div>
        <h3><a href="#">Data Retention</a></h3>
        <div>
            <a href="#" class='adminItem' id='RETENTION'>Retention Policy</a><br />
            <a href="#" class='adminItem' id='RETENTION_DROPS_HOSTS'>Stale Host Purging</a><br />
            <!-- Deprecated in v4.5 
            <a href="#" class='adminItem' id='ARCHIVE_PATH'>Archive Path</a><br />
            <a href="#" class='adminItem' id='ARCHIVE_BACKUP'>Archival Command</a><br />
            <a href="#" class='adminItem' id='ARCHIVE_RESTORE'>Archival Restore Command</a><br /> -->
        </div>
        <h3><a href="#">Authentication</a></h3>
        <div>
            <a href="#" class='adminItem' id='AUTHTYPE'>Authorization Type</a><br />
            <a href="#" class='adminItem' id='LDAP_BASE_DN'>LDAP Base DN</a><br />
            <a href="#" class='adminItem' id='LDAP_CN'>LDAP CN</a><br />
            <a href="#" class='adminItem' id='LDAP_DNU_GRP'>LDAP Group</a><br />
            <a href="#" class='adminItem' id='LDAP_DOMAIN'>LDAP Domain</a><br />
            <a href="#" class='adminItem' id='LDAP_MS'>Use Microsoft LDAP Type</a><br />
            <a href="#" class='adminItem' id='LDAP_SRV'>LDAP Server Address</a><br />
        </div>
        <h3><a href="#">Chart Options</a></h3>
        <div>
            <a href="#" class='adminItem' id='CACHE_CHART_MPH'>MPH Chart</a><br />
            <a href="#" class='adminItem' id='CACHE_CHART_MPW'>MPW Chart</a><br />
            <!-- not used anymore?
            <a href="#" class='adminItem' id='CACHE_CHART_TOPHOSTS'>Hosts Chart Cache</a><br />
            <a href="#" class='adminItem' id='CACHE_CHART_TOPMSGS'>Messages Chart Cache</a><br />
            -->
            <a href="#" class='adminItem' id='CHART_MPD_DAYS'>MPD Chart</a><br />
            <a href="#" class='adminItem' id='CHART_SOW'>Week Start</a><br />
        </div>
        <h3><a href="#">Debugging</a></h3>
        <div>
            <a href="#" class='adminItem' id='DEBUG'>Set Debug Level</a><br />
        </div>
        <h3><a href="#">Deduplication</a></h3>
        <div>
            <a href="#" class='adminItem' id='DEDUP'>Deduplication</a><br />
            <a href="#" class='adminItem' id='DEDUP_WINDOW'>Lookback Window</a><br />
        </div>
        <h3><a href="#">Paths</a></h3>
        <div>
            <a href="#" class='adminItem' id='PATH_BASE'>Path To LogZilla (on disk)</a><br />
            <a href="#" class='adminItem' id='PATH_LOGS'>Path To logging directory (on disk)</a><br />
            <a href="#" class='adminItem' id='SITE_URL'>Relative Site URL</a><br />
        </div>
        <h3><a href="#">Portlets</a></h3>
        <div>
            <a href="#" class='adminItem' id='PORTLET_EID_LIMIT'>Snare Portlet Limit</a><br />
            <a href="#" class='adminItem' id='PORTLET_HOSTS_LIMIT'>Hosts Portlet Limit</a><br />
            <a href="#" class='adminItem' id='PORTLET_MNE_LIMIT'>Mnemonics Portlet Limit</a><br />
            <a href="#" class='adminItem' id='PORTLET_PROGRAMS_LIMIT'>Programs Portlet Limit</a><br />
            <a href="#" class='adminItem' id='SHOWCOUNTS'>Show Portlet Counts</a><br />
        </div>
        <h3><a href="#">Sphinx Tuning</a></h3>
        <div>
            <a href="#" class='adminItem' id='SPX_MAX_MATCHES'>Maximum Result Set</a><br />
            <a href="#" class='adminItem' id='SPX_MEM_LIMIT'>Memory Limit</a><br />
            <a href="#" class='adminItem' id='SPX_PORT'>Port</a><br />
            <a href="#" class='adminItem' id='SPX_SRV'>Server IP</a><br />
            <a href="#" class='adminItem' id='SPX_IDX_DIM'>Index DIM</a><br />
        </div>
        <h3><a href="#">Audit Logging</a></h3>
        <div>
            <a href="#" class='adminItem' id='SYSTEM_LOG_DB'>Audit Logs to Database</a><br />
            <a href="#" class='adminItem' id='SYSTEM_LOG_FILE'>Audit Logs to File</a><br />
            <a href="#" class='adminItem' id='SYSTEM_LOG_SYSLOG'>Audit Logs to Syslog</a><br />
        </div>
        <h3><a href="#">Windows Events</a></h3>
        <div>
            <a href="#" class='adminItem' id='SNARE'>SNARE Windows Event Processing</a><br />
        </div>
        <h3><a href="#">Table Display</a></h3>
        <div>
            <a href="#" class='adminItem' id='TBL_SEV_SHOWCOLORS'>Show Colors</a><br />
            <a href="#" class='adminItem' id='TBL_SEV_0_EMERG'>Severity 0 (Emergency)</a><br />
            <a href="#" class='adminItem' id='TBL_SEV_1_CRIT'>Severity 1 (Critical)</a><br />
            <a href="#" class='adminItem' id='TBL_SEV_2_ALERT'>Severity 2 (Alert)</a><br />
            <a href="#" class='adminItem' id='TBL_SEV_3_ERROR'>Severity 3 (Error)</a><br />
            <a href="#" class='adminItem' id='TBL_SEV_4_WARN'>Severity 4 (Warning)</a><br />
            <a href="#" class='adminItem' id='TBL_SEV_5_NOTICE'>Severity 5 (Notice)</a><br />
            <a href="#" class='adminItem' id='TBL_SEV_6_INFO'>Severity 6 (Informational)</a><br />
            <a href="#" class='adminItem' id='TBL_SEV_7_DEBUG'>Severity 7 (Debug)</a><br />
        </div>
    </div>

</div><!-- End div_adminMenu -->
<style>
    body {
        margin:0; padding:0;
    }
    .tableWrapper {
        position: absolute;
        border: 1px solid #246591;
        width: 60% /* width of your table*/; 
        top: 17%;
        left: 24%;
        margin:0 
        auto;
    }
    #settingsSaveResultBox {
        position: absolute;
        border: 1px solid #00FF00;
        width: 60% /* width of your table*/; 
        top: 17%;
        left: 24%;
        margin:0 
        auto;
    }
</style>
<div class="tableWrapper">
</style>
<table>
    <th><span id="settingsTitle"></span></th>
    <th><span id="settingsDesc"></span></th>
    <tbody>
        <tr>
            <td><span id="settingsDescription"></span></td>
            <td><span id="settingsContent"></span></td>
            <td><button id='settingsButton'>Submit</button></td>
        </tr>
    </table>
</div>
<div id="settingsSaveResultBox"><div id="settingsSaveResultContent" style="text-align:center"></div></div>
    <script type="text/javascript"> 
    // Map the enter key to the submit button
    $(document).bind('keypress', function(e){
        if(e.which === 13) { // return
            $('#settingsButton').trigger('click');
        }
    });
    $(document).ready(function(){
        $("#settingsButton").button();
        $("#settingsButton").hide();
        $(".tableWrapper").hide();
        $("#settingsSaveResultBox").hide();
        var name = "";
        var curValue = "";
        var type = "";
        var options = "";
        var def = "";
        var selected = "";
        var clickedItem = "";
        $('.adminItem').click(function() {
            $("#settingsContent").show();
            $("#settingsButton").show();
            $(".tableWrapper").show('fast');
            $("#settingsSaveResultBox").hide();
            name = $(this).attr('id');
            clickedItem = $(this).text();
            $.get("includes/ajax/admin.php?action=get&name=" +name,
                function(data){
                    // Return data sample: 
                    // Object {name: "FEEDBACK", value: "1", type: "enum", options: "0,1", default: "0"}
                    // def: "0"
                    // default: ""
                    // description: "This variable will enable or disable the "Submit Idea" button on the bottom right of the screen.<br>
                    // ?Servers with no internet access should disable this."
                    // name: "FEEDBACK"
                    // options: "0,1"
                    // type: "enum"
                    // value: "1"
                    name = data.name;
                    curValue = data.value;
                    type = data.type;
                    options = data.options;
                    def = data.default;
                    var opts = "";
                    if (type == "enum") {
                        var options = data.options.split(",");
                        for(i = 0; i < options.length; i++){
                            if(options[i] == curValue) {
                                opts += '<option selected value="'+options[i]+'">'+options[i]+'</option>';
                            } else {
                                opts += '<option value="'+options[i]+'">'+options[i]+'</option>';
                            }
                        }
                        $("#settingsContent").html('<select id="sel_value" multiple size=0>'+opts+'</select><span id="result"></span>');
                        $("#sel_value").multiselect({
                            show: ["blind", 200],
                                hide: ["drop", 200],
                                selectedList: 1,
                                multiple: false,
                                noneSelectedText: 'Select',
                        });
                    } else {
                        $("#settingsContent").html('<input type=text class="rounded ui-widget ui-corner-all" id="inp_'+name+'" value="'+curValue+'"  /><span id="result"></span>');
                    }
                    $("#settingsDescription").html("<div style='padding:10px;'>" + data.description + "<br>Default: " + data.def + "<div>");
                }, "json");

        })
            $('#settingsButton').click(function() {
                if (type == "enum") {
                    selected = $('#sel_value').val();
                } else {
                    selected = $('#inp_'+name).val();
                }
                // console.log("DEBUG Selected = " + selected);
                $.get("includes/ajax/admin.php?action=get&name=" +name,
                    function(data){
                        value = data.value;
                    }, "json");
                $.get("includes/ajax/admin.php?action=save&name=" +name+"&orig_value="+curValue+"&new_value="+selected,
                    function(data){
                        $("#settingsContent").hide();
                        $("#settingsButton").hide();
                        $(".tableWrapper").hide('slow');
                        $("#settingsSaveResultContent").html(clickedItem + data);
                        $("#settingsSaveResultBox").show('slow');
                    })
            })
    }); // end doc ready
    </script>

<?php } else { ?>
    <script type="text/javascript">
    $('#portlet_Server_Settings').remove()
        </script>
    <?php } ?>
