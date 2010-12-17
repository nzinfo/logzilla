#/bin/bash
mysql --user root --password=mysql -e "call export;" syslog
for i in $( ls /var/www/logzilla/exports/*.txt );
do 
	bzip2 $i
done 
