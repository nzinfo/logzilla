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
my $subversion = ".234";

# Grab the base path
my $lzbase = getcwd;
$lzbase =~ s/\/scripts//g;
my $now = localtime;

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
if ($dbhost !~ /localhost|127.0.0.1/) {
    system "perl -i -pe 's|qq{LOAD DATA INFILE|qq{LOAD DATA LOCAL INFILE|g' ./db_insert.pl" or die "Could not modify ./db_insert.pl $!\n";
}
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
my $email  = &p("Enter your email address", 'info@logzilla.pro');
my $sitename  = &p("Enter a name for your website", 'The home of LogZilla');
my $url  = &p("Enter the base url for your site (include trailing slash)", '/logs/');
my $logpath  = &p("Where should log files be stored?", '/var/log/logzilla');
my $retention  = &p("How long before I archive old logs? (in days)", '7');
my $snare  = &p("Do you plan to log Windows events from SNARE to this server?", 'n');


if (! -d "$logpath") {
    mkdir "$logpath";
}

# Create mysql .cnf file
if (! -f "$lzbase/scripts/sql/lzmy.cnf") {
    open(CNF,">$lzbase/scripts/sql/lzmy.cnf") || die("Cannot Open $lzbase/scripts/sql/lzmy.cnf: $!"); 
    print CNF "[logzilla]\n";
    print CNF "user = $dbadmin\n";
    print CNF "password = $dbadminpw\n";
    print CNF "host = $dbhost\n";
    print CNF "port = $dbport\n";
    print CNF "database = $dbname\n";
    close(CNF); 
    chmod 0400, "$lzbase/scripts/sql/lzmy.cnf";
}

update_paths();
make_logfiles();
genconfig();

