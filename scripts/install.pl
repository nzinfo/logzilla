#!/usr/bin/perl

#
# install.pl
#
# Developed by Clayton Dukes <cdukes@cdukes.com>
# Copyright (c) 2010 LogZilla, LLC
# All rights reserved.
#
# Changelog:
# 2009-11-15 - created
# 2010-10-10 - Modified to work with LogZilla v3.0
# 2010-06-07 - Modified partitioning and events
# 2010-12-20 - Added support for mysql my.cnf file

use strict;

$| = 1;


use Cwd;
use DBI;
use Date::Calc;
use Term::ReadLine;
use File::Copy;
use Switch;

# not needed here, but might as well warn the user to install it now since db_insert will need them
use Text::LevenshteinXS qw(distance);
use File::Spec;
use File::Basename;
use String::CRC32;
use MIME::Lite;



$| = 1;

system("stty erase ^H");
sub p {
    my($prompt, $default) = @_;
    my $defaultValue = $default ? "[$default]" : "";
    print "$prompt $defaultValue: ";
    chomp(my $input = <STDIN>);
    return $input ? $input : $default;
}

my $version = "3.2";
my $subversion = ".302";

# Grab the base path
my $lzbase = getcwd;
$lzbase =~ s/\/scripts//g;
my $now = localtime;

my ($sec, $min, $hour, $curmday, $curmon, $curyear, $wday, $yday, $isdst) = localtime time;
$curyear = $curyear + 1900;
$curmon = $curmon + 1;
my ($year,$mon,$mday) = Date::Calc::Add_Delta_Days($curyear,$curmon,$curmday,1);
my $pAdd = "p".$year.sprintf("%02d",$mon).sprintf("%02d",$mday);
my $dateTomorrow = $year."-".sprintf("%02d",$mon)."-".sprintf("%02d",$mday);

# The command line args below are really just for me so I don't have to keep going through extra steps to test 1 thing.
# But you can use them if you want :-)
foreach (@ARGV) {
    switch ($_) {
        case "update_paths" {
            update_paths();
            exit;
        }
        case "genconfig" {
            genconfig();
            exit;
        }
        case "add_logrotate" {
            add_logrotate();
            exit;
        }
        case "add_syslog_conf" {
            add_syslog_conf();
            exit;
        }
        case "setup_cron" {
            setup_cron();
            exit;
        }
        case "setup_sudo" {
            setup_sudo();
            exit;
        }
        case "setup_apparmor" {
            setup_apparmor();
            exit;
        }
        case "install_sphinx" {
            install_sphinx();
            exit;
        }
    }
}
print("\n\033[1m\n\n========================================\033[0m\n");
print("\n\033[1m\tLogZilla End User License\n\033[0m");
print("\n\033[1m========================================\n\n\033[0m\n\n");

my $ok  = &p("You must read and accept the End User License Agreement to continue.\nContinue? (yes/no)", "n");
if ($ok !~ /[Yy]/) {
    print "Please try again when you are ready to accept.\n";
    exit 1;
} else {
    &show_EULA;
}
my $ok  = &p("Do you accept? (yes/no)", "n");
if ($ok !~ /[Yy]/) {
    print "Please try again when you are ready to accept.\n";
    exit 1;
}

print("\n\033[1m\n\n========================================\033[0m\n");
print("\n\033[1m\tInstallation\n\033[0m");
print("\n\033[1m========================================\n\n\033[0m\n\n");
my $dbroot = &p("Enter the MySQL root username", "root");
$dbroot = qq{$dbroot};
my $dbrootpass = &p("Enter the password for $dbroot", "mysql");
$dbrootpass = qq{$dbrootpass};
my $dbname = &p("Database to install to", "syslog");
my $dbtable =  "logs";
my $dbhost  = &p("Enter the name of the MySQL server", "localhost");
my $dbport  = &p("Enter the port of the MySQL server", "3306");
use IO::Socket::INET;

my $sock = IO::Socket::INET->new(
    PeerAddr=> "$dbhost",
    PeerPort=> $dbport,
    Proto   => "tcp");
