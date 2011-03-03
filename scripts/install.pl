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
use String::CRC32;

system("stty erase ^H");
sub p {
    my($prompt, $default) = @_;
    my $defaultValue = $default ? "[$default]" : "";
    print "$prompt $defaultValue: ";
    chomp(my $input = <STDIN>);
    return $input ? $input : $default;
}

my $version = "3.1";
my $subversion = ".200";

# Grab the base path
my $lzbase = getcwd;
$lzbase =~ s/\/scripts//g;
my $paths_updated = 0;
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
my $dbport  = &p("Enter the port of the MySQL server", "3306");
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

print("\n\033[1m\n\n========================================\033[0m\n");
print("\n\033[1m\tPath Updates\n\033[0m");
print("\n\033[1m========================================\n\n\033[0m\n\n");
print "Getting ready to replace paths in all files with \"$lzbase\"\n";
#my $ok  = &p("Ok to continue?", "y");
#if ($ok =~ /[Yy]/) {
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
$paths_updated++;
#} else {
#print "Skipping path updates\n";
#}

print("\n\033[1m\n\n========================================\033[0m\n");
print("\n\033[1m\tDatabase Installation\n\033[0m");
print("\n\033[1m========================================\n\n\033[0m\n\n");
print "All data will be installed into the $dbname database\n";
my $ok  = &p("Ok to continue?", "y");
if ($ok =~ /[Yy]/) {
# First, connect to the mysql database and create the $dbname
    my $mydbh = DBI->connect( "DBI:mysql:mysql:$dbhost:$dbport", $dbroot, $dbrootpass );
    if (!$mydbh) {
        print "Can't connect to the mysql database: ", $DBI::errstr, "\n";
        exit;
    }

    # Check version of MySQL
    my $sth = $mydbh->prepare("SELECT version()") or die "Could not create the $dbname database: $DBI::errstr";
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

    my $sth = $mydbh->prepare("create database $dbname");
    $sth->execute;
    if ($mydbh->err) {
        print("\n\033[1m\tERROR!\n\033[0m");
        print "Database \"$dbname\" already exists!\nPlease delete it and re-run $0\n";
        exit;
    }
    $mydbh->disconnect();


# Now that we have the DB created, re-connect and create the tables
    my $dsn = "DBI:mysql:$dbname:;mysql_read_default_group=logzilla;"
    . "mysql_read_default_file=$lzbase/scripts/sql/lzmy.cnf";
    #$dbh = DBI->connect( "DBI:mysql:$dbname:$dbhost:$dbport", $dbroot, $dbrootpass );
    my $dbh = DBI->connect($dsn, $dbroot, $dbrootpass);
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
#    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/logs_archive.sql`;
#    print $res;

# Create triggers table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/triggers.sql`;
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
    my $sth = $dbh->prepare("
        update settings set value='$retention' where name='RETENTION';
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

# Insert archives table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/archives.sql`;
    print $res;

# Create Views
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
        (`suppress`.`expire` > now()))) or $dbtable.`msg` in
        (select `suppress`.`name` from `suppress` where
        ((`suppress`.`col` = 'msg') and (`suppress`.`expire` >
        now()))) or $dbtable.`counter` in (select
        `suppress`.`name` from `suppress` where
        ((`suppress`.`col` = 'counter') and
        (`suppress`.`expire` > now()))) or $dbtable.`notes` in
        (select `suppress`.`name` from `suppress` where
        ((`suppress`.`col` = 'notes') and (`suppress`.`expire`
        > now()))))
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
        (not($dbtable.`msg` in (select `suppress`.`name` from
        `suppress` where ((`suppress`.`col` = 'msg') and
        (`suppress`.`expire` > now()))))) and
        (not($dbtable.`counter` in (select `suppress`.`name`
        from `suppress` where ((`suppress`.`col` = 'counter')
            and (`suppress`.`expire` > now()))))) and
        (not($dbtable.`notes` in (select `suppress`.`name` from
        `suppress` where ((`suppress`.`col` = 'notes') and
        (`suppress`.`expire` > now()))))))
        ") or die "Could not create $dbtable table: $DBI::errstr";
    $sth->execute;



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
    #my $event = qq{
    #CREATE EVENT logs_add_partition ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL logs_add_part_proc();
    #};
    #my $sth = $dbh->prepare("
    #$event
    #") or die "Could not create partition events: $DBI::errstr";
    #$sth->execute;

