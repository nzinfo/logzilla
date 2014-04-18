#!/bin/bash
# ------------------------------------------------------------------
# Test for missing indexes and auto-create them
# ------------------------------------------------------------------
function chkidx(){
idxARR=()
idxARR+=(`/var/www/logzilla/sphinx/bin/searchd -c /var/www/logzilla/sphinx/sphinx.conf | grep "sph: No such file or" | awk '{print $3}' | sed "s/'//g" | sed 's/://g'`)
sphStop
if [ ${#idxARR[@]} -gt 0 ]; then
    for i in "${idxARR[@]}"
    do
        echo "Creating Missing Indexes"
        /var/www/logzilla/sphinx/bin/indexer -c /var/www/logzilla/sphinx/sphinx.conf $i
    done
fi
}
function sphStart(){
# Added for cluster crm commands
if [ "$#" -ne 0 ];then
    /var/www/logzilla/sphinx/bin/searchd $@
else
    echo "Starting Searchd"
    /var/www/logzilla/sphinx/bin/searchd -c /var/www/logzilla/sphinx/sphinx.conf >/dev/null
fi
}
function sphStop(){
echo "Stopping Searchd"
if [ "$#" -ne 0 ];then
    /var/www/logzilla/sphinx/bin/searchd $@
else
    /var/www/logzilla/sphinx/bin/searchd --stop -c /var/www/logzilla/sphinx/sphinx.conf >/dev/null
fi
}

# If any command line args, just stop the daemon
# This is needed in the cluster config
if [ $3 == "--stop" ];then
    sphStop
else
    status=`/var/www/logzilla/sphinx/bin/searchd --status -c /var/www/logzilla/sphinx/sphinx.conf | grep uptime`
    if [ "$status" ]; then
        echo "LogZilla indexer is already running on PID $PID" >&2
        sphStop
        chkidx
        sphStart
    else
        sphStop
        chkidx
        sphStart
    fi
fi
