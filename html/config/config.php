<?php
DEFINE('DBADMIN', 'syslogadmin');
DEFINE('DBADMINPW', 'syslogadmin');
DEFINE('DBNAME', 'syslog');
DEFINE('DBHOST', '127.0.0.1');
DEFINE('DBPORT', '3306');
DEFINE('LOG_QUERIES', 'FALSE');
DEFINE('MYSQL_QUERY_LOG', '/var/log/logzilla/mysql_query.log');
$regExpArray = array(
            "username" => "(^[A-Za-z_.@]{4,}\$)",
            "password"=>"(^.{4,}\$)",
            "pageId"=>"(^\w+$)",
            "sessionId"=>"(^\w{32}\$)",
            "date"=>"/^yesterday$|^today$|^now$|^([0123]*\d)-([012]*\d)-(\d){4}$/i",
            "time"=>"/^now$|^([012]*\d):([012345]*\d):([012345]*\d)$/i",
            "limit"=>"(^\d+$)",
            "topx"=>"(^\d+$)",
            "orderby"=>"/^id$|^seq$|^counter|^host$|^program$|^facility$|^priority$|^msg$|^fo$|^lo$|^counter$/i",
            "order"=>"/^asc$|^desc$/i",
            "offset"=>"(^\d+$)",
            "collapse"=>"/^1$/",
            "table"=>"(^\w+$)",
            "excludeX"=>"(^[01]$)",
            "regexpX"=>"(^[01]$)",
            "host"=>"(^([\w_.%-]+[,;]\s*)*[\w_.%-]+$)",
            "program"=>"(^([\w/_.%-]+[,;]\s*)*[\w/_.%-]+$)",
            "hostRegExp"=>"(^\S+$)",
            "programRegExp"=>"(^\S+$)",
            "facility"=>"(^\w+$)",
            "priority"=>"/^debug$|^info$|^notice$|^warning$|^err$|^crit$|^alert$|^emerg$/i",
            "dupop"=>"(^lt|gt|eq$)",
            "dupcount"=>"(^\d+$)",
            "graphtype"=>"/^tophosts$|^topmsgs$|^pri$|^fac$|^prog$/i",
            );
?>
