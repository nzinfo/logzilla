#!/usr/bin/perl
# This script is used in the VMWare deployements only.
# It is used to set the /etc/issue and /etc/issue.net files
# to inform users about the VM setup.
# The script is called from /etc/rc.local

use strict;
my @ip = `ifconfig eth0`;
my $ip = $ip[1];
chomp($ip);
if ($ip =~ /.*addr:(\d+\.\d+\.\d+\.\d+).*/) {
    $ip = $1;
} else {
    $ip = "<ip>";
}
my $banner = qq{
#######################################################################
LOGZILLA
#######################################################################
This VM is running LogZilla v3.2 on Ubuntu 10.04LTS Server x64
To obtain an evaluation license, please visit http://www.logzilla.pro

Timezone:
This server is configured for Eastern Standard Time (EST)
You will need to set the timezone to your locale by typing:
dpkg-reconfigure tzdata

First Bootup:
Please run:
cd /var/www/logzilla && svn update && /etc/init.d/syslog-ng restart
to get the latest source

Access:
The login/password for the shell is log/log
The login/password for the Web Interface is admin/admin
To get to the web interface, browse to http://$ip from your local PC

More Information and Help:
Please read /var/www/logzilla/VM-README.txt

Please report any trouble to http://support.logzilla.pro                       
#######################################################################

};

open(FILE,">/etc/issue");
print FILE "$banner";
close (FILE);
open(FILE,">/etc/issue.net");
print FILE "$banner";
close (FILE);
system("restart tty1");
