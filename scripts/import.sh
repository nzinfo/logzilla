#!/bin/bash
export=/var/www/logzilla/exports/$1
if [ -s "$export" ]; then
  echo "file found in the online store";
else
  echo "file not in the online store"

#  echo "try to restore from backup"  
#  echo "doing restore *brumm* *brumm*"
#  if [ $? ]; then 
#      echo "cant restore from backup"
     exit  ;
#  fi

fi
echo "Copying file to temp space"
cp  -f $export /tmp/$1.bz2
cd /tmp
echo "unzipping..."
bunzip2 $1.bz2
mv -f $1 logs
echo "loading into the database"
mysqlimport -i -C -u root --password=mysql syslog /tmp/logs
rm -f /tmp/logs
echo "all done"