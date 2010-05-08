#!/usr/bin/perl 

#
# db_insert.pl
# Last updated on 2010-05-07
#
# Developed by Clayton Dukes <cdukes@cdukes.com>
# Copyright (c) 2009 LogZilla, LLC
# All rights reserved.
#
# This script is used to parse incoming syslog-ng messages. 
# There is no disadvantage to using this script unless you need to insert 
# more than 20,000 messages per second into the database (the current bottleneck for this script)
# There are, however MANY advantages.

# When using this script, it will:
# 1. Read settings from both a file (to get DB user and pass) and the DB itself for other settings
# 2. Provide enhanced logging options through a config file so that debug can be enabled without a restart (not implemented yet)
# 3. Accept tokenized strings from syslog-ng PIPE call (not a file)
# 4. Parse the string to calculate the facility and severity codes from the incoming PRI code.
# 5. Parse the Mnemonic field from the message
# 6. Convert the PRG and MNE to a CRC32 integer field (this allows much better storage into the DB)
# 7. Create a loop for incoming messages to:
#   a: Compare the incoming message to all current messages in the database using a Levenshtein algorithim.
#   a2: Incoming matches should be from the same host, with the same PRI and PRG and must match within a configurable window of time and a configurable match of likeness (distance in Levenshtein terminology).
#   b. If a match is found, update the current row in the database with a new counter (counter + 1) and last occurrence and throw away the incoming PIPE message that was matched.
#   c. if no match was found, insert a new record.
# 8. While all this is being done, maintain a cache of the PRG's and MNE's so that no unnecessary inserts are avoided (if a duplicate exists, don't insert a new record for that table).
# 9. While all this is done, also keep track of the number of messages per second, per hour, per week, etc. and update the appropriate cache tables in the database with those numbers.
# 10. Allow for regex pattern match cleanups for incoming messages (an example is around lines 440-445 of the current script)
# That's a summary off the top of my head, there may be more :-)


# Changelog:
# 2009-05-28 - created
# 2009-09-11 - added a fork to child process to stop I/O blocking which was causing high CPU when dedup was enabled
# 2009-09-14 - Changed re_pipe to allow for missing prg fields
#			 - Replaced the incoming date and time with the machine's date and time since not everyone uses NTP
# 2009-10-09 - Added command line parameters to allow better control when testing
# 2010-10-10 - Updated to work with LogZilla v3.0
# 2010-02-23 - Added str2hex conversion - all messages are now stored into the db as HEX.
# 2010-03-01 - Removed str2hex, unfortunately, while db queries were faster, searching would 
#              only allow for case-sensitive searches and no regex.
# 2010-04-04 - Removed forking and added load data infile (now able to process spikes up to ~12kmps)
# 2010-04-12 - Fixed issue with 1s granularity
# 2010-04-14 - REMOVED Tail::File and daemonize. Calling db_insert.pl directly from syslog-ng provided much better insert rates (now at 20kmps)
# 2010-04-20 - Replaced re_pipe with better fields from syslog-ng (only need host, pri, ts, prg and msg)
# 2010-04-29 - Added regex for Snare windows events
#


use strict;
use POSIX qw/strftime/;
use DBI;
use Text::LevenshteinXS qw(distance);
use File::Spec;
use File::Basename;
use String::CRC32;


$| = 1;

#
# Declare variables to use
#
use vars qw/ %opt /;

# Set command line vars
my ($debug, $config, $logfile, $verbose, $dbh, $selftest, $qsize);

#
# Command line options processing
#
sub init()
{
    use Getopt::Std;
    my $opt_string = 'hd:c:l:svq:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
    $debug = defined($opt{'d'}) ? $opt{'d'} : '0';
    $logfile = $opt{'l'} if $opt{'l'};
    $verbose = $opt{'v'} if $opt{'v'};
    $qsize = $opt{'q'} if $opt{'q'};
    $selftest = $opt{'s'} if $opt{'s'};
    $config = defined($opt{'c'}) ? $opt{'c'} : "/path_to_logzilla/html/config/config.php";
}

init();

