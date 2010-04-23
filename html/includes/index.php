<?php
// Copyright (C) 2010 Clayton Dukes, cdukes@cdukes.com
$basePath = dirname( __FILE__ );
require_once ($basePath . "/html_header.php");
session_start(); 
?>

<!-- BEGIN HTML Code -->

<!-- BEGIN Theme Switcher -->
<div id="switcher" style="float:right; top: 2%; right: 1%;"></div>
<!-- END Theme Switcher -->

<!-- BEGIN Placeholders for alert messages (default is top right, so no need to add a class for that) -->
<div id="msgbox_tl" class="jGrowl top-left"></div>
<div id="msgbox_br" class="jGrowl bottom-right"></div>
<div id="msgbox_bl" class="jGrowl bottom-left"></div>
<div id="msgbox_tc" class="jGrowl center"></div>
<!-- END Placeholders for alert messages -->

<!-- BEGIN Top Menu Navigation -->
<div id="container">

<!-- NAVIGATION
http://playground.emanuelblagonic.com/creating-nested-drop-down-menus/
-->
<ul id="menu">
<?php include("navmenu.php");?>
</ul>
<!-- /NAVIGATION -->    

</div>
<!-- /CONTAINER -->

<!-- END Top Menu Navigation -->

<?php
$start_time = microtime(true);
$page = get_input('page');
$page = (!empty($page)) ? $page : "Main";
$pagecontent = "<div id=\"pagecontent\" style=\"position:absolute; width: 100%; top: 8%; left: 1%;\">\n";
if ($page == "Main") {
    $pagecontent .= "<form method=\"post\" id=\"results\" name=\"results\" action=\"".$_SESSION['SITE_URL']."\">\n";
}
$colarray = array();
$access = getgroup($_SESSION['username']);
if ($access == "admins") {
    $sql = ("SELECT DISTINCT(col) FROM ui_layout WHERE userid=(SELECT id FROM users WHERE username='".$_SESSION['username']."') AND pagename='$page' ORDER BY col ASC");
} else {
    $sql = ("SELECT DISTINCT(col) FROM ui_layout WHERE userid=(SELECT id FROM users WHERE username='".$_SESSION['username']."') AND pagename='$page' AND group_access LIKE '%$access%' ORDER BY col ASC");
}
$queryresult = perform_query($sql, $dbLink, $_REQUEST['pageId']);

// Check for invalid page request in the URL (404)
if(num_rows($queryresult)==0){
    ?>
<!-- BEGIN 404 -->
<div class="dialog_hide">
    <div id="404modal" title='Page Not Found'>
        The page you requested is either not found or you do not have sufficient access rights.<br>
        Try one of these pages instead:
        <ul>
        <?php
        $sql = "SELECT DISTINCT(pagename) FROM ui_layout WHERE userid=(SELECT id FROM users WHERE username='".$_SESSION['username']."') AND group_access='$access' ORDER BY pagename ASC";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    while($row = fetch_array($result)) { 
        $pagename = $row['pagename'];
        echo "<li><a href=\"".$_SESSION['SITE_URL']."?page=$pagename\">$pagename</a></li>\n";
    }
    ?>
        </ul>
    </div>
</div>
<script type="text/javascript">
$().ready(function(){
        $("#404modal").dialog({
                        bgiframe: true,
                        resizable: true,
                        height: 'auto',
                        width: '50%',
                        autoOpen:false,
                        modal: true,
                        overlay: {
                                backgroundColor: '#000',
                                opacity: 0.5
                        },
                });
                $("#404modal").dialog('open');     
        });
</script>
<!-- END 404 -->
    <?
    exit;
}

