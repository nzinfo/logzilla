#!/bin/sh

#
# indexer.sh
#
# Developed by Clayton Dukes <cdukes@logzilla.pro>
# Copyright (c) 2010 gdd.net
# Licensed under terms of GNU General Public License.
# All rights reserved.
#
# Changelog:
# 2010-04-05 - created
#

################################################################
# This script is used to update the Sphinx indexes
# Several variables are needed to run, some of which are pulled
# from config.php
################################################################

# Get DT for echoing run times into log files
# -------------------------------------------
DATE=`date +%F`
TIME=`date +%T`

# -------------------------------------------
# Set logzilla base path
# -------------------------------------------
lzhome="/path_to_logzilla"
[ ! -d "$lzhome" ] && lzhome="/var/www/logzilla"

sphinxhome="$lzhome/sphinx"
# -------------------------------------------
# -------------------------------------------
# Path to sphinx config file
# -------------------------------------------
spconf="sphinx.conf"
# -------------------------------------------
# Sphinx executable programs
# -------------------------------------------
#indexer="bin/indexer --print-queries"
indexer="bin/indexer"
# changed to use run_searchd so that clusters come up properly
# cdukes: 2014-07-07: changed back as calling run_searchd from here threw a ulimit error
searchd="bin/searchd --iostats --cpustats"
#searchd="$lzhome/sphinx/run_searchd.sh"
# Path to logzilla config file
# -------------------------------------------
lzconf="$lzhome/html/config/config.php"
# -------------------------------------------
# Whether or not to start the daemon if not yet run
# -------------------------------------------
startsearchd='1'
# -------------------------------------------
# Get DB info from config.php
# -------------------------------------------
dbuser=`cat $lzconf | grep "DBADMIN'" | awk -F"'" '{print $4}'`
dbpass=`cat $lzconf | grep "DBADMINPW'" | awk -F"'" '{print $4}'`
db=`cat $lzconf | grep "DBNAME'" | awk -F"'" '{print $4}'`
dbhost=`cat $lzconf | grep "DBHOST'" | awk -F"'" '{print $4}'`
dbport=`cat $lzconf | grep "DBPORT'" | awk -F"'" '{print $4}'`
MYSQL="mysql -N -u$dbuser -p$dbpass -h$dbhost -P$dbport $db"
logtable="logs" 

# -------------------------------------------
# Check for Sphinx's searchd process ID
# -------------------------------------------
pid=`cat $spconf | grep pid_file | awk '{print $3}'`
rotate=""
searchdcmd=" $searchd"
if [ -f "$pid" ] ; then
    spid=`cat $pid`
    if [ -d "/proc/$spid" ] ; then
        rotate=" --rotate --sighup-each"
        searchdcmd=""
    elif [ "z$startsearchd"!="z1" ] ; then
        searchdcmd=""
    fi
fi

do_indexing()
{
    indices=$1
    echo "home = $sphinxhome"
    echo "indexer = $indexer"
    echo "indices = $indices"
    echo "rotate = $rotate"
    echo "[$$] Running Command: ( cd $sphinxhome && $indexer $indices$rotate;$searchdcmd )"
    (
    # -------------------------------------------
    # Must wait for LZTool  if it's running
    # -------------------------------------------
    PID=`ps aux | grep "LZTool" | grep -v grep | awk '{print $2}'`
    for pid in "$PID"; do
        while kill -0 "$pid" >/dev/null 2>&1; do
            echo "indexer.sh: Waiting for the LZTool process on pid $pid to finish"
            sleep 5
        done
    done
    cd $sphinxhome
    $indexer $indices$rotate
    $searchdcmd
    )

}
# -------------------------------------------
# Check to see if there are any indexes created
# If not, a full scan will be forced
# For example, on a new install.
# -------------------------------------------
CHKFILES=$(ls -C1 $lzhome/sphinx/data/*idx_logs* 2> /dev/null | wc -l)

# -------------------------------------------
#  Start main
# -------------------------------------------
if [ $# -lt 1 ]; then
    echo "Please specify \"delta\", or \"full\""
    echo "If \"delta\" is provided, only the delta updates will be done"
    #        echo "If \"merge\" is provided, the delta index will be merged with the main index (this should only be done periodically)"
    echo "If any other argument is passed, such as \"full\", then a full index will be done"
    exit 1
fi
echo
echo
if [ $CHKFILES -eq 0 ] || [ "$1" = "full" ]; then
    echo "[$$] Creating NEW indexes, this may take a while, so be patient..."
    # cdukes: [[ticket:430]] - removing the manual inserts below and using the actual sql file for resetting.
    $MYSQL < $lzhome/scripts/sql/sph_counter.sql
    do_indexing "--all"
    echo "Restarting searchd"; $searchd --stopwait; $searchd 
    exit;
fi
if [ $1 = "delta" ]; then
    echo "[$$] Starting delta indexer: $DATE $TIME"
    # the active index is the one where we put the latest data
    # activeindex=`echo "select index_name from sph_counter where counter_id=3" | $MYSQL | grep log_arch`
    echo "[$$] Spawning DELTA indexer for delta idx_delta_logs"
    # to avoid race conditions first mark all log_arch* indexes for this run
    echo "update sph_counter set this_run=1 where counter_id>2"| $MYSQL 
    indexes=''
    cores=`echo "select value-1 from settings where name='SPX_CPU_CORES'" | $MYSQL`

    for a in `echo "select index_name from sph_counter where this_run=1" \
        | $MYSQL ` ; do for b in `seq 0 $cores`; 
do 
    $indexer "idx_"$a"_"$b --rotate &

done
 done
 wait
 indexes="idx_delta_logs"
 # now reindex new indexes, not totally all of them
 do_indexing "$indexes"

 # restart searchd everytime when there was a view rotation
 x=`echo "select index_name from sph_counter where this_run=1" \
     | $MYSQL ` 
 if [ "z$x" != "z" ]; then  echo "restarting searchd";  $searchd --stopwait; $searchd; fi

 # clean out 
 echo "DELETE FROM sph_counter WHERE counter_id>2 and this_run=1" | $MYSQL
 #        fi
 fi
 DATE2=`date +%F`
 TIME2=`date +%T`

 echo "[$$] $1 indexer started on $DATE at $TIME and completed on $DATE2 at $TIME2"
 echo "insert into sph_metrics (name,ts_start,ts_end,value) VALUES ('indexer', UNIX_TIMESTAMP('$DATE $TIME'), UNIX_TIMESTAMP('$DATE2 $TIME2'), UNIX_TIMESTAMP('$DATE2 $TIME2')-UNIX_TIMESTAMP('$DATE $TIME'))" | $MYSQL