#
# Help message
#
sub usage()
{
    print STDERR << "EOF";
This program is used to process incoming syslog messages from a file.
    usage: $0 [-hdvlcs] 
    -h        : this (help) message
    -d        : debug level (0-5) (0 = disabled [default])
    -v        : Also print results to STDOUT
    -l        : log file (default used from config.php if not set here)
    -c        : config file (overrides the default config.php file location set in the '\$config' variable in this script)
    example: $0 -l /var/log/foo.log -d 5 -c /path_to_logzilla/html/config/config.php -v -t /var/log/syslog

    -s        : **Special Option**: 
            This option may be used to run a self test
            You can run a self  test by typing:
            $0 -s -c /path_to_logzilla/html/config/config.php (replace with the path to your config)
EOF
    exit;
}
if (! -f $config) {
    print STDOUT "Can't open config file \"$config\" : $!\nTry $0 -h\n"; 
    exit;
} 
open( CONFIG, $config );
my @config = <CONFIG>; 
close( CONFIG );

my($dbtable,$dbuser,$dbpass,$db,$dbhost,$dbport,$DEBUG,$dedup,$dedup_window,$dedup_dist,$log_path,$bulk_ins,$insert_string,@msgs, $q_time, $q_limit);
foreach my $var (@config) {
    next unless $var =~ /DEFINE/; # read only def's
    $dbuser = $1 if ($var =~ /'DBADMIN', '(\w+)'/);
    $dbpass = $1 if ($var =~ /'DBADMINPW', '(\w+)'/);
    $db = $1 if ($var =~ /'DBNAME', '(\w+)'/);
    $dbhost = $1 if ($var =~ /'DBHOST', '(\w+.*|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'/);
    $dbport = $1 if ($var =~ /'DBPORT', '(\w+)'/);
}
if (!$db){
    print "Error: Unable to read $db config variables from $config\n";
    exit;
}
$dbh = DBI->connect( "DBI:mysql:$db:$dbhost", $dbuser, $dbpass );
if (!$dbh) {
    print LOG "Can't connect to $db database: ", $DBI::errstr, "\n";
    print STDOUT "Can't connect to $db database: ", $DBI::errstr, "\n";
    exit;
}
my $sth = $dbh->prepare("SELECT name,value FROM settings");
$sth->execute();
if ($sth->errstr()) {
    print LOG "FATAL: Unable to execute SQL statement: ", $sth->errstr(), "\n";
    print STDOUT "FATAL: Unable to execute SQL statement: ", $sth->errstr(), "\n";
    exit;
}
while (my @settings = $sth->fetchrow_array()) {
    $dbtable = $settings[1] if ($settings[0] =~ /^TBL_MAIN$/);
    $DEBUG = $settings[1] if ($settings[0] =~ /^DEBUG$/);
    $dedup = $settings[1] if ($settings[0] =~ /^DEDUP$/);
    $dedup_window = $settings[1] if ($settings[0] =~ /^DEDUP_WINDOW$/);
    $dedup_dist = $settings[1] if ($settings[0] =~ /^DEDUP_DIST$/);
    $log_path = $settings[1] if ($settings[0] =~ /^PATH_LOGS$/);
    $q_time = $settings[1] if ($settings[0] =~ /^Q_TIME$/);
    $q_limit = $settings[1] if ($settings[0] =~ /^Q_LIMIT$/);
}

# If debug is set in the settings table, then increment debug to at least 1
if ($DEBUG > "0") {
    $debug = $debug + $DEBUG;
}


# Initialize some vars for later use
my $insert = 1;
my ($distance,$datetime_now,$datetime_past,$fo);
my (@rows, @fos, @inserts);
my $counter = 1;
my $datetime = strftime("%Y-%m-%d %H:%M:%S", localtime);
my $message;
$logfile = "$log_path/".basename($0, ".pl").".log" if not ($logfile);
my $file_path = File::Spec->rel2abs($0);

mkdir $log_path;
if (! -d $log_path) {
    print STDOUT "Failed to create $log_path: $!\n";
    exit;
}
open(LOG,">>$logfile");
if (! -f $logfile) {
    print STDOUT "Unable to open log file \"$logfile\" for writing...$!\n";
    exit;
}
select(LOG);
print LOG "\n$datetime\nStarting $logfile for $file_path at pid $$\n";
print LOG "Using Database: $db\n";
print STDOUT "\n$datetime\nStarting $logfile for $file_path at pid $$\n" if (($debug > 0) and ($verbose));
print STDOUT "Using Database: $db\n" if (($debug > 0) and ($verbose));