print "All data will be installed into the $dbname database\n";
my $ok  = &p("Ok to continue?", "y");
if ($ok =~ /[Yy]/) {
# First, connect to the mysql database and create the $dbname
    my $dbh = DBI->connect( "DBI:mysql:mysql:$dbhost:$dbport", $dbroot, $dbrootpass );
    # Check version of MySQL
    my $sth = $dbh->prepare("SELECT version()") or die "Could not create the $dbname database: $DBI::errstr";
    $sth->execute;
    while (my @data = $sth->fetchrow_array()) {
        my $ver = $data[0];
        if ($ver !~ /5\.[15]/) {
            print("\n\033[1m\tERROR!\n\033[0m");
            print "LogZilla requires MySQL v5.1 or better.\n";
            print "Your version is $ver\n";
            print "Please upgrade MySQL to v5.1 or better and re-run this installation.\n";
            exit;
        }
    }
    my $sth = $dbh->prepare("create database $dbname");
    $sth->execute;
    if ($dbh->err) {
        print("\n\033[1m\tThe $dbname Database Already Exists\n\033[0m");
        print "Install can attempt an upgrade, but be aware of the following:\n";
        print "1. The upgrade process could potentially take a VERY long time on very large databases.\n";
        print "2. There is a potential for data loss, so please make sure you have backed up your database before proceeding.\n";
        my $ok  = &p("Ok to continue?", "y");
        if ($ok =~ /[Yy]/) {
            my ($ver, $major, $table, @data);
            my $sth = $dbh->prepare("
                show tables like 'settings';
                ") or die "Could not execute: $DBI::errstr";
            $sth->execute;
            while (@data = $sth->fetchrow_array()) {
                $table = $data[0];
            }
            if ($table eq "settings") {
                $major eq 3;
            } else {
                $major eq 2;
            }
            if ($major eq 3) {
                print "$major\n";
                exit;
                my $sth = $dbh->prepare("
                    select name,value from $dbname.settings where name='VERSION';
                    ") or die "Could not execute: $DBI::errstr";
                $sth->execute;
                while (my @data = $sth->fetchrow_array()) {
                    $ver = $data[1];
                }
                if ($ver =~ /3\.1/) {
                    do_upgrade('3.1');
                } else {
                    print("\n\033[1m\tERROR!\n\033[0m");
                    print "Sorry, but there is no upgrade available from version $ver to $version\n";
                    exit;
                }
            } else {
                print "You are running a very old version of LogZilla (php-syslog-ng).\n";
                print "Install will try to upgrade, but be sure you have backed up your database.\n";
                my $ok  = &p("Ok to continue?", "y");
                if ($ok =~ /[Yy]/) {
                    do_upgrade('2');
                }
            }
        } else {
            print "Please select a database name other than $dbname\n";
            my $dbname = &p("Database to install to", "syslog");
            my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
            my $sth = $dbh->prepare("create database $dbname");
            $sth->execute;
            if ($dbh->err) {
                print("\n\033[1m\t$dbname Already Exists!\n\033[0m");
                print "Installation aborted\n";
                exit;
            } else {
                do_install();
            }
        }
    } else {
        do_install();
    }
    $dbh->disconnect();
}
make_dbuser();
update_settings();
add_logrotate();
add_syslog_conf();
setup_cron();
setup_sudo();
setup_apparmor();
fbutton();
hup_syslog();

sub do_install {
    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
    if (!$dbh) {
        print "Can't connect to $dbname database: ", $DBI::errstr, "\n";
        exit;
    }

# Create main table
    my $sth = $dbh->prepare("
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
        KEY mne (mne),
        KEY eid (eid),
        KEY program (program),
        KEY suppress (suppress),
        KEY lo (lo),
        KEY fo (fo)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8 
        ") or die "Could not create $dbtable table: $DBI::errstr";
    $sth->execute;

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
    create_views();
}

sub update_paths {
    my $search = "/path_to_logzilla";
    print "Updating file paths\n";
    foreach my $file (qx(grep -Rl $search ../* | egrep -v "install.pl|\\.svn|\\.sql|license.txt|CHANGELOG|html/includes/index.php|\\.logtest|sphinx/src|sphinx/bin|html/ioncube")) {
        chomp $file;
        print "Modifying $file\n";
        system "perl -i -pe 's|$search|$lzbase|g' $file" and warn "Could not modify $file $!\n";
    }
    my $search = "/path_to_logs";
    print "Updating log paths\n";
    foreach my $file (qx(grep -Rl $search ../* | egrep -v "install.pl|.svn|.sql|CHANGELOG")) {
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
    my ($sec, $min, $hour, $curmday, $curmon, $curyear, $wday, $yday, $isdst) = localtime time;
    $curyear = $curyear + 1900;
    $curmon = $curmon + 1;
    my ($year,$mon,$mday) = Date::Calc::Add_Delta_Days($curyear,$curmon,$curmday,1);
    my $pAdd = "p".$year.sprintf("%02d",$mon).sprintf("%02d",$mday);
    my $dateTomorrow = $year."-".sprintf("%02d",$mon)."-".sprintf("%02d",$mday);

    my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
# Create initial Partition of the $dbtable table
    my $sth = $dbh->prepare("
        alter table $dbtable PARTITION BY RANGE( TO_DAYS( lo ) ) (
        PARTITION $pAdd VALUES LESS THAN (to_days('$dateTomorrow'))
        );
        ") or die "Could not create partition for the $dbtable table: $DBI::errstr";
    $sth->execute; 

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
    CREATE PROCEDURE logs_add_part_proc()
    SQL SECURITY DEFINER
    COMMENT 'Creates partitions for tomorrow' 
    BEGIN    
    DECLARE new_partition CHAR(32) DEFAULT
    CONCAT ('p', DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 DAY), '%Y%m%d'));
    DECLARE max_day INTEGER DEFAULT TO_DAYS(NOW()) +1;
    SET \@s =
    CONCAT('ALTER TABLE `logs` ADD PARTITION (PARTITION ', new_partition,
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

# Grant access to $dbadmin
    my $grant = qq{GRANT ALL PRIVILEGES ON $dbname.* TO '$dbadmin'\@'$localip' IDENTIFIED BY '$dbadminpw';};
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
    my $grant = qq{GRANT ALL PRIVILEGES ON $dbname.* TO '$dbadmin'\@'localhost' IDENTIFIED BY '$dbadminpw';};
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

    $dbh->disconnect();
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
    if ($email ne "info\@logzilla.pro") {
        my $sth = $dbh->prepare("
            update triggers set mailto='$email', mailfrom='$email';
            ") or die "Could not update triggers table: $DBI::errstr";
        $sth->execute;
    }
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
        print "Adding LogZilla logrotate.d file to /etc/logrotate.d\n";
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
        }
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
    my $ver = shift;
    if ($ver eq "3.1") {
        my $dbh = db_connect($dbname, $lzbase, $dbroot, $dbrootpass);
        my $sth = $dbh->prepare("
            alter table logs add `eid` int(10) unsigned NOT NULL DEFAULT '0';
            ") or die "Could not update $dbname: $DBI::errstr";
        $sth->execute;
        my $sth = $dbh->prepare("
            alter table logs add index eid(eid);
            ") or die "Could not update $dbname: $DBI::errstr";
        $sth->execute;
        my $sth = $dbh->prepare("
            alter table hosts add `lastseen` datetime NOT NULL default '2011-03-01 00:00:00';
            ") or die "Could not update $dbname: $DBI::errstr";
        $sth->execute;
        my $sth = $dbh->prepare("
            alter table hosts add `seen` smallint(5) unsigned NOT NULL DEFAULT '1';
            ") or die "Could not update $dbname: $DBI::errstr";
        $sth->execute;
        my $sth = $dbh->prepare("
            alter table mne add `lastseen` datetime NOT NULL default '2011-03-01 00:00:00';
            ") or die "Could not update $dbname: $DBI::errstr";
        $sth->execute;
        my $sth = $dbh->prepare("
            alter table mne add `seen` smallint(5) unsigned NOT NULL DEFAULT '1';
            ") or die "Could not update $dbname: $DBI::errstr";
        $sth->execute;
        my $sth = $dbh->prepare("
            CREATE TABLE `snare_eid` (
            `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
            `eid` smallint(5) unsigned NOT NULL DEFAULT '0',
            `lastseen` datetime NOT NULL,
            `seen` smallint(5) unsigned NOT NULL DEFAULT '1',
            PRIMARY KEY (`id`),
            UNIQUE KEY `eid` (`eid`)
            ) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
            ") or die "Could not update $dbname: $DBI::errstr";
        $sth->execute;
        my $sth = $dbh->prepare("
            CREATE TABLE `triggers` (
            `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
            `description` varchar(255) NOT NULL,
            `pattern` varchar(255) NOT NULL,
            `mailto` varchar(255) NOT NULL DEFAULT 'root\@localhost',
            `mailfrom` varchar(255) NOT NULL DEFAULT 'root\@localhost',
            `subject` varchar(255) NOT NULL,
            `body` text CHARACTER SET utf8 NOT NULL,
            `disabled` enum('Yes','No') NOT NULL DEFAULT 'No',
            PRIMARY KEY (`id`)
            ) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
            ") or die "Could not update $dbname: $DBI::errstr";
        $sth->execute;
        my $sth = $dbh->prepare("
            RENAME TABLE settings TO settings_orig;
            ") or die "Could not update $dbname: $DBI::errstr";
        $sth->execute;
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/settings.sql`;
        print $res;
        my $sth = $dbh->prepare("
            REPLACE INTO settings SELECT * FROM settings_orig;
            ") or die "Could not update $dbname: $DBI::errstr";
        $sth->execute;
        my $sth = $dbh->prepare("
            DROP TABLE settings_orig;
            ") or die "Could not update $dbname: $DBI::errstr";
        $sth->execute;
    } else {
        print "Your version is not a candidate for upgrade.\n";
        exit;
    }
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

