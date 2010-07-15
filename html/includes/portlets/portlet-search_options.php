<?php

/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2009 gdd.net
 * All rights reserved.
 *
 * Changelog:
 * 2009-12-13 - created
 *
 */

session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
if ((has_portlet_access($_SESSION['username'], 'Search Options') == TRUE) || ($_SESSION['AUTHTYPE'] == "none")) {
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
// -------------------------
// Get Message count and duplicate calculation
// -------------------------
if ($_SESSION['SHOWCOUNTS'] == "1") {
    if ($_SESSION['DEDUP'] == "1") {
        $sql = "SELECT (SELECT value FROM cache WHERE name='msg_sum') as count_all, COUNT(*) as count FROM ".$_SESSION["TBL_MAIN"]."";
        $result = perform_query($sql, $dbLink, $_REQUEST['pageId']);
        $line = fetch_array($result);
        $messagecount = humanReadable($line['count_all']);
        $sumcnt = $line['count_all'];
        $count = $line['count'];
        // simple test for new (or empty) databases so we don't divide by zero on new installs
        if (empty($sumcnt)) {
            $sumcnt = 1;
        }
        if (empty($count)) {
            $count = 1;
        }
        $mph = ($sumcnt/$count);
        // subtract 100 from the total below to get the opposite effect (savings = 90% rather than 10%)
        // Calculation is to get the percentage of messages to messages_per_host (convert a ratio to percentage)
        $dedup_tot = (100 - (round(100/($mph * 100),4)) * 100);
        $dedup_pct = round($dedup_tot,4)."%";
    }
}
?>

<!-- BEGIN HTML for search options -->
<table id="tbl_search_options" cellpadding="0" cellspacing="0" width="100%" border="0">
<thead class="ui-widget-header">
  <tr>
    <th width="45%"></th>
    <th width="10%"></th>
    <th width="45%"></th>
  </tr>
</thead>
  <tbody>
    <?php  if ( $_SESSION['FOOGRAPHS'] == "1" ) { ?>
    <tr>
        <td>TopX</td>
        <td>
        <select name="topx" id="topx">
        <option selected>10</option>
        <option>20</option>
        <option>25</option>
        <option>30</option>
        <option>35</option>
        <option>40</option>
        <option>50</option>
        <option>100</option>
        </select>
        </td>
    </tr>
    <?php  } ?>

    <?php  if ( $_SESSION["DEDUP"] == "1" ) { ?>
    <tr>
        <td>Duplicates <?php echo $dedup_pct?></td>
        <td>
        <select name="dupop" id="dupop">
        <option selected value=""></option>
        <option value="gt">></option>
        <option value="lt"><</option>
        <option value="eq">=</option>
        <option value="gte">>=</option>
        <option value="lte"><=</option>
        </select>
        <input type=text class="rounded watermark ui-widget ui-corner-all" name="dupcount" id="dupcount" value="0" size="3" />
        </td>
    </tr>
    <?php  } ?>

    <tr>
        <td>Sort Order</td>
        <td>
        <select name="orderby" id="orderby">
        <option value="id">Database ID</option>
        <option value="counter">Count</option>
        <option value="host">Host</option>
        <option value="program">Program</option>
        <option value="facility">Facility</option>
        <option value="severity">Severity</option>
        <option value="msg">Message</option>
        <option value="fo">First Occurrence</option>
        <option value="lo" selected>Last Occurrence</option>
        </select>
        </td>
    </tr>

    <tr>
        <td>Search Order</td>
        <td>
        <select name="order" id="order">
        <option value="ASC">Ascending</option>
        <option value="DESC" selected>Descending</option>
        </select>
        </td>
    </tr>

    <tr>
        <td>Limit</td>
        <td>
        <select name="limit" id="limit">
        <option>10
        <option>25
        <option>50
        <option>100
        <option>150
        <option>250
        <option>500
        </select>
        </td>
     </tr>

    <tr>
        <td>Group By</td>
        <td>
        <select name="groupby" id="groupby">
        <option value="host">Host</option>
        <option value="msg">Message</option>
        <option value="program">Program</option>
        <option value="facility">Facility</option>
        <option value="severity">Severity</option>
        <option value="mne">Mnemonic</option>
        </select>
        </td>
    </tr>

    <tr>
        <td>Chart Type</td>
        <td>
        <select name="chart_type" id="chart_type">
        <option value="pie">Pie</option>
        <option value="bar">Bar</option>
        <option value="line">Line</option>
        </select>
        </td>
    </tr>



    <tr>
        <td>Auto Refresh</td>
        <td>
        <select name="tail" id="tail">
        <option value="off">Off
        <option value="1000">1 Second
        <option value="5000">5 Seconds
        <option value="15000">15 Seconds
        <option value="30000">30 Seconds
        <option value="60000">1 Minute
        <option value="300000">5 Minutes
        </select>
        </td>
    </tr>

    <tr>
        <td>Show</td>
        <td>
        <select name="show_suppressed" id="show_suppressed">
        <option value="all">All Events</option>
        <option value="suppressed">Suppressed Events</option>
        <option selected value="unsuppressed">Unsuppressed Events</option>
        </select>
        </td>
    </tr>


    <tr>
        <?php  if ( $_SESSION['FOOGRAPHS'] == "1" ) { ?>
        <td>Graph Type</td>
        <td>
        <select name="graphtype" id="graphtype">
        <option value="tophosts" selected>Hosts</option>
        <option value="topmsgs">Messages</option>
        <option value="severity">Severity</option>
        <option value="facility">Facilities</option>
        <option value="program">Programs</option>
        </select>
        <?php } ?>
        </td>
    </tr>
</tbody>
</table>
<!-- END HTML for search options -->
<?php } else { ?>
<script type="text/javascript">
$('#portlet_Search_Options').remove()
</script>
<?php } ?>