while ($line = fetch_array($queryresult)) {
    array_push($colarray, $line['col']);
}
$colcount = count($colarray);
$colwidth = round((100 / $colcount), 2);
$_SESSION['colwidth'] = $colwidth;
if ($_SESSION['DEBUG'] > 1 ) {
    echo "$colcount columns in this tab<br>\n";
}
//----------------------------------------------------------
// Store the column count in a session variable
// This is used in js_footer for portlet height
//----------------------------------------------------------
$_SESSION[$page]['maxcols'] = $colcount;
foreach($colarray as $column) {
    $pagecontent .= "<!-- BEGIN Column $column -->\n";
    // !IMPORTANT! the id set below  - $page|$column - is used to save the layouts in savelayout.php
    if ($colwidth < 100) { // No need to make the portlet draggable if it's the only one on the page.
    $pagecontent .= "<div class=\"column\" style=\"width: $colwidth%; float: left; padding-bottom: 100px;\" id=\"$page|$column\">\n";
    }
    //----------------------------------------------------------
    // 3. For each column, get the row
    //----------------------------------------------------------
    if ($access == "admins") {
    $sql = ("SELECT header, content FROM ui_layout WHERE userid=(SELECT id FROM users WHERE username='".$_SESSION['username']."') AND pagename='$page' AND col='$column' ORDER BY rowindex ASC");
    } else {
    $sql = ("SELECT header, content FROM ui_layout WHERE userid=(SELECT id FROM users WHERE username='".$_SESSION['username']."') AND pagename='$page' AND group_access LIKE '%$access%' AND col='$column' ORDER BY rowindex ASC");
    }
    $queryresult = perform_query($sql, $dbLink, $_REQUEST['pageId']);
    $rowindexarray = array();
    while ($line = fetch_array($queryresult)) {
        $header = $line['header'];
        $content = $line['content'];
        array_push($rowindexarray, array("$header","$content"));
    }
    $thiscol = count($rowindexarray);
    if ($lastcol > $thiscol) {
        $lastcol = $lastcol;
    } else {
        $lastcol = $thiscol;
    }
    //----------------------------------------------------------
    // Store the row count in a session variable
    // This is used in js_footer for portlet width
    //----------------------------------------------------------
    $_SESSION[$page]['maxrows'] = $lastcol;
    if ($_SESSION['DEBUG'] > 1) {
        echo "&nbsp;&nbsp;".count($rowindexarray)." rows in this column<br>\n";
    }
    for($i = 0; $i<count($rowindexarray) ; $i++) {
        $header = $rowindexarray[$i][0];
        $content = $rowindexarray[$i][1];
        if ($_SESSION['DEBUG'] > 1) {
            echo "&nbsp;&nbsp;&nbsp;Column = $column<br>&nbsp;&nbsp;&nbsp;Header = $header<br>&nbsp;&nbsp;&nbsp;Content = $content<br>\n";
        }
        $pagecontent .= "<!-- Starting portlet for $page, $column -->\n";;
        $hdid = str_replace(" ", "_", $header);
        $pagecontent .= "<div class=\"portlet\" id=\"portlet_$hdid\">\n";
        $pagecontent .="<div class=\"portlet-header\" id=\"portlet-header_$hdid\">$header</div>\n";
        $pagecontent .="<div class=\"portlet-content\" id=\"portlet-content_$hdid\">\n";
        //----------------------------------------------------------
        // include_contents is used to include the actual content
        // from the file. if you used the regular php include("filename")
        // here, it would only print that string instead of actually
        // including the contents of the file.
        //----------------------------------------------------------
        $pagecontent .= include_contents($content);
        $pagecontent .="</div>\n";
        $pagecontent .= "<!-- Ending portlet for $page, $column -->\n";;
        $pagecontent .= "</div>\n";
    }
    $pagecontent .= "<!-- END Column: $page $column -->\n";
    $pagecontent .= "</div>\n";
}
$pagecontent .= "<!-- Clear style for next tab -->\n";
$pagecontent .= "<div style=\"clear:both\"></div>\n";
$pagecontent .= "<!-- END Tab: $page -->\n";



if ($page == "Main") {
$pagecontent .= "<table id='footer' size='100%' cellpadding='0' cellspacing='0' border='0'>\n";
$pagecontent .= "<thead>\n";
$pagecontent .= "<tr>\n";
$pagecontent .= "<th></th>\n";
$pagecontent .= "<th></th>\n";
$pagecontent .= "<th></th>\n";
$pagecontent .= "</tr>\n";
$pagecontent .= "</thead>\n";
$pagecontent .= "<tbody>\n";
$pagecontent .= "<td width='33%'>\n";
// $pagecontent .= "<span id='span_search_params'>The options currently selected will return <span id='span_limit'>the last 10</span> results <span id'span_date>for today</span> for</span> <span id='span_prog'>all programs</span>, <span id='span_pri'>all severities</span>, <span id='span_fac'>all facilities</span>, <span id='span_host'>all hosts</span>, <span id='span_msg'>and all messages</span>\n";
$pagecontent .= "</td>\n";
$pagecontent .= "<td width='33%'>\n";
    $pagecontent .= "<div class='submitButtons'>";
    $pagecontent .= "<input class='ui-state-default ui-corner-all' type='submit' id='btnSearch' value='Search'>\n";
    $pagecontent .= "<input class='ui-state-default ui-corner-all' type='submit' id='btnGraph' value='Graph'>\n";
    $pagecontent .= "<input class='ui-state-default ui-corner-all' type='reset' value='Reset'>\n";
    $pagecontent .= "<!-- End Submit Buttons -->\n";
    $pagecontent .= "</div>\n";
$pagecontent .= "</td>\n";
$pagecontent .= "<td width='33%'></td>\n";
if ($_SESSION['DEBUG'] == "1") {
    $end_time = microtime(true);
    $pagecontent .= "Page generated in " . round(($end_time - $start_time),5) . " seconds\n";
}
$pagecontent .= "</tbody>\n";
$pagecontent .= "</table>\n";
}



    $pagecontent .= "<!-- End Form -->\n";
    $pagecontent .= "</form>\n";
$pagecontent .= "</div>\n";
echo $pagecontent;
?>
<!-- END Tabs  -->
<!-- BEGIN Tip -->
<?php 
$sql = "SELECT id, name, text FROM totd where lastshown<(SELECT NOW() - INTERVAL ".$_SESSION['TOOLTIP_REPEAT']." MINUTE) ORDER BY RAND() LIMIT 1";
$result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
if(num_rows($result)==1){
    $sql = "SELECT totd FROM users where username='$_SESSION[username]'";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    $line = fetch_array($result);
    if ($line[0] == "show") {
?>
<div class="dialog_hide">
    <div id="tipmodal" title='Useful Tips'>
    <div id="tiptext"></div>
    </div>
</div>
<?php }} ?>
<!-- END Tip -->
