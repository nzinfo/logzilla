#!/bin/bash
# ------------------------------------------------------------------
# Test for missing indexes and auto-create them
# --------------------------------------------------------$----------
verbose=$1
function chkidx(){
idxARR=()
errARR=()
idxARR+=(`/var/www/logzilla/sphinx/bin/searchd -c /var/www/logzilla/sphinx/sphinx.conf | grep "sph: No such file or" | awk '{print $3}' | sed "s/'//g" | sed 's/://g'`)
sphStop
if [ ${#idxARR[@]} -gt 0 ]; then
    for index in "${idxARR[@]}"
    do
        [[ "$verbose" == "-v" ]] && echo "Creating Missing Indexes"
        errARR+=(`/var/www/logzilla/sphinx/bin/indexer -c /var/www/logzilla/sphinx/sphinx.conf $index | grep "range-query fetch failed" | awk '{print $3}' | sed "s/'//g" | sed 's/://g'`)
        #/var/www/logzilla/sphinx/bin/indexer -c /var/www/logzilla/sphinx/sphinx.conf $index
    done
    for index in "${errARR[@]}"
    do
        date=`echo $index | awk -F '_' '{print $5}' | sed 's/^\(.\{4\}\)\(.\{2\}\)/\1-\2-/' `
         [[ "$verbose" == "-v" ]] && echo "Recreating Missing Indexes SQL Views for $date"
        sphStart
        /var/www/logzilla/scripts/LZTool -v -r makeview -mvdate $date -y >/dev/null
    done
fi
}
function sphStart(){
# Added for cluster crm commands
if [ "$#" -ne 0 ];then
    /var/www/logzilla/sphinx/bin/searchd $@ --iostats --cpustats
else
     [[ "$verbose" == "-v" ]] && echo "Starting Searchd"
    /var/www/logzilla/sphinx/bin/searchd -c /var/www/logzilla/sphinx/sphinx.conf --iostats --cpustats >/dev/null
fi
}
function sphStop(){
 [[ "$verbose" == "-v" ]] && echo "Stopping Searchd"
if [ "$#" -ne 0 ];then
    /var/www/logzilla/sphinx/bin/searchd $@
else
    /var/www/logzilla/sphinx/bin/searchd --stop -c /var/www/logzilla/sphinx/sphinx.conf >/dev/null
fi
}

# If any command line args, just stop the daemon
# This is needed in the cluster config
if [ "$3" == "--stop" ];then
    sphStop
else
    status=`/var/www/logzilla/sphinx/bin/searchd --status -c /var/www/logzilla/sphinx/sphinx.conf | grep uptime`
    if [ "$status" ]; then
         [[ "$verbose" == "-v" ]] && echo "LogZilla indexer is already running on PID $PID" 
        sphStop
        chkidx
        sphStart
    else
        sphStop
        chkidx
        sphStart
    fi
fi
