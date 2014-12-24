#!/bin/sh
# Simple script used to wait for MySQL prior to starting Sphinx
# Also sets console message for VMs
# This script is called from /etc/rc.local during bootup

lzhome="/path_to_logzilla"
[ ! -d "$lzhome" ] && lzhome="/var/www/logzilla"

for i in 1 2 3 4 5 6; do
    echo "Waiting for MySQL Startup"
    if [ -S /var/run/mysql/mysql.sock ]; then
        break
    else
        sleep 1
        echo -n "."
    fi
done
if [ -f $lzhome/scripts/VM/firstboot ]; then
    wget --timeout=2 -q -O /tmp/test "http://www.logzilla.net/pingme" || rm /tmp/test
    if [ -f /tmp/test ]; then
        $lzhome/scripts/VM/update.pl
        rm -f $lzhome/scripts/VM/firstboot
	# cleanup the test entry
	$lzhome/scripts/LZTool -delhost -host "host-1"
	$lzhome/scripts/LZTool -delhost -host "host-1"
    else
        printf "\n\033[1m\tERROR!\n\033[0m\n"
        echo "LogZilla requires internet access upon first boot. Please configure your network properly then reboot the system"
        echo "LogZilla requires internet access upon first boot. Please configure your network properly then reboot the system" > /etc/issue
        echo "LogZilla requires internet access upon first boot. Please configure your network properly then reboot the system" > /etc/issue.net
        restart tty1
        exit 1
    fi
fi
(cd /path_to_logzilla/sphinx && ./run_searchd.sh --stop)
(cd /path_to_logzilla/sphinx && ./run_searchd.sh)
(cd $lzhome/scripts/VM && ./banner.pl)
