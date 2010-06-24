#!/usr/bin/perl

#
# install.pl
# Last updated on 2010-06-15
#
# Developed by Clayton Dukes <cdukes@cdukes.com>
# Copyright (c) 2010 LogZilla, LLC
# All rights reserved.
#
# Changelog:
# 2009-11-15 - created
# 2010-10-10 - Modified to work with LogZilla v3.0
# 2010-06-07 - Modified partitioning and events
#

use strict;

$| = 1;


use Cwd;
use DBI;
use Date::Calc;
use Term::ReadLine;
use File::Copy;

# not needed here, but might as well warn the user to install it now since db_insert will need them
use Text::LevenshteinXS qw(distance); 
use String::CRC32;

system("stty erase ^H");
sub p {
    my($prompt, $default) = @_;
    my $defaultValue = $default ? "[$default]" : "";
    print "$prompt $defaultValue: ";
    chomp(my $input = <STDIN>);
    return $input ? $input : $default;
}

my $version = "3.0";
my $subversion = ".83";

# Grab the base path
my $lzbase = getcwd;
$lzbase =~ s/\/scripts//g;
my $paths_updated = 0;

print("\n\033[1m\n\n========================================\033[0m\n");
print("\n\033[1m\tLogZilla Installation\n\033[0m");
print("\n\033[1m========================================\n\n\033[0m\n\n");

my $dbroot = &p("Enter the MySQL root username", "root");
$dbroot = qq{$dbroot};
print "\nNote: Mysql passwords with a ' in them may not work\n";
my $dbrootpass = &p("Enter the password for $dbroot", "mysql");
$dbrootpass = qq{$dbrootpass};
my $dbname = &p("Database to install to", "syslog");
my $dbtable = &p("Database table to install to", "logs");
my $dbhost  = &p("Enter the name of the MySQL server", "127.0.0.1");
my $dbport  = &p("Enter the port of the MySQL server", "3306");
my $dbadmin  = &p("Enter the name to create as the owner of the $dbtable database", "syslogadmin");
$dbadmin = qq{$dbadmin};
print "Note that a password containing ' may not work.\n";
my $dbadminpw = &p("Enter the password for the $dbadmin user", "$dbadmin");
$dbadminpw = qq{$dbadminpw};
my $siteadmin  = &p("Enter the name to create as the WEBSITE owner", "admin");
$siteadmin = qq{$siteadmin};
my $siteadminpw = &p("Enter the password for $siteadmin", "$siteadmin");
$siteadminpw = qq{$siteadminpw};
my $email  = &p("Enter your email address", 'cdukes@cdukes.com');
my $sitename  = &p("Enter a name for your website", 'The home of LogZilla');
my $url  = &p("Enter the base url for your site (include trailing slash)", '/logs/');
my $logpath  = &p("Where should log files be stored?", '/var/log/logzilla');
my $retention  = &p("How long should I keep old logs? (in days)", '30');


if (! -d "$logpath") {
    mkdir "$logpath";
}

