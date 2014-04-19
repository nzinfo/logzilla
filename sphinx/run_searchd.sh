#!/bin/bash
allargs=$@

# Just stop if asked
if [[ $@ == **stop** ]]; then
    if [[ `pgrep -f "bin/searchd"` ]]; then
        echo "Stopping Searchd"
        /var/www/logzilla/sphinx/bin/searchd --stop
        exit 1
    else 
        echo "Searchd not running"
        exit 0
    fi
fi

# ------------------------------------------------------------------
# Test for missing indexes and auto-create them
# ------------------------------------------------------------------
# Make sure we're stopped first
if [[ `pgrep -f "bin/searchd"` ]]; then
    echo "Searchd is already running"
    exit 0
fi
idxARR+=(`/var/www/logzilla/sphinx/bin/searchd -c /var/www/logzilla/sphinx/sphinx.conf | grep "sph: No such file or" | awk '{print $3}' | sed "s/'//g" | sed 's/://g'`)
uniq=$(echo "${idxARR[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
if [ ${#idxARR[@]} -gt 0 ]; then
    for index in "${idxARR[@]}"
    do
        echo "Creating Missing Index: $index"
        errARR+=(`/var/www/logzilla/sphinx/bin/indexer -c /var/www/logzilla/sphinx/sphinx.conf $index | grep "range-query fetch failed" | awk '{print $3}' | sed "s/'//g" | sed 's/://g'`)
    done
    uniq=$(echo "${errARR[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    for index in "${uniq[@]}"
    do
        date=`echo $index | awk -F '_' '{print $5}' | sed 's/^\(.\{4\}\)\(.\{2\}\)/\1-\2-/' `
        echo "Recreating Missing SQL Views for $date"
        /var/www/logzilla/scripts/LZTool -v -r makeview -mvdate $date -y 
    done
fi
