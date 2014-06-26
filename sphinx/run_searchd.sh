#!/bin/bash
lzhome="/path_to_logzilla"
[ ! -d "$lzhome" ] && lzhome="/var/www/logzilla"
ulimit -Hn 25000
ulimit -Sn 25000
allargs=$@

# Just stop if asked
if [[ $@ == **stop ]]; then
    if [[ `pgrep -f "bin/searchd"` ]]; then
        echo "Stopping Searchd"
        $lzhome/sphinx/bin/searchd -c $lzhome/sphinx/sphinx.conf --stop && echo $?
        exit
    fi
fi
if [[ $@ == **stopwait ]]; then
    if [[ `pgrep -f "bin/searchd"` ]]; then
        echo "Stopping Searchd"
        $lzhome/sphinx/bin/searchd -c $lzhome/sphinx/sphinx.conf --stopwait && echo $?
        exit
    fi
fi

# ------------------------------------------------------------------
# Test for missing indexes and auto-create them
# ------------------------------------------------------------------
# Make sure we're stopped first
if [[ `pgrep -f "bin/searchd"` ]]; then
    echo "Stopping Search Daemon"
    $lzhome/sphinx/bin/searchd -c $lzhome/sphinx/sphinx.conf --stopwait && echo $?
fi
idxARR+=(`$lzhome/sphinx/bin/searchd -c $lzhome/sphinx/sphinx.conf | grep "sph: No such file or" | awk '{print $3}' | sed "s/'//g" | sed 's/://g'`)
uniq=$(echo "${idxARR[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
for index in "${idxARR[@]}"
do
    echo "Creating Missing Index: '$index'"
    errARR+=(`$lzhome/sphinx/bin/indexer -c $lzhome/sphinx/sphinx.conf $index | grep "range-query fetch failed" | awk '{print $3}' | sed "s/'//g" | sed 's/://g'`)
done
uniq=$(echo "${errARR[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
for index in "${uniq[@]}"
do
    date=`echo $index | awk -F '_' '{print $5}' | sed 's/^\(.\{4\}\)\(.\{2\}\)/\1-\2-/' `
    if [[ "$date" ]]; then
        echo "Recreating Missing SQL Views for $date"
        $lzhome/scripts/LZTool -v -r makeview -mvdate $date -y 
    fi
done
if [[ `pidof searchd` ]]; then
    echo "Starting Search Daemon"
    kill -HUP `pidof searchd`
fi
