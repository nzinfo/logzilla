#!/bin/bash
test -f /path_to_logzilla/exports/import.running && exit 1
nohup /path_to_logzilla/scripts/import.sh $1 >/path_to_logzilla/exports/import.running &
