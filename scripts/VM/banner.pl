#!/usr/bin/perl
# This script is used in the VMWare deployements only.
# It is used to set the /etc/issue and /etc/issue.net files
# to inform users about the VM setup.
# The script is called from /etc/rc.local

use strict;
my ($linfo, $ip);
my $release = `lsb_release -a | grep Description | cut -f2`;

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
                                                                   
       `,;:.                                                       
     .;;;;;;;:                                                     
    :;;;;;;;;;;`                                                   
   :;;,,;,,,,;;;    ..    `,:`    ,:.   .... `.. `..   ..    ....  
  `;;;  ;`   ;;;:   ;;`  `;;;;, `;;;;:  ;;;; .;; ,;;   ;;`   :;;;  
  ;;;;  ;;; `;;;;   ;;`  :;:.;; ,;;`;;  .:;; .;; ,;;   ;;`   ;;;;  
  ;;;;  ;;. :;;;;.  ;;`  :;:.;; ,;;`;;   ;;; .;; ,;;   ;;`   ;;:;` 
  ;;;;  ;; `;;;;;:  ;;`  :;:.;; ,;;      ;;. .;; ,;;   ;;`   ;;:;. 
  ;;;;  ;` ;;;;;;:  ;;`  :;:.;; ,;;:;;  .;;  .;; ,;;   ;;`  `;;,;: 
  ;;;;  ;    ;;;;,  ;;`  :;:.;; ,;;.;;  :;;  .;; ,;;   ;;`  .;:.;: 
  ;;;;  ;,,,,;;;;`  ;;`  :;:.;; ,;; ;;  ;;,  .;; ,;;   ;;`  ,;;;;; 
  :;;;  ::::;;;;;   ;;:: ,;;,;; .;;`;; `;;:: .;; ,;;:. ;;:: :;:.;; 
   ;;;     `;;;;.   ;;;;  ;;;;`  ;;;:; .;;;; .;; ,;;;. ;;;: ;;:`;; 
   .;;;;;;;;;;;:           ``     `                                
    .;;;;;;;;;:                                                    
      :;;;;;;`                                                     

#######################################################################
This VM is running LogZilla v4.5 $release
To obtain an evaluation license, please visit http://www.logzilla.net

Access:
The login/password for the shell is lzadmin/lzadmin (as in "LogZilla Admin")
The login/password for the Web Interface is admin/admin
The login/password for MySQL root is root/mysql
$linfo

Please report any trouble to http://support.logzilla.net                       
#######################################################################
};

open(FILE,">/etc/issue");
print FILE "$banner";
close (FILE);
open(FILE,">/etc/issue.net");
print FILE "$banner";
close (FILE);
system("restart tty1");