print("\n\033[1m\n\n========================================\033[0m\n");
print("\n\033[1m\tPath Updates\n\033[0m");
print("\n\033[1m========================================\n\n\033[0m\n\n");
print "Getting ready to replace paths in all files with \"$lzbase\"\n";
my $ok  = &p("Ok to continue?", "y");
if ($ok =~ /[Yy]/) {
    my $search = "/path_to_logzilla";
    print "Updating file paths\n";
    foreach my $file (qx(grep -Rl $search ../* | egrep -v "install.pl|.svn|.sql|CHANGELOG")) {
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
    $paths_updated++;
} else {
    print "Skipping path updates\n";
}

print("\n\033[1m\n\n========================================\033[0m\n");
print("\n\033[1m\tDatabase Installation\n\033[0m");
print("\n\033[1m========================================\n\n\033[0m\n\n");
print "All data will be installed into the $dbname database\n";
my $ok  = &p("Ok to continue?", "y");
if ($ok =~ /[Yy]/) {
# First, create the mysql database and create the $dbname
    my $dbh;
    $dbh = DBI->connect( "DBI:mysql:mysql:$dbhost:$dbport", $dbroot, $dbrootpass );
    if (!$dbh) {
        print "Can't connect to the mysql database: ", $DBI::errstr, "\n";
        exit;
    }

    # Check version of MySQL
    my $sth = $dbh->prepare("SELECT version()") or die "Could not create the $dbname database: $DBI::errstr";
    $sth->execute;
    while (my @data = $sth->fetchrow_array()) {
        my $ver = $data[0];
        if ($ver !~ /5\.1/) {
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
        print("\n\033[1m\tERROR!\n\033[0m");
        print "Database \"$dbname\" already exists!\nPlease delete it and re-run $0\n";
        exit;
    }
    $dbh->disconnect();


# Now that we have the DB created, re-connect and create the tables
    $dbh = DBI->connect( "DBI:mysql:$dbname:$dbhost:$dbport", $dbroot, $dbrootpass );
    if (!$dbh) {
        print "Can't connect to $dbname database: ", $DBI::errstr, "\n";
        exit;
    }

# Create main table
    my $sth = $dbh->prepare("
        CREATE TABLE $dbtable (
        id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
        host varchar(128) NOT NULL,
        facility enum('0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','100','101','102','103') NOT NULL,
        severity enum('0','1','2','3','4','5','6','7') NOT NULL,
        program int(10) unsigned NOT NULL,
        msg varchar(2048) NOT NULL,
        mne int(10) unsigned NOT NULL,
        suppress datetime NOT NULL DEFAULT '2010-03-01 00:00:00',
        counter int(11) NOT NULL DEFAULT '1',
        fo datetime NOT NULL,
        lo datetime NOT NULL,
        notes varchar(255) NOT NULL,
        PRIMARY KEY (id,lo),
        KEY facility (facility),
        KEY severity (severity),
        KEY mne (mne),
        KEY program (program),
        KEY suppress (suppress),
        KEY lo (lo),
        KEY fo (fo)
        ) ENGINE=MyISAM
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

# Create archive table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/logs_archive.sql`;
    print $res;

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



# Insert user data
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/users.sql`;
    print $res;
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


# Get some date values in order to create the MySQL Partition
    my ($sec, $min, $hour, $curmday, $curmon, $curyear, $wday, $yday, $isdst) = localtime time;
    $curyear = $curyear + 1900;
    $curmon = $curmon + 1;
    my ($year,$mon,$mday) = Date::Calc::Add_Delta_Days($curyear,$curmon,$curmday,1);
    my $pAdd = "p".$year.sprintf("%02d",$mon).sprintf("%02d",$mday);
    my $dateTomorrow = $year."-".sprintf("%02d",$mon)."-".sprintf("%02d",$mday);

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

    my $event = qq{
    CREATE EVENT logs_add_archive ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:10:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL logs_add_archive_proc();
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create partition events: $DBI::errstr";
    $sth->execute;

    my $event = qq{
    CREATE EVENT logs_del_partition ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:15:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL logs_delete_part_proc();
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create partition events: $DBI::errstr";
    $sth->execute;

    my $event = qq{
    CREATE PROCEDURE logs_add_archive_proc()
    SQL SECURITY DEFINER
    COMMENT 'Creates archive for messages older than $retention days' 
    BEGIN    
    INSERT INTO `logs_archive` SELECT * FROM `$dbtable` 
    WHERE `$dbtable`.`lo` < DATE_SUB(CURDATE(), INTERVAL $retention DAY);
    END 
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create partition events: $DBI::errstr";
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
    COMMENT 'Deletes partitions older than $retention days' 
    BEGIN    
    SELECT CONCAT( 'ALTER TABLE `$dbtable` DROP PARTITION ',
    GROUP_CONCAT(`partition_name`))
    INTO \@s
    FROM `information_schema`.`partitions`
    WHERE `table_schema` = '$dbname'
    AND `table_name` = '$dbtable'
    AND `partition_description` <
    TO_DAYS(DATE_SUB(CURDATE(), INTERVAL $retention DAY))
    GROUP BY TABLE_NAME;

    PREPARE stmt FROM \@s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    END 
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create partition events: $DBI::errstr";
    $sth->execute;

# Turn the event scheduler on
    my $sth = $dbh->prepare("
        SET GLOBAL event_scheduler = 1;
        ") or die "Could not enable the Global event scheduler: $DBI::errstr";
    $sth->execute;


# Grant access to $dbadmin
    my $grant = qq{GRANT ALL PRIVILEGES ON $dbname.* TO '$dbadmin'\@'$dbhost' IDENTIFIED BY '$dbadminpw';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not create $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;
    if ($dbhost == "127.0.0.1") {
        my $grant = qq{GRANT ALL PRIVILEGES ON $dbname.* TO '$dbadmin'\@'localhost' IDENTIFIED BY '$dbadminpw';};
        my $sth = $dbh->prepare("
            $grant
            ") or die "Could not create $dbadmin user on $dbname: $DBI::errstr";
        $sth->execute;
    }


    $dbh->disconnect();
} else {
    print "Skipped database creation\n";
}
print("\n\033[1m\n\n========================================\033[0m\n");
print("\n\033[1m\tConfig.php generation\n\033[0m");
print("\n\033[1m========================================\n\n\033[0m\n\n");
print "Generating $lzbase/html/config/config.php\n";
my $ok  = &p("Ok to continue?", "y");
if ($ok =~ /[Yy]/) {
    my $config =qq{<?php
    DEFINE('DBADMIN', '$dbadmin');
    DEFINE('DBADMINPW', '$dbadminpw');
    DEFINE('DBNAME', '$dbname');
    DEFINE('DBHOST', '$dbhost');
    DEFINE('DBPORT', '$dbport');
    DEFINE('LOG_QUERIES', 'FALSE');
    DEFINE('LOG_PATH', '$logpath');
    DEFINE('MYSQL_QUERY_LOG', '$logpath/mysql_query.log');
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
} else {
    print "Skipped config generation\n";
}

#Create log files for later use by the server
my $logfile = "$logpath/logzilla.log";
open(LOG,">>$logfile");
if (! -f $logfile) {
    print STDOUT "Unable to open log file \"$logfile\" for writing...$!\n";
    exit;
}
close(LOG);
my $logfile = "$logpath/mysql_query.log";
open(LOG,">>$logfile");
if (! -f $logfile) {
    print STDOUT "Unable to open log file \"$logfile\" for writing...$!\n";
    exit;
}
close(LOG);

if ($paths_updated >0) {
    print("\n\033[1m\n\n========================================\033[0m\n");
    print("\n\033[1m\tSystem files\n\033[0m");
    print("\n\033[1m========================================\n\n\033[0m\n\n");
    #if ( -d "/etc/init.d") {
    #print "Adding LogZilla init file to /etc/init.d\n";
    #my $ok  = &p("Ok to continue?", "y");
    #my $test = `uname -a | awk '{print \$4}'`;
    #if ($test =~ /Ubuntu/) {
    #if ($ok =~ /[Yy]/) {
    #system("cp contrib/system_configs/logzilla.initd /etc/init.d/logzilla");
    #chmod 0755, '/etc/init.d/logzilla';
    #} else {
    #print "Skipped init.d file, you will need to manually copy:\n";
    #print "cp contrib/system_configs/logzilla.initd /etc/init.d/logzilla\n";
    #}
    #} else {
    #print("\n\033[1m\tWARNING!\n\033[0m");
    #print "Non-Ubuntu system found, you'll need to manually copy the\n";
    #print "appropriate init.d file from the contrib/system_confgs directory.\n";
    #}
    #}
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
        print "cp contrib/system_configs/logzilla.logrotate /etc/logrotate.d/logzilla\n";
    }
    my $file  = &p("Where is your syslog-ng.conf file located?", "/etc/syslog-ng/syslog-ng.conf");
    if (-f "$file") {
        print "Adding syslog-ng configuration to $file\n";
        my $ok  = &p("Ok to continue?", "y");
        if ($ok =~ /[Yy]/) {
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
            print "Skipped syslog-ng merge\n";
            print "You will need to manually merge contrib/system_configs/syslog-ng.conf with yours.\n";
        }
    } else {
        print "Unable to locate your syslog-ng.conf file\n";
        print "You will need to manually merge contrib/system_configs/syslog-ng.conf with yours.\n";
    }
} else {
    print "Since you chose not to update paths, you will need to manually merge contrib/system_configs/syslog-ng.conf with your syslog-ng.conf.\n";
}
print("\n\033[1m\tLogZilla installation complete...\n\033[0m");
print("\033[1mNote: you may need to enable the MySQL Event Scheduler in your /etc/my.cnf file.\n\033[0m");
print("\033[1mPlease visit http://forum.logzilla.info/index.php/topic,71.0.html for more information.\n\033[0m");
print("\033[1m\nAlso, please visit http://nms.gdd.net/index.php/Install_Guide_for_LogZilla_v3.0#UDP_Buffers to learn how to increase your UDP buffer size (otherwise you may drop messages).\n\033[0m");
#print("\n\033[1m\tTo Start LogZilla (you'll need to restart syslog-ng also), type:\n\033[0m");
#print("\033[1m\t/etc/init.d/syslog-ng restart && /etc/init.d/logzilla start\n\033[0m");
print("\033[1m\nPlease run /etc/init.d/syslog-ng restart\n\033[0m");
