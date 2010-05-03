#!/bin/sh

#
# indexer.sh
#
# Developed by Clayton Dukes <cdukes@cdukes.com>
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

# -------------------------------------------
# Get DT for echoing run times into log files
# -------------------------------------------
DATE=`date +%F`
TIME=`date +%T`

# -------------------------------------------
# Set logzilla base path
# -------------------------------------------
lzhome="/path_to_logzilla"
# -------------------------------------------
# Path to sphinx indexer binary
# -------------------------------------------
indexer="$lzhome/sphinx/bin/indexer"
# -------------------------------------------
# Path to sphinx config file
# -------------------------------------------
spconf="$lzhome/sphinx/sphinx.conf"
# -------------------------------------------
# Path to logzilla config file
# -------------------------------------------
lzconf="$lzhome/html/config/config.php"
# -------------------------------------------
# Get DB info from config.php
# -------------------------------------------
dbuser=`cat $lzconf | grep "DBADMIN'" | awk -F"'" '{print $4}'`
dbpass=`cat $lzconf | grep "DBADMINPW'" | awk -F"'" '{print $4}'`
db=`cat $lzconf | grep "DBNAME'" | awk -F"'" '{print $4}'`

## FIX THIS IN THE RELEASE VERSION!
logtable="logs" 
## FIX THIS IN THE RELEASE VERSION!

# -------------------------------------------
# Check for Sphinx's searchd process ID
# -------------------------------------------
spid=`ps -ef | grep searchd | grep -v grep | awk '{print $2}'`
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
        echo "Please specify \"delta\", \"full\" or \"merge\""
        echo "If \"delta\" is provided, only the delta updates will be done"
        echo "If \"merge\" is provided, the delta index will be merged with the main index (this should only be done periodically)"
        echo "If any other argument is passed, such as \"full\", then a full index will be done"
        exit 1
fi
echo
echo
echo "Starting Sphinx Indexer: $DATE $TIME"
if [ $1 = "delta" ]; then
        if [ $spid ]; then
                echo "Spawning DELTA indexer for delta idx_delta_logs"
                echo "Running Command: $indexer --config $spconf --rotate idx_delta_logs"
                $indexer --config $spconf --rotate idx_delta_logs
        else
                echo "Unable to update deltas, make sure searchd is running first!"
        fi

else
        if [ $1 = "merge" ]; then
                if [ $spid ]; then
                        echo "Spawning MERGE indexer for idx_logs and idx_delta_logs"
                        echo "Running command: $indexer --config $spconf --merge idx_logs idx_delta_logs --rotate"
                        $indexer --config $spconf --merge idx_logs idx_delta_logs --rotate --merge-dst-range deleted 0 0
                        `echo "UPDATE sph_counter SET max_id= (SELECT MAX(id) FROM $logtable) WHERE \
                        index_name = 'idx_logs'" | mysql -u$dbuser -p$dbpass $db`
                else
                        echo "Unable to update deltas, make sure searchd is running first!"
                fi
        else
                if [ $CHKFILES -eq 0 ]; then
                        echo "No previous index files found"
                        echo "Creating NEW indexes, this may take a while, so be patient..."
                        echo "Running command: $indexer --config $spconf idx_logs idx_delta_logs"
                        $indexer --config $spconf idx_logs idx_delta_logs
                else
                        if [ $spid ]; then
                                echo "UPDATing indexes for idx_logs with command: $indexer --config $spconf idx_logs --rotate"
                                $indexer --config $spconf idx_logs --rotate
                        else
                                echo "Unable to update indexes, make sure searchd is running first!"
                        fi
                fi
        fi
fi
DATE=`date +%F`
TIME=`date +%T`
echo "Finished Sphinx Indexer: $DATE $TIME"
