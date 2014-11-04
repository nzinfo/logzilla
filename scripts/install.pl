#!/usr/bin/perl

#
# install.pl
#
# Developed by Clayton Dukes <cdukes@logzilla.net>
# Copyright (c) 2010 LogZilla, LLC
# All rights reserved.
#

use strict;

$| = 1;

################################################
# Help user if Perl mods are missing
################################################
my @mods = (qw(DBI Date::Calc Term::ReadLine File::Copy Digest::MD5 LWP::Simple File::Spec String::CRC32 MIME::Lite IO::Socket::INET Getopt::Long CHI Net::SNMP Test::mysqld PerlIO::Util Find::Lib MooseX::Params::Validate Test::Deep Test::MockTime Date::Simple ));

foreach my $mod (@mods) {
    ( my $fn = "$mod.pm" ) =~ s|::|/|g;    # Foo::Bar::Baz => Foo/Bar/Baz.pm
    if ( eval { require $fn; 1; } ) {
        ##print "Module $mod loaded ok\n";
    } else {
        print "You are missing a required Perl Module: $mod\nI will attempt to install it for you.\n";
        system("(echo o conf prerequisites_policy follow;echo o conf commit)|cpan");
        #my $ok = &getYN( "Shall I attempt to install it for you?", "y" );
        #if ( $ok =~ /[Yy]/ ) {
        require CPAN;
        CPAN::install($mod);
        #} else {
        #print "LogZilla requires $mod\n";
        #exit;
        #}
        print "Module installation complete. Please re-run install\n";
        exit;
    }
}


use Cwd;
use File::Basename;
use POSIX;
use Socket;
require 'sys/ioctl.ph';
require DBI;
require CHI;
require Date::Calc;
require Term::ReadLine;
require File::Copy;
require Digest::MD5->import("md5_hex");
require LWP::Simple->import('getstore');
require LWP::Simple->import('is_success');
require File::Spec;
require String::CRC32;
require MIME::Lite;
require IO::Socket::INET;
require Getopt::Long;
require Net::SNMP;
require Date::Simple;



sub prompt {
    my ( $prompt, $default ) = @_;
    my $defaultValue = $default ? "[$default]" : "";
    print "$prompt $defaultValue: ";
    chomp( my $input = <STDIN> );
    return $input ? $input : $default;
}

my $version    = "4.5";
my $subversion = ".657";

# Grab the base path
my $lzbase = getcwd;
$lzbase =~ s/\/scripts//g;
my $now = localtime;

my ( $sec, $min, $hour, $curmday, $curmon, $curyear, $wday, $yday, $isdst ) = localtime time;
$curyear = $curyear + 1900;
$curmon  = $curmon + 1;
my ( $year, $mon, $mday ) = Date::Calc::Add_Delta_Days( $curyear, $curmon, $curmday, 1 );
my $pAdd = "p" . $year . sprintf( "%02d", $mon ) . sprintf( "%02d", $mday );
my $dateTomorrow = $year . "-" . sprintf( "%02d", $mon ) . "-" . sprintf( "%02d", $mday );
my ( $dbroot, $dbrootpass, $dbname, $dbtable, $dbhost, $dbport, $dbadmin, $dbadminpw, $siteadmin, $siteadminpw, $email, $sitename, $url, $logpath, $retention, $snare, $j4, $arch, $skipcron, $skipdb, $skipsysng, $skiplogrot, $skipsudo, $skipfb, $skiplic, $sphinx_compile, $sphinx_index, $skip_ioncube,$skipapparmor, $syslogng_conf, $webuser, $syslogng_source, $upgrade, $test, $autoyes, $spx_cores );
my ( $installdb, $logrotate, $docron, $do_hup_syslog, $do_hup_cron, $set_sudo, $set_apparmor, $apparmor_restart, $do_fback, $do_ioncube, $restart_php, $do_sphinx_compile );


sub getYN {
    unless ( $autoyes =~ /[Yy]/ ) {
        my ( $prompt, $default ) = @_;
        my $defaultValue = $default ? "[$default]" : "";
        print "$prompt $defaultValue: ";
        chomp( my $input = <STDIN> );
        return $input ? $input : $default;
    } else {
        return "Y";
    }
}

my $rcfile = ".lzrc";
if ( -e $rcfile ) {
    open CONFIG, "$rcfile";
    my $config = join '', <CONFIG>;
    close CONFIG;
    eval $config;
    die "Couldn't interpret the configuration file ($rcfile) that was given.\nError details follow: $@\n" if $@;
}
# The command line args below are really just for me so I don't have to keep going through extra steps to test 1 thing.
# But you can use them if you want :-)
foreach my $arg (@ARGV) {
    if($arg eq "update_paths") {
        update_paths();
        exit;
    }
    elsif($arg eq "genconfig") {
        genconfig();
        exit;
    }
    elsif($arg eq "add_logrotate") {
        add_logrotate();
        exit;
    }
    elsif($arg eq "add_syslog_conf") {
        add_syslog_conf();
        exit;
    }
    elsif($arg eq "setup_syslog") {
        add_syslog_conf();
        exit;
    }
    elsif($arg eq "install_syslog") {
        add_syslog_conf();
        exit;
    }
    elsif($arg eq "setup_cron") {
        setup_cron();
        exit;
    }
    elsif($arg eq "setup_sudo") {
        setup_sudo();
        exit;
    }
    elsif($arg eq "setup_apparmor") {
        setup_apparmor();
        exit;
    }
    elsif($arg eq "install_sphinx") {
        install_sphinx();
        exit;
    }
    elsif($arg eq "install_license") {
        install_license();
        exit;
    }
    elsif($arg eq "install_ioncube") {
        add_ioncube();
        exit;
    }
    elsif($arg eq "test") {
        run_tests();
        exit;
    }
    elsif($arg eq "insert_test") {
        insert_test();
        exit;
    }
}

print("\n\033[1m\n\n========================================\033[0m\n");
print("\n\033[1m\tLogZilla End User License\n\033[0m");
print("\n\033[1m========================================\n\n\033[0m\n\n");

# Display the end-user license agreement
if ( $skiplic =~ /[Yy]/ ) {
    print "You've agreed to the license using the .lzrc method, skipping...\n";
} else {
    #my $pager = $ENV{PAGER} || 'less' || 'more';
    #system( $pager, "$lzbase/scripts/EULA.txt" ) == 0 or die "$pager call failed: $?";
    &EULA;
}

print("\n\033[1m\n\n========================================\033[0m\n");
print("\n\033[1m\tInstallation\n\033[0m");
print("\n\033[1m========================================\n\n\033[0m\n\n");

