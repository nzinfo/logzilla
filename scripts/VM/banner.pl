#!/usr/bin/perl
# This script is used in the VMWare deployements only.
# It is used to set the /etc/issue and /etc/issue.net files
# to inform users about the VM setup.
# The script is called from /etc/rc.local

use strict;
my ($linfo, $ip);

my $re = qr/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/;
sub getip {
    $ip = ((`/sbin/ifconfig eth0`)[1] =~ /inet addr:(\S+).*/);
    return $1;
}

my $i = 0;
while ((getip !~ /$re/) && ($i <=5)) {
    print "Waiting for network...\n";
    sleep 1;
    $i++
}
if (getip =~ /$re/) {
    $ip = getip;
    $linfo = "To get to the web interface, browse to http://$ip from your local PC";
} else {
    $linfo = "To get to the web interface, browse to http://<ip> from your local PC
    To find your IP address, run 'ifconfig' after logging in to this console.";
}
my $banner = qq{
#######################################################################
LOGZILLA
#######################################################################
This VM is running LogZilla v3.2 on Ubuntu 10.10 Server x64
To obtain an evaluation license, please visit http://www.logzilla.pro



! READ THIS, IT IS ACTUALLY IMPORTANT!

Timezone:
This server is configured for Eastern Standard Time (EST)
You will need to set the timezone to your locale by typing:
dpkg-reconfigure tzdata

First Bootup:
Please run "lzupdate" to get the latest software.
(sudo password is your password, which is "log")

Access:
The login/password for the shell is log/log
The login/password for the Web Interface is admin/admin
$linfo

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
