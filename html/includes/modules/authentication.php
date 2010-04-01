<?php
/*
 *
 * Developed by Clayton Dukes <cdukes@cdukes.com>
 * Copyright (c) 2010 gdd.net
 * All rights reserved.
 *
 * Changelog:
 * 2010-03-13 - created
 *
 */

session_start();
$basePath = dirname( __FILE__ );
require_once ($basePath . "/../common_funcs.php");
$dbLink = db_connect_syslog(DBADMIN, DBADMINPW);

if (file_exists($basePath . "/ldap.php")) {
    require_once ($basePath . "/ldap.php");
}

//------------------------------------------------------------------------
// This functions verifies a username/password combination. If the
// combination exists then the function returns TRUE. If not then it
// returns FALSE.
//------------------------------------------------------------------------
function verify_login($username, $password, $dbLink) {
    // If the username or password is blank then return FALSE.
    if(!$username || !$password) {
        return FALSE;
    }

    // Get the md5 hash of the password and query the database.
    $pwHash = md5($password);
    $query = "SELECT * FROM ".$_SESSION["TBL_AUTH"]." WHERE username='".$username."' AND pwhash='".$pwHash."'";
    $result = perform_query($query, $dbLink, $_SERVER['PHP_SELF']);

    if(num_rows($result) == 1) {
        $sql = "SELECT * FROM ui_layout WHERE userid=(SELECT id FROM users WHERE username='$username')";
        $res = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
        if(num_rows($res)==0){
            reset_layout($username);
        }
        $sessionId = session_id();
        $_SESSION["pageId"] = "searchform" ;
        $expTime = time()+$_SESSION["SESS_EXP"];
        $expTimeDB = date('Y-m-d H:i:s', $expTime);
        $query = "UPDATE ".$_SESSION["TBL_AUTH"]." SET sessionid='".$sessionId."', 
            exptime='".$expTimeDB."' WHERE username='".$username."'";
        $result = perform_query($query, $dbLink, $_SERVER['PHP_SELF']);
        return TRUE;
    }
    else {
        return FALSE;
    }
}

//------------------------------------------------------------------------
// This function verifies a username/sessionId combination. If the
// combination exists then the function returns TRUE. If not then it
// returns FALSE. If the RENEW_SESSION_ON_EACH_PAGE parameter is set then
// the functions also updates the timestamp for the session after it is
// verified.
//------------------------------------------------------------------------
function verify_session($username, $sessionId, $dbLink) {
    // If the username or sessionId is blank then return FALSE.
    if(!$username || !$sessionId) {
        return FALSE;
    }

    // Query the database.
    $query = "SELECT * FROM ".$_SESSION["TBL_AUTH"]." WHERE username='".$username."' 
        AND sessionid='".$sessionId."' AND exptime>now()";
    $result = perform_query($query, $dbLink, $_SERVER['PHP_SELF']);

    // If the query returns one result row then the session is verified.
    if(num_rows($result) == 1) {
        //If RENEW_SESSION_ON_EACH_PAGE is set then update the
        // session timestamp in the database.
        // if(defined('RENEW_SESSION_ON_EACH_PAGE') && RENEW_SESSION_ON_EACH_PAGE == TRUE) {
        // CDUKES: 2009-11-04 Removed check for RENEW_SESSION_ON_EACH_PAGE, what's the 
        // point of doing that, why not just renew the sessions anyways?
        $expTime = time()+$_SESSION["SESS_EXP"];
        $expTimeDB = date('Y-m-d H:i:s', $expTime);
        $query = "UPDATE ".$_SESSION["TBL_AUTH"]." SET exptime='".$expTimeDB."'
            WHERE username='".$username."'";
        perform_query($query, $dbLink, $_SERVER['PHP_SELF']);
        // }
        return TRUE;
    }
    else {
        return FALSE;
    }
}

