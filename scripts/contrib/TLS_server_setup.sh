#!/bin/bash
# -------------------------------------------
# Set logzilla base path
# -------------------------------------------
lzhome="/path_to_logzilla"
[ ! -d "$lzhome" ] && lzhome="/var/www/logzilla"
# Path to logzilla config file
# -------------------------------------------
lzconf="$lzhome/html/config/config.php"

. /etc/lsb-release
if [ "$DISTRIB_ID" != "Ubuntu" ]; then
    echo "This script is only made for Ubuntu"
    exit
fi
cd /etc/syslog-ng
mkdir ssl
cd ssl
openssl genrsa -des3 -out logserver.key 2048
openssl req -new -key logserver.key -out logserver.csr
cp logserver.key logserver.key.org
openssl rsa -in logserver.key.org -out logserver.key
openssl x509 -req -days 365 -in logserver.csr -signkey logserver.key -out logserver.crt
cp /$lzhome/scripts/contrib/tls.conf /etc/syslog-ng/conf.d/
service syslog-ng restart
