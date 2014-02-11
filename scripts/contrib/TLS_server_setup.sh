#!/bin/expect
set pass "temp"

cd /etc/syslog-ng
mkdir ssl
cd ssl
openssl genrsa -des3 -out logserver.key 2048
expect "Enter pass phrase for logserver.key: "
send "$pass"
openssl req -new -key logserver.key -out logserver.csr
cp logserver.key logserver.key.org
openssl rsa -in logserver.key.org -out logserver.key
openssl x509 -req -days 365 -in logserver.csr -signkey logserver.key -out logserver.crt
cp /var/www/logzilla/scripts/contrib/tls.conf /etc/syslog-ng/conf.d/
service syslog-ng restart