//========================================================================
// BEGIN ACCESS CONTROL FUNCTIONS
//========================================================================
//------------------------------------------------------------------------
// This function verifies that the user has access to a particular part
// of php-syslog-ng.
// Inputs are:
// username
// actionName
// dbLink
//
// Outputs TRUE or FALSE
//------------------------------------------------------------------------

// currently not used in v3.0
function grant_access($userName, $actionName, $dbLink) {
    // If $_SESSION["AUTHTYPE"] is non (open system), then allow access
    if($_SESSION["AUTHTYPE"] = "none") {
        return TRUE;
    }
    // Get user access
    $sql = "SELECT access FROM ".$_SESSION["TBL_AUTH"]." WHERE username='".$userName."' 
        AND actionname='".$actionName."'";
    $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
    $row = fetch_array($result);
    if(num_rows($result) && $row['access'] == 'TRUE') {
        return TRUE;
    }
    // Get default access
    else {
        $sql = "SELECT defaultaccess FROM ".$_SESSION["TBL_ACTIONS"]." WHERE actionname='".$actionName."'";
        $result = perform_query($sql, $dbLink, $_SERVER['PHP_SELF']);
        $row = fetch_array($result);
        if($row['defaultaccess'] == 'TRUE') {
            return TRUE;
        }
        else {
            return FALSE;
        }
    }
}
//========================================================================
// END ACCESS CONTROL FUNCTIONS
//========================================================================


# cdukes - Added below for 2.9.4
function secure () {
    if (!($_SESSION["username"]) || ($_SESSION["username"] == "")) {
        $destination = $_SESSION["SITE_URL"]."login.php";
        // Remember search query across login
        if (!empty($_SERVER['QUERY_STRING']))
        {
            $destination .= '?' . $_SERVER['QUERY_STRING'];
        }
        Header("Location:" . $destination);
        exit();
    } else {
        return $_SESSION["username"];
    }
}
function auth ($postvars) {
    $error = "";
    $username = $postvars["username"];
    $password = $postvars["password"];

    switch ($postvars['authtype']) {

        case "local":
            if ($_POST["username"] && $_POST["username"] !== "local_noauth") {
                $dbLink = db_connect_syslog(DBADMIN, DBADMINPW);
                if ($username && $password && verify_login($username, $password, $dbLink)) {
                    $error ="";
                } else {
                    $error .= " Invalid password for user $username";
                }
            } else {
                if (trim($username) == "") $error .= "Your username is empty.<br>";
                if (trim($password) == "") $error .= "Your password is empty.";
            }
        if (trim($error)!="") {
            return $_SESSION["error"] = $error;
        } else {
            return $_SESSION["username"] = $username;
        }
        break;

        case "ldap":
            $error .= "LDAP not implemented yet";
        if (trim($error)!="") {
            return $_SESSION["error"] = $error;
        } else {
            return $_SESSION["username"] = $username;
        }
        break;

        case "webbasic":
            $error .= "Web Basic not implemented yet";
        if (trim($error)!="") {
            return $_SESSION["error"] = $error;
        } else {
            return $_SESSION["username"] = $username;
        }
        break;

        case "msad":
            $error .= "Microsoft Authentication not implemented yet";
        if (trim($error)!="") {
            return $_SESSION["error"] = $error;
        } else {
            return $_SESSION["username"] = $username;
        }
        break;

        case "cert":
            $error .= "SSL Certificate Authentication not implemented yet";
        if (trim($error)!="") {
            return $_SESSION["error"] = $error;
        } else {
            return $_SESSION["username"] = $username;
        }
        break;

        case "tacacs":
            $error .= "Tacacs Authentication not implemented yet";
        if (trim($error)!="") {
            return $_SESSION["error"] = $error;
        } else {
            return $_SESSION["username"] = $username;
        }
        break;

        case "radius":
            $error .= "Radius Authentication not implemented yet";
        if (trim($error)!="") {
            return $_SESSION["error"] = $error;
        } else {
            return $_SESSION["username"] = $username;
        }
        break;
    }
}