#  TH: use the new archive feature!
#    my $event = qq{
#    CREATE EVENT logs_add_archive ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:10:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL logs_add_archive_proc();
#    };
#    my $sth = $dbh->prepare("
#        $event
#        ") or die "Could not create archive events: $DBI::errstr";
#    $sth->execute;

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

    #my $event = qq{
    #CREATE PROCEDURE logs_add_part_proc()
    #SQL SECURITY DEFINER
    #COMMENT 'Creates partitions for tomorrow' 
    #BEGIN    
    #DECLARE new_partition CHAR(32) DEFAULT
    #CONCAT ('p', DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 DAY), '%Y%m%d'));
    #DECLARE max_day INTEGER DEFAULT TO_DAYS(NOW()) +1;
    #SET \@s =
    #CONCAT('ALTER TABLE `logs` ADD PARTITION (PARTITION ', new_partition,
    #' VALUES LESS THAN (', max_day, '))');
    #PREPARE stmt FROM \@s;
    #EXECUTE stmt;
    #DEALLOCATE PREPARE stmt;
    #END 
    #};
    #my $sth = $dbh->prepare("
    #    $event
    #    ") or die "Could not create partition events: $DBI::errstr";
    #$sth->execute;

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

#  TH: use the new archive feature!
#    my $event = qq{
#    CREATE PROCEDURE logs_add_archive_proc()
#    SQL SECURITY DEFINER
#    COMMENT 'Creates archive for old messages' 
#    BEGIN    
#    INSERT INTO `logs_archive` SELECT * FROM `$dbtable` 
#    WHERE `$dbtable`.`lo` < DATE_SUB(CURDATE(), INTERVAL (SELECT value from settings WHERE name='RETENTION') DAY);
#    END 
#    };
#    my $sth = $dbh->prepare("
#        $event
#        ") or die "Could not create partition events: $DBI::errstr";
#    $sth->execute;

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

    # TH: adding export procedure (a fragment)
    my $event = qq{
    CREATE PROCEDURE export()
    SQL SECURITY DEFINER
    COMMENT 'Export yesterdays data to a file'
    BEGIN
    DECLARE export CHAR(32) DEFAULT CONCAT ('dumpfile_', DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 day), '%Y%m%d'),'.txt');
    DECLARE export_path CHAR(127);
    SELECT value into export_path from settings WHERE name="ARCHIVE_PATH";
    SET \@s =
    CONCAT('select * into outfile "',export_path, '/' , export,'" from logs  where TO_DAYS( lo )=',TO_DAYS(NOW())-1);
    PREPARE stmt FROM \@s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    INSERT INTO archives (archive) VALUES (export);
    END 
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not create export Procedure: $DBI::errstr";
    $sth->execute;


# Turn the event scheduler on

    my $sth = $dbh->prepare("
        SET GLOBAL event_scheduler = 1;
        ") or die "Could not enable the Global event scheduler: $DBI::errstr";
    $sth->execute;


    # DB User
    # Remove old user in case this is an upgrade
    # Have to do this for the new LOAD DATA INFILE
    my $grant = qq{GRANT USAGE ON *.* TO '$dbadmin'\@'$dbhost';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not temporarily drop the $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;
    my $grant = qq{DROP USER '$dbadmin'\@'$dbhost';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not temporarily drop the $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

# Grant access to $dbadmin
    my $grant = qq{GRANT ALL PRIVILEGES ON $dbname.* TO '$dbadmin'\@'$dbhost' IDENTIFIED BY '$dbadminpw';};
    my $sth = $dbh->prepare("
        $grant
        ") or die "Could not create $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

    # CDUKES: [[ticket:16]]
    my $grant = qq{GRANT FILE ON *.* TO '$dbadmin'\@'$dbhost' IDENTIFIED BY '$dbadminpw';};
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
} else {
    print "Skipped database creation\n";
}
print "Generating $lzbase/html/config/config.php\n";
#my $ok  = &p("Ok to continue?", "y");
#if ($ok =~ /[Yy]/) {
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
#} else {
#print "Skipped config generation\n";
#}

#Modifies the exports dir to he correct user
system "chown mysql.mysql ../exports" and warn "Could not modify archive directory";   


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

if ($paths_updated >0) {
    print("\n\033[1m\n\n========================================\033[0m\n");
    print("\n\033[1m\tSystem files\n\033[0m");
    print("\n\033[1m========================================\n\n\033[0m\n\n");
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
0 1 * * * root sh $lzbase/scripts/export.sh

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
        sleep 1;
    }

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
} else {
    print "Since you chose not to update paths, you will need to manually merge contrib/system_configs/syslog-ng.conf with your syslog-ng.conf.\n";
}




print("\n\033[1m\tLogZilla installation complete!\n\033[0m");

my $cTerminalLineSize = 79;
# Wordwrap system: deal with the next character
sub wrap_one_char {
    my $output = shift;
    my $pos = shift;
    my $word = shift;
    my $char = shift;
    my $reserved = shift;
    my $length;

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

# Print an error message and exit
sub error {
    my $msg = shift;

    print STDERR $msg . "Installation aborted.\n";
    exit 1;
}

# Display the end-user license agreement
sub show_EULA {
    my $pager = $ENV{PAGER} || 'less' || 'more';
    system($pager, './EULA.txt') == 0 or die "$pager call failed: $?";
    print "\n\n";
}
