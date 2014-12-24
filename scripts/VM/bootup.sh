#!/bin/bash
# Simple script used to wait for MySQL prior to starting Sphinx
# Also sets console message for VMs
# This script is called from /etc/rc.local during bootup

lzhome="/path_to_logzilla"
[ ! -d "$lzhome" ] && lzhome="/var/www/logzilla"


function getyn {
	while echo -e '\E[37;44m'"\033[1m$1\033[0m" >&2 ; do
		read ANS dummy
		case $ANS in
			[Yy]*)	return 0 ;;
			[Nn]*)	return 1 ;;
			*)	echo "Invalid response, try again ..." >&2
		esac
	done
}

for i in 1 2 3 4 5 6; do
    echo "Waiting for MySQL Startup"
    if [ -S /var/run/mysqld/mysqld.sock ]; then
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
	# Reconfigure Timezone and Keyboard 
#TODO: Figure out how to allow this to run during bootup - I wasn't able to answer/use the keyboard
	#echo
	#echo -e '\E[37;44m'"\033[1mThis VM is configured for US Eastern Standard Time (GMT-5)\033[0m"
	#if getyn "Would you like to configure a different Timezone?[y/n]" ; then
		#dpkg-reconfigure tzdata
	#fi
	#echo -e '\E[37;44m'"\033[1mThis VM is configured for a US Keyboard\033[0m"
	#if getyn "Would you like to set a different keyboard layout?[y/n]" ; then
		#dpkg-reconfigure keyboard-configuration
	#fi
    else
        printf "\n\033[1m\tERROR!\n\033[0m\n"
        echo "LogZilla requires internet access upon first boot. Please configure your network properly then reboot the system"
        echo "LogZilla requires internet access upon first boot. Please configure your network properly then reboot the system" > /etc/issue
        echo "LogZilla requires internet access upon first boot. Please configure your network properly then reboot the system" > /etc/issue.net
        restart tty1
        exit 1
    fi
fi
tput sgr0
(cd /var/www/logzilla/sphinx && ./run_searchd.sh --stop)
(cd /var/www/logzilla/sphinx && ./run_searchd.sh)
(cd $lzhome/scripts/VM && ./banner.pl)