if (($debug > 0) or ($verbose)) { 
    print STDOUT "Debug level: $debug\n";
    print STDOUT "Table: $dbtable\n";
    print STDOUT "Adminuser: $dbuser\n";
    print STDOUT "PW: $dbpass\n";
    print STDOUT "DB: $db\n";
    print STDOUT "DB Host: $dbhost\n";
    print STDOUT "DB Port: $dbport\n";
    print STDOUT "Deduplication Feature = $dedup\n";
    print STDOUT "Logging results to $logfile\n";
    print STDOUT "Printing results to screen (STDOUT)\n" if (($debug > 0) and ($verbose));
}

my ($host, %host_cache, $facility, $pri, $prg, %program_cache, $prg32, $msg, $mne, %mne_cache, $mne32, $severity); 
my $re_pipe = qr/(\S+)\t(\d+)\t(\S+)\t(.*)/;
# v3.0 Fields are: Host, PRI, Program,  and MSG
# the $severity and $facility fields are split from the $pri coming in so that they can be stored as integers into 2 separate db columns
# re_mne is used to capture Cisco Mnemonics
my $re_mne = qr/%(\w+-.*\d-\w+)\s?:?/;

$dbh->disconnect();
$dbh = DBI->connect( "DBI:mysql:$db:$dbhost", $dbuser, $dbpass );
if (!$dbh) {
    print LOG "Can't connect to $db database: ", $DBI::errstr, "\n";
    print STDOUT "Can't connect to $db database: ", $DBI::errstr, "\n";
    exit;
}
my $db_select = $dbh->prepare("SELECT id,msg FROM $dbtable WHERE host=? AND facility=? AND severity=? AND program=? AND fo BETWEEN ? AND ?");
my $db_select_id = $dbh->prepare("SELECT counter,fo,lo FROM $dbtable WHERE id=?");
my $db_update = $dbh->prepare("UPDATE $dbtable SET counter=?, fo=?, lo=? WHERE id=?");
my $db_del = $dbh->prepare("DELETE FROM $dbtable WHERE id=?");
my $db_insert = $dbh->prepare("INSERT INTO $dbtable (host,facility,severity,program,msg,mne,fo,lo) VALUES (?,?,?,?,?,?,?,?)");
my $db_insert_prg = $dbh->prepare("INSERT IGNORE INTO programs (name,crc) VALUES (?,?) ");
my $db_insert_mne = $dbh->prepare("INSERT IGNORE INTO mne (name,crc) VALUES (?,?) ");
my $db_insert_host = $dbh->prepare("INSERT IGNORE INTO hosts (host) VALUES (?) ");
my $dumpfile = "/dev/shm/infile.txt";
my $sql = qq{LOAD DATA LOCAL INFILE '$dumpfile' INTO TABLE logs FIELDS TERMINATED BY "\\t" LINES TERMINATED BY "\\n" (host,facility,severity,program,msg,mne,fo,lo)};
my $db_insert_mpX = $dbh->prepare("REPLACE INTO cache (name,value,updatetime) VALUES (?,?,?)");
my $db_insert_sum = $dbh->prepare("INSERT INTO cache (name,value,updatetime) VALUES ('msg_sum',?,?) ON DUPLICATE KEY UPDATE value=value + ?");
my $db_load = $dbh->prepare("$sql");
my $queue;
my @dumparr;

my $start_time = (time);
my $end_time;
my $time_limit = ($start_time + $q_time);
my $mps_timer_start = $start_time;
my ($do_msg_mps, $mps, $tmp_mps, @mps, $sec);
my ($mpm, @mpm, $min);
my ($mph, @mph, $hr);
my ($mpd, @mpd, $day);
my $sumcount;
my $now;

