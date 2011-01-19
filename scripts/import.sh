#!/bin/bash
temp=/tmp/import_$$
export=/path_to_logzilla/exports/$1
if [ -s "$export" ]; then
  echo "file found in the online store";
else
    echo "file not in the online store"
    exit  ;
fi
cd $lzhome/exports
echo "unzipping..."
bunzip2 $1.bz2
echo "splitting into partions..."
# only works with dumpfiles <67m Messages, otherwire split fail!
mkdir $temp
split -l 100000 $1 $temp/logs.
echo "loading into the database"
u=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep user | sed 's/user[[:space:]]=[[:space:]]//g'`
p=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep password | sed 's/password[[:space:]]=[[:space:]]//g'`
d=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep database | sed 's/database[[:space:]]=[[:space:]]//g'`
h=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep host | sed 's/host[[:space:]]=[[:space:]]//g'`
o=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep port | sed 's/port[[:space:]]=[[:space:]]//g'`
for x in $( ls $temp/logs* );
do  
  mysqlimport -L --low-priority -i -h $h -P $o -u $u --password=$p $d $x
  # wait after every 100000 records so mysql can so some other stuff too..
  sleep 3
done
rm -rf $temp
rm -rf /tmp/$1

echo "reindex sphinx"
$lzhome/sphinx/indexer.sh full
echo "***all done***"