unless ( -e $rcfile ) {
    $dbroot     = &prompt( "Enter the MySQL root username",      "root" );
    $dbrootpass = &prompt( "Enter the password for $dbroot",     "mysql" );
    $dbname     = &prompt( "Database to install to",             "syslog" );
    $dbhost     = &prompt( "Enter the name of the MySQL server", "localhost" );
    $dbport     = &prompt( "Enter the port of the MySQL server", "3306" );
    $dbadmin = &prompt( "Enter the name to create as the owner of the $dbname database", "syslogadmin" );
    $dbadminpw = &prompt( "Enter the password for the $dbadmin user", "$dbadmin" );
    $siteadmin = &prompt( "Enter the name to create as the WEBSITE owner", "admin" );
    $siteadminpw = &prompt( "Enter the password for $siteadmin", "$siteadmin" );
    $email = &prompt( "Enter your email address", 'root@localhost' );
    $sitename = &prompt( "Enter a name for your website", 'The home of LogZilla' );
    $url = &prompt( "Enter the base url for your site (e.g: / or /logs/)", '/' );
    $logpath = &prompt( "Where should log files be stored?", '/var/log/logzilla' );
    $retention = &prompt( "How long before I archive old logs? (in days)", '7' );
    $snare = &getYN( "Do you plan to log Windows events from SNARE to this server?", 'n' );
    #$spx_cores = &prompt( "How many cores do you want to use for indexing", '8' );
}
$dbtable     = "logs";
$dbroot      = qq{$dbroot};
$dbrootpass  = qq{$dbrootpass};
$dbadmin     = qq{$dbadmin};
$dbadminpw   = qq{$dbadminpw};
$siteadmin   = qq{$siteadmin};
$siteadminpw = qq{$siteadminpw};
$url         = $url . "/" if ( $url !~ /\/$/ );
$url         = "/" . $url if ( $url !~ /^\// );

use IO::Socket::INET;

my $sock = IO::Socket::INET->new(
    PeerAddr => "$dbhost",
    PeerPort => $dbport,
    Proto    => "tcp" );
my $localip = $sock->sockhost;

if ( $dbhost !~ /localhost|127.0.0.1/ ) {
    my $file = "$lzbase/scripts/logzilla";
    system("perl -i -pe 's/LOAD DATA INFILE/LOAD DATA LOCAL INFILE/g' $file");
}

if ( !-d "$logpath" ) {
    mkdir "$logpath";
}
if ( !-d "$lzbase/data" ) {
    mkdir "$lzbase/data";
}

# Create mysql .cnf file
open( CNF, ">$lzbase/scripts/sql/lzmy.cnf" ) || die("Cannot Open $lzbase/scripts/sql/lzmy.cnf: $!");
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


if ( $skipdb !~ /[Yy]/ ) {
    if ( $installdb !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
        print "All data will be installed into the $dbname database\n";
        $installdb = &getYN( "Ok to continue?", "y" );
    }
    if ( $installdb =~ /[Yy]/ ) {
        my $dbh = DBI->connect( "DBI:mysql:mysql:$dbhost:$dbport", $dbroot, $dbrootpass );
        if (!$dbh) {
            print("\n\033[1m\tERROR!\n\033[0m");
            print "Unable to connect to the $dbname database on $dbhost:$dbport using the credentials set in $lzbase/scripts/.lzrc\n";
            $dbroot     = &prompt( "Enter the MySQL root username",      "root" );
            $dbrootpass = &prompt( "Enter the password for $dbroot",     "mysql" );
            $dbh = DBI->connect( "DBI:mysql:mysql:$dbhost:$dbport", $dbroot, $dbrootpass );
        }
        if (!$dbh) {
            print("\n\033[1m\tERROR!\n\033[0m");
            print "Still unable to connect. Please edit your .lzrc file (https://www.assembla.com/wiki/show/LogZillaWiki/RC_File) and set the correct credentials\n";
            exit;
        }
        my $sth = $dbh->prepare("SELECT version()") or die "Could not get MySQL version: $DBI::errstr";
        $sth->execute;
        while ( my @data = $sth->fetchrow_array() ) {
            my $ver = $data[0];
            if ( $ver !~ /5\.[1-9]/ ) {
                print("\n\033[1m\tERROR!\n\033[0m");
                print "LogZilla requires MySQL v5.1 or better.\n";
                print "Your version is $ver\n";
                print "Please upgrade MySQL to v5.1 or better and re-run this installation.\n";
                exit;
            }
        }
        if ( db_exists() eq 0 ) {
            $dbh->do("create database $dbname");
            do_install();
        } else {
            $upgrade='yes';
            print("\n\033[1m\tPrevious installation detected!\n\033[0m");
            print "Install can attempt an upgrade, but be aware of the following:\n";
            print "1. The upgrade process could potentially take a VERY long time on very large databases.\n";
            print "2. There is a potential for data loss, so please make sure you have backed up your database before proceeding.\n";
            my $ok = &getYN( "Ok to continue?", "y" );
            if ( $ok =~ /[Yy]/ ) {
                &rm_config_block("/etc/apparmor.d/usr.sbin.mysqld");
                &rm_config_block("/etc/syslog-ng/syslog-ng.conf");
                &rm_config_block("/etc/sudoers");
                &rm_config_block("/etc/php5/apache2/php.ini");
                my ( $major, $minor, $sub ) = getVer();
                print "Your Version: $major.$minor.$sub\n";
                print "New Version: $version" . "$subversion\n";
                my $t = $subversion;
                $t =~ s/\.(\d+)/$1/;

                if ( $sub =~ $t ) {
                    print "DB is already at the lastest revision, no need to upgrade.\n";
                } else {
                    # print "VERSION = $major $minor $sub\n";
                    #    exit;
                    if ( "$minor" eq 0 ) {
                        do_upgrade("0");
                    } elsif ( "$minor$sub" eq 1122 ) {
                        do_upgrade("1122");
                    } elsif ( "$major$minor" eq 299 ) {
                        do_upgrade("php-syslog-ng");
                    } elsif ( "$major$minor" eq 32 ) {
                        do_upgrade("32");
                    } else {
                        do_upgrade("all");
                    }
                }
            }
        }
    }
    verify_columns();
    do_procs();
    update_version();
}
add_logrotate()   unless $skiplogrot =~ /[Yy]/;
add_syslog_conf() unless $skipsysng  =~ /[Yy]/;
setup_cron()      unless $skipcron   =~ /[Yy]/;
setup_sudo()      unless $skipsudo   =~ /[Yy]/;
setup_apparmor()  unless $skipapparmor   =~ /[Yy]/;
install_sphinx()  unless $sphinx_compile   =~ /[Nn]/;
insert_test();
if ($sphinx_index   =~ /[Yy]/) {
    print "Starting Sphinx search daemon and re-indexing data...\n";
    system("(rm -f $lzbase/sphinx/data/* && cd $lzbase/sphinx && ./indexer.sh full)");
}
fbutton()         unless $skipfb       =~ /[Yy]/;
add_ioncube()     unless $skip_ioncube =~ /[Yy]/;
install_license() unless $skiplic      =~ /[Yy]/;
# run_tests()       unless $test    =~ /[Nn]/;

setup_rclocal();
hup_syslog();

sub make_archive_tables {
    my $i = 0; 
    my $j = 0;
    my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
    if ( !$dbh ) {
        print "Can't connect to $dbname database: ", $DBI::errstr, "\n";
        exit;
    }

# Insert archives table
#[[ticket:315]]
# Can't overwrite current archives on upgrade. We'll copy the existing table to old, then replace into new table.
    if ( tblExists("archives") eq 1 ) {
        copy_old_archives();
    } else {
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/archives.sql`;
    }

    # TH: seed the hourly views with the no record
    # Hourly
    for ( $i = 0 ; $i <= 23 ; $i++ ) {
        $dbh->do( "CREATE OR REPLACE VIEW log_arch_hr_$i AS SELECT * FROM $dbtable where id>2 and id<1;
            " ) or die "Could not create log_arch_hr_$i: $DBI::errstr";
    }

    # TH: seed the quad-hourly views with the no record
    # quad-Hourly
    for ( $i = 0 ; $i <= 3 ; $i++ ) {
        $j = $i*15;
        $dbh->do( "CREATE OR REPLACE VIEW log_arch_qrhr_$j AS SELECT * FROM $dbtable where id>2 and id<1;
            " ) or die "Could not create log_arch_hr_$i: $DBI::errstr";
    }

}

sub do_install {
    my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
    if ( !$dbh ) {
        print "Can't connect to $dbname database: ", $DBI::errstr, "\n";
        exit;
    }

    # Create main table
    $dbh->do( "
        CREATE TABLE $dbtable (
        id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
        host varchar(128) NOT NULL,
        facility enum('0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23') NOT NULL,
        severity enum('0','1','2','3','4','5','6','7') NOT NULL,
        program int(10) unsigned NOT NULL,
        msg varchar(8192) NOT NULL,
        mne int(10) unsigned NOT NULL,
        eid int(10) unsigned NOT NULL DEFAULT '0',
        suppress datetime NOT NULL DEFAULT '2010-03-01 00:00:00',
        counter int(11) NOT NULL DEFAULT '1',
        fo datetime NOT NULL,
        lo datetime NOT NULL,
        notes varchar(255) NOT NULL DEFAULT '',
        PRIMARY KEY (id,fo),
        KEY lo (lo),
        KEY `fo` (`fo`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 
        " ) or die "Could not create $dbtable table: $DBI::errstr";

    # Create sphinx table
    if ( $upgrade !~ /[Yy][Ee][Ss]/ ) {
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/sph_counter.sql`;
        print $res;
    }

    # Create cache table
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/cache.sql`;
    print $res;

    # Create hosts table
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/hosts.sql`;
    print $res;

    # Create mnemonics table
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/mne.sql`;
    print $res;

    # Create mnemonics table
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/mac.sql`;
    print $res;

    # Create snare_eid table
    create_snare_table();

    # Create programs table
    do_programs();

    # Create suppress table
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/suppress.sql`;
    print $res;

    # Create facilities table
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/facilities.sql`;
    print $res;

    # Create severities table
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/severities.sql`;
    print $res;

    # Create ban table
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/banned_ips.sql`;
    print $res;

    # Create epx tables
    `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/epx.sql` if ( colExists( "events_per_second", "name" ) eq 0 );

    # Create email alerts table
    do_email_alerts();

    # Groups
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/groups.sql`;
    print $res;

    # Insert totd data
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/totd.sql`;
    print $res;

    # Insert LZECS data
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/lzecs.sql`;
    print $res;

    # Insert Suppress data
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/suppress.sql`;
    print $res;

    # Insert ui_layout data
    if ( tblExists("ui_layout") eq 1 ) {
        upgrade_ui_layout();
    } else {
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/ui_layout.sql`;
    }

    # Insert help data
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/help.sql`;
    print $res;

    # Insert history table
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/history.sql`;
    print $res;

    # Insert users table
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/users.sql`;
    print $res;

    # Insert system_log table
    $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/system_log.sql`;
    print $res;

    # Insert rbac table
    if ( tblExists("rbac") eq 1 ) {
        copy_old_rbac();
    } else {
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/rbac.sql`;
    }

    # Insert view_limits table
    # cdukes: moved down to verify_columns()
    #if ( tblExists("view_limits") eq 1 ) {
    #copy_old_view_limits();
    #} else {
    #my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/view_limits.sql`;
    #}
    make_partitions();
    create_views();
    make_dbuser();
    add_table_triggers();
    make_archive_tables();
    update_settings();
}

sub update_paths {
    my $search = "/path_to" . "_logzilla";
    print "Updating file paths\n";
    my @flist = `find ../ -name '*.sh' -o -name '*.pl' -o -name '*.conf' -o -name '*.rc' -o -name 'logzilla.*' -type f | egrep -v '/install.pl|sphinx\/src|\\.svn|\\.lzrc' | xargs grep -l "$search"`;

    #print "@flist\n";
    foreach my $file (@flist) {
        chomp $file;
        print "Modifying $file\n";
        system "perl -i -pe 's|$search|$lzbase|g' $file" and warn "Could not modify $file $!\n";
    }
    $search = "/path_to" . "_logs";
    print "Updating log paths\n";
    @flist = `find ../ -name '*.sh' -o -name '*.pl' -o -name '*.conf' -o -name '*.rc' -o -name 'logzilla.*' -type f | egrep -v '/install.pl|sphinx\/src|\\.svn|\\.lzrc' | xargs grep -l "$search"`;

    #print "@flist\n";
    foreach my $file (@flist) {
        chomp $file;
        print "Modifying $file\n";
        system "perl -i -pe 's|$search|$logpath|g' $file" and warn "Could not modify $file $!\n";
    }
}

sub make_logfiles {

    #Create log files for later use by the server
    my $logfile = "$logpath/logzilla.log";
    open( LOG, ">>$logfile" );
    if ( !-f $logfile ) {
        print STDOUT "Unable to open log file \"$logfile\" for writing...$!\n";
        exit;
    }
    chmod 0666, "$logpath/logzilla.log";
    close(LOG);
    $logfile = "$logpath/mysql_query.log";
    open( LOG, ">>$logfile" );
    if ( !-f $logfile ) {
        print STDOUT "Unable to open log file \"$logfile\" for writing...$!\n";
        exit;
    }
    close(LOG);
    chmod 0666, "$logpath/mysql_query.log";
    $logfile = "$logpath/audit.log";
    open( LOG, ">>$logfile" );
    if ( !-f $logfile ) {
        print STDOUT "Unable to open log file \"$logfile\" for writing...$!\n";
        exit;
    }
    close(LOG);
    chmod 0666, "$logpath/audit.log";
    $logfile = "$logpath/logmsg.log";
    open( LOG, ">>$logfile" );
    if ( !-f $logfile ) {
        print STDOUT "Unable to open log file \"$logfile\" for writing...$!\n";
        exit;
    }
    close(LOG);
    chmod 0666, "$logpath/logmsg.log";
}

sub genconfig {
    print "Generating $lzbase/html/config/config.php\n";
    my $config = qq{<?php
    DEFINE('DBADMIN', '$dbadmin');
    DEFINE('DBADMINPW', '$dbadminpw');
    DEFINE('DBNAME', '$dbname');
    DEFINE('DBHOST', '$dbhost');
    DEFINE('DBPORT', '$dbport');
    DEFINE('LOG_PATH', '$logpath');
    DEFINE('DATA_DIR', '$lzbase/data');
    DEFINE('MYSQL_QUERY_LOG', '$logpath/mysql_query.log');
    DEFINE('PATHTOLOGZILLA', '$lzbase');
    DEFINE('SPHINXHOST', '127.0.0.1'); // NOT 'localhost'! Else it will connect to local socket instead
    DEFINE('SPHINXPORT', '9306');
    DEFINE('SPHINXAPIPORT', '3312');
# Enabling query logging will degrade performance.
DEFINE('LOG_QUERIES', 'FALSE');
};
my $file = "$lzbase/html/config/config.php";
open( CNF, ">$file" ) || die("Cannot Open $file: $!");
print CNF "$config";
my $rfile = "$lzbase/scripts/sql/regexp.txt";
open( FILE, $rfile ) || die("Cannot Open file: $!");
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
    my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );

    # Import procedures
    system "perl -i -pe 's| logs | $dbtable |g' sql/procedures.sql" and warn "Could not modify sql/procedures.sql $!\n";
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/procedures.sql`;
    print $res;
    # Create initial Partition of the $dbtable table
    $dbh->do( "CALL manage_logs_partitions();" )
        or die "Could not create partition for the $dbtable table: $DBI::errstr";

}

sub do_events {
    my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
    print "Creating MySQL Events...\n";

    # Drop events and recreate them whether this is a new install or an upgrade.
    $dbh->do( "
        DROP EVENT IF EXISTS `cacheEid`;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP EVENT IF EXISTS `cacheHosts`;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP EVENT IF EXISTS `cacheMne`;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP EVENT IF EXISTS `log_arch_daily_event`;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP EVENT IF EXISTS `log_arch_hr_event`;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP EVENT IF EXISTS `logs_add_partition`;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP EVENT IF EXISTS `logs_del_partition`;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP EVENT IF EXISTS `log_arch_qrhr_event`;
        " ) or die "$DBI::errstr";
    # ticket #412 : As of v4.25, all cleanup and updateCache procedures moved from DB to Perl to speed up the processes.
    $dbh->do( "
        DROP EVENT IF EXISTS `updateCache`;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP EVENT IF EXISTS `cleanup`;
        " ) or die "$DBI::errstr";

    # Create Partition events
    my $event = qq{
    CREATE EVENT logs_add_partition ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:00:00' ON
    COMPLETION NOT PRESERVE ENABLE DO CALL manage_logs_partitions();
    };
    my $sth = $dbh->prepare( "
        $event
        " ) or die "Could not create partition events: $DBI::errstr";
    $sth->execute;

    $event = qq{
    CREATE EVENT logs_del_partition ON SCHEDULE EVERY 1 DAY STARTS '$dateTomorrow 00:15:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL logs_delete_part_proc();
    };
    $sth = $dbh->prepare( "
        $event
        " ) or die "Could not create partition events: $DBI::errstr";
    $sth->execute;

    $dbh->do( "
        CREATE EVENT `log_arch_daily_event` ON SCHEDULE EVERY 1 DAY STARTS date_add(date_add(date(now()), interval 1 day),interval 270 second) ON COMPLETION NOT PRESERVE ENABLE DO call log_arch_daily_proc();
        " ) or die "$DBI::errstr";
    $dbh->do( "
        CREATE EVENT `log_arch_hr_event` ON SCHEDULE EVERY 1 HOUR STARTS date_add(date(now()),interval maketime(date_format(now(),'%H')+1,4,40) hour_second) ON COMPLETION PRESERVE ENABLE DO call log_arch_hr_proc();
        " ) or die "$DBI::errstr";
    $dbh->do( "
        CREATE EVENT `log_arch_qrhr_event` ON SCHEDULE EVERY 15 MINUTE STARTS date_add(date(now()),interval maketime(date_format(now(),'%H'),4,15) hour_second) ON COMPLETION PRESERVE ENABLE DO call log_arch_qrthr_proc();
        " ) or die "$DBI::errstr";
}

sub do_procs {
    print "Verifying MySQL Procedures\n";
    my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );

    # Drop procs and recreate them whether this is a new install or an upgrade.
    $dbh->do( "
        DROP PROCEDURE IF EXISTS updateHosts;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP PROCEDURE IF EXISTS updateMne;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP PROCEDURE IF EXISTS updateEid;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP PROCEDURE IF EXISTS export;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP PROCEDURE IF EXISTS import;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP PROCEDURE IF EXISTS cleanup;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP PROCEDURE IF EXISTS log_arch_daily_proc;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP PROCEDURE IF EXISTS log_arch_hr_proc;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP PROCEDURE IF EXISTS log_arch_qrthr_proc;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP PROCEDURE IF EXISTS logs_add_archive_proc;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP PROCEDURE IF EXISTS logs_add_part_proc;
        " ) or die "$DBI::errstr";
    $dbh->do( "
        DROP PROCEDURE IF EXISTS logs_delete_part_proc;
        " ) or die "$DBI::errstr";

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
    my $sth = $dbh->prepare( "
        $event
        " ) or die "Could not create partition events: $DBI::errstr";
    $sth->execute;

    $event = qq{
    CREATE PROCEDURE logs_delete_part_proc()
    SQL SECURITY DEFINER
    COMMENT 'Deletes old partitions - based on value of settings>retention' 
    BEGIN    
    select REPLACE(concat('drop view log_arch_day_',DATE_SUB(CURDATE(), INTERVAL (SELECT value from settings WHERE name='RETENTION') DAY)), '-','') into \@v;
    SELECT CONCAT( 'ALTER TABLE `logs` DROP PARTITION ',
    GROUP_CONCAT(`partition_name`))
    INTO \@s

    FROM INFORMATION_SCHEMA.partitions
    WHERE table_schema = '$dbname'
        AND table_name = '$dbtable'
        AND partition_description <
    TO_DAYS(DATE_SUB(CURDATE(), INTERVAL (SELECT value from settings WHERE name='RETENTION') DAY))
    GROUP BY TABLE_NAME;

    IF \@s IS NOT NULL then
    PREPARE stmt FROM \@s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    PREPARE stmt FROM \@v;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    END IF;
    select min(id) from logs into \@h; 
    update sph_counter set max_id=\@h-1 where counter_id=2;
    END 
    };
    $sth = $dbh->prepare( "
        $event
        " ) or die "Could not create partition events: $DBI::errstr";
    $sth->execute;

    $event = qq{
    CREATE PROCEDURE export()
    SQL SECURITY DEFINER
    COMMENT 'Acrhive all old data to a file'
    BEGIN
    DECLARE export CHAR(32) DEFAULT CONCAT ('dumpfile_',  DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 day), '%Y%m%d'),'.txt');
    DECLARE export_path CHAR(127);
    SELECT value INTO export_path FROM settings WHERE name="ARCHIVE_PATH";
    SET \@s =
    CONCAT('select log.id, log.host, log.facility, log.severity, prg.name as program, log.msg, mne.name as mne, log.eid, log.suppress, log.counter, log.fo, log.lo, log.notes  into outfile "',export_path, '/' , export,'"  FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY """" LINES TERMINATED BY "\n" from  `$dbtable` as log, `programs` as prg, `mne` as mne where  prg.crc=log.program and mne.crc=log.mne and TO_DAYS( log.lo )=',TO_DAYS(NOW())-1);
    PREPARE stmt FROM \@s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    INSERT IGNORE INTO archives (archive, records) VALUES (export,(SELECT COUNT(*) FROM `$dbtable` WHERE lo BETWEEN DATE_SUB(CONCAT(CURDATE(), ' 00:00:00'), INTERVAL 1 DAY) AND DATE_SUB(CONCAT(CURDATE(), ' 23:59:59'), INTERVAL  1 DAY))); END 
    };

    $sth = $dbh->prepare( "
        $event
        " ) or die "Could not create export Procedure: $DBI::errstr";
    $sth->execute;

    # TH: adding import procedure
    $event = qq{
    CREATE PROCEDURE `import`( `i_id` bigint(20) unsigned ,
    `i_host` varchar(128),
    `i_facility` int(2) unsigned,
    `i_severity` int(2) unsigned,
    `i_program` varchar(255),
    `i_msg` varchar(8192),
    `i_mne` varchar(255),
    `i_eid` int(10) unsigned,
    `i_suppress` datetime ,
    `i_counter` int(11),
    `i_fo` datetime,
    `i_lo` datetime,
    `i_notes` varchar(255))
    SQL SECURITY DEFINER
    COMMENT 'Import Data from archive'
    BEGIN
    INSERT INTO mne(name,crc,lastseen) VALUES (i_mne,crc32(i_mne),i_lo) ON DUPLICATE KEY UPDATE lastseen=GREATEST(i_lo,lastseen), hidden='false';
    INSERT INTO programs(name,crc,lastseen) VALUES (i_program,crc32(i_program),i_lo) ON DUPLICATE KEY UPDATE lastseen=GREATEST(i_lo,lastseen), hidden='false';
    INSERT IGNORE INTO `$dbtable`(id, host, facility, severity, program, msg, mne, eid, suppress, counter, fo, lo, notes)
    values (i_id, i_host, i_facility, i_severity, crc32(i_program), i_msg, crc32(i_mne), i_eid, i_suppress, i_counter,
    i_fo, i_lo, i_notes); 
    END
    };
    $sth = $dbh->prepare( "
        $event
        " ) or die "Could not create import Procedure: $DBI::errstr";
    $sth->execute;

    # Turn the event scheduler on

    $sth = $dbh->prepare( "
        SET GLOBAL event_scheduler = 1;
        " ) or die "Could not enable the Global event scheduler: $DBI::errstr";
    $sth->execute;

    #    $dbh->do("
    #        DROP PROCEDURE IF EXISTS `log_arch_mnthly_proc`;
    #        ") or die "$DBI::errstr";
    #    $dbh->do("
    #        DROP PROCEDURE IF EXISTS `log_arch_weekly_proc`;
    #        ") or die "$DBI::errstr";

    # Now create the events that trigger these procs
    do_events();
    # cdukes: added below after v4.25 because we moved some procedures to file but they were getting deleted above
    # this will all get cleaned up when Piotr writes the new install :-)
    system "perl -i -pe 's| logs | $dbtable |g' sql/procedures.sql" and warn "Could not modify sql/procedures.sql $!\n";
    my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/procedures.sql`;
    print $res;
}

