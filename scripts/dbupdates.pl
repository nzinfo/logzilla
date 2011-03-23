#!/usr/bin/perl
# updateCache
use strict;
$| = 1;
use DBI;

my $dbtable = "logs";
my $config = "../html/config/config.php";

system("stty erase ^H");
sub p {
    my($prompt, $default) = @_;
    my $defaultValue = $default ? "[$default]" : "";
    print "$prompt $defaultValue: ";
    chomp(my $input = <STDIN>);
    return $input ? $input : $default;
}
my $ok  = &p("This script will perform a DB column and Event Procedure update to the syslog databasee.\nIt is only meant for users of LogZilla v3.x.214 through .247\nBEFORE you continue, please edit this file and set \$dbtable and \$config at the top!\nContinue? (yes/no)", "n");
if ($ok =~ /[Yy]/) {
    print "Performing updates...\n";

    if (! -f $config) {
        print STDOUT "Can't open config file \"$config\" : $!\n"; 
        exit;
    } 
    open( CONFIG, $config );
    my @config = <CONFIG>; 
    close( CONFIG );

    my($dbuser,$dbpass,$db,$dbhost);
    foreach my $var (@config) {
        next unless $var =~ /DEFINE/; # read only def's
        $db = $1 if ($var =~ /'DBNAME', '(\w+)'/);
    }
    my $dsn = "DBI:mysql:$db:;mysql_read_default_group=logzilla;"
    . "mysql_read_default_file=sql/lzmy.cnf";
    my $dbh = DBI->connect($dsn, $dbuser, $dbpass);

    my $event = qq{
    DROP PROCEDURE IF EXISTS updateCache;
    };
    my $sth = $dbh->prepare("
        $event
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
