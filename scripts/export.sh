#/bin/bash

# Apparmor users:
# This script WILL NOT run unless you unblock MySQL read/writes in Apparmor first.
# See here: http://nms.gdd.net/index.php/Install_Guide_for_LogZilla_v3.x#Apparmor_Blocking
u=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep user | sed 's/user[[:space:]]=[[:space:]]//g'`
p=`cat /path_to_logzilla/scripts/sql/lzmy.cnf | grep password | sed 's/password[[:space:]]=[[:space:]]//g'`
mysql --user $u --password=$p -e "call export;" syslog
for i in $( ls /path_to_logzilla/exports/*.txt );
do 
	bzip2 $i
done 
