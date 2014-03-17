#!/bin/bash
# -------------------------------------------
# Set logzilla base path
# -------------------------------------------
lzhome="/var/www/logzilla"
[ ! -d "$lzhome" ] && lzhome="/var/www/logzilla"
# Path to logzilla config file
# -------------------------------------------
lzconf="$lzhome/html/config/config.php"

# -------------------------------------------
# Get DB info from config.php
# -------------------------------------------
dbuser=`cat $lzconf | grep "DBADMIN'" | awk -F"'" '{print $4}'`
dbpass=`cat $lzconf | grep "DBADMINPW'" | awk -F"'" '{print $4}'`
db=`cat $lzconf | grep "DBNAME'" | awk -F"'" '{print $4}'`
dbhost=`cat $lzconf | grep "DBHOST'" | awk -F"'" '{print $4}'`
dbport=`cat $lzconf | grep "DBPORT'" | awk -F"'" '{print $4}'`
MYSQL="mysql -N -u$dbuser -p$dbpass -h$dbhost -P$dbport $db"
TABLE=triggers
FNAME=/tmp/`hostname`_LogZilla_Alerts-$(date +%Y.%m.%d).csv

#(1)creates empty file and sets up column names using the information_schema
$MYSQL -e "SELECT CONCAT(GROUP_CONCAT(COLUMN_NAME SEPARATOR ','), \"\") FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '$db' AND TABLE_NAME = '$TABLE' GROUP BY TABLE_NAME" > $FNAME

#(2)dumps data from DB into /tmp/tempfile.csv
mysql -u $dbuser -p$dbpass $db -B -e "SELECT * INTO OUTFILE '/tmp/tempfile.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' FROM $TABLE;"

#(3)merges data file and file w/ column names
cat /tmp/tempfile.csv >> $FNAME

#(4)deletes tempfile
rm -f /tmp/tempfile.csv

echo "File saved as $FNAME"
echo "Please email the file to support@logzilla.net"
