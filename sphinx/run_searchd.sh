#!/bin/bash
ulimit -Hn 25000
ulimit -Sn 25000
allargs=$@

# Just stop if asked
if [[ $@ == **stop ]]; then
    if [[ `pgrep -f "bin/searchd"` ]]; then
        echo "Stopping Searchd"
        /path_to_logzilla/sphinx/bin/searchd -c /path_to_logzilla/sphinx/sphinx.conf --stop && echo $?
    fi
fi
if [[ $@ == **stopwait ]]; then
    if [[ `pgrep -f "bin/searchd"` ]]; then
        echo "Stopping Searchd"
        /path_to_logzilla/sphinx/bin/searchd -c /path_to_logzilla/sphinx/sphinx.conf --stopwait && echo $?
    fi
fi

# ------------------------------------------------------------------
# Test for missing indexes and auto-create them
# ------------------------------------------------------------------
# Make sure we're stopped first
if [[ `pgrep -f "bin/searchd"` ]]; then
    echo "Searchd is already running"
    exit 1
fi
idxARR+=(`/path_to_logzilla/sphinx/bin/searchd -c /path_to_logzilla/sphinx/sphinx.conf | grep "sph: No such file or" | awk '{print $3}' | sed "s/'//g" | sed 's/://g'`)
uniq=$(echo "${idxARR[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
if [ ${#idxARR[@]} -gt 0 ]; then
    for index in "${idxARR[@]}"
    do
        echo "Creating Missing Index: $index"
        errARR+=(`/path_to_logzilla/sphinx/bin/indexer -c /path_to_logzilla/sphinx/sphinx.conf $index | grep "range-query fetch failed" | awk '{print $3}' | sed "s/'//g" | sed 's/://g'`)
    done
    uniq=$(echo "${errARR[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    for index in "${uniq[@]}"
    do
        date=`echo $index | awk -F '_' '{print $5}' | sed 's/^\(.\{4\}\)\(.\{2\}\)/\1-\2-/' `
        echo "Recreating Missing SQL Views for $date"
        /path_to_logzilla/scripts/LZTool -v -r makeview -mvdate $date -y 
    done
fi
if [[ `pgrep -f "bin/searchd"` ]]; then
        /path_to_logzilla/sphinx/bin/searchd -c /path_to_logzilla/sphinx/sphinx.conf --stopwait 
        /path_to_logzilla/sphinx/bin/searchd -c /path_to_logzilla/sphinx/sphinx.conf $allargs && echo $?
fi