open (DUMP, ">$dumpfile") or die "can't open $dumpfile: $!\n";
close (DUMP);
$db_load->{TraceLevel} = 4 if (($debug > 4) and ($verbose));
if ($selftest) {
    my $sth = $dbh->prepare("
        DELETE from $dbtable where host='dbins_testhost';
        ") or die "Could not delete old test results: $DBI::errstr";
    $sth->execute;
    my $cmd = "$0";
    $cmd .= " -d 3"; # Force debug on so test results are shown 
    $cmd .= " -c " . $opt{'c'} if $opt{'c'};
    $cmd .= " -l " . $opt{'l'} if $opt{'l'};
    $cmd .= " -v "; # Force verbose mode so results are printed to screen
    print STDOUT "\nPERFORMING SELF TEST USING COMMAND: $cmd\n\n";
    my $res = `printf "\n" | $cmd -q 1`;
    print STDOUT "Database Lookup (resulting message should be from Fred):\n";
    my $sth = $dbh->prepare("
        SELECT msg FROM $dbtable ORDER BY id DESC LIMIT 1;
        ") or die "Could not fetch last row: $DBI::errstr";
    $sth->execute;
    if (my $res = $sth->fetchrow_array() ) {
        print STDOUT "$res\n";
        print STDOUT "SELF TEST COMPLETE!\n";
    } else {
        print STDOUT "Test Failed\n";
    }
    exit;
}
if ($qsize) {
    $q_limit = $qsize;
}
# Pre-populate cache's with db values
my $prg_select = $dbh->prepare("SELECT * FROM programs");
$prg_select->execute();
while (my $ref = $prg_select->fetchrow_hashref()) {
    $program_cache{$ref->{'name'}} = $ref->{'crc'};
}
my $host_select = $dbh->prepare("SELECT * FROM hosts");
$host_select->execute();
while (my $ref = $host_select->fetchrow_hashref()) {
    $host_cache{$ref->{'host'}} = $ref->{'host'};
}
my $mne_select = $dbh->prepare("SELECT * FROM mne");
$mne_select->execute();
while (my $ref = $mne_select->fetchrow_hashref()) {
    $mne_cache{$ref->{'name'}} = $ref->{'crc'};
}
while (my $msg = <STDIN>) {
    chomp($msg);
    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
    print LOG "\n\n-=-=-=-=-=-=-=\nLOOP START: $now\n" if ($debug > 10);
    if ($qsize) {
        for (my $i=0; $i <= 5; $i++) {
            push (@dumparr, "dbins_testhost\t86\tdb_insert.pl\tdb_insert.pl[$$]: %SYS-5-CONFIG_I: Configured from 172.16.0.123 by Fred Flinstone <fred\@flinstone.com>\tSYS-5-CONFIG_I\t$datetime\t$datetime\t\n");
        }
    }
    $mps++;
    if (($#dumparr < $q_limit) && ($start_time <= $time_limit)) {
        push(@dumparr, do_msg($msg));
        print LOG "DEBUG: Pushing message into the array because either the size of the dumparr is < Q_limit or the start time <= time limit\n" if ($debug > 10);
        print LOG "DEBUG: Dump array size = ".$#dumparr."\n" if ($debug > 10);
        print LOG "DEBUG: Q Limit set to ".$q_limit."\n" if ($debug > 10);
        print LOG "DEBUG: Start Time was ".$start_time."\n" if ($debug > 10);
        print LOG "DEBUG: Time Limit set to ".$time_limit."\n" if ($debug > 10);
        $start_time = time;
        print LOG "DEBUG: *NEW* Start Time is ".$start_time."\n" if ($debug > 10);
    } else { 
        print LOG "DEBUG: Limit reached, processing queue\n" if ($debug > 10);
        if ($#dumparr >= 0 ) {
            if ($start_time >= $time_limit) {
                print STDOUT "\n\nQueue time limit reached ($q_time seconds)\n" if ($debug > 0) ;
                print LOG "\n\nQueue time limit reached ($q_time seconds)\n" if ($debug > 0);
            } else {
                my $t = ($end_time - $start_time);
                if ($t > 0) {
                    $tmp_mps = round($q_limit / $t);
                } else {
                    $tmp_mps = round($q_limit / 1);
                }
                print LOG "\n\nQueue Limit Reached: $q_limit messages in $t seconds ($tmp_mps MPS)\n" if ($debug > 0);
                print STDOUT "\n\nQueue Limit Reached: $q_limit messages in $t seconds ($tmp_mps MPS)\n" if ($debug > 0);
            }
            foreach my $var (@mps) {
                if ($var =~ m/(.*),(.*),(.*)/) {
                    $db_insert_mpX->execute("$1", "$2", "$3");
                    print STDOUT "Inserting MPS string: $1, $2, $3\n" if ($debug > 1);
                }
            }
            open (DUMP, ">$dumpfile") or die "can't open $dumpfile: $!\n";
            print LOG "Starting insert: " . strftime("%H:%M:%S", localtime) ."\n" if ($debug > 0);
            print STDOUT "Starting insert: " . strftime("%H:%M:%S", localtime) ."\n" if (($debug > 0) and ($verbose));
            print STDOUT "Importing $#dumparr messages into the database\n" if ($debug > 0);
            print LOG "Importing $#dumparr messages into the database\n" if ($debug > 0);
            print DUMP @dumparr;
            close (DUMP);
            $db_load->execute();
            if ($db_load->errstr()) {
                print STDOUT "FATAL: Unable to execute SQL statement: ", $db_load->errstr(), "\n" if ($debug > 0);
            }
            print LOG "Ending insert: " . strftime("%H:%M:%S", localtime) ."\n" if ($debug > 0);
            print STDOUT "Ending insert: " . strftime("%H:%M:%S", localtime) ."\n" if (($debug > 0) and ($verbose));
            @dumparr = ();
            $time_limit = ($start_time + $q_time);
        } else {
            push(@dumparr, do_msg($msg));
            print LOG "DEBUG: SHOULD NOT HIT THIS\nDEBUG:Dump array size = ".$#dumparr."\nDEBUG: Contents = " . @dumparr ."\n" if ($debug > 10);
            print LOG "DEBUG: Current Message is $msg\n" . @dumparr if ($debug > 10);
        }
    }
    my $mps_timer_end = (time);
    my $secs = ($mps_timer_end - $mps_timer_start);
    if ($secs > 0) {
        $mps = $mps + $do_msg_mps;
        $mps = ($mps/$secs);
        if ($mps < 1) {
            $mps = ($mps * $secs);
        }
        $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
        $day = strftime("%d", localtime);
        $hr = strftime("%H", localtime);
        $min = strftime("%M", localtime);
        $sec = strftime("%S", localtime);
        $mps = round($mps);
        print STDOUT "\n#######\nCurrent MPS = $mps ($do_msg_mps deduplicated)\n#######\n" if ($debug > 2);
        print LOG "\n#######\nCurrent MPS = $mps ($do_msg_mps deduplicated)\n#######\n" if ($debug > 2);
        $mpm += $mps;
        push(@mps, "chart_mps_$sec,$mps,$now");
        $db_insert_sum->{TraceLevel} = 4 if ($debug > 4);
        $db_insert_sum->execute($mps, $now, $mps);
        if ($#mps == 60) {
            my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
            push(@mpm, "chart_mpm_$min,$mpm,$now");
            $db_insert_mpX->{TraceLevel} = 4 if (($debug > 4) and ($verbose));
            $db_insert_mpX->execute("chart_mpm_$min", "$mpm", "$now");
            print STDOUT "Messages Per Minute = $mpm\n" if ($debug > 1);
            print LOG "Messages Per Minute = $mpm\n" if ($debug > 1);
            $mph += $mpm;
            $mpm = 0;
            @mps = ();
            my @hosts = keys %host_cache;
            foreach my $h (@hosts) {
                $db_insert_host->execute($h);
            }
            my @prgs = keys %program_cache;
            foreach my $p (@prgs) {
                $db_insert_prg->execute($p, $program_cache{$p});
            }
            my @mnes = keys %mne_cache;
            foreach my $m (@mnes) {
                $db_insert_mne->execute($m, $mne_cache{$m});
            }
            %host_cache = ();
            %program_cache = ();
            %mne_cache = ();
        }
        # Temp: exit after 5 minutes for testing
        #if ($#mpm == 5) {
        #print STDOUT "Test Exit\n";
        #exit;
        #}
        if ($#mpm == 60) {
            push(@mph, "chart_mph_$hr,$mph,$now");
            $db_insert_mpX->execute("chart_mph_$hr", "$mph", "$now");
            print STDOUT "Messages Per Hour = $mph\n" if ($debug > 1);
            print LOG "Messages Per Hour = $mph\n" if ($debug > 1);
            $mpd += $mph;
            $mph = 0;
            @mpm = ();
        }
        if ($#mph == 24) {
            push(@mpd, "chart_mpd_$day,$mpd,$now");
            $db_insert_mpX->execute("chart_mpd_$day", "$mpd", "$now");
            print STDOUT "Messages Per Day = $mpd\n" if ($debug > 1);
            print LOG "Messages Per Day = $mpd\n" if ($debug > 1);
            $mpd = 0;
            @mph = ();
        }
        $mps = 0;
        $do_msg_mps = 0;
        $mps_timer_start = (time);
    }
    $end_time = (time);
    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
    print LOG "LOOP END: $now\n-=-=-=-=-=-=-=-=-=\n" if ($debug > 10);
}

# Subs
sub round {
    my($number) = shift;
    return int($number + .5);
}
sub do_msg {
    $msg = shift;
    if (!$qsize) {
        print LOG "\n\nINCOMING MESSAGE:\n$msg\n" if ($debug > 0);
        print STDOUT "\n\nINCOMING MESSAGE:\n$msg\n" if (($debug > 2) and ($verbose));
    }

    # Get current date and time
    $datetime_now = strftime("%Y-%m-%d %H:%M:%S", localtime);

    # Get current date and time minus $dedup_window in seconds (5 minutes by default)
    $datetime_past = strftime("%Y-%m-%d %H:%M:%S", localtime(time - $dedup_window));

    # Get incoming variables from PIPE
    if ($msg =~ m/$re_pipe/) {
        # v3.0 Fields are: Host, PRI, Program,  and MSG
        $host = $1;
        $pri = $2;
        $facility = int($pri/8);
        $severity =  $pri - ($facility * 8 );
        $prg = $3;
        $msg = $4;
        # Handle Snare Format
        if ($prg =~ m/MSWinEventLog\\011.*\\011(.*)\\011.*\\011.*/) {
            my $facilityname = $1;
            if ($facilityname =~ m/^Application/) {
                $facility = 23;
            } elsif ($facilityname =~ m/^Security/) {
                $facility = 4;
            } elsif ($facilityname =~ m/^System/) {
                $facility = 3;
            } else {
                # Custom facility
                $facility = 16;
            }
            if ($msg =~ m/.*\\011(.*)\\011(.*)\\011(.*)\\011(.*)\\011(.*)\\011(.*)\\011(.*)\\011.*\\011(.*)\\011.*/) {
                my $eventid = $1;
                my $source = $2;
                my $username = $3;
                my $usertype = $4;
                my $type = $5;
                my $computer = $6;
                my $category = $7;
                my $description = $8;
                if ($debug > 1) {
                    print LOG "facility: $facilityname ($facility)\n";
                    print LOG "eventid: $eventid\n";
                    print LOG "source: $source\n";
                    print LOG "username: $username\n";
                    print LOG "usertype: $usertype\n";
                    print LOG "type: $type\n";
                    print LOG "computer: $computer\n";
                    print LOG "category: $category\n";
                    print LOG "description: $description\n";
                }
                if (($debug > 2) and ($verbose)) { 
                    print STDOUT "facility: $facilityname ($facility)\n";
                    print STDOUT "eventid: $eventid\n";
                    print STDOUT "source: $source\n";
                    print STDOUT "username: $username\n";
                    print STDOUT "type: $type\n";
                    print STDOUT "computer: $computer\n";
                    print STDOUT "category: $category\n";
                    print STDOUT "description: $description\n";
                }
                $prg = $source;
                $msg = "Log=".$facilityname.", Source=".$source.", Category=".$category.", Type=".$type.", EventID=".$eventid.", Username=".$username.", Usertype=".$usertype.", Computer=".$computer.", Description=".$description;
            }
        }
        $msg =~ s/\\//; # Some messages come in with a trailing slash
        #$msg =~ s/"|'//g; # Remove quotes so we don't screw up search filters later on.
        $msg =~ s/\t/ /g; # remove any TABs (gotta love windows...)
        # if ($msg =~ /%(\w+-.*\d-\w+):/) { # modified to below to catch some IOS-XR messages (which have a space before the colon)
        if ($msg =~ m/$re_mne/) {
            $mne = $1;
        } elsif ($prg =~ /$re_mne/) { # Attempt to capture ACE and ASA Mnemonics (they send the mne's as a program)
            $mne = $1;
        } else {
            $mne = "None";
        }
        $msg =~ s/[\x00-\x1F\x80-\xFF]//; # Remove any non-printable characters
        $prg =~ s/%ACE.*\d+/Cisco ACE/; # Added because ACE modules don't send their program field properly
        $prg =~ s/%ASA.*\d+/Cisco ASA/; # Added because ASA's don't send their program field properly
        $prg =~ s/%FWSM.*\d+/Cisco FWSM/; # Added because FWSM's don't send their program field properly
        $prg =~ s/date=\d+-\d+-\d+/Fortigate Firewall/; # Added because Fortigate's don't follow IETF standards
        $msg =~ s/time=\d+:\d+:\d+\s//; # Added because Fortigate's don't s follow IETF standards
        # @msgs = split(/:/, $msg);
        if ($prg =~ /^\d+/) { # Some messages come in with the sequence as the PROGRAM field
            $prg = "Cisco Syslog";
        }
        if (!$prg) {
            $prg = "Syslog";
        }
        # Added below to strip paths from program names so that just the program is listed
        # i.e.: /USR/SBIN/CRON would be inserted into the DB as just CRON
        if ($prg =~ /\//) { 
            $prg = fileparse($prg);
        }
        # Below is an attempt to grab the SEQ id 
        # Note: sequence numbers really are best effort
        # To enable sequence numbers on a cisco device, use "service sequence-numbers"
        # I may remove the SEQ field from the database altogether in future releases.
        #if ($msgs[0] =~ /^\d+/) { 
        #	$seq = $msgs[0];
        #}
        #$msg =~ s/^$seq\s?:\s?//; # Remove SEQ from the message if it exists
        #if ($seq !~ /\d/) {
        #	$seq = 0;
        #}
        $prg32 = crc32("$prg");
        $mne32 = crc32("$mne");
        unless ($host_cache{$host}){
            $host_cache{$host} = ($host);
        }
        unless ($mne_cache{$mne}){
            $mne_cache{$mne} = ($mne32);
        }
        unless ($program_cache{$prg}){
            $program_cache{$prg} = ($prg32);
        }
        if ($debug > 0) { 
            print LOG "HOST: $host\n";
            print LOG "PRI: $pri\n";
            print LOG "FAC: $facility\n";
            print LOG "SEV: $severity\n";
            print LOG "PRG: $prg\n";
            print LOG "MSG: $msg\n\n";
            print LOG "MNE: $mne\n\n";
        }
        if (($debug > 2) and ($verbose)) { 
            print STDOUT "HOST: $host\n";
            print STDOUT "PRI: $pri\n";
            print STDOUT "FAC: $facility\n";
            print STDOUT "SEV: $severity\n";
            print STDOUT "PRG: $prg\n";
            print STDOUT "MSG: $msg\n\n";
            print STDOUT "MNE: $mne\n\n";
        }
    } else {
        # If something gets inserted wrong from the PIPE we'll set host = blank so we can error out later
        $host = "";
        if (!$qsize) {
            print LOG "INVALID MESSAGE FORMAT:\n$msg\n" if ($debug > 0);
            print STDOUT "INVALID MESSAGE FORMAT:\n$msg\n" if (($debug > 0) and ($verbose));
        }
    }
    # If the SQZ feature is enabled, continue, if not we'll just insert the record afterward
    if($dedup eq 1) {
        $insert = 1;
        $db_select->{TraceLevel} = 4 if (($debug > 4) and ($verbose));
        # Select any records between now and $dedup_window seconds ago that match this host, facility, etc.
        $db_select->execute($host, $facility, $severity, $prg32, $datetime_past, $datetime_now);
        if ($db_select->errstr()) {
            print LOG "FATAL: Unable to execute SQL statement: ", $db_select->errstr(), "\n" if ($debug > 0);
            print STDOUT "FATAL: Unable to execute SQL statement: ", $db_select->errstr(), "\n";
            #exit;
        }

        # For each of the rows obtained above, calculate the likeness of messages using a distance measurement
        while (my $ref = $db_select->fetchrow_hashref()) {
            $distance = distance($ref->{'msg'},$msg);

            # If the distance between the two messages is less than $dedup_dist then we'll consider it a match and deduplicate the message
            if ($distance < $dedup_dist ) {
                # Store the identical record into an array for later processing
                push(@rows, $ref->{'id'});
                print LOG "A duplicate message was found with database id: ".$ref->{'id'}." having a distance of $distance\n" if ($debug > 3);
                print STDOUT "A duplicate message was found with database id: ".$ref->{'id'}." having a distance of $distance\n" if (($debug > 3) and ($verbose));
            }
        }
        # If rows matched above, we're now going to process them for deduplication
        my $numrows = scalar @rows;
        if ($numrows > 0) {
            print LOG "Found $numrows duplicate rows\n" if ($debug > 3);
            print STDOUT "Found $numrows duplicate rows\n" if (($debug > 3) and ($verbose));
            # Next, sort the row id's so that we know the oldest in order to update it later (we only want to update the oldest row and delete the newer ones that are duplicates)
            @rows = sort @rows; 
            # Set the first row as the update row and grab info
            my $update_id = $rows[0];
            $db_select_id->execute($update_id);
            while (my $ref = $db_select_id->fetchrow_hashref()) {
                $fo = $ref->{'fo'};
                # If FO doesn't exist, then set the current datetime instead.
                if (!$fo) { $fo = $datetime_now }
                push (@fos, $fo);
            }
            # Next, for each row found, we're going to select it and get some information such as the fo and counter
            for (my $i=0; $i <= $#rows; $i++) {
                print LOG "Processing rows:\n\tSource: $rows[0]\n\tCurrent: $rows[$i]\n" if ($debug > 3);
                print STDOUT "Processing rows:\n\tSource: $rows[0]\n\tCurrent: $rows[$i]\n" if (($debug > 3) and ($verbose));
                $db_select_id->execute($rows[$i]);
                while (my $ref = $db_select_id->fetchrow_hashref()) {
                    print LOG "Counter from DBID $rows[$i] = ".$ref->{'counter'}."\n" if ($debug > 3);
                    print STDOUT "Counter from DBID $rows[$i] = ".$ref->{'counter'}."\n" if (($debug > 3) and ($verbose));
                    $counter = ($counter + $ref->{'counter'});
                    print LOG "New Counter = $counter\n" if ($debug > 3);
                    print STDOUT "New Counter = $counter\n" if (($debug > 3) and ($verbose));
                }
                # Sort the arrays so that we get the first ones
                @fos = sort @fos; 
                $fo = $fos[0];
                # if the row returned is greater than 0 (i.e. not the FIRST record) then delete it as a duplicate.
                # Skip the first record (which will be the source ID)
                if ($rows[0] != $rows[$i]) {
                    print LOG "DELETING DB Record: $rows[$i] which is a duplicate record of $rows[0]\n" if ($debug > 3);
                    print STDOUT "DELETING DB Record: $rows[$i] which is a duplicate record of $rows[0]\n" if (($debug > 3) and ($verbose));
                    $db_del->execute($rows[$i]);
                }
                # Else, if the row returned is the FIRST record, we need to update it with new counter, fo and lo
                print LOG "UPDATING DB Record: $update_id with new counter and timestamps\n" if ($debug > 3);
                print STDOUT "UPDATING DB Record: $update_id with new counter and timestamps\n" if (($debug > 3) and ($verbose));
                $do_msg_mps++;
                $db_update->execute($counter,$fo,$datetime_now,$update_id);
            }
            # Since we've already done an update of the first record, we don't need to insert anything after this
            $insert = 0;
            # reset vars for new loop
            @rows =();
            @fos = ();
            $counter = 1;
        }
    }
    # Now that the distance test is over we need to insert any new records that either didn't previously exist or because we had the dedup feature disabled
    if ($insert != 0) {
        if ($host ne "")  {
            $queue = "$host\t$facility\t$severity\t$prg32\t$msg\t$mne32\t$datetime_now\t$datetime_now\t\n";
        } else {
            if (!$qsize) {
                $do_msg_mps++;
                print LOG "Error inserting record $msg\n" if ($debug > 3); 
                print STDOUT "Error inserting record $msg\n" if (($debug > 3) and ($verbose)); 
            }
        }
    } else {
        print LOG "insert = $insert, Skipping insert of this message since it was a duplicate\n" if ($debug > 3);
        print STDOUT "insert = $insert, Skipping insert of this message since it was a duplicate\n" if (($debug > 3) and ($verbose));
    }
    return $queue;
}
