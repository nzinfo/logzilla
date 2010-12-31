#/bin/bash
mysql --user root --password=mysql -e "call export;" syslog
for i in $( ls /path_to_logzilla/exports/*.txt );
do 
	bzip2 $i
done 
