#!/usr/bin/perl
# updateCache
use strict;
use Switch;
use Date::Calc;
$| = 1;
use DBI;

# Get LogZilla base directory
use Cwd;

if (!@ARGV) {
    print "If you have not been instructed to run this file with a command line argument, please do not run it\n";
    exit;
}

system("stty erase ^H");
sub p {
    my($prompt, $default) = @_;
    my $defaultValue = $default ? "[$default]" : "";
    print "$prompt $defaultValue: ";
    chomp(my $input = <STDIN>);
    return $input ? $input : $default;
}
my $dbroot = &p("Enter the MySQL root username", "root");
$dbroot = qq{$dbroot};
my $dbrootpass = &p("Enter the password for $dbroot", "mysql");
$dbrootpass = qq{$dbrootpass};
my $db = &p("Enter the database name", "syslog");
my $dbtable = &p("Enter the table name for $db", "logs");


my ($sec, $min, $hour, $curmday, $curmon, $curyear, $wday, $yday, $isdst) = localtime time;
$curyear = $curyear + 1900;
$curmon = $curmon + 1;
my ($year,$mon,$mday) = Date::Calc::Add_Delta_Days($curyear,$curmon,$curmday,1);
my $pAdd = "p".$year.sprintf("%02d",$mon).sprintf("%02d",$mday);
my $dateTomorrow = $year."-".sprintf("%02d",$mon)."-".sprintf("%02d",$mday);


foreach (@ARGV) {
    switch ($_) {
        case "214_217" {
            update_214_to_247();
            exit;
        }
        case "update_procs" {
            print "\nUpdating MySQL Procedures...\n";
            do_procs();
            exit;
        }
        case "update_events" {
            print "\nUpdating MySQL Events...\n";
            do_events();
            exit;
        }
        case "update_pe" {
            print "\nUpdating MySQL Events and Procedures...\n";
            do_procs();
            do_events();
            exit;
        }
    }
}
sub db_connect {

    my $lzbase = getcwd;
    $lzbase =~ s/\/scripts//g;
    my $file = "$lzbase/scripts/sql/lzmy.cnf";
    if (! -f $file) {
        print "ERROR: $file is missing, have you run install.pl yet?\n";
        exit;
    }
    my $dsn = "DBI:mysql:$db:;mysql_read_default_group=logzilla;"
    . "mysql_read_default_file=$lzbase/scripts/sql/lzmy.cnf";
    if (!$dsn) {
        print "Can't get dsn, is your sql/my.cnf to $db database: ", $DBI::errstr, "\n";
        exit;
    }
    my $dbh = DBI->connect($dsn, $dbroot, $dbrootpass);
    return $dbh
}

sub update_214_to_247 {
    my $ok  = &p("This script will perform a DB column and Event Procedure update to the syslog databasee.\nIt is only meant for users of LogZilla v3.x.214 through .247\nBEFORE you continue, please edit this file and set \$dbtable at the top!\nContinue? (yes/no)", "n");
    if ($ok =~ /[Yy]/) {
        my $dbh = db_connect();
        print "Performing updates...\n";

        my $sth = $dbh->prepare("
            DROP PROCEDURE IF EXISTS updateCache;
            ") or die "Could not create updateCache Procedure: $DBI::errstr";
        $sth->execute;

        my $event = qq{
        CREATE PROCEDURE updateCache()
        SQL SECURITY DEFINER
        COMMENT 'Verifies cache totals every night' 
        BEGIN    
        REPLACE INTO cache (name,value,updatetime) VALUES ('msg_sum', (SELECT SUM(counter) FROM `$dbtable`),NOW());
        REPLACE INTO cache (name,value,updatetime) VALUES (CONCAT('chart_mpd_',DATE_FORMAT(NOW() - INTERVAL 1 DAY, '%Y-%m-%d_%a')), (SELECT SUM(counter) FROM `$dbtable` WHERE lo BETWEEN DATE_SUB(CONCAT(CURDATE(), ' 00:00:00'), INTERVAL 1 DAY) AND DATE_SUB(CONCAT(CURDATE(), ' 23:59:59'), INTERVAL  1 DAY)),NOW());
        UPDATE `hosts` SET `seen` = ( SELECT SUM(`$dbtable`.`counter`) FROM `$dbtable` WHERE `$dbtable`.`host` = `hosts`.`host` );
        UPDATE `mne` SET `seen` = ( SELECT SUM(`$dbtable`.`counter`) FROM `$dbtable` WHERE `$dbtable`.`mne` = `mne`.`crc` );
        UPDATE `snare_eid` SET `seen` = ( SELECT SUM(`$dbtable`.`counter`) FROM `$dbtable` WHERE `$dbtable`.`eid` = `snare_eid`.`eid` );
        END 
        };
        my $sth = $dbh->prepare("
            $event
            ") or die "Could not create updateCache Procedure: $DBI::errstr";
        $sth->execute;

        my $event = qq{
        alter table hosts modify `seen` int  unsigned NOT NULL DEFAULT '1'; 
        };
        my $sth = $dbh->prepare("
            $event
            ") or die "Could not create updateCache Procedure: $DBI::errstr";
        $sth->execute;

        my $event = qq{
        alter table mne modify `seen` int  unsigned NOT NULL DEFAULT '1'; 
        };
        my $sth = $dbh->prepare("
            $event
            ") or die "Could not create updateCache Procedure: $DBI::errstr";
        $sth->execute;
        my $event = qq{
        alter table snare_eid modify `seen` int  unsigned NOT NULL DEFAULT '1'; 
        };
        my $sth = $dbh->prepare("
            $event
            ") or die "Could not create updateCache Procedure: $DBI::errstr";
        $sth->execute;
        print "Updates completed...\n";
    }
}

sub do_events {
    my $dbh = db_connect();

# Create Partition events
    my $sth = $dbh->prepare("
        DROP EVENT IF EXISTS logs_add_partition;
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        DROP EVENT IF EXISTS logs_add_archive;
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        DROP EVENT IF EXISTS logs_del_partition;
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        DROP EVENT IF EXISTS cacheUpdate;
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        DROP EVENT IF EXISTS cacheHosts;
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        DROP EVENT IF EXISTS cacheMne;
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        DROP EVENT IF EXISTS cacheEid;
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;

    my $sth = $dbh->prepare("
        CREATE EVENT logs_add_partition ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL logs_add_part_proc();
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        CREATE EVENT logs_add_archive ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:10:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL logs_add_archive_proc();
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;

    my $sth = $dbh->prepare("
        CREATE EVENT logs_del_partition ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:15:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL logs_delete_part_proc();
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        CREATE EVENT cacheUpdate ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 01:00:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL updateCache();
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        CREATE EVENT cacheHosts ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 01:30:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL updateHosts();
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        CREATE EVENT cacheMne ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 02:00:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL updateMne();
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        CREATE EVENT cacheEid ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 02:30:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL updateEid();
        ") or die "Could not create updateCache Procedure: $DBI::errstr";
    $sth->execute;
    my $sth = $dbh->prepare("
        SET GLOBAL event_scheduler = 1;
        ") or die "Could not enable the Global event scheduler: $DBI::errstr";
    $sth->execute;
    print "MySQL Events have been updated\n";
}

sub do_procs {
    my $dbh = db_connect();

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

    print "MySQL Procedures have been updated\n";
}