my $localip = $sock->sockhost;
my $dbadmin  = &p("Enter the name to create as the owner of the $dbname database", "syslogadmin");
$dbadmin = qq{$dbadmin};
my $dbadminpw = &p("Enter the password for the $dbadmin user", "$dbadmin");
$dbadminpw = qq{$dbadminpw};
my $siteadmin  = &p("Enter the name to create as the WEBSITE owner", "admin");
$siteadmin = qq{$siteadmin};
my $siteadminpw = &p("Enter the password for $siteadmin", "$siteadmin");
$siteadminpw = qq{$siteadminpw};
my $email  = &p("Enter your email address", 'root@localhost');
my $sitename  = &p("Enter a name for your website", 'The home of LogZilla');
my $url  = &p("Enter the base url for your site (e.g: / or /logs/)", '/logs/');
$url = $url . "/" if ($url !~ /\/$/); 
$url = "/" . $url if ($url !~ /^\//); 
my $logpath  = &p("Where should log files be stored?", '/var/log/logzilla');
my $retention  = &p("How long before I archive old logs? (in days)", '7');
my $snare  = &p("Do you plan to log Windows events from SNARE to this server?", 'n');


if (! -d "$logpath") {
    mkdir "$logpath";
}

# Create mysql .cnf file
open(CNF,">$lzbase/scripts/sql/lzmy.cnf") || die("Cannot Open $lzbase/scripts/sql/lzmy.cnf: $!"); 
print CNF "[logzilla]\n";
print CNF "user = $dbadmin\n";
print CNF "password = $dbadminpw\n";
print CNF "host = $dbhost\n";
print CNF "port = $dbport\n";
print CNF "database = $dbname\n";
close(CNF); 
chmod 0400, "$lzbase/scripts/sql/lzmy.cnf";

update_paths();
make_logfiles();
genconfig();

print "All data will be installed into the $dbname database\n";
my $ok  = &p("Ok to continue?", "y");
if ($ok =~ /[Yy]/) {
    my $dbh = DBI->connect( "DBI:mysql:mysql:$dbhost:$dbport", $dbroot, $dbrootpass );
    my $sth = $dbh->prepare("SELECT version()") or die "Could not get MySQL version: $DBI::errstr";
    $sth->execute;
    while (my @data = $sth->fetchrow_array()) {
        my $ver = $data[0];
        if ($ver !~ /5\.[19]/) {
            print("\n\033[1m\tERROR!\n\033[0m");
            print "LogZilla requires MySQL v5.1 or better.\n";
            print "Your version is $ver\n";
            print "Please upgrade MySQL to v5.1 or better and re-run this installation.\n";
            exit;
        }
    }
    if (db_exists() eq 0) {
        $dbh->do("create database $dbname");
        do_install();
    } else {
        print("\n\033[1m\tPrevious installation detected!\n\033[0m");
        print "Install can attempt an upgrade, but be aware of the following:\n";
        print "1. The upgrade process could potentially take a VERY long time on very large databases.\n";
        print "2. There is a potential for data loss, so please make sure you have backed up your database before proceeding.\n";
        my $ok  = &p("Ok to continue?", "y");
        if ($ok =~ /[Yy]/) {
            my ($major, $minor, $sub) = getVer();
            print "Your Version: $major.$minor.$sub\n";
            print "New Version: $version" . "$subversion\n";
            my $t = $subversion;
            $t =~ s/\.(\d+)/$1/;
            if ($sub =~ $t) {
                print "DB is already at the lastest revision, no need to upgrade.\n";
            } else {
                if ("$minor" eq 0) {
                    do_upgrade(0);
                } elsif ("$minor$sub" eq 1122) {
                    do_upgrade(1122);
                } elsif ("$major$minor" eq 299) {
                    do_upgrade("php-syslog-ng");
                } else {
                    do_upgrade("all");
                }
            }
        }
    }
    print "\n";
    make_dbuser();
    add_triggers();
    update_settings();
    add_logrotate();
    add_syslog_conf();
    setup_cron();
    setup_sudo();
    setup_apparmor();
    install_sphinx();
    fbutton();
}
if ($dbhost !~ /localhost|127.0.0.1/) {
    my $file = "$lzbase/scripts/db_insert.pl";
    open( FILE, "$file" );
    my @data = <FILE>;
    close( FILE );
    open(FILE,">$file") || die("Cannot Open $file: $!"); 
    foreach my $line (@data) {
        chomp $line;
        if ($line =~ /^(my.*=.*LOAD DATA) (INFILE.*)/) {
            #print "Altering $line:\n$1 LOCAL $2\n";
            print FILE "$1 LOCAL $2\n";
        } elsif ($line =~ /^(my.*"DBI:mysql.*;)(mysql_read_default_group=logzilla;")/) {
            print FILE $1 . "mysql_local_infile=1;" . $2 ."\n";
        } else {
            print FILE "$line\n";
        }
    }
    close( FILE );
}
setup_rclocal();
hup_syslog();

sub do_install {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    if (!$dbh) {
        print "Can't connect to $dbname database: ", $DBI::errstr, "\n";
        exit;
    }

# Create main table
    $dbh->do("
        CREATE TABLE $dbtable (
        id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
        host varchar(128) NOT NULL,
        facility enum('0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23') NOT NULL,
        severity enum('0','1','2','3','4','5','6','7') NOT NULL,
        program int(10) unsigned NOT NULL,
        msg varchar(2048) NOT NULL,
        mne int(10) unsigned NOT NULL,
        eid int(10) unsigned NOT NULL DEFAULT '0',
        suppress datetime NOT NULL DEFAULT '2010-03-01 00:00:00',
        counter int(11) NOT NULL DEFAULT '1',
        fo datetime NOT NULL,
        lo datetime NOT NULL,
        notes varchar(255) NOT NULL,
        PRIMARY KEY (id,lo),
        KEY facility (facility),
        KEY severity (severity),
        KEY host (host),
        KEY mne (mne),
        KEY eid (eid),
        KEY program (program),
        KEY suppress (suppress),
        KEY lo (lo),
        KEY fo (fo)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8 
        ") or die "Could not create $dbtable table: $DBI::errstr";

# Create sphinx table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/sph_counter.sql`;
    print $res;

# Create cache table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/cache.sql`;
    print $res;

# Create hosts table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/hosts.sql`;
    print $res;

# Create mnemonics table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/mne.sql`;
    print $res;

# Create snare_eid table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/snare_eid.sql`;
    print $res;

# Create programs table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/programs.sql`;
    print $res;

# Create suppress table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/suppress.sql`;
    print $res;

# Create facilities table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/facilities.sql`;
    print $res;

# Create severities table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/severities.sql`;
    print $res;

# Create ban table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/banned_ips.sql`;
    print $res;

#  TH: use the new archive feature!
## Create archive table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/logs_archive.sql`;
    print $res;

# Create triggers table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/triggers.sql`;
    print $res;

# Groups
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/groups.sql`;
    print $res;

# Insert totd data
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/totd.sql`;
    print $res;

# Insert LZECS data
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/lzecs.sql`;
    print $res;

# Insert Suppress data
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/suppress.sql`;
    print $res;

# Insert ui_layout data
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/ui_layout.sql`;
    print $res;

# Insert help data
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/help.sql`;
    print $res;

# Insert history table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/history.sql`;
    print $res;

# Insert archives table
#   my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/archives.sql`;
#   print $res;
# Insert users table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/users.sql`;
    print $res;

    make_partitions();
    do_procs();
    do_events();
    create_views();
}

sub update_paths {
    my $search = "/path_to_logzilla";
    print "Updating file paths\n";
    foreach my $file (qx(grep -RlI $search ../* | egrep -v "install.pl|\\.svn|\\.sql|license.txt|CHANGELOG|html/includes/index.php|\\.logtest|sphinx/src|sphinx/bin|html/ioncube")) {
        chomp $file;
        print "Modifying $file\n";
        system "perl -i -pe 's|$search|$lzbase|g' $file" and warn "Could not modify $file $!\n";
    }
    my $search = "/path_to_logs";
    print "Updating log paths\n";
    foreach my $file (qx(grep -RlI $search ../* | egrep -v "install.pl|.svn|.sql|CHANGELOG")) {
        chomp $file;
        print "Modifying $file\n";
        system "perl -i -pe 's|$search|$logpath|g' $file" and warn "Could not modify $file $!\n";
    }
}


sub make_logfiles {
#Create log files for later use by the server
    my $logfile = "$logpath/logzilla.log";
    open(LOG,">>$logfile");
    if (! -f $logfile) {
        print STDOUT "Unable to open log file \"$logfile\" for writing...$!\n";
        exit;
    }
    chmod 0666, "$logpath/logzilla.log";
    close(LOG);
    my $logfile = "$logpath/mysql_query.log";
    open(LOG,">>$logfile");
    if (! -f $logfile) {
        print STDOUT "Unable to open log file \"$logfile\" for writing...$!\n";
        exit;
    }
    close(LOG);
    chmod 0666, "$logpath/mysql_query.log";
}

sub genconfig {
    print "Generating $lzbase/html/config/config.php\n";
    my $config =qq{<?php
    DEFINE('DBADMIN', '$dbadmin');
    DEFINE('DBADMINPW', '$dbadminpw');
    DEFINE('DBNAME', '$dbname');
    DEFINE('DBHOST', '$dbhost');
    DEFINE('DBPORT', '$dbport');
    DEFINE('LOG_PATH', '$logpath');
    DEFINE('MYSQL_QUERY_LOG', '$logpath/mysql_query.log');
# Enabling query logging will degrade performance.
DEFINE('LOG_QUERIES', 'FALSE');
};
my $file="$lzbase/html/config/config.php";
open(CNF,">$file") || die("Cannot Open $file: $!"); 
print CNF "$config"; 
my $rfile="$lzbase/scripts/sql/regexp.txt";
open(FILE,$rfile) || die("Cannot Open file: $!"); 
my @data = <FILE>;
foreach my $line (@data) {
    print CNF "$line";
}
print CNF "?>\n"; 
close(CNF); 
close(FILE); 
}

sub make_partitions {
# Get some date values in order to create the MySQL Partition
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
# Create initial Partition of the $dbtable table
    $dbh->do("
        ALTER TABLE $dbtable PARTITION BY RANGE( TO_DAYS( lo ) ) (
        PARTITION $pAdd VALUES LESS THAN (to_days('$dateTomorrow'))
        );
        ") or die "Could not create partition for the $dbtable table: $DBI::errstr";

    my $event = qq{
    CREATE PROCEDURE logs_add_part_proc()
    SQL SECURITY DEFINER
    COMMENT 'Creates partitions for tomorrow' 
    BEGIN    
    DECLARE new_partition CHAR(32) DEFAULT
    CONCAT ('p', DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 DAY), '%Y%m%d'));
    DECLARE max_day INTEGER DEFAULT TO_DAYS(NOW()) +1;
    SET \@s =
    CONCAT('ALTER TABLE `$dbtable` ADD PARTITION (PARTITION ', new_partition,
    ' VALUES LESS THAN (', max_day, '))');
    PREPARE stmt FROM \@s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    END 
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create partition events: $DBI::errstr";
    $sth->execute;

    my $event = qq{
    CREATE PROCEDURE logs_delete_part_proc()
    SQL SECURITY DEFINER
    COMMENT 'Deletes old partitions - based on value of settings>retention' 
    BEGIN    
    SELECT CONCAT( 'ALTER TABLE `$dbtable` DROP PARTITION ',
    GROUP_CONCAT(`partition_name`))
    INTO \@s
    FROM `information_schema`.`partitions`
    WHERE `table_schema` = '$dbname'
    AND `table_name` = '$dbtable'
    AND `partition_description` <
    TO_DAYS(DATE_SUB(CURDATE(), INTERVAL (SELECT value from settings WHERE name='RETENTION') DAY))
    GROUP BY TABLE_NAME;

    IF \@s IS NOT NULL then
    PREPARE stmt FROM \@s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    END IF;
    END 
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create partition events: $DBI::errstr";
    $sth->execute;

    my $event = qq{
    CREATE PROCEDURE logs_add_archive_proc()
    SQL SECURITY DEFINER
    COMMENT 'Creates archive for old messages' 
    BEGIN    
    INSERT INTO `logs_archive` SELECT * FROM `$dbtable` 
    WHERE `$dbtable`.`lo` < DATE_SUB(CURDATE(), INTERVAL (SELECT value from settings WHERE name='RETENTION') DAY);
    END 
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create partition events: $DBI::errstr";
    $sth->execute;
}

sub do_events {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);

# Create Partition events
    my $event = qq{
    CREATE EVENT logs_add_partition ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL logs_add_part_proc();
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create partition events: $DBI::errstr";
    $sth->execute;

#  TH: use the new archive feature!
    my $event = qq{
    CREATE EVENT logs_add_archive ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:10:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL logs_add_archive_proc();
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create archive events: $DBI::errstr";
    $sth->execute;

    my $event = qq{
    CREATE EVENT logs_del_partition ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:15:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL logs_delete_part_proc();
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create partition events: $DBI::errstr";
    $sth->execute;

# CDUKES: [[ticket:17]]
    my $event = qq{
    CREATE EVENT cacheUpdate ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 01:00:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL updateCache();
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create event: cacheUpdate: $DBI::errstr";
    $sth->execute;
    my $event = qq{
    CREATE EVENT cacheHosts ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 01:30:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL updateHosts();
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create event: cacheHosts: $DBI::errstr";
    $sth->execute;
    my $event = qq{
    CREATE EVENT cacheMne ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 02:00:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL updateMne();
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create event: cacheMne: $DBI::errstr";
    $sth->execute;
    my $event = qq{
    CREATE EVENT cacheEid ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 02:30:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL updateEid();
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create event: cacheEid: $DBI::errstr";
    $sth->execute;
}

sub do_procs {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);

    my $event = qq{
    DROP PROCEDURE IF EXISTS updateCache;
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not drop updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $event = qq{
    DROP PROCEDURE IF EXISTS updateHosts;
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not drop updateHosts Procedure: $DBI::errstr";
    $sth->execute;

    my $event = qq{
    DROP PROCEDURE IF EXISTS updateMne;
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not drop updateMne Procedure: $DBI::errstr";
    $sth->execute;

    my $event = qq{
    DROP PROCEDURE IF EXISTS updateEid;
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not drop updateEid Procedure: $DBI::errstr";
    $sth->execute;


# CDUKES: [[ticket:17]]
    my $event = qq{
    CREATE PROCEDURE updateCache()
    SQL SECURITY DEFINER
    COMMENT 'Verifies cache totals every night' 
    BEGIN    
    REPLACE INTO cache (name,value,updatetime) VALUES ('msg_sum', (SELECT SUM(counter) FROM `$dbtable`),NOW());
    REPLACE INTO cache (name,value,updatetime) VALUES (CONCAT('chart_mpd_',DATE_FORMAT(NOW() - INTERVAL 1 DAY, '%Y-%m-%d_%a')), (SELECT SUM(counter) FROM `$dbtable` WHERE lo BETWEEN DATE_SUB(CONCAT(CURDATE(), ' 00:00:00'), INTERVAL 1 DAY) AND DATE_SUB(CONCAT(CURDATE(), ' 23:59:59'), INTERVAL  1 DAY)),NOW());
    END 
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;

# CDUKES: #122
    my $event = qq{
    CREATE PROCEDURE updateHosts()
    SQL SECURITY DEFINER
    COMMENT 'Verifies host cache totals every night' 
    BEGIN    
    UPDATE `hosts` SET `seen` = ( SELECT SUM(`$dbtable`.`counter`) FROM `$dbtable` WHERE `$dbtable`.`host` = `hosts`.`host` );
    END 
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create updateHosts Procedure: $DBI::errstr";
    $sth->execute;

# CDUKES: #122
    my $event = qq{
    CREATE PROCEDURE updateMne()
    SQL SECURITY DEFINER
    COMMENT 'Verifies host Mnemonics totals every night' 
    BEGIN    
    UPDATE `mne` SET `seen` = ( SELECT SUM(`$dbtable`.`counter`) FROM `$dbtable` WHERE `$dbtable`.`mne` = `mne`.`crc` );
    END 
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create updateMne Procedure: $DBI::errstr";
    $sth->execute;

# CDUKES: #122
    my $event = qq{
    CREATE PROCEDURE updateEid()
    SQL SECURITY DEFINER
    COMMENT 'Verifies host SNARE EID totals every night' 
    BEGIN    
    UPDATE `snare_eid` SET `seen` = ( SELECT SUM(`$dbtable`.`counter`) FROM `$dbtable` WHERE `$dbtable`.`eid` = `snare_eid`.`eid` );
    END 
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create updateEid Procedure: $DBI::errstr";
    $sth->execute;

# [[ticket:10]] TH: adding export procedure
#my $event = qq{
#CREATE PROCEDURE export()
#SQL SECURITY DEFINER
#COMMENT 'Export yesterdays data to a file'
#BEGIN
#DECLARE export CHAR(32) DEFAULT CONCAT ('dumpfile_', DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 day), '%Y%m%d'),'.txt');
#DECLARE export_path CHAR(127);
#SELECT value into export_path from settings WHERE name="ARCHIVE_PATH";
#SET \@s =
#CONCAT('select * into outfile "',export_path, '/' , export,'" from `$dbtable` where TO_DAYS( lo )=',TO_DAYS(NOW())-1);
#PREPARE stmt FROM \@s;
#EXECUTE stmt;
#DEALLOCATE PREPARE stmt;
#INSERT INTO archives (archive, records) VALUES (export,(SELECT COUNT(*) FROM `$dbtable` WHERE lo BETWEEN DATE_SUB(CONCAT(CURDATE(), ' 00:00:00'), INTERVAL 1 DAY) AND DATE_SUB(CONCAT(CURDATE(), ' 23:59:59'), INTERVAL  1 DAY)));
#END 
#};
#my $sth = $dbh->prepare("
#$event
#") or die "Could not create export Procedure: $DBI::errstr";
#$sth->execute;

# Turn the event scheduler on

    my $sth = $dbh->prepare("
        SET GLOBAL event_scheduler = 1;
        ") or die "Could not enable the Global event scheduler: $DBI::errstr";
    $sth->execute;
}

sub make_dbuser {
    # DB User
    # Remove old user in case this is an upgrade
    # Have to do this for the new LOAD DATA INFILE
    print "Temporarily removing $dbadmin from $localip\n";
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    my $grant = qq{GRANT USAGE ON *.* TO '$dbadmin'\@'$localip';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not temporarily drop the $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;
    my $grant = qq{DROP USER '$dbadmin'\@'$localip';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not temporarily drop the $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

    print "Adding $dbadmin to $localip\n";
# Grant access to $dbadmin
    my $grant = qq{GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, GRANT OPTION, REFERENCES, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EXECUTE, EVENT, TRIGGER ON `$dbname`.* TO '$dbadmin'\@'$localip'  IDENTIFIED BY '$dbadminpw'};
    #my $grant = qq{GRANT ALL PRIVILEGES ON `$dbname.*` TO '$dbadmin'\@'$localip' IDENTIFIED BY '$dbadminpw';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not create $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

    # CDUKES: [[ticket:16]]
    my $grant = qq{GRANT FILE ON *.* TO '$dbadmin'\@'$localip' IDENTIFIED BY '$dbadminpw';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not create $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;


    # Repeat for localhost
    # Remove old user in case this is an upgrade
    # Have to do this for the new LOAD DATA INFILE
    print "Temporarily removing $dbadmin from localhost\n";
    my $grant = qq{GRANT USAGE ON *.* TO '$dbadmin'\@'localhost';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not temporarily drop the $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;
    my $grant = qq{DROP USER '$dbadmin'\@'localhost';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not temporarily drop the $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

# Grant access to $dbadmin
    print "Adding $dbadmin to localhost\n";
    my $grant = qq{GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, GRANT OPTION, REFERENCES, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EXECUTE, EVENT, TRIGGER ON `$dbname`.* TO '$dbadmin'\@'localhost'  IDENTIFIED BY '$dbadminpw'};
    #my $grant = qq{GRANT ALL PRIVILEGES ON `$dbname.*` TO '$dbadmin'\@'localhost' IDENTIFIED BY '$dbadminpw';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not create $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

    # CDUKES: [[ticket:16]]
    my $grant = qq{GRANT FILE ON *.* TO '$dbadmin'\@'localhost' IDENTIFIED BY '$dbadminpw';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not create $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

    # THOMAS HONZIK: [[ticket:16]]
    my $flush = qq{FLUSH PRIVILEGES;};
    my $sth = $dbh->prepare("
        $flush
        ") or die "Could not FLUSH PRIVILEGES: $DBI::errstr";
    $sth->execute;

}

sub create_views {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    my $sth = $dbh->prepare("
        Create view logs_suppressed as 
        select *
        from $dbtable where (($dbtable.`suppress` > now()) or
        $dbtable.`host` in (select `suppress`.`name` from
        `suppress` where ((`suppress`.`col` = 'host') and
        (`suppress`.`expire` > now()))) or $dbtable.`facility`
        in (select `suppress`.`name` from `suppress` where
        ((`suppress`.`col` = 'facility') and
        (`suppress`.`expire` > now()))) or $dbtable.`severity`
        in (select `suppress`.`name` from `suppress` where
        ((`suppress`.`col` = 'severity') and
        (`suppress`.`expire` > now()))) or $dbtable.`program` in
        (select `suppress`.`name` from `suppress` where
        ((`suppress`.`col` = 'program') and
        (`suppress`.`expire` > now()))) or $dbtable.`mne` in
        (select `suppress`.`name` from `suppress` where
        ((`suppress`.`col` = 'mnemonic') and
        (`suppress`.`expire` > now()))) or $dbtable.`counter` in (select
        `suppress`.`name` from `suppress` where
        ((`suppress`.`col` = 'counter') and
        (`suppress`.`expire` > now()))))
        ") or die "Could not create $dbtable table: $DBI::errstr";
    $sth->execute;

    my $sth = $dbh->prepare("
        Create view logs_unsuppressed as
        select *
        from $dbtable where (($dbtable.`suppress` < now()) and
        (not($dbtable.`host` in (select `suppress`.`name` from
        `suppress` where ((`suppress`.`col` = 'host') and
        (`suppress`.`expire` > now()))))) and
        (not($dbtable.`facility` in (select `suppress`.`name`
        from `suppress` where ((`suppress`.`col` = 'facility')
            and (`suppress`.`expire` > now()))))) and
        (not($dbtable.`severity` in (select `suppress`.`name`
        from `suppress` where ((`suppress`.`col` = 'severity')
            and (`suppress`.`expire` > now()))))) and
        (not($dbtable.`program` in (select `suppress`.`name`
        from `suppress` where ((`suppress`.`col` = 'program')
            and (`suppress`.`expire` > now()))))) and
        (not($dbtable.`mne` in (select `suppress`.`name` from
        `suppress` where ((`suppress`.`col` = 'mnemonic') and
        (`suppress`.`expire` > now()))))) and
        (not($dbtable.`counter` in (select `suppress`.`name`
        from `suppress` where ((`suppress`.`col` = 'counter')
            and (`suppress`.`expire` > now()))))))
        ") or die "Could not create $dbtable table: $DBI::errstr";
    $sth->execute;
}

sub update_settings {

    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
# Insert settings data
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/settings.sql`;
    print $res;
    my $sth = $dbh->prepare("
        update settings set value='$url' where name='SITE_URL';
        ") or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        update settings set value='$email' where name='ADMIN_EMAIL';
        ") or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        update settings set value='$siteadmin' where name='ADMIN_NAME';
        ") or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        update settings set value='$lzbase' where name='PATH_BASE';
        ") or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        update settings set value='$sitename' where name='SITE_NAME';
        ") or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        update settings set value='$dbtable' where name='TBL_MAIN';
        ") or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        update settings set value='$logpath' where name='PATH_LOGS';
        ") or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        update settings set value='$version' where name='VERSION';
        ") or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        update settings set value='$subversion' where name='VERSION_SUB';
        ") or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        update settings set value='$retention' where name='RETENTION';
        ") or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    if ($snare =~ /[Yy]/) {
        my $sth = $dbh->prepare("
            update settings set value=1 where name='SNARE';
            ") or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
    } else {
        my $sth = $dbh->prepare("
            delete from ui_layout where header='Snare EventId' and userid>0;
            ") or die "Could not update ui layout for snare: $DBI::errstr";
        $sth->execute;
        my $sth = $dbh->prepare("
            update settings set value=0 where name='SNARE';
            ") or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
    }
    my $sth = $dbh->prepare("
        update triggers set mailto='$email', mailfrom='$email';
        ") or die "Could not update triggers table: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        update users set username='$siteadmin' where username='admin';
        ") or die "Could not insert user data: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        update users set pwhash=MD5('$siteadminpw') where username='$siteadmin';
        ") or die "Could not insert user data: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        delete from users where username='guest';
        ") or die "Could not insert user data: $DBI::errstr";
    $sth->execute;
}

sub add_logrotate {
    if ( -d "/etc/logrotate.d") {
        print "\nAdding LogZilla logrotate.d file to /etc/logrotate.d\n";
        my $ok  = &p("Ok to continue?", "y");
        if ($ok =~ /[Yy]/) {
            system("cp contrib/system_configs/logzilla.logrotate /etc/logrotate.d/logzilla");
        } else {
            print "Skipped logrotate.d file, you will need to manually copy:\n";
            print "cp contrib/system_configs/logzilla.logrotate /etc/logrotate.d/logzilla\n";
        }
    } else {
        print("\n\033[1m\tWARNING!\n\033[0m");
        print "Unable to locate your /etc/logrotate.d directory\n";
        print "You will need to manually copy:\n";
        print "cp $lzbase/scripts/contrib/system_configs/logzilla.logrotate /etc/logrotate.d/logzilla\n";
    }
}


# [[ticket:10]] Modifies the exports dir to he correct user
# system "chown mysql.mysql ../exports" and warn "Could not modify archive directory";   




sub add_syslog_conf {
    print "\n\nAdding LogZilla to syslog-ng\n";
    my $ok  = &p("Ok to continue?", "y");
    if ($ok =~ /[Yy]/) {
        my $file  = &p("Where is your syslog-ng.conf file located?", "/etc/syslog-ng/syslog-ng.conf");
        if (-f "$file") {
            # Check to see if entry already exists
            my $find = qr/[Ll]og[Zz]illa/;
            open FILE, "<$file";
            my @lines = <FILE>;
            close FILE;
            if (grep(/$find/, @lines)) {
                print "\nLogZilla config already exists in $file, skipping add...\n";
                my $find = qr/lzsub = (\d+)/;
                if (!grep(/$find/, @lines)) {
                    print("\n\033[1m\tWARNING!\n\033[0m");
                    print "An old version of the LogZilla template was detected.\n";
                    print "\nOLD FORMAT:\n";
                    print "destination d_logzilla {\n";
                    print 'program("/var/www/svn/logzilla/scripts/db_insert.pl"';
                    print "\n";
                    print 'template("$HOST\t$PRI\t$PROGRAM\t$MSGONLY\n")';
                    print "\n";
                    print "template_escape(yes)\n";
                    print ");\n";
                    print "};\n";

                    print "\n\nNEW FORMAT:\n";
                    print "destination d_logzilla {\n";
                    print 'program("/var/www/svn/logzilla/scripts/db_insert.pl"';
                    print "\n";
                    print 'template("$S_YEAR-$S_MONTH-$S_DAY $S_HOUR:$S_MIN:$S_SEC\t$HOST\t$PRI\t$PROGRAM\t$MSGONLY\n")';
                    print "\n";
                    print "template_escape(yes)\n";
                    print ");\n";
                    print "};\n";

                    print "\n";
                    print "Install will attempt to alter the line for you, but be sure to verify it after the installation completes.\n";
                    my $ok  = &p("Modifying $file, ok to continue?", "y");
                    if ($ok =~ /[Yy]/) {
                        my $new = '"\$S_YEAR-\$S_MONTH-\$S_DAY \$S_HOUR:\$S_MIN:\$S_SEC\\\t\$HOST\\\t\$PRI\\\t\$PROGRAM\\\t\$MSGONLY\\\n"';
                        my $old = qw{"\$HOST\\\t\$PRI\\\t\$PROGRAM\\\t\$MSGONLY\\\n"};
                        #print "perl -i -pe 's|$old|$new|g' $file\n";
                        system "perl -i -pe 's|$old|$new|g' $file" and warn "Could not modify $file $!\n";
                    }
                }
            } else {
                print "Adding syslog-ng configuration to $file\n";
                # Find syslog-ng.conf source definition
                my (@sources, $source);
                open( NGCONFIG, $file );
                my @config = <NGCONFIG>;
                close( NGCONFIG );
                foreach my $var (@config) {
                    next unless $var =~ /^source/; # Skip non-source def's
                    $source = $1 if ($var =~ /^source (\w+)/);
                    push(@sources, $source);
                }
                my $count = $#sources + 1;
                if ($count > 1) {
                    print("\n\033[1m\tWARNING!\n\033[0m");
                    print"You have more than 1 source defined\nThis can potentially be a bad thing\n";
                    print "Your source definitions are:\n";
                    foreach my $t (@sources)
                    { 
                        print $t ."\n";
                    } 
                } else {
                    print "Found $count sources\n";
                } 
                $source  = &p("Which source definition would you like to use?", "$source");
                if ($source !~ "s_all") {
                    system "perl -i -pe 's|s_all|$source|g' contrib/system_configs/syslog-ng.conf" and warn "Could not modify contrib/system_configs/syslog-ng.conf $!\n";
                }
                open(CNF,">>$file") || die("Cannot Open $file: $!"); 
                open(FILE,"contrib/system_configs/syslog-ng.conf") || die("Cannot Open file: $!"); 
                my @data = <FILE>;
                foreach my $line (@data) {
                    print CNF "$line";
                }
                close(CNF); 
                close(FILE); 
            }
        } else {
            print "Unable to locate your syslog-ng.conf file\n";
            print "You will need to manually merge contrib/system_configs/syslog-ng.conf with yours.\n";
        }
    } else {
        print "Skipped syslog-ng merge\n";
        print "You will need to manually merge contrib/system_configs/syslog-ng.conf with yours.\n";
    }
}

sub setup_cron {
# Cronjob  Setup
    print("\n\033[1m\n\n========================================\033[0m\n");
    print("\n\033[1m\tCron Setup\n\033[0m");
    print("\n\033[1m========================================\n\n\033[0m\n");
    print "\n";
    print "Cron is used to run backend indexing and data exports.\n";
    print "Install will attempt to do this automatically for you by adding it to /etc/cron.d\n";
    print "In the event that something fails or you skip this step, \n";
    print "You MUST create it manually or create the entries in your root's crontab file.\n";
    my $crondir;
    my $ok  = &p("Ok to continue?", "y");
    if ($ok =~ /[Yy]/) {
        my $minute;
        my $sml  = &p("\n\nWill this copy of LogZilla be used to process more than 1 Million messages per day?\nNote: Your answer here only determines how often to run indexing.", "n");
        if ($sml =~ /[Yy]/) {
            $minute = 5;
        } else {
            $minute = 1;
        }
        my $cron = qq{
#####################################################
# BEGIN LogZilla Cron Entries
#####################################################
# http://www.logzilla.pro
# Sphinx indexer cron times
# Note: Your setup may require some tweaking depending on expected message rates!
# Install date: $now
#####################################################

#####################################################
# Run Sphinx "full" scan 30 minutes after midnight
# in order to create a new index for today.
#####################################################
30 0 1 * * root $lzbase/sphinx/indexer.sh full >> $logpath/sphinx_indexer.log 2>&1

#####################################################
# Run Sphinx "delta" scans every 5 minutes throughout 
# the day.  
# Delta indexing should be very fast but you may need
# to adjust these times on very large systems.
#####################################################
*/$minute * * * * root $lzbase/sphinx/indexer.sh delta >> $logpath/sphinx_indexer.log 2>&1

#####################################################
# Run Sphinx "merge" scans every day at midnight
# Merging is much faster than a full scan.
# You may need to adjust these times on very large systems.
#####################################################
0 0 * * * root $lzbase/sphinx/indexer.sh merge >> $logpath/sphinx_indexer.log 2>&1

#####################################################
# Daily export archives
#####################################################
# 0 1 * * * root sh $lzbase/scripts/export.sh

#####################################################
# END LogZilla Cron Entries
#####################################################
};
$crondir = "/etc/cron.d";
unless ( -d "$crondir") {
    $crondir  = &p("What is the correct path to your cron.d?", "/etc/cron.d");
}
if (-d "$crondir") {
    my $file = "$crondir/logzilla";
    open FILE, ">$file" or die "cannot open $file: $!";
    print FILE $cron;
    close FILE;
    print "Cronfile added to $crondir\n";
} else {
    print "$crondir does not exist\n";
    print "You will need to manually copy $lzbase/scripts/contrib/system_configs/logzilla.crontab to /etc/cron.d\n";
    print "or use 'crontab -e' as root and paste the contents of $lzbase/scripts/contrib/system_configs/logzilla.crontab into it.\n";
    print "If you add it manually as root's personal crontab, then be sure to remove the \"root\" username from the last entry.\n";
}
    } else {
        print "Skipping Crontab setup.\n";
        print "You will need to manually copy $lzbase/scripts/contrib/system_configs/logzilla.crontab to /etc/cron.d\n";
        print "or use 'crontab -e' as root and paste the contents of $lzbase/scripts/contrib/system_configs/logzilla.crontab into it.\n";
        print "If you add it manually as root's personal crontab, then be sure to remove the \"root\" username from the last entry.\n";
    }
    hup_crond();
}

sub setup_sudo {
# Sudo Access Setup
    print("\n\033[1m\n\n========================================\033[0m\n");
    print("\n\033[1m\tSUDO Setup\n\033[0m");
    print("\n\033[1m========================================\n\n\033[0m\n\n");
    print "In order for the Apache user to be able to apply changes to syslog-ng, sudo access needs to be provided in /etc/sudoers\n";
    print "Note that you do not HAVE to do this, but it will make things much easier on your for both licensing and Email Alert editing.\n";
    print "If you choose not to install the sudo commands, then you must manually SIGHUP syslog-ng each time an Email Alert is added, changed or removed.\n";
    my $ok  = &p("Ok to continue?", "y");
    if ($ok =~ /[Yy]/) {
        my $file = "/etc/sudoers";
        unless (-e $file) {
            $file  = &p("Please provide the location of your sudoers file", "/etc/sudoers");
        }
        if (-f "$file") {
            # Try to get current web user
            my $PROGRAM = qr/apache|httpd/;
            my @ps = `ps axu`;
            @ps = map { m/^(\S+)/; $1 } grep { /$PROGRAM/ } @ps;
            my $webuser = $ps[$#ps];
            my $webuser  = &p("Please provide the username that Apache runs as", "$webuser");
            # Check to see if entry already exists
            my $find = qr/.*ALL=NOPASSWD:$lzbase\/scripts\/hup\.pl/;
            open SFILE, "<$file";
            my @lines = <SFILE>;
            close SFILE;
            if (grep(/$find/, @lines)) {
                print "Line already exists in $file, skipping add...\n";
            } else {
                my $os = `uname -a`;
                $os =~ s/.*(ubuntu).*/$1/i;
                my $now = localtime;
                open SFILE, ">>$file" or die "cannot open $file for append: $!";
                print SFILE "\n";
                print SFILE "# Below added by LogZilla installation on $now\n";
                print SFILE "# Allows Apache user to HUP the syslog-ng process\n";
                print SFILE "$webuser ALL=NOPASSWD:$lzbase/scripts/hup.pl\n";
                print SFILE "# Allows Apache user to apply new licenses from the web interface\n";
                print SFILE "$webuser ALL=NOPASSWD:$lzbase/scripts/licadd.pl\n";
                # print SFILE "# Allows Apache user to import data from archive\n";
                # print SFILE "# $webuser ALL=NOPASSWD:$lzbase/scripts/doimport.sh\n";
                close SFILE;
                print "Appended sudoer access for $webuser to $file\n";
                if ($os !~ /Ubuntu/i) {
                    my $find = qr/^Defaults.*requiretty/;
                    open SFILE, "<$file";
                    my @lines = <SFILE>;
                    close SFILE;
                    if (grep(/$find/, @lines)) {
                        print "Non-ubuntu OS's will require removal (or comment out) of the following line from $file:\n";
                        print "Defaults    requiretty\n";
                    }
                }
            }
        } else {
            print "$file does not exist\nUnable to continue!";
            exit;
        }

    } else {
        print "Skipping SUDO setup.\n";
        print "You will need to add the following to your sudoers so that LogZilla has permission to apply changes from the web interface\n";
        print "Note: You should change \"www-data\" below to match the user that runs Apache\n";
        print "# Allows Apache user to HUP the syslog-ng process\n";
        print "www-data ALL=NOPASSWD:$lzbase/scripts/hup.pl\n";
        print "www-data ALL=NOPASSWD:$lzbase/scripts/licadd.pl\n";
    }
}

sub kill {
    my $PROGRAM = shift;
    my @ps = `ps ax`;
    @ps = map { m/(\d+)/; $1 } grep { /\Q$PROGRAM\E/ } @ps;
    for ( @ps ) {
        (kill 9, $_) or die("Unable to kill process for $PROGRAM\n");
    }
    my $time = gmtime();
#print "Killed $PROGRAM @ps\n";
}

sub install_sphinx {
    print("\n\033[1m\n\n========================================\033[0m\n");
    print("\n\033[1m\tSphinx Indexer\n\033[0m");
    print("\n\033[1m========================================\n\n\033[0m\n\n");
    print "Install will attempt to extract and compile your sphinx indexer.\n";
    print "This option may not work on all systems, so please watch for errors.\n";
    print "The steps taken are as follows:\n";
    print "killall searchd (to stop any currently running Sphinx searchd processes).\n";
    print "cd $lzbase/sphinx/src\n";
    print "tar xzvf sphinx-0.9.9.tar.gz\n";
    print "cd $lzbase/sphinx/src/sphinx-0.9.9\n";
    print "./configure --prefix `pwd`/../..\n";
    print "make && make install\n";
    print "cd $lzbase/sphinx\n";
    print "$lzbase/sphinx/bin/searchd -c $lzbase/sphinx/sphinx.conf\n";
    print "./indexer.sh full\n";
    my $ok  = &p("Ok to continue?", "y");
    if ($ok =~ /[Yy]/) {
        my $checkprocess = `ps -C searchd -o pid=`;
        if ($checkprocess) {
            system("killall searchd");
        }
        system("rm -f $lzbase/sphinx/data/idx_* && cd $lzbase/sphinx/src && tar xzvf sphinx-0.9.9.tar.gz && cd $lzbase/sphinx/src/sphinx-0.9.9 && ./configure --prefix `pwd`/../.. && make && make install && $lzbase/sphinx/indexer.sh full && $lzbase/sphinx/bin/searchd -c $lzbase/sphinx/sphinx.conf && cd $lzbase/scripts");
    } else {
        print "Skipping Sphinx Installation\n";
    }
}

sub setup_apparmor {
# Attempt to fix AppArmor
    my $file = "/etc/apparmor.d/usr.sbin.mysqld";
    if (-f "$file") {
        open FILE, "<$file";
        my @lines = <FILE>;
        close FILE;
        if (!grep(/logzilla_import/, @lines)) {
            print("\n\033[1m\n\n========================================\033[0m\n");
            print("\n\033[1m\tAppArmor Setup\n\033[0m");
            print("\n\033[1m========================================\n\n\033[0m\n\n");
            print "In order for MySQL to import and export data, you must take measures to allow it access from AppArmor.\n";
            print "Install will attempt do do this for you, but please be sure to check /etc/apparmor.d/usr.sbin.mysqld and also to restart the AppArmor daemon once install completes.\n";
            my $ok  = &p("Ok to continue?", "y");
            if ($ok =~ /[Yy]/) {
                print "Adding the following to lines to $file:\n";
                print "/tmp/logzilla_import.txt r,\n$lzbase/exports/** rw,\n";
                open my $config, '+<', "$file" or warn "FAILED: $!\n";
                my @all = <$config>;
                seek $config, 0, 0;
                splice @all, -1, 0, "  /tmp/logzilla_import.txt r,\n  $lzbase/exports/** rw,\n";
                print $config @all;
                close $config;
            }
            print "\n\nAppArmor must be restarted, would you like to restart it now?\n";
            my $ok  = &p("Ok to continue?", "y");
            if ($ok =~ /[Yy]/) {
                my $r = `/etc/init.d/apparmor restart`;
            } else {
                print("\033[1m\n\tPlease be sure to restart apparmor..\n\033[0m");
            }
        }
    }
}
sub setup_rclocal {
    my $file = "/etc/rc.local";
    if (-f "$file") {
        open my $config, '+<', "$file" or warn "FAILED: $!\n";
        my @all = <$config>;
        if (!grep(/sphinx/, @all)) {
            seek $config, 0, 0;
            splice @all, -1, 0, "$lzbase/sphinx/bin/searchd -c $lzbase/sphinx/sphinx.conf\n";
            print $config @all;
        }
        close $config;
    } else {
        print("\n\033[1m\tERROR!\n\033[0m");
        print "Unable to locate your $file\n";
        print "You will need to manually add the Sphinx Daemon startup to your system...\n";
        print "Sphinx startup command:\n";
        print "$lzbase/sphinx/bin/searchd -c $lzbase/sphinx/sphinx.conf\n";
    }
}

sub fbutton {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
# Feedback button
    print("\n\033[1m\n\n========================================\033[0m\n");
    print("\n\033[1m\tFeedback and Support\n\033[0m");
    print("\n\033[1m========================================\n\n\033[0m\n\n");

    print "\nIf it's ok with you, install will include a small 'Feedback and Support'\n";
    print  "icon which will appear at the bottom right side of the web page\n";
    print "This non-intrusive button will allow you to instantly open support \n";
    print "requests with us as well as make suggestions on how we can make LogZilla better.\n";
    print "You can always disable it by selecting 'Admin>Settings>FEEDBACK' from the main menu\n";
    my $ok  = &p("Ok to add support and feedback?", "y");
    if ($ok =~ /[Yy]/) {
        my $sth = $dbh->prepare("
            update settings set value='1' where name='FEEDBACK';
            ") or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
    }
}


sub hup_syslog {
# syslog-ng HUP
    print "\n\n";
    my $checkprocess = `ps -C syslog-ng -o pid=`;
    if ($checkprocess) {
        print "\n\nSyslog-ng MUST be restarted, would you like to send a HUP signal to the process?\n";
        my $ok  = &p("Ok to HUP syslog-ng?", "y");
        if ($ok =~ /[Yy]/) {
            if ($checkprocess =~ /(\d+)/) {
                my $pid = $1;
                print STDOUT "HUPing syslog-ng PID $pid\n";
                my $r = `kill -HUP $pid`;
            } else {
                print STDOUT "Unable to find PID for syslog-ng\n";
            }
        } else {
            print("\033[1m\n\tPlease be sure to restart syslog-ng..\n\033[0m");
        }
    }
}

sub hup_crond {
    print "\n\n";
    my $checkprocess = `cat /var/run/crond.pid`;
    if ($checkprocess) {
        print "\n\nCron.d should be restarted, would you like to send a HUP signal to the process?\n";
        my $ok  = &p("Ok to HUP CRON?", "y");
        if ($ok =~ /[Yy]/) {
            if ($checkprocess =~ /(\d+)/) {
                my $pid = $1;
                print STDOUT "HUPing CRON PID $pid\n";
                my $r = `kill -HUP $pid`;
            } else {
                print STDOUT "Unable to find PID for CRON.D in /var/run\n";
            }
        } else {
            print("\033[1m\n\tPlease be sure to restart CRON..\n\033[0m");
        }
    }
}







print("\n\033[1m\tLogZilla installation complete!\n\033[0m");

# Wordwrap system: deal with the next character
sub wrap_one_char {
    my $output = shift;
    my $pos = shift;
    my $word = shift;
    my $char = shift;
    my $reserved = shift;
    my $length;

    my $cTerminalLineSize = 79;
    if (not (($char eq "\n") || ($char eq ' ') || ($char eq ''))) {
        $word .= $char;

        return ($output, $pos, $word);
    }

    # We found a separator.  Process the last word

    $length = length($word) + $reserved;
    if (($pos + $length) > $cTerminalLineSize) {
        # The last word doesn't fit in the end of the line. Break the line before
        # it
        $output .= "\n";
        $pos = 0;
    }
    ($output, $pos) = append_output($output, $pos, $word);
    $word = ''; 

    if ($char eq "\n") {
        $output .= "\n";
        $pos = 0;
    } elsif ($char eq ' ') {
        if ($pos) {
            ($output, $pos) = append_output($output, $pos, ' ');
        }
    }

    return ($output, $pos, $word);
}

# Wordwrap system: word-wrap a string plus some reserved trailing space
sub wrap {
    my $input = shift;
    my $reserved = shift;
    my $output;
    my $pos;
    my $word;
    my $i;

    if (!defined($reserved)) {
        $reserved = 0;
    }

    $output = '';
    $pos = 0;
    $word = '';
    for ($i = 0; $i < length($input); $i++) {
        ($output, $pos, $word) = wrap_one_char($output, $pos, $word,
            substr($input, $i, 1), 0);
    }
    # Use an artifical last '' separator to process the last word
    ($output, $pos, $word) = wrap_one_char($output, $pos, $word, '', $reserved);

    return $output;
}

# Print message
sub msg {
    my $msg = shift;

    print $msg . "\n";
    exit;
}

# Display the end-user license agreement
sub show_EULA {
    my $pager = $ENV{PAGER} || 'less' || 'more';
    system($pager, './EULA.txt') == 0 or die "$pager call failed: $?";
    print "\n\n";
}

sub do_upgrade {
    my $rev = shift;
    print("\n\033[1m\tUpgrading, please be patient!\nIf you have a large DB, this could take a long time...\n\033[0m");
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    switch ($rev) {
        case 0 {
            print "You are running an unsupported version of LogZilla (<3.1)\n";
            print "An attempt will be made to upgrade to $version$subversion...\n";
            my $ok  = &p("Continue? (yes/no)", "y");
            if ($ok =~ /[Yy]/) {
                add_snare_to_logtable();
                hosts_add_seen_columns();
                mne_add_seen_columns();
                tbl_add_programs();
                tbl_add_severities();
                tbl_add_facilities();
                create_snare_table();
                create_email_alerts_table();
                copy_old_settings();
                update_procs();
                if (colExists("logs", "priority") eq 1) {
                    tbl_logs_alter_from_30();
                }
                print "\n\tUpgrade complete, continuing installation...\n\n";
            }
        }
        case 1122 { 
            print "Upgrading Database from v3.1.122 to $version$subversion...\n";
            add_snare_to_logtable();
            hosts_add_seen_columns();
            mne_add_seen_columns();
            create_snare_table();
            create_email_alerts_table();
            copy_old_settings();
            update_procs();
            print "\n\tUpgrade complete, continuing installation...\n\n";

        }
        case "php-syslog-ng" {
            print "You are running an unsupported version of LogZilla (Php-syslog-ng v2.x)\n";
            print "An attempt will be made to upgrade to $version$subversion...\n";
            my $ok  = &p("Continue? (yes/no)", "y");
            if ($ok =~ /[Yy]/) {
                add_snare_to_logtable();
                hosts_add_seen_columns();
                mne_add_seen_columns();
                tbl_add_programs();
                tbl_add_severities();
                tbl_add_facilities();
                create_snare_table();
                create_email_alerts_table();
                update_procs();
                if (colExists("logs", "priority") eq 1) {
                    tbl_logs_alter_from_299();
                }
                print "\n\tUpgrade complete, continuing installation...\n\n";
            }
        }
        case "all" {
            print "Your version is not an officially supported upgrade.\n";
            print "An attempt will be made to upgrade to $version$subversion...\n";
            my $ok  = &p("Continue? (yes/no)", "y");
            if ($ok =~ /[Yy]/) {
                add_snare_to_logtable();
                hosts_add_seen_columns();
                mne_add_seen_columns();
                tbl_add_programs();
                tbl_add_severities();
                tbl_add_facilities();
                create_snare_table();
                create_email_alerts_table();
                copy_old_settings();
                update_procs();
                print "\n\tUpgrade complete, continuing installation...\n\n";
            }
        }
        case 2 { 
            print "Attempting upgrade from php-syslog-ng (v2.x) to LogZilla (v3.x)\n";
            print "Not Implemented yet...sorry\n";
            exit;
        }
        else  { 
            print "Your version is not a candidate for upgrade.\n";
            exit;
        }
    }
    update_help();
    update_ui_layout();
}

sub db_connect {
    my $dbname = shift;
    my $lzbase = shift;
    my $dbroot = shift;
    my $dbrootpass = shift;
    my $dsn = "DBI:mysql:$dbname:;mysql_read_default_group=logzilla;"
    . "mysql_read_default_file=$lzbase/scripts/sql/lzmy.cnf";
    my $dbh = DBI->connect($dsn, $dbroot, $dbrootpass);

    if (!$dbh) {
        print "Can't connect to the mysql database: ", $DBI::errstr, "\n";
        exit;
    }

    return $dbh;
}

sub db_exists {
    my $dbh = DBI->connect( "DBI:mysql:mysql:$dbhost:$dbport", $dbroot, $dbrootpass );
    my $sth = $dbh->prepare("show databases like '$dbname'") or die "Could not get DB's: $DBI::errstr";
    $sth->execute;
    while (my @data = $sth->fetchrow_array()) {
        if ($data[0] == "$dbtable") {
            return 1;
        } else {
            return 0;
        }
    }
}

sub getVer {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    if (colExists("settings", "id") eq 1) {
        my $ver = $dbh->selectrow_array("
            SELECT value from settings where name='VERSION';
            ");
        my ($major, $minor) = split(/\./, $ver);
        my $sub = $dbh->selectrow_array("SELECT value from settings where name='VERSION_SUB'; ");
        $sub =~ s/^\.//;
        return ($major, $minor, $sub);
    } else {
        # If there is no settings table in the DB, it's php-syslog-ng v2.x
        return (2, 99, 0);
    }
}

sub add_triggers {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    print "Dropping Triggers...\n";
    $dbh->do("DROP TRIGGER IF EXISTS counts") or die "Could not drop trigger: $DBI::errstr";
    print "Adding Triggers...\n";
    $dbh->do("
        CREATE TRIGGER `counts`
        AFTER INSERT ON `$dbtable`
        FOR EACH ROW
        BEGIN
        INSERT INTO hosts(host,lastseen,seen) VALUES (NEW.host,NOW(),1) ON DUPLICATE KEY UPDATE seen=seen + 1, lastseen=NOW();
        UPDATE mne SET seen=seen + 1, lastseen=NOW() WHERE crc=NEW.mne;
        UPDATE snare_eid SET seen=seen + 1, lastseen=NOW() WHERE eid=NEW.eid;
        INSERT INTO cache (name,value,updatetime) VALUES ('msg_sum',1,NOW()) ON DUPLICATE KEY UPDATE value=value + 1,updatetime=NOW();
        END
        ") or die "Could not add triggers: $DBI::errstr";
}

sub add_snare_to_logtable {
    if (colExists("$dbtable", "eid") eq 0) {
        my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
        print "Adding SNARE eids to $dbtable...\n";
        $dbh->do("ALTER TABLE $dbtable ADD `eid` int(10) unsigned NOT NULL DEFAULT '0'") or die "Could not update $dbtable: $DBI::errstr";
        print "Adding SNARE index to $dbtable...\n";
        $dbh->do("ALTER TABLE $dbtable ADD index eid(eid)") or die "Could not update $dbtable: $DBI::errstr";
    }
}
sub create_snare_table {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    print "Adding new SNARE table...\n";
    $dbh->do("DROP TABLE IF EXISTS snare_eid") or die "Could not update $dbname: $DBI::errstr";
    $dbh->do("
        CREATE TABLE `snare_eid` (
        `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
        `eid` smallint(5) unsigned NOT NULL DEFAULT '0',
        `lastseen` datetime NOT NULL,
        `seen` int(10) unsigned NOT NULL DEFAULT '1',
        PRIMARY KEY (`id`),
        UNIQUE KEY `eid` (`eid`)
        ) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
        ") or die "Could not update $dbname: $DBI::errstr";
}

sub hosts_add_seen_columns {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    if (colExists("hosts", "id") eq 0) {
        print "Creating Hosts table...\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/hosts.sql`;
        print "$res\n";
    }
    if (colExists("hosts", "lastseen") eq 0) {
        print "Updating Hosts table...\n";
        $dbh->do("ALTER TABLE hosts ADD `lastseen` datetime NOT NULL default '2011-03-01 00:00:00'; ") or die "Could not update $dbname: $DBI::errstr";
        $dbh->do("ALTER TABLE hosts ADD `seen` int(10) unsigned NOT NULL DEFAULT '1'; ") or die "Could not update $dbname: $DBI::errstr";
    }
}
sub mne_add_seen_columns {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    if (colExists("mne", "id") eq 0) {
        print "Creating Mnemonics table...\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/mne.sql`;
        print "$res\n";
    }
    if (colExists("mne", "lastseen") eq 0) {
        print "Updating Mnemonics table...\n";
        $dbh->do("ALTER TABLE mne ADD `lastseen` datetime NOT NULL default '2011-03-01 00:00:00'; ") or die "Could not update $dbname: $DBI::errstr";
        $dbh->do("ALTER TABLE mne ADD `seen` int(10) unsigned NOT NULL DEFAULT '1'; ") or die "Could not update $dbname: $DBI::errstr";
    }
}
sub tbl_logs_alter_from_30 {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    print "Attempting to modify an older logs table to work with the new version.\n";
    print "This could take a VERY long time, DO NOT cancel this operation\n";
    if (colExists("$dbtable", "priority") eq 1) {

        print "Updating column: priority->severity\n";
        $dbh->do("ALTER TABLE $dbtable CHANGE `priority` severity enum('0','1','2','3','4','5','6','7') NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Updating column: facility\n";
        $dbh->do("ALTER TABLE $dbtable CHANGE `facility` `facility` enum('0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23') NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Dropping tag column\n";
        $dbh->do("ALTER TABLE $dbtable DROP COLUMN tag") or die "Could not update $dbname: $DBI::errstr";

        print "Updating column: program\n";
        $dbh->do("ALTER TABLE $dbtable CHANGE `program` `program` int(10) unsigned NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Updating column: mne\n";
        $dbh->do("ALTER TABLE $dbtable CHANGE `mne` `mne` int(10) unsigned NOT NULL") or die "Could not update $dbname: $DBI::errstr";
        print "Adding Sphinx Counter table\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/sph_counter.sql`;

    }
}

sub tbl_logs_alter_from_299 {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    print("\n\033[1m\tWARNING!\n\033[0m");
    print "Attempting to modify an older logs table to work with the new version.\n";
    print "This could take a VERY long time, DO NOT cancel this operation\n";
    if (colExists("$dbtable", "priority") eq 1) {

        print "Updating column: priority->severity\n";
        $dbh->do("ALTER TABLE $dbtable CHANGE `priority` severity enum('0','1','2','3','4','5','6','7') NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Updating column: facility\n";
        $dbh->do("ALTER TABLE $dbtable CHANGE `facility` `facility` enum('0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23') NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Dropping tag column\n";
        $dbh->do("ALTER TABLE $dbtable DROP COLUMN tag") or die "Could not update $dbname: $DBI::errstr";

        print "Dropping level column\n";
        $dbh->do("ALTER TABLE $dbtable DROP COLUMN level") or die "Could not update $dbname: $DBI::errstr";

        print "Dropping seq column\n";
        $dbh->do("ALTER TABLE $dbtable DROP COLUMN seq") or die "Could not update $dbname: $DBI::errstr";

        print "Updating column: program\n";
        $dbh->do("ALTER TABLE $dbtable CHANGE `program` `program` int(10) unsigned NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Updating column: host\n";
        $dbh->do("ALTER TABLE $dbtable CHANGE `host` `host` varchar(128) NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Updating column: fo\n";
        $dbh->do("ALTER TABLE $dbtable CHANGE `fo` `fo` datetime NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Updating column: lo\n";
        $dbh->do("ALTER TABLE $dbtable CHANGE `lo` `lo` datetime NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Adding column: mne\n";
        $dbh->do("ALTER TABLE $dbtable ADD `mne` int(10) unsigned NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Adding column: suppress\n";
        $dbh->do("ALTER TABLE $dbtable ADD `suppress` datetime NOT NULL DEFAULT '2010-03-01 00:00:00'") or die "Could not update $dbname: $DBI::errstr";

        print "Adding column: notes\n";
        $dbh->do("ALTER TABLE $dbtable ADD `notes` varchar(255) NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Altering column: msg\n";
        $dbh->do("ALTER TABLE $dbtable CHANGE `msg` `msg` varchar(2048) NOT NULL") or die "Could not update $dbname: $DBI::errstr";

        print "Dropping index: priority\n";
        $dbh->do("ALTER TABLE $dbtable DROP INDEX priority") or die "Could not update $dbname: $DBI::errstr";

        print "Adding index: severity\n";
        $dbh->do("ALTER TABLE $dbtable ADD INDEX severity (severity)") or die "Could not update $dbname: $DBI::errstr";

        print "Adding index: mne\n";
        $dbh->do("ALTER TABLE $dbtable ADD INDEX mne (mne)") or die "Could not update $dbname: $DBI::errstr";

        print "Adding index: suppress\n";
        $dbh->do("ALTER TABLE $dbtable ADD INDEX suppress (suppress)") or die "Could not update $dbname: $DBI::errstr";

        print "Adding primary key\n";
        $dbh->do("ALTER TABLE $dbtable DROP PRIMARY KEY, ADD PRIMARY KEY (`id`, `lo`)") or die "Could not update $dbname: $DBI::errstr";
        print "Dropping users table primary key\n";
        $dbh->do("ALTER TABLE users DROP PRIMARY KEY") or die "Could not update $dbname: $DBI::errstr";

        print "Modifying users table: add id and primary key\n";
        $dbh->do("ALTER TABLE users ADD `id` int(9) NOT NULL AUTO_INCREMENT, ADD PRIMARY KEY id (id);") or die "Could not update $dbname: $DBI::errstr";

        print "Updating column: users.username\n";
        $dbh->do("ALTER TABLE users CHANGE `username` `username` varchar(15) NOT NULL") or die "Could not update $dbname: $DBI::errstr";
        print "Adding column: users.group\n";
        $dbh->do("ALTER TABLE users ADD `group` int(3) NOT NULL DEFAULT '2'") or die "Could not update $dbname: $DBI::errstr";

        print "Adding column: users.totd\n";
        $dbh->do("ALTER TABLE users ADD `totd` enum('show','hide') NOT NULL DEFAULT 'show'") or die "Could not update $dbname: $DBI::errstr";

        print "Setting up $siteadmin user\n";
        $dbh->do("REPLACE INTO `users` (username,pwhash) VALUES ('$siteadmin',md5('$siteadminpw'))") or die "Could not update $dbname: $DBI::errstr";


        print "Dropping table: actions\n";
        $dbh->do("DROP TABLE actions") or die "Could not update $dbname: $DBI::errstr";

        print "Dropping MERGE table: all_logs\n";
        $dbh->do("DROP TABLE all_logs") or die "Could not update $dbname: $DBI::errstr";

        print "Dropping table: cemdb\n";
        $dbh->do("DROP TABLE cemdb") or die "Could not update $dbname: $DBI::errstr";

        print "Dropping table: search_cache\n";
        $dbh->do("DROP TABLE search_cache") or die "Could not update $dbname: $DBI::errstr";

        print "Dropping table: user_access\n";
        $dbh->do("DROP TABLE user_access") or die "Could not update $dbname: $DBI::errstr";

        print "Adding Sphinx Counter table\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/sph_counter.sql`;

        print "Adding Cache Table\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/cache.sql`;
        print $res;

        print "Adding Groups Table\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/groups.sql`;
        print $res;

        print "Adding History Table\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/history.sql`;
        print $res;

        print "Adding lzecs Table\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/lzecs.sql`;
        print $res;

        print "Creating Suppress Table\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/suppress.sql`;
        print $res;

        print "Creating Totd Table\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/totd.sql`;

        print "Creating views\n";
        create_views();
    }
}

sub create_email_alerts_table {
    print "Adding Email Alerts...\n";
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/triggers.sql`;
    print $res;
}
sub tbl_add_programs {
    if (colExists("programs", "id") eq 0) {
        print "Adding Programs Table...\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/programs.sql`;
        print $res;
    }
}
sub tbl_add_severities {
    if (colExists("severities", "id") eq 0) {
        print "Adding Severities Table...\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/severities.sql`;
        print $res;
    }
}
sub tbl_add_facilities {
    if (colExists("facilities", "id") eq 0) {
        print "Adding Facilities Table...\n";
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/facilities.sql`;
        print $res;
    }
}

sub update_help {
    print "Updating help files...\n";
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/help.sql`;
    print $res;
}

sub update_ui_layout {
    print "Updating UI Layout files...\n";
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/ui_layout.sql`;
    print $res;
}


sub copy_old_settings {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    print "Updating Settings...\n";
    $dbh->do("RENAME TABLE settings TO settings_orig") or die "Could not update $dbname: $DBI::errstr";
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/settings.sql`;
    print $res;
    $dbh->do("REPLACE INTO settings SELECT * FROM settings_orig; ") or die "Could not update $dbname: $DBI::errstr";
    $dbh->do("DROP TABLE settings_orig") or die "Could not update $dbname: $DBI::errstr";
}
sub update_procs {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    print "Updating SQL Procedures...\n";
    $dbh->do("DROP PROCEDURE IF EXISTS updateCache") or die "Could not create updateCache Procedure: $DBI::errstr";
    $dbh->do("
        CREATE PROCEDURE updateCache()
        SQL SECURITY DEFINER
        COMMENT 'Verifies cache totals every night' 
        BEGIN    
        REPLACE INTO cache (name,value,updatetime) VALUES (CONCAT('chart_mpd_',DATE_FORMAT(NOW() - INTERVAL 1 DAY, '%Y-%m-%d_%a')), (SELECT SUM(counter) FROM `$dbtable` WHERE lo BETWEEN DATE_SUB(CONCAT(CURDATE(), ' 00:00:00'), INTERVAL 1 DAY) AND DATE_SUB(CONCAT(CURDATE(), ' 23:59:59'), INTERVAL  1 DAY)),NOW());
        END
        ") or die "Could not create updateCache Procedure: $DBI::errstr";

}
sub colExists {
    my $table = shift;
    my $col = shift;
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    my $sth = $dbh->column_info( undef, $dbname, $table, '%');
    my $ref = $sth->fetchall_arrayref;
    my @cols = map { $_->[3] } @$ref;
    if (grep(/$col/, @cols)) {
        return 1;
    } else {
        return 0;
    }
}

