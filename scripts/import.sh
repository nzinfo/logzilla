#!/bin/bash
temp=/tmp/import_$$
u=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep user | sed 's/user[[:space:]]=[[:space:]]//g'`
p=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep password | sed 's/password[[:space:]]=[[:space:]]//g'`
d=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep database | sed 's/database[[:space:]]=[[:space:]]//g'`
h=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep host | sed 's/host[[:space:]]=[[:space:]]//g'`
o=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep port | sed 's/port[[:space:]]=[[:space:]]//g'`
export_path=$( mysql -h $h -P $o -u $u --password=$p $d -B -N -e "SELECT value from settings WHERE name='ARCHIVE_PATH';" )

export=$export_path/$1.gz
echo $export
if [ -s "$export" ]; then
  echo "file found in the online store";
else
    echo "file not in the online store"
    exit  ;
fi
mkdir $temp
cd $temp
echo "unzipping and splitting into partions..."
# only works with dumpfiles <67m Messages, otherwire split fail!

gzip -d -c $export | split -l 100000 - logs.

echo "loading into the database"

for x in $( ls $temp/logs* );
do  
  mysqlimport -L --low-priority -i -h $h -P $o -u $u --password=$p $d $x
  # wait after every 100000 records so mysql can so some other stuff too..
  sleep 3
done
cd /
rm -rf $temp

echo "reindex sphinx"
/path_to_logzilla/sphinx/indexer.sh full
echo "***all done***"