sub make_dbuser {

    # DB User
    # Remove old user in case this is an upgrade
    # Have to do this for the new LOAD DATA INFILE
    print "Temporarily removing $dbadmin from $localip\n";
    my $dbh   = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
    my $grant = qq{GRANT USAGE ON *.* TO '$dbadmin'\@'$localip';};
    my $sth   = $dbh->prepare( "
        $grant
        " ) or die "Could not temporarily drop the $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;
    $grant = qq{DROP USER '$dbadmin'\@'$localip';};
    $sth   = $dbh->prepare( "
        $grant
        " ) or die "Could not temporarily drop the $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

    print "Adding $dbadmin to $localip\n";

    # Grant access to $dbadmin
    $grant = qq{GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, GRANT OPTION, REFERENCES, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EXECUTE, EVENT, TRIGGER ON `$dbname`.* TO '$dbadmin'\@'$localip'  IDENTIFIED BY '$dbadminpw'};

#my $grant = qq{GRANT ALL PRIVILEGES ON `$dbname.*` TO '$dbadmin'\@'$localip' IDENTIFIED BY '$dbadminpw';};
    $sth = $dbh->prepare( "
        $grant
        " ) or die "Could not create $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

    # CDUKES: [[ticket:16]]
    $grant = qq{GRANT FILE ON *.* TO '$dbadmin'\@'$localip' IDENTIFIED BY '$dbadminpw';};
    $sth = $dbh->prepare( "
        $grant
        " ) or die "Could not create $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

    # Repeat for localhost
    # Remove old user in case this is an upgrade
    # Have to do this for the new LOAD DATA INFILE
    print "Temporarily removing $dbadmin from localhost\n";
    $grant = qq{GRANT USAGE ON *.* TO '$dbadmin'\@'localhost';};
    $sth   = $dbh->prepare( "
        $grant
        " ) or die "Could not temporarily drop the $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;
    $grant = qq{DROP USER '$dbadmin'\@'localhost';};
    $sth   = $dbh->prepare( "
        $grant
        " ) or die "Could not temporarily drop the $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

    # Grant access to $dbadmin
    print "Adding $dbadmin to localhost\n";
    $grant = qq{GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, GRANT OPTION, REFERENCES, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EXECUTE, EVENT, TRIGGER ON `$dbname`.* TO '$dbadmin'\@'localhost'  IDENTIFIED BY '$dbadminpw'};

#my $grant = qq{GRANT ALL PRIVILEGES ON `$dbname.*` TO '$dbadmin'\@'localhost' IDENTIFIED BY '$dbadminpw';};
    $sth = $dbh->prepare( "
        $grant
        " ) or die "Could not create $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

    # CDUKES: [[ticket:16]]
    $grant = qq{GRANT FILE ON *.* TO '$dbadmin'\@'localhost' IDENTIFIED BY '$dbadminpw';};
    $sth = $dbh->prepare( "
        $grant
        " ) or die "Could not create $dbadmin user on $dbname: $DBI::errstr";
    $sth->execute;

    # THOMAS HONZIK: [[ticket:16]]
    my $flush = qq{FLUSH PRIVILEGES;};
    $sth   = $dbh->prepare( "
        $flush
        " ) or die "Could not FLUSH PRIVILEGES: $DBI::errstr";
    $sth->execute;

}

sub create_views {
    my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
    my $sth = $dbh->prepare( "
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
        " ) or die "Could not create $dbtable table: $DBI::errstr";
    $sth->execute;

    $sth = $dbh->prepare( "
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
        " ) or die "Could not create $dbtable table: $DBI::errstr";
    $sth->execute;
}

sub update_settings {

    my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );

    # Insert settings data
    # use copy_old settings so upgraders don't get overwritten
    if ( tblExists("settings") eq 1 ) {
        copy_old_settings();
        my $sth = $dbh->prepare( "
            update settings set value='$url' where name='SITE_URL';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update settings set value='$lzbase' where name='PATH_BASE';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update settings set value='$dbtable' where name='TBL_MAIN';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update settings set value='$logpath' where name='PATH_LOGS';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
    } else {
        my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/settings.sql`;
        my $sth = $dbh->prepare( "
            update settings set value='$url' where name='SITE_URL';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update settings set value='$email' where name='ADMIN_EMAIL';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update settings set value='$siteadmin' where name='ADMIN_NAME';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update settings set value='$lzbase' where name='PATH_BASE';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update settings set value='$sitename' where name='SITE_NAME';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update settings set value='$dbtable' where name='TBL_MAIN';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update settings set value='$logpath' where name='PATH_LOGS';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update settings set value='$retention' where name='RETENTION';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update triggers set mailto='$email', mailfrom='$email';
            " ) or die "Could not update triggers table: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update users set username='$siteadmin' where username='admin';
            " ) or die "Could not insert user data: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update users set pwhash=MD5('$siteadminpw') where username='$siteadmin';
            " ) or die "Could not insert user data: $DBI::errstr";
        $sth->execute;
    }
    # cdukes: Update SPX Port to use new 9306 port
    my $sth = $dbh->prepare( "UPDATE settings set value=9306 WHERE name='SPX_PORT'" ) or die "Could not update SPX_PORT in settings table: $DBI::errstr";
    $sth->execute;
    if (not $spx_cores) {
        $spx_cores = `cat /proc/cpuinfo | grep processor | wc -l`;
    }
    # Added for larger systems where we don't need to use *all* cores - leaves some for mysql
    $spx_cores = 6 if ($spx_cores > 12);
    $sth = $dbh->prepare( "
        update settings set value='$spx_cores' where name='SPX_CPU_CORES';
        " ) or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    # workaround for v4.25->v4.5 upgrades
    $sth = $dbh->prepare( "
        update settings set description='This variable is used to determine the number of days to keep data in the database. <br>Any data older than this setting will be automatically purged.' where name='RETENTION';
        " ) or die "Could not update settings table: $DBI::errstr";
    $sth->execute;
    if ( $snare =~ /[Yy]/ ) {
        my $sth = $dbh->prepare( "
            update settings set value=1 where name='SNARE';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
    } else {
        my $sth = $dbh->prepare( "
            delete from ui_layout where header='Snare EventId' and userid>0;
            " ) or die "Could not update ui layout for snare: $DBI::errstr";
        $sth->execute;
        $sth = $dbh->prepare( "
            update settings set value=0 where name='SNARE';
            " ) or die "Could not update settings table: $DBI::errstr";
        $sth->execute;
    }
    # cdukes 2014-06-05: Modify trigger table patterns column to allow larger regex's
    $sth = $dbh->prepare( "alter table triggers modify pattern varchar(2048) NOT NULL" ) or die "Could not update triggers table: $DBI::errstr";

    $sth = $dbh->prepare( "
        delete from users where username='guest';
        " ) or die "Could not insert user data: $DBI::errstr";
    $sth->execute;

}

sub add_logrotate {
    if ( -d "/etc/logrotate.d" ) {
        if ( $logrotate !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
            print "\nAdding LogZilla logrotate.d file to /etc/logrotate.d\n";
            $logrotate = &getYN( "Ok to continue?", "y" );
        }
        if ( $logrotate =~ /[Yy]/ ) {
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
system "chown mysql.mysql ../exports" and warn "Could not modify archive directory";

# [[ticket:300]] chown scripts also
system "chown mysql.mysql $lzbase/scripts/export.sh" and warn "Could not set permission on $lzbase/scripts/export.sh";
system "chown mysql.mysql $lzbase/scripts/import.sh" and warn "Could not set permission on $lzbase/scripts/import.sh";
system "chown mysql.mysql $lzbase/scripts/doimport.sh" and warn "Could not set permission on $lzbase/scripts/doimport.sh";

sub add_syslog_conf {
    my $dir = "/etc/syslog-ng/conf.d";
    my $file = "/etc/syslog-ng/conf.d/logzilla.conf";
    my @arr = `syslog-ng -V | grep Version`;
    my $ngmaj;
    my $ngmin;
    my $threaded;
    if ( $arr[0] =~ /\S+\s+(\d)\.(\d+)\..*/ ) { 
        $ngmaj = $1;
        $ngmin = $2;
        if ($ngmin < 3) {
            $threaded = "# threaded(yes); # enable if using Syslog-NG 3.3.x or greater";
        } else {
            $threaded = "threaded(yes); # enable if using Syslog-NG 3.3.x or greater";
        }
    }
    system("touch $file");
    unless ( -d "$dir" ) {
        $file = "/etc/syslog-ng/syslog-ng.conf";
        unless ( -e "$file" ) {
            $file = &prompt( "What is the correct path to your syslog-ng.conf file?", "/etc/syslog-ng/syslog-ng.conf" );
        }
    }
    if ( -e $file ) {
        open my $config, '+<', "$file";
        my @arr = <$config>;
        my $sconf = qq{
#<lzconfig> BEGIN LogZilla settings
# LogZilla "standard" config - this may or may not work well for your environment
# It is advisable that you learn what is best for your server.
# There's a great web gui available at http://mitzkia.github.com/syslog-ng-ose-configurator/#/howtouse
# Install Date: $now

# Global Options
options {
    chain_hostnames(no);
    keep_hostname(yes);
    $threaded
    use_fqdn(no); # This should be set to no in high scale environments
    use_dns(yes); # This should be set to no in high scale environments
};

};
my $sconf2 = q{

# Windows Events from SNARE
# https://www.assembla.com/spaces/LogZillaWiki/wiki/Receiving_Windows_Events_from_SNARE
rewrite r_snare { 
    subst("MSWinEventLog.+(Security|Application|System).+", "MSWin_$1", value("PROGRAM") flags(global)); 
};
# SNARE sends TAB delimited messages, we want pipes...
rewrite r_snare2pipe { 
    subst("\t", "|", value("MESSAGE") 
    flags(global)
    ); 
};

# Grab Cisco Mnemonics and write program name
    filter f_rw_cisco { match('^(%[A-Z]+\-\d\-[0-9A-Z]+): ([^\n]+)' value("MSGONLY") type("pcre") flags("store-matches" "nobackref")); };
    filter f_rw_cisco_2 { match('^[\*\.]?(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2}\s\d{1,2}:\d{1,2}:\d{1,2}(?:\.\d+)?(?: [A-Z]{3})?: (%[^:]+): ([^\n]+)' value("MSGONLY") type("pcre") flags("store-matches" "nobackref")); };
    filter f_rw_cisco_3 { match('^\d+[ywdh]\d+[ywdh]: (%[^:]+): ([^\n]+)' value("MSGONLY") type("pcre") flags("store-matches" "nobackref")); };
    filter f_rw_cisco_4 { match('^\d{6}: [\*\.]?(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2}\s\d{1,2}:\d{1,2}:\d{1,2}(?:\.\d+)?(?: [A-Z]{3})?: (%[^:]+): ([^\n]+)' value("MSGONLY") type("pcre") flags("store-matches" "nobackref")); };

rewrite r_cisco_program {
    set("Cisco_Syslog", value("PROGRAM") condition(filter(f_rw_cisco) or filter(f_rw_cisco_2) or filter(f_rw_cisco_3) or filter(f_rw_cisco_4)));
    set("$1: $2", value("MESSAGE") condition(filter(f_rw_cisco) or filter(f_rw_cisco_2) or filter(f_rw_cisco_3) or filter(f_rw_cisco_4)));
};

# Some guesses to detect VMWare, feel free to add your hostname to the HOST matches below
filter f_vmware {  
match('vmware|vim\.' value("MSGONLY"))
    or match("^Vpxa:" value("MSGONLY")) 
    or match("^Hostd:" value("MSGONLY")) 
    or match("^Rhttpproxt:" value("MSGONLY")) 
    or match("^Fdm:" value("MSGONLY")) 
    or match("^hostd-probe:" value("MSGONLY"))  
    or match("^vmkernel:" value("MSGONLY"))
    or match("[Vv][Mm][Ww][Aa][Rr][Ee].*" value("HOST"))
    or match("[Vv][Cc][Ee][Nn][Tt][Ee][Rr].*" value("HOST"))
}; 
rewrite r_vmware {
    set("VMWare", value("PROGRAM") condition(filter(f_vmware)));
};

# Cisco Context Directory Agent doesn't send host or program name properly
filter f_CiscoCDA {  
    match('ContextManager: ' value("MSGONLY"))
};  
rewrite r_CiscoCDA {
    set("CiscoCDA", value("PROGRAM") condition(filter(f_CiscoCDA)));
    set("$SOURCEIP", value("HOST") condition(filter(f_CiscoCDA)));
};  

# Capture real program name in case it's missing in the syslog header
filter f_rw_prg { match('(\w+)\[\d+' value("MSGONLY") type("pcre") flags("store-matches" "nobackref")); };
rewrite r_rw_prg {
    set("$1", value("PROGRAM") condition(filter(f_rw_prg)));
};  

# Set Program name for OpenAM events
filter f_rw_openam { match('openam' value("MSGONLY") ); };
rewrite r_rw_openam {
    set("OpenAM", value("PROGRAM") condition(filter(f_rw_openam)));
};

# Capture SNMP Traps
# See https://www.assembla.com/spaces/LogZillaWiki/wiki/Sending_SNMP_Traps_to_LogZilla
# For proper formatting in the snmptrapd.conf file
# You must enable the system() source (check /etc/syslog-ng.syslog-ng.conf) for this to get logged

filter f_snmptrapd { program("snmptrapd"); };
parser p_snmptrapd { 
    csv-parser(columns("SNMPTRAP.HOST", "SNMPTRAP.MSG") delimiters(",") flags(greedy, escape-backslash, strip-whitespace));
};
rewrite r_snmptrapd {
 set("${SNMPTRAP.HOST}" value("HOST") condition(filter(f_snmptrapd)));
 set("${SNMPTRAP.MSG}" value("MESSAGE") condition(filter(f_snmptrapd)));
};

source s_logzilla {
    tcp();
    udp();
    # Use no-multi-line so that java events get read properly
    syslog(flags(no-multi-line));
};

destination d_logzilla {
    program(
    "/var/www/logzilla/scripts/logzilla"
    log_fifo_size(1000)
    flush_lines(100)
    flush_timeout(1)
    template("$R_YEAR-$R_MONTH-$R_DAY $R_HOUR:$R_MIN:$R_SEC\t$HOST\t$PRI\t$PROGRAM\t$MSGONLY\n")
    );
};

destination df_logzilla {
    file("/var/log/logzilla/DEBUG.log"
    template("$R_YEAR-$R_MONTH-$R_DAY $R_HOUR:$R_MIN:$R_SEC\t$HOST\t$PRI\t$PROGRAM\t$MSGONLY\n")
    ); 
};

log {
    source(s_logzilla);
    rewrite(r_CiscoCDA);
    rewrite(r_rw_prg);
    rewrite(r_rw_openam);
    rewrite(r_vmware);
    rewrite(r_snare);
    rewrite(r_snare2pipe);
    rewrite(r_cisco_program);
    destination(d_logzilla);
    # Optional: Log all events to file
    destination(df_logzilla);
    flags(flow-control);
};
# Enable if you are sending SNMP Traps to LogZilla
    # NOTE: If your /etc/syslog-ng/syslong-ng.conf file does not have "system()" defined in s_src, this will not work.
#log {
    #source(s_src);
    #parser(p_snmptrapd);
    #rewrite(r_snmptrapd);
    #rewrite(r_snare2pipe);
    #destination(d_logzilla);
    ## Optional: Log all events to file
    #destination(df_logzilla);
    #flags(final);
#};
#</lzconfig> END LogZilla settings
};
        if ( !grep( /logzilla|lzconfig/, @arr ) ) {
            print "Creating LogZilla configuration for syslog-ng at $file\n";
            open FILE, ">>$file" or die $!;
            print FILE $sconf . $sconf2;
        } else {
            print "Skipping syslog-ng config as $file already exists...\n";
        }
    }
}

sub setup_cron {
    my $crondir;
    
    if ( $docron !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
	# Cronjob  Setup
	print("\n\033[1m\n\n========================================\033[0m\n");
	print("\n\033[1m\tCron Setup\n\033[0m");
	print("\n\033[1m========================================\n\n\033[0m\n");
	print "\n";
	print "Cron is used to run backend indexing and data exports.\n";
	print "Install will attempt to do this automatically for you by adding it to /etc/cron.d\n";
	print "In the event that something fails or you skip this step, \n";
	print "You MUST create it manually or create the entries in your root's crontab file.\n";
	$docron = &getYN( "Ok to continue?", "y" );
    }
    if ( $docron =~ /[Yy]/ ) {
        my $minute;
	
# due hourly views cron can always run every minute
#        my $sml = &getYN( "\n\nWill this copy of LogZilla be used to process more than 1 Million messages per day?\nNote: Your answer here only determines how often to run indexing.", "n" );
#        if ( $sml =~ /[Yy]/ ) {
#            $minute = 5;
#        } else {
        $minute = 1;

        #        }
        my $cron = qq{
#####################################################
# BEGIN LogZilla Cron Entries
# http://www.logzilla.net
# Install date: $now
#####################################################

#####################################################
# Run indexer every minute  
#####################################################
*/1 * * * * root test -d $lzbase && ( cd $lzbase/sphinx; ./indexer.sh delta ) >> $logpath/sphinx_indexer.log 2>&1

#####################################################
# Daily DB/SP Maintenance
#####################################################
# Grab some metrics every night @ 11pm
11 23 * * * root test -d $lzbase && perl /var/www/logzilla/scripts/LZTool -v -ss

# Update and general maintenance @ 1am
23 1 * * * root test -d $lzbase && perl $lzbase/scripts/LZTool -v 

# Rotate indexes @ midnight and 2am
0 2 * * * root test -d $lzbase && $lzbase/scripts/rotate 

#####################################################
# END LogZilla Cron Entries
#####################################################
};
$crondir = "/etc/cron.d";
unless ( -d "$crondir" ) {
    $crondir = &prompt( "What is the correct path to your cron.d?", "/etc/cron.d" );
}
if ( -d "$crondir" ) {
    my $file = "$crondir/logzilla";
    open FILE, ">$file" or die "cannot open $file: $!";
    print FILE $cron;
    close FILE;
    print "Cronfile added to $crondir\n";
    hup_crond();
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
      if ( $set_sudo !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
	  $set_sudo = &getYN( "Ok to continue?", "y" );
      }
      if ( $set_sudo =~ /[Yy]/ ) {
          my $file = "/etc/sudoers";
          unless ( -e $file ) {
              $file = &prompt( "Please provide the location of your sudoers file", "/etc/sudoers" );
          }
          if ( -e "$file" ) {

              # Try to get current web user
              my $PROGRAM = qr/apache|httpd/;
              my @ps      = `ps axu`;
              @ps = map { m/^(\S+)/; $1 } grep { /$PROGRAM/ } @ps;
              my $webuser = $ps[$#ps];
              if ( not $webuser ) {
                  my $webuser = &prompt( "Please provide the username that Apache runs as", "$webuser" );
              }

# since we have $webuser here, let's go ahead and chown the files needed for licensing
              system "chown $webuser.$webuser $lzbase/html/includes/ajax/license.log" and warn "Could not chown license.log";
              system "chown $webuser.$webuser $lzbase/html/" and warn "Could not chown html/";

              # Check to see if entry already exists
              open SFILE, "<$file";
              my @lines = <SFILE>;
              close SFILE;
              if ( grep( /<lzconfig>/, @lines ) ) {
                  print "Config entry already exists in $file, skipping add...\n";
              } else {
                  my $os = `uname -a`;
                  $os =~ s/.*(ubuntu).*/$1/i;
                  my $now = localtime;
                  open( SFILE, ">>$file" ) || die("Cannot Open $!");
                  my @data = <FILE>;
                  foreach my $line (@data) {
                      chomp $line;
                      print SFILE "$line";
                  }
                  print SFILE "\n";
                  print SFILE "# <lzconfig> BEGIN: Added by LogZilla installation on $now\n";
                  print SFILE "# Allows Apache user to HUP the syslog-ng process\n";
                  print SFILE "$webuser ALL=NOPASSWD:$lzbase/scripts/hup.pl\n";
                  print SFILE "# Allows Apache user to apply new licenses from the web interface\n";
                  print SFILE "$webuser ALL=NOPASSWD:$lzbase/scripts/licadd.pl\n";
                  print SFILE "# Allows Apache user to import data from archive\n";
                  print SFILE "$webuser ALL=NOPASSWD:$lzbase/scripts/doimport.sh\n";
                  print SFILE "$webuser ALL=NOPASSWD:$lzbase/scripts/dorestore.sh\n";
                  print SFILE "# </lzconfig> END: Added by LogZilla installation on $now\n";
                  close(SFILE);
                  print "Appended sudoer access for $webuser to $file\n";

                  if ( $os !~ /Ubuntu/i ) {
                      my $find = qr/^Defaults.*requiretty/;
                      open SFILE, "<$file";
                      my @lines = <SFILE>;
                      close SFILE;
                      if ( grep( /$find/, @lines ) ) {
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
          print "# <lzconfig> BEGIN: Added by LogZilla installation on $now\n";
          print "# Allows Apache user to HUP the syslog-ng process\n";
          print "www-data ALL=NOPASSWD:$lzbase/scripts/hup.pl\n";
          print "www-data ALL=NOPASSWD:$lzbase/scripts/licadd.pl\n";
          print "www-data ALL=NOPASSWD:$lzbase/scripts/doimport.sh\n";
          print "www-data ALL=NOPASSWD:$lzbase/scripts/dorestore.sh\n";
          print "# </lzconfig> END: Added by LogZilla installation on $now\n";

      }
  }

  sub kill {
      my $PROGRAM = shift;
      my @ps      = `ps ax`;
      @ps = map { m/(\d+)/; $1 } grep { /\Q$PROGRAM\E/ } @ps;
      for (@ps) {
          ( kill 9, $_ ) or die("Unable to kill process for $PROGRAM\n");
      }
      my $time = gmtime();

      #print "Killed $PROGRAM @ps\n";
  }

  sub install_sphinx {

      # [[ticket:306]]
      my $now   = strftime( '%Y-%m-%d %H:%M:%S', localtime );
      my $procs = `cat /proc/cpuinfo | grep ^proce | wc -l`;
      my $arch  = `uname -m`;
      if ( $procs > 3 ) {
          $j4 = "-j4";
      }

      # TH: ID64 works also on IA32 machines
      # if ($arch =~ /64/) {
      # $arch = "--enable-id64";
      # }
      my $makecmd = "make $j4 install";
      print("\n\033[1m\n\n========================================\033[0m\n");
      print("\n\033[1m\tSphinx Indexer\n\033[0m");
      print("\n\033[1m========================================\n\n\033[0m\n\n");
      print "Install will attempt to extract and compile your sphinx indexer.\n";

      # [[ticket:417]] - extract sphinx source from tarball
      if ( $do_sphinx_compile !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
	  $do_sphinx_compile = &getYN( "Ok to continue?", "y" );
      }
      if ( $do_sphinx_compile =~ /[Yy]/ ) {
          my $checkprocess = `ps -C searchd -o pid=`;
          chomp($checkprocess);
          if ($checkprocess) {
              system("kill -9 $checkprocess");
          }
          system("rm -rf $lzbase/sphinx/src");
          print "Extracting source tarball to $lzbase/sphinx/src...\n";
          system("tar xzvf $lzbase/sphinx/sphinx_source.tgz -C $lzbase/sphinx");
          if ( -d "$lzbase/sphinx/src") {
              system("cd $lzbase/sphinx/src && ./configure --enable-id64 --with-syslog --prefix `pwd`/.. && $makecmd");
              if ( $sphinx_index =~ /[Yy]/ ) {
                  print "Starting Sphinx search daemon and re-indexing data...\n";
                  system("(rm -f $lzbase/sphinx/data/* && cd $lzbase/sphinx && ./indexer.sh full)");
              }
          } else {
              print "The Unable to locate $lzbase/sphinx/src, did the tarball fail to extract?\n";
          }
      } else {
          print "Skipping Sphinx Installation\n";
      }
  }

  sub setup_apparmor {

      # Attempt to fix AppArmor
      my $file = "/etc/apparmor.d/usr.sbin.mysqld";
      if ( -e "$file" ) {
          open FILE, "<$file";
          my @lines = <FILE>;
          close FILE;
          if ( !grep( /logzilla_import/, @lines ) ) {
              print("\n\033[1m\n\n========================================\033[0m\n");
              print("\n\033[1m\tAppArmor Setup\n\033[0m");
              print("\n\033[1m========================================\n\n\033[0m\n\n");
              print "In order for MySQL to import and export data, you must take measures to allow it access from AppArmor.\n";
              print "Install will attempt do do this for you, but please be sure to check /etc/apparmor.d/usr.sbin.mysqld and also to restart the AppArmor daemon once install completes.\n";
	      if ( $set_apparmor !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
		  $set_apparmor = &getYN( "Ok to continue?", "y" );
	      }
              if ( $set_apparmor =~ /[Yy]/ ) {
                  print "Adding the following to lines to $file:\n";
                  print "/tmp/logzilla_import.txt r,\n$lzbase/exports/** rw,\n";
                  open my $config, '+<', "$file" or warn "FAILED: $!\n";
                  my @all = <$config>;
                  seek $config, 0, 0;
                  splice @all, -1, 0, "# <lzconfig> (please do not remove this line)\n  /tmp/logzilla_import.txt r,\n  $lzbase/exports/** rw,\n  /tmp/** r,\n# </lzconfig> (please do not remove this line)\n";
                  print $config @all;
                  close $config;
              }
	      if ( $apparmor_restart !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
		  print "\n\nAppArmor must be restarted, would you like to restart it now?\n";
		  $apparmor_restart  = &getYN( "Ok to continue?", "y" );
	      }
              if ( $apparmor_restart =~ /[Yy]/ ) {
                  my $r = `/etc/init.d/apparmor restart`;
              } else {
                  print("\033[1m\n\tPlease be sure to restart apparmor..\n\033[0m");
              }
          }
      }
  }

  sub setup_rclocal {
      my $file = "/etc/rc.local";
      if ( -e "$file" ) {
          open my $config, '+<', "$file" or warn "FAILED: $!\n";
          my @all = <$config>;
          if ( !grep( /sphinx|vmstartup/, @all ) ) {
              seek $config, 0, 0;
              splice @all, -1, 0, "# <lzconfig>\n(cd $lzbase/sphinx && ./run_searchd.sh)\n# </lzconfig>\n";
              print $config @all;
          }
          close $config;
      } else {
          print("\n\033[1m\tERROR!\n\033[0m");
          print "Unable to locate your $file\n";
          print "You will need to manually add the Sphinx Daemon startup to your system...\n";
          print "Sphinx startup command:\n";
          print "$lzbase/sphinx/run_searchd.sh -c $lzbase/sphinx/sphinx.conf\n";
      }
  }

  sub fbutton {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );

      # Feedback button
      print("\n\033[1m\n\n========================================\033[0m\n");
      print("\n\033[1m\tFeedback and Support\n\033[0m");
      print("\n\033[1m========================================\n\n\033[0m\n\n");

      print "\nIf it's ok with you, install will include a small 'Feedback and Support'\n";
      print "icon which will appear at the bottom right side of the web page\n";
      print "This non-intrusive button will allow you to instantly open support \n";
      print "requests with us as well as make suggestions on how we can make LogZilla better.\n";
      print "You can always disable it by selecting 'Admin>Settings>FEEDBACK' from the main menu\n";

      if ( $do_fback !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
	  $do_fback = &getYN( "Ok to add support and feedback?", "y" );
      }
      if ( $do_fback =~ /[Yy]/ ) {
          my $sth = $dbh->prepare( "
              update settings set value='1' where name='FEEDBACK';
              " ) or die "Could not update settings table: $DBI::errstr";
          $sth->execute;
      }
  }

  sub hup_syslog {

      # syslog-ng HUP
      print "\n\n";
      my $checkprocess = `ps -C syslog-ng -o pid=`;
      if ($checkprocess) {
          if ( $do_hup_syslog !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
	      print "\n\nSyslog-ng MUST be restarted, would you like to send a HUP signal to the process?\n";
	      $do_hup_syslog = &getYN( "Ok to HUP syslog-ng?", "y" );
	  }
	  if ( $do_hup_syslog =~ /[Yy]/ ) {
	      if ( $checkprocess =~ /(\d+)/ ) {
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
          if ( $do_hup_cron !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
	      print "\n\nCron.d should be restarted, would you like to send a HUP signal to the process?\n";
	      $do_hup_cron = &getYN( "Ok to HUP CRON?", "y" );
	  }
          if ( $do_hup_cron =~ /[Yy]/ ) {
              if ( $checkprocess =~ /(\d+)/ ) {
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
      my $output   = shift;
      my $pos      = shift;
      my $word     = shift;
      my $char     = shift;
      my $reserved = shift;
      my $length;

      my $cTerminalLineSize = 79;
      if ( not( ( $char eq "\n" ) || ( $char eq ' ' ) || ( $char eq '' ) ) ) {
          $word .= $char;

          return ( $output, $pos, $word );
      }

      # We found a separator.  Process the last word

      $length = length($word) + $reserved;
      if ( ( $pos + $length ) > $cTerminalLineSize ) {

          # The last word doesn't fit in the end of the line. Break the line before
          # it
          $output .= "\n";
          $pos = 0;
      }
      ( $output, $pos ) = append_output( $output, $pos, $word );
      $word = '';

      if ( $char eq "\n" ) {
          $output .= "\n";
          $pos = 0;
      } elsif ( $char eq ' ' ) {
          if ($pos) {
              ( $output, $pos ) = append_output( $output, $pos, ' ' );
          }
      }

      return ( $output, $pos, $word );
  }

# Wordwrap system: word-wrap a string plus some reserved trailing space
  sub wrap {
      my $input    = shift;
      my $reserved = shift;
      my $output;
      my $pos;
      my $word;
      my $i;

      if ( !defined($reserved) ) {
          $reserved = 0;
      }

      $output = '';
      $pos    = 0;
      $word   = '';
      for ( $i = 0 ; $i < length($input) ; $i++ ) {
          ( $output, $pos, $word ) = wrap_one_char( $output, $pos, $word,
              substr( $input, $i, 1 ), 0 );
      }

      # Use an artifical last '' separator to process the last word
      ( $output, $pos, $word ) = wrap_one_char( $output, $pos, $word, '', $reserved );

      return $output;
  }

# Print message
  sub msg {
      my $msg = shift;

      print $msg . "\n";
      exit;
  }

  sub do_upgrade {
      my $rev = shift;
      print("\n\033[1m\tUpgrading, please be patient!\nIf you have a large DB, this could take a long time...\n\033[0m");
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      if ( $rev eq "0" ) {
          print "You are running an unsupported version of LogZilla (<3.1)\n";
          print "An attempt will be made to upgrade to $version$subversion...\n";
          my $ok = &getYN( "Continue? (yes/no)", "y" );
          if ( $ok =~ /[Yy]/ ) {
              add_snare_to_logtable();
              do_programs();
              tbl_add_severities();
              tbl_add_facilities();
              create_snare_table();
              do_email_alerts();
              update_procs();
              make_archive_tables();
              make_dbuser();
              add_table_triggers();

              if ( colExists( "logs", "priority" ) eq 1 ) {
                  tbl_logs_alter_from_30();
              }
              print "\n\tUpgrade complete, continuing installation...\n\n";
          }
      }
      elsif ( $rev eq "1122" ) {
          print "Upgrading Database from v3.1.122 to $version$subversion...\n";
          add_snare_to_logtable();
          create_snare_table();
          do_email_alerts();
          update_procs();
          make_archive_tables();
          make_dbuser();
          add_table_triggers();
          print "\n\tUpgrade complete, continuing installation...\n\n";

      }
      elsif ( $rev eq "php-syslog-ng" ) {
          print "You are running an unsupported version of LogZilla (Php-syslog-ng v2.x)\n";
          print "An attempt will be made to upgrade to $version$subversion...\n";
          my $ok = &getYN( "Continue? (yes/no)", "y" );
          if ( $ok =~ /[Yy]/ ) {
              add_snare_to_logtable();
              do_programs();
              tbl_add_severities();
              tbl_add_facilities();
              create_snare_table();
              do_email_alerts();
              update_procs();
              make_dbuser();
              add_table_triggers();

              if ( colExists( "logs", "priority" ) eq 1 ) {
                  tbl_logs_alter_from_299();
              }
              make_partitions();
              make_archive_tables();
              print "\n\tUpgrade complete, continuing installation...\n\n";
          }
      }
      elsif ( $rev eq "32" ) {
          update_procs();
          make_archive_tables();
          make_dbuser();
          add_table_triggers();
          print "\n\tUpgrade complete, continuing installation...\n\n";
      }
      elsif ( $rev eq "all" ) {
          print "Your version is not an officially supported upgrade.\n";
          print "An attempt will be made to upgrade to $version$subversion...\n";
          my $ok = &getYN( "Continue? (yes/no)", "y" );
          if ( $ok =~ /[Yy]/ ) {
              add_snare_to_logtable();
              do_programs();
              tbl_add_severities();
              tbl_add_facilities();
              create_snare_table();
              do_email_alerts();
              update_procs();
              make_archive_tables();
              make_dbuser();
              add_table_triggers();
              print "\n\tUpgrade complete, continuing installation...\n\n";
          }
      }
      elsif ( $rev eq 2 ) {
          print "Attempting upgrade from php-syslog-ng (v2.x) to LogZilla (v3.x)\n";
          print "Not Implemented yet...sorry\n";
          exit;
      }
      else {
          print "Your version is not a candidate for upgrade.\n";
          exit;
      }
      update_help();

      # Insert ui_layout data
      if ( tblExists("ui_layout") eq 1 ) {
          upgrade_ui_layout();
      } else {
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/ui_layout.sql`;
      }
      update_settings();
      hup_syslog();
  }

  sub db_connect {
      my $dbname     = shift;
      my $lzbase     = shift;
      my $dbroot     = shift;
      my $dbrootpass = shift;
      my $dsn        = "DBI:mysql:$dbname:;mysql_read_default_group=logzilla;"
      . "mysql_read_default_file=$lzbase/scripts/sql/lzmy.cnf";
      my $dbh = DBI->connect( $dsn, $dbroot, $dbrootpass );

      if ( !$dbh ) {
          print "Can't connect to the mysql database: ", $DBI::errstr, "\n";
          exit;
      }

      return $dbh;
  }

  sub db_exists {
      my $dbh = DBI->connect( "DBI:mysql:mysql:$dbhost:$dbport", $dbroot, $dbrootpass );
      my $sth = $dbh->prepare("show databases like '$dbname'") or die "Could not get DB's: $DBI::errstr";
      $sth->execute;
      while ( my @data = $sth->fetchrow_array() ) {
          if ( $data[0] == "$dbtable" ) {
              return 1;
          } else {
              return 0;
          }
      }
  }

  sub getVer {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      if ( colExists( "settings", "id" ) eq 1 ) {
          my $ver = $dbh->selectrow_array( "
              SELECT value from settings where name='VERSION';
              " );
          my ( $major, $minor ) = split( /\./, $ver );
          my $sub = $dbh->selectrow_array("SELECT value from settings where name='VERSION_SUB'; ");
          $sub =~ s/^\.//;
          return ( $major, $minor, $sub );
      } else {

          # If there is no settings table in the DB, it's php-syslog-ng v2.x
          return ( 2, 99, 0 );
      }
  }

  sub add_table_triggers {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      print "Dropping Table Triggers...\n";
      $dbh->do("DROP TRIGGER IF EXISTS counts") or die "Could not drop trigger: $DBI::errstr";
      $dbh->do("DROP TRIGGER IF EXISTS system_log") or die "Could not drop trigger: $DBI::errstr";
      print "Adding Table Triggers...\n";
      $dbh->do( "
          CREATE TRIGGER `system_log`
          BEFORE INSERT ON system_log
          FOR EACH ROW
          BEGIN
          SET NEW.timestamp = NOW();
          END
          " ) or die "Could not add triggers: $DBI::errstr";

  }

  sub add_snare_to_logtable {
      if ( colExists( "$dbtable", "eid" ) eq 0 ) {
          my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
          print "Adding SNARE eids to $dbtable...\n";
          $dbh->do("ALTER TABLE $dbtable ADD `eid` int(10) unsigned NOT NULL DEFAULT '0'") or die "Could not update $dbtable: $DBI::errstr";
          print "Adding SNARE index to $dbtable...\n";
          $dbh->do("ALTER TABLE $dbtable ADD index eid(eid)") or die "Could not update $dbtable: $DBI::errstr";
      }
  }

  sub create_snare_table {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      if ( tblExists("snare_eid") eq 1 ) {
          copy_old_snare();
      } else {
          print "Adding SNARE table...\n";
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/snare_eid.sql`;
      }
  }

  sub copy_old_snare {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      print "Updating SNARE table...\n";
      $dbh->do("RENAME TABLE snare_eid TO snare_eid_orig") or die "Could not update $dbname: $DBI::errstr";
      my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/snare_eid.sql`;
      print $res;
      $dbh->do("REPLACE INTO snare_eid SELECT * FROM snare_eid_orig; ") or die "Could not update $dbname: $DBI::errstr";
      $dbh->do("DROP TABLE snare_eid_orig") or die "Could not update $dbname: $DBI::errstr";
  }

  sub copy_old_archives {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      print "Updating Archives table...\n";
      $dbh->do("RENAME TABLE archives TO archives_orig") or die "Could not update $dbname: $DBI::errstr";
      my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/archives.sql`;
      print $res;
      $dbh->do("REPLACE INTO archives SELECT * FROM archives_orig; ") or die "Could not update $dbname: $DBI::errstr";
      $dbh->do("DROP TABLE archives_orig") or die "Could not update $dbname: $DBI::errstr";
  }

  sub verify_columns {

# As of v4.0, we will just do this for all columns regardless of install or upgrade to make sure they exist.
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      print "Verifying Table Columns...\n";
      my @tables = ( 'hosts', 'programs', 'snare_eid', 'mne', 'mac' );
      my @cols = ( 'lastseen', 'seen', 'hidden' );
      foreach (@tables) {
          print "Validating $_ table:\n";
          my $table = $_;
          if ( colExists( "$table", "id" ) eq 0 ) {
              print "Creating $table table...\n";
              my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/$table.sql`;
              print "$res\n";
          }
          foreach (@cols) {
              my $col = $_;
              print "Validating $table.$col\n";
              if ( colExists( "$table", "$col" ) ne 1 ) {
                  print "Updating $table $col column...\n";
                  if ( $col eq "lastseen" ) {
                      $dbh->do("ALTER TABLE $table ADD `lastseen` datetime NOT NULL default '2012-01-01 00:00:00'; ") or die "Could not update $dbname: $DBI::errstr";
                  }
                  elsif ( $col eq "seen" ) {
                      $dbh->do("ALTER TABLE $table ADD `seen` int(10) unsigned NOT NULL DEFAULT '1'; ") or die "Could not update $dbname: $DBI::errstr";
                  }
                  elsif ( $col eq "hidden" ) {
                      $dbh->do("ALTER TABLE $table ADD `hidden` enum('false','true') DEFAULT 'false'; ") or die "Could not update $dbname: $DBI::errstr";
                  }
              }
          }
      }

      # Test for RBAC
      @tables = ( 'hosts', 'users' );
      foreach (@tables) {
          my $table = $_;
          if ( colExists( "$table", "rbac_key" ) eq 0 ) {
              $dbh->do("ALTER TABLE $table ADD `rbac_key` int(10) unsigned NOT NULL DEFAULT '1'; ") or die "Could not update $dbname: $DBI::errstr";
              $dbh->do("ALTER TABLE $table ADD KEY `rbac` (`rbac_key`); ") or die "Could not update $dbname: $DBI::errstr";
          }
      }

      # Test for EPX
      my $table = 'events_per_second';
      if ( colExists( "$table", "name" ) eq 0 ) {
          print "Creating $table table...\n";
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/epx.sql`;
          print "$res\n";
      }

      # fix for notes column not having the default value set in LogZilla v4.25
      $dbh->do("ALTER TABLE logs MODIFY `notes` varchar(255) NOT NULL DEFAULT '';") or die "Could not update $dbname: $DBI::errstr";

      # Insert sph metrics
      if ( tblExists("sph_metrics") eq 0 ) {
          print "Adding Sphinx Metrics Table\n";
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/sph_metrics.sql`;
      }
      # Insert saudit table
      if ( tblExists("saudit") eq 0 ) {
          print "Adding Search Audit Table\n";
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/saudit.sql`;
      }
      # Insert mails_sent table
      if ( tblExists("mails_sent") eq 0 ) {
          print "Adding Mail Audit Table\n";
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/mails_sent.sql`;
      }
      # Insert view_limits table
      if ( tblExists("view_limits") eq 1 ) {
          copy_old_view_limits();
      } else {
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/view_limits.sql`;
          print "Building view limits\n";
          system("for f in `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport INFORMATION_SCHEMA --skip-column-names --batch -e \"select table_name from tables where table_type = 'VIEW' and table_schema = '$dbname'\"  | grep \"log_arch_day\"`; do mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname -e \"insert ignore into view_limits (view_name, min_id, max_id) values ('\$f', (select min(id) from \$f), (select max(id) from \$f))\"; done");
      }
  }

  sub update_version {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      my $sth = $dbh->prepare( "
          update settings set value='$version' where name='VERSION';
          " ) or die "Could not update settings table: $DBI::errstr";
      $sth->execute;
      $sth = $dbh->prepare( "
          update settings set value='$subversion' where name='VERSION_SUB';
          " ) or die "Could not update settings table: $DBI::errstr";
      $sth->execute;
  }

  sub tbl_logs_alter_from_30 {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      print "Attempting to modify an older logs table to work with the new version.\n";
      print "This could take a VERY long time, DO NOT cancel this operation\n";
      if ( colExists( "$dbtable", "priority" ) eq 1 ) {

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
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      print("\n\033[1m\tWARNING!\n\033[0m");
      print "Attempting to modify an older logs table to work with the new version.\n";
      print "This could take a VERY long time, DO NOT cancel this operation\n";
      if ( colExists( "$dbtable", "priority" ) eq 1 ) {

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
          $dbh->do("ALTER TABLE $dbtable CHANGE `msg` `msg` varchar(8192) NOT NULL") or die "Could not update $dbname: $DBI::errstr";

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
          $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/cache.sql`;
          print $res;

          print "Adding Groups Table\n";
          $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/groups.sql`;
          print $res;

          print "Adding History Table\n";
          $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/history.sql`;
          print $res;

          print "Adding lzecs Table\n";
          $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/lzecs.sql`;
          print $res;

          print "Creating Suppress Table\n";
          $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/suppress.sql`;
          print $res;

          print "Creating Totd Table\n";
          $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/totd.sql`;

          print "Creating views\n";
          create_views();
      }
  }

  sub do_email_alerts {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      if ( tblExists("triggers") eq 0 ) {
          print "Adding Email Alerts...\n";
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/triggers.sql`;
      } else {
          print "Updating Email Alerts...\n";
          if ( colExists( "triggers", "description" ) eq 0 ) {
              $dbh->do("ALTER TABLE triggers ADD `description` varchar(255) NOT NULL DEFAULT ''") or die "Could not update $dbtable: $DBI::errstr";
          }
          if ( colExists( "triggers", "to" ) eq 1 ) {
              $dbh->do("ALTER TABLE triggers CHANGE `to` `mailto` varchar (255)") or die "Could not update $dbtable: $DBI::errstr";
          }
          if ( colExists( "triggers", "from" ) eq 1 ) {
              $dbh->do("ALTER TABLE triggers CHANGE `from` `mailfrom` varchar (255)") or die "Could not update $dbtable: $DBI::errstr";
          }
          if ( colExists( "triggers", "disabled" ) eq 0 ) {
              $dbh->do("ALTER TABLE triggers ADD `disabled` enum('Yes','No') NOT NULL DEFAULT 'Yes'") or die "Could not update $dbtable: $DBI::errstr";
          }

          #continue
          $dbh->do("RENAME TABLE triggers TO triggers_orig") or die "Could not update $dbname: $DBI::errstr";
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/triggers.sql`;
          print $res;
          $dbh->do("REPLACE INTO triggers SELECT * FROM triggers_orig; ") or die "Could not update $dbname: $DBI::errstr";
          $dbh->do("DROP TABLE triggers_orig") or die "Could not update $dbname: $DBI::errstr";
      }
  }

  sub do_programs {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      if ( tblExists("programs") eq 0 ) {
          print "Adding Programs Table...\n";
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/programs.sql`;
      } else {
          print "Updating Programs Table...\n";
          $dbh->do("RENAME TABLE programs TO programs_orig") or die "Could not update $dbname: $DBI::errstr";
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/programs.sql`;
          print $res;
          $dbh->do("REPLACE INTO programs SELECT * FROM programs_orig; ") or die "Could not update $dbname: $DBI::errstr";
          $dbh->do("DROP TABLE programs_orig") or die "Could not update $dbname: $DBI::errstr";
      }
  }

  sub tbl_add_severities {
      if ( tblExists("severities") eq 0 ) {
          print "Adding Severities Table...\n";
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/severities.sql`;
          print $res;
      }
  }

  sub tbl_add_facilities {
      if ( tblExists("facilities") eq 0 ) {
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

  sub upgrade_ui_layout {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      print "Updating UI Layout...\n";
      $dbh->do("RENAME TABLE ui_layout TO ui_layout_orig") or die "Could not update $dbname: $DBI::errstr";
      my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/ui_layout.sql`;
      print $res;
      $dbh->do("REPLACE INTO ui_layout SELECT * FROM ui_layout_orig; ") or die "Could not update $dbname: $DBI::errstr";
      $dbh->do("DROP TABLE ui_layout_orig") or die "Could not update $dbname: $DBI::errstr";
  }

  sub copy_old_settings {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      print "Updating Settings...\n";
      $dbh->do("RENAME TABLE settings TO settings_orig") or die "Could not update $dbname: $DBI::errstr";
      my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/settings.sql`;
      print $res;
      $dbh->do("REPLACE INTO settings SELECT * FROM settings_orig; ") or die "Could not update $dbname: $DBI::errstr";
      $dbh->do("DROP TABLE settings_orig") or die "Could not update $dbname: $DBI::errstr";
  }

  sub copy_old_rbac {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      print "Updating RBAC...\n";
      $dbh->do("RENAME TABLE rbac TO rbac_orig") or die "Could not update $dbname: $DBI::errstr";
      my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/rbac.sql`;
      print $res;
      $dbh->do("REPLACE INTO rbac SELECT * FROM rbac_orig; ") or die "Could not update $dbname: $DBI::errstr";
      $dbh->do("DROP TABLE rbac_orig") or die "Could not update $dbname: $DBI::errstr";
  }

  sub copy_old_view_limits {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      print "Updating view_limits...\n";
      $dbh->do("RENAME TABLE view_limits TO view_limits_orig") or die "Could not update $dbname: $DBI::errstr";
      my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/view_limits.sql`;
      print $res;
      $dbh->do("REPLACE INTO view_limits SELECT * FROM view_limits_orig; ") or die "Could not update $dbname: $DBI::errstr";
      $dbh->do("DROP TABLE view_limits_orig") or die "Could not update $dbname: $DBI::errstr";
  }

  sub update_procs {
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      print "Updating SQL Procedures...\n";

      # Import procedures
      system "perl -i -pe 's| logs | $dbtable |g' sql/procedures.sql" and warn "Could not modify sql/procedures.sql $!\n";
      my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/procedures.sql`;
      print $res;

      # Insert system_log table
      $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/system_log.sql`;
      print $res;

      # Insert rbac table
      if ( tblExists("rbac") eq 1 ) {
          copy_old_rbac();
      } else {
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/rbac.sql`;
      }

      # Insert view_limits table
      if ( tblExists("view_limits") eq 1 ) {
          copy_old_view_limits();
      } else {
          my $res = `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname < sql/view_limits.sql`;
          print "Building view limits\n";
          system("for f in `mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport INFORMATION_SCHEMA --skip-column-names --batch -e \"select table_name from tables where table_type = 'VIEW' and table_schema = '$dbname'\"  | grep \"log_arch_day\"`; do mysql -u$dbroot -p'$dbrootpass' -h $dbhost -P $dbport $dbname -e \"insert ignore into view_limits (view_name, min_id, max_id) values ('\$f', (select min(id) from \$f), (select max(id) from \$f))\"; done");
      }

  }

  sub insert_test {
      print "Inserting first message as a test ...\n";
      system("$lzbase/scripts/test/genlog -hn 1 -n 1 | $lzbase/scripts/logzilla -d 1 -v");
  }

  sub colExists {
      my $table = shift;
      my $col   = shift;
      my $dbh   = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      my $sth   = $dbh->column_info( undef, $dbname, $table, '%' );
      my $ref   = $sth->fetchall_arrayref;
      my @cols  = map { $_->[3] } @$ref;

      #print "DEB: looking for $col\n";
      #print "DEB: @cols\n";
      if ( grep( /\b$col\b/, @cols ) ) {
          return 1;
      } else {
          return 0;
      }
  }

  sub tblExists {
      my $tbl = shift;
      my $dbh = db_connect( $dbname, $lzbase, $dbroot, $dbrootpass );
      my $sth = $dbh->table_info( undef, undef, $tbl, "TABLE" );
      if ( $sth->fetch ) {
          return 1;
      } else {
          return 0;
      }
  }

  sub add_ioncube {
      print("\n\033[1m\n\n========================================\033[0m\n");
      print("\n\033[1m\tIONCube License Manager\n\033[0m");
      print("\n\033[1m========================================\n\n\033[0m\n\n");
      print "Extracting IONCube files to /usr/local/ioncube\n";
      my $arch = `uname -m`;
      if ( $arch =~ /64/ ) {
          system("tar xzvf ioncube/ioncube_loaders_lin_x86-64.tar.gz -C /usr/local");
      } else {
          system("tar xzvf ioncube/ioncube_loaders_lin_x86.tar.gz -C /usr/local");
      }
      my $phpver = `/usr/bin/php -v | head -1`;
      my $ver = $1 if ( $phpver =~ /PHP (\d\.\d)/ );
      if ( $ver !~ /[45]\.[04]/ ) {	  
	  if ( $do_ioncube !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
	      $do_ioncube = &getYN( "\nInstall will try to add the license loader to php.ini for you is this ok?", "y" );
	  }
          if ( $do_ioncube =~ /[Yy]/ ) {
              my $file = "/etc/php5/apache2/php.ini";
              if ( !-e "$file" ) {
                  $file = "/etc/php.ini";
                  if ( !-e "$file" ) {
                      $file = &prompt( "Please enter the location of your php.ini file", "$file" );
                  }
              }
              if ( !-e "$file" ) {
                  print "unable to locate $file\n";
              } else {
                  open my $config, '+<', "$file" or warn "FAILED: $!\n";
                  my @all = <$config>;
                  if ( !grep( /lzconfig/, @all ) ) {
                      seek $config, 0, 0;
                      splice @all, 1, 0, ";# <lzconfig> (please do not remove this line)\nzend_extension = /usr/local/ioncube/ioncube_loader_lin_$ver.so\n;# </lzconfig> (please do not remove this line)\n";
                      print $config @all;
                  }
                  close $config;

                  if ( -e "/etc/init.d/apache2" ) {
		      if ( $restart_php !~ /[YyNn]/ ) { # i.e. undefined in .lzrc
			  $restart_php = &getYN( "Is it ok to restart Apache to apply changes?", "y" );
		      }
                      if ( $restart_php =~ /[Yy]/ ) {
                          my $r = `/etc/init.d/apache2 restart`;
                      } else {
                          print("\033[1m\n\tPlease be sure to restart your Apache server..\n\033[0m");
                      }
                  } else {
                      print("\033[1m\n\tPlease be sure to restart your Apache server..\n\033[0m");
                  }
              }
          }
      } else {
          print "\nWARNING: Your PHP version ($ver) does not appear to be a candidate for auto-populating the php.ini file.\nPlease read /usr/local/ioncube/README.txt for more information.\n";
      }
  }

  sub install_license {

      print("\n\033[1m\n\n========================================\033[0m\n");
      print("\n\033[1m\tLicense\n\033[0m");
      print("\n\033[1m========================================\n\n\033[0m\n\n");
      print "If you have already ordered your license, install will attempt to connect to the licensing server and download it.\n";
      print "It is highly recommended that you use this method in order to avoid any possible copy/paste issues with your license.\n";
      print "If you skip this step, or if something goes wrong, you will still have an opportunity to enter your license in the web interface.\n\n";
      print "You can also run \"$0 install_license\" at any time.\n";
      my $ok = &getYN( "Would you like to attempt automatic license install? (y/n)", "y" );
      if ( $ok =~ /[Yy]/ ) {
	my ($ip, $mac);
	# Below uses getIf sub instead of unreliable ifconfig -a to get the IP
	$ip = getIf('eth0');
print "getIf Reported IP: $ip\n" if ($ip);
          my @lines = `ifconfig eth0`;
          for (@lines) {
              if (/\s*HWaddr (\S+)/) {
                  $mac = lc($1);
                  print "Found MAC ($mac)\n";
              }
	# skip getting ip from ifconfig if getIf worked above
	next if ($ip);
              if (/\s*inet addr:([\d.]+)/) {
                  $ip = $1;
                  print "Found IP ($ip)\n";
                  last;    # we only want the first interface
              }
          }
          my $ip_orig = $ip;
          my $mac_orig = $mac;
          $ip  =~ s/[^a-zA-Z0-9]//g;
          $mac =~ s/[^a-zA-Z0-9]//g;
          $mac = lc($mac);
          my $hash = md5_hex("$ip$mac");

          my $url  = "http://lic.logzilla.net/$hash.txt";
          print "Check for license using $ip_orig/$mac_orig ($ip$mac)\n";
          print "Requesting license file from $url\n";
          my $file = "$lzbase/html/license.txt";

          if ( is_success( getstore( $url, $file ) ) ) {
              print "License Installed Successfully\n";
          } else {
              my $macUC = uc($mac);
              my $hashUC = md5_hex("$ip$macUC");
              my $url  = "http://lic.logzilla.net/$hashUC.txt";
              print "Requesting alternate license file from $url\n";
              if ( is_success( getstore( $url, $file ) ) ) {
                  print "License Installed Successfully\n";
              } else {
                  print "\n\033[1m[ERROR] Failed to download: $url\n\033[0m";
                  print "Unable to find your license on the license server\n";
                  print "Have you ordered a license from our website?\n";
                  print "Please visit http://logzilla.net/products/trying-out-logzilla\n";
              }
          }
      }
  }

  sub rm_config_block {
      my $d = strftime( '%m%d%H%M', localtime );
      my $file = shift;
      if ( -e $file ) {
          system "cp $file $file.lzbackup.$d";
          my @data;
          open my $config, '<', "$file" or warn "FAILED: $!\n";
          while (<$config>) {
              next if ( /# <lzconfig>/ .. /# <\/lzconfig>/ );
              next if ( /# http:\/\/nms.gdd.net\/index.php\/Install_Guide_for_LogZilla_v3.2/ .. /# END LogZilla/ );
              next if (/logzilla/);
              next if (/ioncube/);
              push( @data, $_ );
          }
          close $config;
          open FILE, ">$file" or die "Unable to open $file: $!";
          print FILE @data;
          close FILE;
      } else {
          print "$file does not exist\n";
      }
  }

  sub run_tests {
      print("\n\033[1m\n\n========================================\033[0m\n");
      print("\n\033[1m\tPost-Install Self Tests\n\033[0m");
      print("\n\033[1m========================================\n\n\033[0m\n\n");
      print("\n\033[1m\n\n/*---------------------*/\033[0m\n");
      print("\033[1m     Usability Tests\n\033[0m");
      print("\033[1m/*---------------------*/\n\n\033[0m\n\n");
      opendir( DIR, "$lzbase/t/log_processor" );
      foreach my $file ( sort { $a <=> $b } readdir(DIR) )
      {

          if ( $file =~ /\d+/ ) {
              print "Running test: $file\n";
              my $cmd = `$lzbase/t/log_processor/$file`;
              print "$cmd\n";
          }
      }
      opendir( DIR, "$lzbase/t/sql" );
      foreach my $file ( sort { $a <=> $b } readdir(DIR) )
      {

          if ( $file =~ /\d+/ ) {
              print "Running test: $file\n";
              my $cmd = `$lzbase/t/sql/$file`;
              print "$cmd\n";
          }
      }
      closedir(DIR);
      closedir(DIR);
      print("\n\033[1m\n\n/*---------------------*/\033[0m\n");
      print("\033[1m    Performance Tests\n\033[0m");
      print("\033[1m/*---------------------*/\n\n\033[0m\n\n");
      opendir( DIR, "$lzbase/t/log_processor/perf" );
      foreach my $file ( sort { $a <=> $b } readdir(DIR) )
      {

          if ( $file =~ /\d+/ ) {
              print "Running test: $file\n";
              my $cmd = `$lzbase/t/log_processor/perf/$file`;
              print "$cmd\n";
          }
      }
      closedir(DIR);
  }

sub getIf {
    my ($iface) = @_;
    my $socket;
    socket($socket, PF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2]) || die "Sub 'getIf' is unable to create a socket: $!\n";
    my $buf = pack('a256', $iface);
    if (ioctl($socket, SIOCGIFADDR(), $buf) && (my @address = unpack('x20 C4', $buf)))
    {
        return join('.', @address);
    }
    return undef;
}
sub EULA {
      print <<EOF;

END USER LICENSE AGREEMENT

This End User License Agreement, including any Order which by this reference is incorporated herein (this "Agreement"), is a binding agreement between LogZilla Corporation ("LogZilla") and the person or entity receiving the Software (as defined below) accompanied by this Agreement ("you" or "Customer"). You may have received an "evaluation edition", "alpha", "beta", or other non-commercial release version of the Software ("Evaluation Edition") or a commercially released or generally available version of the Software and your rights will vary depending on the version that you received.
       
LOGZILLA PROVIDES THE SOFTWARE SOLELY ON THE TERMS AND CONDITIONS SET FORTH IN THIS AGREEMENT AND ON THE CONDITION THAT CUSTOMER ACCEPTS AND COMPLIES WITH THEM. BY CLICKING THE "ACCEPT" BUTTON, YOU (A) ACCEPT THIS AGREEMENT AND AGREE THAT CUSTOMER IS LEGALLY BOUND BY ITS TERMS; AND (B) REPRESENT AND WARRANT THAT: (I) YOU ARE OF LEGAL AGE TO ENTER INTO A BINDING AGREEMENT; AND (II) IF CUSTOMER IS A CORPORATION, GOVERNMENTAL ORGANIZATION OR OTHER LEGAL ENTITY, YOU HAVE THE RIGHT, POWER AND AUTHORITY TO ENTER INTO THIS AGREEMENT ON BEHALF OF CUSTOMER AND BIND CUSTOMER TO ITS TERMS. IF CUSTOMER DOES NOT AGREE TO THE TERMS OF THIS AGREEMENT, LOGZILLA WILL NOT AND DOES NOT LICENSE THE SOFTWARE TO CUSTOMER AND YOU MUST NOT INSTALL THE SOFTWARE OR DOCUMENTATION.
       
NOTWITHSTANDING ANYTHING TO THE CONTRARY IN THIS AGREEMENT OR YOUR OR CUSTOMER'S ACCEPTANCE OF THE TERMS AND CONDITIONS OF THIS AGREEMENT, NO LICENSE IS GRANTED (WHETHER EXPRESSLY, BY IMPLICATION OR OTHERWISE) UNDER THIS AGREEMENT, AND THIS AGREEMENT EXPRESSLY EXCLUDES ANY RIGHT, CONCERNING ANY SOFTWARE THAT CUSTOMER DID NOT ACQUIRE LAWFULLY OR THAT IS NOT A LEGITIMATE, AUTHORIZED COPY OF LOGZILLA'S SOFTWARE.

1. Definitions. For purposes of this Agreement, the following terms have the following meanings:
       
"Development Use" means use of the Software by Customer to design, develop and/or test new applications for Production Use.
       
"Documentation" means user manuals, technical manuals and any other materials provided by LogZilla, in printed, electronic or other form, that describe the installation, operation, use or technical specifications of the Software.
       
"Fees" are the License Fees and the Support Fees.
       
"License Fees" means the license fees, including all taxes thereon, paid or required to be paid by Customer for the license granted under this Agreement.
       
"License Package" means the type of license selected by Customer depending on the number of hosts and messages Customer needs. License Packages are available in evaluation, small business and enterprise sizes.
       
"Order" means the document by which the Software and any Support Services are ordered by Customer.
       
"Person" means an individual, corporation, partnership, joint venture, limited liability company, governmental authority, unincorporated organization, trust, association or other entity.
       
"Production Use" means using the Software with Customer's applications for internal business purposes only, which may include third party customers' access to or use of such applications. "Production Use" does not include the right to reproduce the software for sublicensing, resale, or distribution, including without limitation, operation on a time sharing or service bureau basis or distributing the software as part of an ASP, VAR, OEM, distributor or reseller arrangement.
       
"Software" means the object code versions of the software set forth in the Order.

"Support Fees" means the support fees, including all taxes thereon, paid or required to be paid by Customer for the Support Services ordered under this Agreement.

"Third Party" means any Person other than Customer or LogZilla.

"Use" means Development Use or Production Use.

2. License Grant and Scope. Subject to and conditioned upon Customer's strict compliance with all terms and conditions set forth in this Agreement, LogZilla hereby grants to Customer a non-exclusive, non-transferable, non-sublicensable (except as expressly set forth in Section 2(d)), limited license during the Term (as defined below) to use the Software and Documentation, solely as set forth in this Section 2 and subject to all conditions and limitations set forth in Section 4 or elsewhere in this Agreement. This license grants Customer the right to:

       (a) Download and install in accordance with the Documentation the Software and Documentation solely for Customer's Use and in accordance with the number of hosts and messages associated with the License Package, each as specified in the Order. In addition to the foregoing, Customer has the right to make one copy of the Software solely for archival purposes, provided that Customer does not, and does not allow any Person to, install or use any such copy other than if and for so long as the copy installed in accordance with the preceding sentence is inoperable and, provided, further, that Customer uninstalls and otherwise deletes such inoperable copy. All copies of the Software made by Customer:

             (i) will be the exclusive property of LogZilla;

             (ii) will be subject to the terms and conditions of this Agreement; and

             (iii) must include all trademark, copyright, patent and other intellectual property rights notices contained in the original.

       (b) Use and run the Software as properly installed in accordance with this Agreement and the Documentation, solely as set forth in the Documentation and solely for Customer's internal business purposes. If Customer has acquired Software for Development Use, Customer is not permitted to use the Software for Production Use. If Customer has acquired Software for Production Use, Customer is not permitted to use the Software for Development Use.

       (c) Download or otherwise make a reasonable number of copies of the Documentation depending on the License Package and use such Documentation, solely in support of its licensed use of the Software in accordance herewith. All copies of the Documentation made by Customer:

             (i) will be the exclusive property of LogZilla;

             (ii) will be subject to the terms and conditions of this Agreement; and

             (iii) must include all trademark, copyright, patent and other intellectual property rights notices contained in the original.

       (d) Permit third party consultants to access and use the Software solely for Customer's internal business operations, provided that such consultants execute an agreement with Customer with terms and conditions no less protective of LogZilla than those in this Agreement. Customer remains liable for any breach of this Agreement by a third party consultant.

3. Third-Party Materials. The Software may include software, content, data or other materials, including related documentation, that are owned by Persons other than LogZilla and that are provided to Customer on terms that are in addition to and/or different from those contained in this Agreement ("Third-Party Licenses"). Customer is bound by and will comply with all Third-Party Licenses. Any breach by Customer or any of its authorized users of any Third-Party License is also a breach of this Agreement.

4. Use Restrictions. Customer will not:

       (a) use (including make any copies of) the Software or Documentation beyond the scope of the license granted under Section 2;

       (b) except as may be permitted by Section 2(d) and strictly in compliance with its terms, provide any other Person, including any subcontractor, independent contractor, affiliate or service provider of Customer, with access to or use of the Software or Documentation;

       (c) modify, translate, adapt or otherwise create derivative works or improvements, whether or not patentable, of the Software or Documentation or any part thereof;

       (d) combine the Software or any part thereof with, or incorporate the Software or any part thereof in, any other programs;

       (e) reverse engineer, disassemble, decompile, decode or otherwise attempt to derive or gain access to the source code of the Software or any part thereof;

       (f) remove, delete, alter or obscure any trademarks or any copyright, trademark, patent or other intellectual property or proprietary rights notices from the Software or Documentation, including any copy thereof;

       (g) except as expressly set forth in Section 2(a) and Section 2(c), copy the Software or Documentation, in whole or in part;

       (h) rent, lease, lend, sell, sublicense, assign, distribute, publish, transfer or otherwise make available the Software or any features or functionality of the Software, to any Third Party for any reason, whether or not over a network and whether or not on a hosted basis, including in connection with the internet, web hosting, wide area network (WAN), virtual private network (VPN), virtualization, time-sharing, service bureau, software as a service, cloud or other technology or service;

       (i) use the Software in, or in association with, the design, construction, maintenance or operation of any hazardous environments or systems, including:

             (i) power generation systems;

             (ii) aircraft navigation or communication systems, air traffic control systems or any other transport management systems;

             (iii) safety-critical applications, including medical or life-support systems, vehicle operation applications or any police, fire or other safety response systems; and

             (iv) military or aerospace applications, weapons systems or environments;

       (j) use the Software in violation of any federal, state or local law, regulation or rule; or

       (k) use the Software for purposes of competitive analysis of the Software, the development of a competing software product or service or any other purpose that is to LogZilla's commercial disadvantage.

5. Responsibility for Use of Software. Customer is responsible and liable for all uses of the Software through access thereto provided by Customer, directly or indirectly. Specifically, and without limiting the generality of the foregoing, Customer is responsible and liable for all actions and failures to take required actions with respect to the Software by any other Person to whom Customer may provide access to or use of the Software, whether such access or use is permitted by or in violation of this Agreement.

6. Feedback. If Customer provides any feedback to LogZilla concerning the functionality and performance of the Software (including identifying potential errors and improvements) ("Feedback"), Customer hereby assigns to LogZilla all right, title, and interest in and to the Feedback, and LogZilla is free to use the Feedback without any payment or restriction.

7. Compliance Measures.

       (a) The Software may contain technological copy protection or other security features designed to prevent unauthorized use of the Software, including features to protect against use of the Software: (i) beyond the scope of the license granted pursuant to Section 2; or (ii) prohibited under Section 4. Customer will not, and will not attempt to, remove, disable, circumvent or otherwise create or implement any workaround to, any such copy protection or security features.

       (b) Upon reasonable notice to Customer, during the Term and for three years thereafter, Customer will keep current, complete, and accurate records regarding the reproduction, distribution, and use of the Software. Customer will provide such information to LogZilla and certify that it has paid all fees required under this Agreement within five business days of any written request, so long as no more than two requests are made each year. LogZilla may, in LogZilla's sole discretion, audit Customer's use of the Software under this Agreement at any time during the Term and for three years thereafter to ensure Customer's compliance with this Agreement, provided that (i) any such audit will be conducted on not less than 30 days' prior notice to Customer, and (ii) no more than 2 audits may be conducted in any 12 month period except for good cause shown. LogZilla also may, in its sole discretion, audit Customer's systems within 3 months after the end of the Term to ensure Customer has ceased use of the Software and removed the all copies of the Software from such systems as required hereunder. Customer will fully cooperate with LogZilla's personnel conducting such audits and provide all reasonable access requested by LogZilla to records, systems, equipment, information and personnel, including machine IDs, serial numbers and related information. LogZilla will only examine information related to Customer's use of the Software. LogZilla may conduct audits only during Customer's normal business hours and in a manner that does not unreasonably interfere with Customer's business operations.

       (c) If any of the measures taken or implemented under this Section 6 determines that Customer's use of the Software exceeds or exceeded the use permitted by this Agreement then:

             (i) Customer will, within 7 days following the date of receipt of written notice from LogZilla, pay to LogZilla the retroactive License Fees for such excess use and obtain and pay for a valid license to bring Customer's use into compliance with this Agreement. In determining the Customer Fee payable pursuant to the foregoing, (x) unless Customer can demonstrate otherwise by documentary evidence, all excess use of the Software will be deemed to have commenced on the commencement date of this Agreement or, if later, the completion date of any audit previously conducted by LogZilla hereunder, and continued uninterrupted thereafter, and (y) the rates for such licenses will be determined without regard to any discount to which Customer may have been entitled had such use been properly licensed prior to its commencement (or deemed commencement).

             (ii) If the use exceeds or exceeded the use permitted by this Agreement by more than 5%, Customer will also pay to LogZilla, within 7 days following the date of LogZilla's written request therefor, LogZilla's reasonable costs incurred in conducting the audit.
LogZilla's remedies set forth in this Section 6 are cumulative and are in addition to, and not in lieu of, all other remedies LogZilla may have at law or in equity, whether under this Agreement or otherwise.

8. Maintenance and Support.

       (a) Subject to Section 8(d), the license granted hereunder entitles Customer to the technical support and maintenance services ("Support Services") identified on the Order, if any, during the Term.

       (b) Support Services will include provision of such updates, upgrades, bug fixes, patches and other error corrections (collectively, "Updates") as LogZilla makes generally available at no additional charge to all Customers of the Software then entitled to Support Services. LogZilla may develop and provide Updates in its sole discretion, and Customer agrees that LogZilla has no obligation to develop any Updates at all or for particular issues. Customer further agrees that all Updates will be deemed "Software," and related documentation will be deemed "Documentation," all subject to all terms and conditions of this Agreement. Customer acknowledges that LogZilla may provide Updates via download from a website designated by LogZilla and that Customer's receipt thereof will require an internet connection, which connection is Customer's sole responsibility. LogZilla has no obligation to provide Updates via any other media. Support Services do not include any new version or new release of the Software LogZilla may issue as a separate or new product, and LogZilla may determine whether any issuance qualifies as a new version, new release or Update in its sole discretion.

       (c) If Customer reports a bug or error to LogZilla, LogZilla will use commercially reasonable efforts to begin development on an Update for such bug or error within 12 hours of receipt of notification from Customer.

       (d) LogZilla reserves the right to condition the provision of Support Services, including all or any Updates, on Customer's registration of the copy of Software for which support is requested. LogZilla has no obligation to provide Support Services, including Updates:

             (i) for any but the most current version or release of the Software;

             (ii) for any copy of Software for which all previously issued Updates have not been installed;

             (iii) if Customer is in breach under this Agreement; or

             (iv) for any Software that has been modified other than by or with the authorization of LogZilla, or that is being used with any hardware, software, configuration or operating system not specified in the Documentation or expressly authorized by LogZilla in writing.

9. Collection and Use of Information.

       (a) Customer acknowledges that LogZilla may, directly or indirectly through the services of Third Parties, collect and store information regarding use of the Software and about equipment on which the Software is installed or through which it otherwise is accessed and used, through:

             (i) the provision of maintenance and support services; and

             (ii) security measures included in the Software as described in Section 6.

       (b) Customer agrees that LogZilla may use such information for any purpose related to any use of the Software by Customer or on Customer's equipment, including but not limited to:

             (i) improving the performance of the Software or developing Updates; and

             (ii) verifying Customer's compliance with the terms of this Agreement and enforcing LogZilla's rights, including all intellectual property rights in and to the Software.

10. Intellectual Property Rights. Customer acknowledges and agrees that the Software and Documentation are provided under license, and not sold, to Customer. Customer does not acquire any ownership interest in the Software or Documentation under this Agreement, or any other rights thereto other than to use the same in accordance with the license granted, and subject to all terms, conditions and restrictions, under this Agreement. LogZilla and its licensors and service providers reserve and retain their entire right, title and interest in and to the Software and all intellectual property rights arising out of or relating to the Software, except as expressly granted to Customer in this Agreement. Customer will safeguard all Software (including all copies thereof) from infringement, misappropriation, theft, misuse or unauthorized access. Customer will promptly notify LogZilla if Customer becomes aware of any infringement of LogZilla's intellectual property rights in the Software and fully cooperate with LogZilla, at LogZilla's sole expense, in any legal action taken by LogZilla to enforce its intellectual property rights.

11. Confidentiality. By virtue of this Agreement, the parties may have access to information that is confidential to one another ("Confidential Information"). Confidential Information includes the Software, Documentation, this Agreement and any Order, and all information clearly identified as confidential. A party's Confidential Information does not include information that: (a) is or becomes a part of the public domain through no act or omission of the other party; (b) was in the other party's lawful possession prior to the disclosure and had not been obtained by the other party either directly or indirectly from the disclosing party; (c) is lawfully disclosed to the other party by a third party without restriction on disclosure; or (d) is independently developed by the other party. The parties agree to hold each other's Confidential Information in confidence during the term of this Agreement and for a period of 2 years after termination of this Agreement. The parties agree, unless required by law, not to make each other's Confidential Information available in any form to any third party for any purpose other than the implementation of this Agreement. LogZilla may reasonably use Customer's name and a description of Customer's use of the Software for its investor relations and marketing purposes, unless Customer provides written notice within 7 days of installation of the Software to LogZilla that it may not do so.

12. Payment. All License Fees and Support Fees are payable within 30 days of the date of invoice from LogZilla and are non-refundable. Any renewal of the license or maintenance and support services hereunder will not be effective until the fees for such renewal have been paid in full. Late payments accrue interest at a rate of 1% per month.

13. Term and Termination.

       (a) This Agreement and the license granted hereunder will remain in effect for the term set forth on the Order or until earlier terminated as set forth herein (the "Initial Term"). This Agreement will renew automatically following the Initial Term for one-year terms (each, a "Renewal Term" and both the Initial Term and the Renewal Term are the "Term") until either party terminates the Agreement upon notice 30 days prior to the end of the then-current term. Notwithstanding the foregoing, for Evaluation Edition licenses, this Agreement and the license granted hereunder will end upon completion of the testing or evaluation period specified by LogZilla, which shall not exceed 30 days from delivery of the Software to Customer unless otherwise expressly agreed in writing by LogZilla.

       (b) LogZilla may terminate this Agreement, effective upon written notice to Customer, if Customer, materially breaches this Agreement and such breach: (i) is incapable of cure; or (ii) being capable of cure, remains uncured 30 days after LogZilla provides written notice thereof.

       (c) LogZilla may terminate this Agreement, effective immediately, if Customer files, or has filed against it, a petition for voluntary or involuntary bankruptcy or pursuant to any other insolvency law, makes or seeks to make a general assignment for the benefit of its creditors or applies for, or consents to, the appointment of a trustee, receiver or custodian for a substantial part of its property.

       (d) Upon expiration or earlier termination of this Agreement, the license granted hereunder will also terminate, and Customer will cease using and destroy all copies of the Software and Documentation. No expiration or termination will affect Customer's obligation to pay all Fees that may have become due before such expiration or termination, or entitle Customer to any refund, in each case except as set forth in Section 14(c).

14. Limited Warranties, Exclusive Remedy and Disclaimer/Warranty Disclaimer.

       (a) If you are using Evaluation Edition of the Software, the Software is provided "AS IS" and without any warranties. Solely with respect to Software for which LogZilla receives a Fee, LogZilla warrants that, for a period of 90 days following the first installation of the Software, the Software will substantially contain the functionality described in the Documentation, and when properly installed on a computer meeting the specifications set forth in, and operated in accordance with, the Documentation, will substantially perform in accordance therewith. THE FOREGOING WARRANTY DOES NOT APPLY, AND LOGZILLA STRICTLY DISCLAIMS ALL WARRANTIES, WITH RESPECT TO ANY THIRD-PARTY MATERIALS.

       (b) The warranties set forth in Section 14(a) will not apply and will become null and void if Customer materially breaches any material provision of this Agreement, or if Customer or any other Person provided access to the Software by Customer, whether or not in violation of this Agreement:

             (i) installs or uses the Software on or in connection with any hardware or software not specified in the Documentation or expressly authorized by LogZilla in writing;

             (ii) modifies or damages the Software; or

             (iii) misuses the Software, including any use of the Software other than as specified in the Documentation or expressly authorized by LogZilla in writing.

       (c) If, during the period specified in Section 14(a), any Software covered by the warranty set forth in such Section fails to perform substantially in accordance with the Documentation, and such failure is not excluded from warranty pursuant to the Section 14(b), LogZilla will, subject to Customer's promptly notifying LogZilla in writing of such failure, either:

             (i) repair or replace the Software, provided that Customer provides LogZilla with all information LogZilla requests to resolve the reported failure, including sufficient information to enable LogZilla to recreate such failure; or

             (ii) if LogZilla is unable to repair or replace the Software, refund the License Fees paid for such Software, subject to Customer's ceasing all use of and, if requested by LogZilla, returning to LogZilla all copies of the Software or certifying in writing that all copies of the Software have been destroyed.

If LogZilla repairs or replaces the Software, the warranty will continue to run from the installation date, and not from Customer's receipt of the repair or replacement. The remedies set forth in this Section 14(c) are Customer's sole remedies and LogZilla's sole liability under the limited warranty set forth in Section 14(a).

       (d) EXCEPT FOR THE LIMITED WARRANTY SET FORTH IN Section 14(a) AND THE SUPPORT SERVICES SET FORTH IN Section 8, THE SOFTWARE AND DOCUMENTATION ARE PROVIDED TO CUSTOMER "AS IS" AND WITH ALL FAULTS AND DEFECTS WITHOUT WARRANTY OF ANY KIND. TO THE MAXIMUM EXTENT PERMITTED UNDER APPLICABLE LAW, LOGZILLA, ON ITS OWN BEHALF AND ON BEHALF OF ITS AFFILIATES AND ITS AND THEIR RESPECTIVE LICENSORS AND SERVICE PROVIDERS, EXPRESSLY DISCLAIMS ALL WARRANTIES, WHETHER EXPRESS, IMPLIED, STATUTORY OR OTHERWISE, WITH RESPECT TO THE SOFTWARE AND DOCUMENTATION, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT, AND WARRANTIES THAT MAY ARISE OUT OF COURSE OF DEALING, COURSE OF PERFORMANCE, USAGE OR TRADE PRACTICE. WITHOUT LIMITATION TO THE FOREGOING, LOGZILLA PROVIDES NO WARRANTY OR UNDERTAKING, AND MAKES NO REPRESENTATION OF ANY KIND THAT THE LICENSED SOFTWARE WILL MEET CUSTOMER'S REQUIREMENTS, ACHIEVE ANY INTENDED RESULTS, BE COMPATIBLE OR WORK WITH ANY OTHER SOFTWARE, APPLICATIONS, SYSTEMS OR SERVICES, OPERATE WITHOUT INTERRUPTION, MEET ANY PERFORMANCE OR RELIABILITY STANDARDS OR BE ERROR FREE OR THAT ANY ERRORS OR DEFECTS CAN OR WILL BE CORRECTED.

15. Limitation of Liability. TO THE FULLEST EXTENT PERMITTED UNDER APPLICABLE LAW:

       (a) IN NO EVENT WILL LOGZILLA OR ITS AFFILIATES, OR ANY OF ITS OR THEIR RESPECTIVE LICENSORS OR SERVICE PROVIDERS, BE LIABLE TO CUSTOMER OR ANY THIRD PARTY FOR ANY USE, INTERRUPTION, DELAY OR INABILITY TO USE THE SOFTWARE, LOST REVENUES OR PROFITS, DELAYS, INTERRUPTION OR LOSS OF SERVICES, BUSINESS OR GOODWILL, LOSS OR CORRUPTION OF DATA, LOSS RESULTING FROM SYSTEM OR SYSTEM SERVICE FAILURE, MALFUNCTION OR SHUTDOWN, FAILURE TO ACCURATELY TRANSFER, READ OR TRANSMIT INFORMATION, FAILURE TO UPDATE OR PROVIDE CORRECT INFORMATION, SYSTEM INCOMPATIBILITY OR PROVISION OF INCORRECT COMPATIBILITY INFORMATION OR BREACHES IN SYSTEM SECURITY, OR FOR ANY CONSEQUENTIAL, INCIDENTAL, INDIRECT, EXEMPLARY, SPECIAL OR PUNITIVE DAMAGES, WHETHER ARISING OUT OF OR IN CONNECTION WITH THIS AGREEMENT, BREACH OF CONTRACT, TORT (INCLUDING NEGLIGENCE) OR OTHERWISE, REGARDLESS OF WHETHER SUCH DAMAGES WERE FORESEEABLE AND WHETHER OR NOT LOGZILLA WAS ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

       (b) IN NO EVENT WILL LOGZILLA'S AND ITS AFFILIATES', INCLUDING ANY OF ITS OR THEIR RESPECTIVE LICENSORS AND SERVICE PROVIDERS', COLLECTIVE AGGREGATE LIABILITY ARISING OUT OF OR RELATED TO THIS AGREEMENT, WHETHER ARISING OUT OF OR RELATED TO BREACH OF CONTRACT, TORT (INCLUDING NEGLIGENCE) OR OTHERWISE, EXCEED THE TOTAL AMOUNT PAID TO LOGZILLA PURSUANT TO THIS AGREEMENT IN THE TWELVE MONTHS PRECEDING THE EVENT GIVING RISE TO LIABILITY FOR THE SOFTWARE OR SUPPORT SERVICES THAT ARE THE SUBJECT OF THE CLAIM.

       (c) THE LIMITATIONS SET FORTH IN Section 15(a) AND Section 15(b) WILL APPLY EVEN IF CUSTOMER'S REMEDIES UNDER THIS AGREEMENT FAIL OF THEIR ESSENTIAL PURPOSE.

16. Export Regulation. The Software and Documentation may be subject to U.S. export control laws, including the U.S. Export Administration Act and its associated regulations. Customer will not, directly or indirectly, export, re-export or release the Software or Documentation to, or make the Software or Documentation accessible from, any jurisdiction or country to which export, re-export or release is prohibited by law, rule or regulation. Customer will comply with all applicable federal laws, regulations and rules, and complete all required undertakings (including obtaining any necessary export license or other governmental approval), prior to exporting, re-exporting, releasing or otherwise making the Software or Documentation available outside the US.

17. US Government Rights. The Software is commercial computer software, as such term is defined in 48 C.F.R. §2.101. Accordingly, if Customer is the U.S. Government or any contractor therefor, Customer will receive only those rights with respect to the Software and Documentation as are granted to all other end users under license, in accordance with (a) 48 C.F.R. §227.7201 through 48 C.F.R. §227.7204, with respect to the Department of Defense and their contractors, or (b) 48 C.F.R. §12.212, with respect to all other U.S. Government Customers and their contractors.

18. Miscellaneous.

       (a) This Agreement will be governed by and construed in accordance with the internal laws of the State of Texas without giving effect to any choice or conflict of law provision or rule (whether of the State of Texas or any other jurisdiction) that would cause the application of laws of any jurisdiction other than those of the State of Texas and not including the provisions of the 1980 U.N. Convention on Contracts for the International Sale of Goods.

       (b) LogZilla will not be in default hereunder by reason of any failure or delay in the performance of its obligations hereunder where such failure or delay is due to strikes, labor disputes, civil disturbances, riot, rebellion, invasion, epidemic, hostilities, war, terrorist attack, embargo, natural disaster, acts of God, flood, fire, sabotage, fluctuations or non-availability of electrical power, heat, light, air conditioning or Customer equipment, loss and destruction of property or any other circumstances or causes beyond LogZilla's reasonable control.

       (c) All notices, requests, consents, claims, demands, waivers and other communications hereunder will be in writing and will be deemed to have been given: (i) when delivered by hand (with written confirmation of receipt); (ii) when received by the addressee if sent by a nationally recognized overnight courier (receipt requested); (iii) on the date sent by facsimile or e-mail of a PDF document (with confirmation of transmission) if sent during normal business hours of the recipient, and on the next business day if sent after normal business hours of the recipient; or (iv) on the third day after the date mailed, by certified or registered mail, return receipt requested, postage prepaid. Such communications must be sent to the respective parties at the addresses set forth on the Order (or to such other address as may be designated by a party from time to time in accordance with this Section 18(c)).

       (d) This Agreement (including the Order) and all other documents that are incorporated by reference herein, constitutes the sole and entire agreement between Customer and LogZilla with respect to the subject matter contained herein, and supersedes all prior and contemporaneous understandings, agreements, representations and warranties, both written and oral, with respect to such subject matter. In the event of a conflict between the terms in the body of this Agreement and the Order, the terms of this Agreement will prevail. Any preprinted or other terms on an Order (including any purchase order) or other correspondence that are in addition to or conflict with this Agreement are hereby rejected. If LogZilla provides you with a new version of the Software with a new agreement, then the new agreement will supersede the terms of this Agreement if Customer uses such new version of the Software.

       (e) Customer will not assign or otherwise transfer any of its rights, or delegate or otherwise transfer any of its obligations or performance, under this Agreement, in each case whether voluntarily, involuntarily, by operation of law, merger, a sale of all or substantially all of Customer's assets, business reorganization or otherwise, without LogZilla's prior written consent. Any purported assignment, delegation or transfer in violation of this Section 18(e) is void. LogZilla may freely assign or otherwise transfer all or any of its rights, or delegate or otherwise transfer all or any of its obligations or performance, under this Agreement without Customer's consent. This Agreement is binding upon and inures to the benefit of the parties hereto and their respective permitted successors and assigns.

       (f) This Agreement is for the sole benefit of the parties hereto and their respective successors and permitted assigns and nothing herein, express or implied, is intended to or will confer on any other Person any legal or equitable right, benefit or remedy of any nature whatsoever under or by reason of this Agreement.
	
       (g) This Agreement may only be amended, modified or supplemented by an agreement in writing signed by each party hereto. No waiver by any party of any of the provisions hereof will be effective unless explicitly set forth in writing and signed by the party so waiving.

       (h) If any term or provision of this Agreement is invalid, illegal or unenforceable in any jurisdiction, such invalidity, illegality or unenforceability will not affect any other term or provision of this Agreement or invalidate or render unenforceable such term or provision in any other jurisdiction.

       (i) This Agreement will be construed without regard to any presumption or rule requiring construction or interpretation against the party drafting an instrument or causing any instrument to be drafted. The Order referred to herein will be construed with, and as an integral part of, this Agreement to the same extent as if they were set forth verbatim herein.

       (j) The headings in this Agreement are for reference only and will not affect the interpretation of this Agreement.

       (k) The following Sections survive termination of this Agreement: 1, 4, 5, 6, 9, 10, 11, 12, 13, 14, 15, 16, 17, and 18.

       (l) The waiver of a breach of any provision of this Agreement will not operate or be interpreted as a waiver of any other or subsequent breach.
EOF
      print "Do you accept the LogZilla License Terms? (yes/no)";
      chomp( my $input = <STDIN> );
      if ( $input !~ /[Yy]/ ) {
          print "Please try again when you are ready to accept.\n";
          exit 1;
      }
  }
