#!/bin/sh
count=0
while [ $count -le 32 ]; do
rand=`perl -e 'print int(rand(800000));'`
echo "insert into logs (host,facility,severity,program,msg,counter,mne,fo,lo)  select host,facility,severity,program,msg,counter,mne,'2010-03-$count' + interval rand()+24 hour,'2010-03-$count' + interval rand()+24 hour from logs limit $rand" | mysql -usyslogadmin -psyslogadmin syslog
    count=`expr $count + 1`
done
