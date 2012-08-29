#!/usr/bin/perl 

#
# db_insert
# Last updated on 2010-06-15
#
# Developed by Clayton Dukes <cdukes@logzilla.pro>
# Copyright (c) 2009 LogZilla, LLC
# All rights reserved.
#

use strict;
use POSIX qw/strftime/;
use DBI;
use File::Spec;
use File::Basename;
use String::CRC32;
use Date::Calc;
use MIME::Lite;
use Data::Dumper;
use Benchmark;
use CHI;
use Net::SNMP qw(:ALL);

$| = 1;

#
# Declare variables to use
#
use vars qw/ %opt /;

# Set command line vars
my ( $debug, $config, $logfile, $verbose, $dbh, $sleep );
my $start;
my $end;

#
# Command line options processing
#
sub init()
{
    use Getopt::Std;
    my $opt_string = 'hd:c:l:vs:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
    $debug = defined( $opt{'d'} ) ? $opt{'d'} : '0';
    $logfile = $opt{'l'} if $opt{'l'};
    $verbose = $opt{'v'} if $opt{'v'};
    $sleep   = $opt{'s'} if $opt{'s'};
    $config = defined( $opt{'c'} ) ? $opt{'c'} : "/path_to_logzilla/html/config/config.php";
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
EOF
    exit;
}
if ( !-f $config ) {
    print STDOUT "Can't open config file \"$config\" : $!\nTry $0 -h\n";
    exit;
}
open( CONFIG, $config );
my @config = <CONFIG>;
close(CONFIG);

my ( $dbtable, $dbuser, $dbpass, $db, $dbhost, $dbport, $DEBUG, $dedup, $dedup_window, $dedup_dist, $log_path, $bulk_ins, $insert_string, @msgs, $q_time, $q_limit, $snare, $snmp_sendtraps, $snmp_trapdest, $snmp_community );
foreach my $var (@config) {
    next unless $var =~ /DEFINE/;    # read only def's
    $db = $1 if ( $var =~ /'DBNAME', '(\w+)'/ );
}
if ( !$db ) {
    print "Error: Unable to read $db config variables from $config\n";
    exit;
}
my $dsn = "DBI:mysql:$db:;mysql_read_default_group=logzilla;"
  . "mysql_read_default_file=/path_to_logzilla/scripts/sql/lzmy.cnf";
$dbh = DBI->connect( $dsn, $dbuser, $dbpass );

#$dbh = DBI->connect( "DBI:mysql:$db:$dbhost;mysql_read_default_group=logzilla;", $dbuser, $dbpass );
if ( !$dbh ) {
    print LOG "Can't connect to database: ",    $DBI::errstr, "\n";
    print STDOUT "Can't connect to database: ", $DBI::errstr, "\n";
    exit;
}
my $sth = $dbh->prepare("SELECT name,value FROM settings");
$sth->execute();
if ( $sth->errstr() ) {
    print LOG "FATAL: Unable to execute SQL statement: ", $sth->errstr(), "\n";
    print STDOUT "FATAL: Unable to execute SQL statement: ", $sth->errstr(), "\n";
    exit;
}
while ( my @settings = $sth->fetchrow_array() ) {
    $dbtable        = $settings[1] if ( $settings[0] =~ /^TBL_MAIN$/ );
    $DEBUG          = $settings[1] if ( $settings[0] =~ /^DEBUG$/ );
    $dedup          = $settings[1] if ( $settings[0] =~ /^DEDUP$/ );
    $dedup_window   = $settings[1] if ( $settings[0] =~ /^DEDUP_WINDOW$/ );
    $dedup_dist     = $settings[1] if ( $settings[0] =~ /^DEDUP_DIST$/ );
    $log_path       = $settings[1] if ( $settings[0] =~ /^PATH_LOGS$/ );
    $q_time         = $settings[1] if ( $settings[0] =~ /^Q_TIME$/ );
    $q_limit        = $settings[1] if ( $settings[0] =~ /^Q_LIMIT$/ );
    $snare          = $settings[1] if ( $settings[0] =~ /^SNARE$/ );
    $snmp_sendtraps = $settings[1] if ( $settings[0] =~ /^SNMP_SENDTRAPS$/ );
    $snmp_trapdest  = $settings[1] if ( $settings[0] =~ /^SNMP_TRAPDEST$/ );
    $snmp_community = $settings[1] if ( $settings[0] =~ /^SNMP_COMMUNITY$/ );
}
my $cache = CHI->new( driver => 'RawMemory', global => 1, memoize_cache_objects => 1 );

# cdukes: 2012-03-02 Added makepart on script startup to just try and create a missing partition rather than waiting for the error.
makepart();
$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 1;
$dbh->do("DELETE from cache where name LIKE 'chart_mps_%'");
if ( $snare != 1 ) { $snare = 0; }

# cdukes: 2010-06-07: Manually set q_time and q_limit for testing
#$q_time = 15;
#$q_limit = 10;

# If debug is set in the settings table, then increment debug to at least 1
if ( $DEBUG > "0" ) {
    $debug = $debug + $DEBUG;
}

# Initialize some vars for later use
my $insert = 0;
my ( $distance, $datetime_now, $datetime_past, $fo, $update_id, $numrows, @duplicates );
my ( %dedup_rows, @fos, @inserts );
my $counter;
my $datetime = strftime( "%Y-%m-%d %H:%M:%S", localtime );
my $message;
$logfile = "$log_path/" . basename( $0, ".pl" ) . ".log" if not($logfile);
my $file_path = File::Spec->rel2abs($0);

mkdir $log_path;
if ( !-d $log_path ) {
    print STDOUT "Failed to create $log_path: $!\n";
    exit;
}
open LOG, ">>$logfile" or die $!;
{ my $fh = select LOG;
    $| = 1;
    select(LOG);
}
select(LOG);
print LOG "\n$datetime\nStarting $logfile for $file_path at pid $$\n";
print LOG "Debug level: $debug\n";
print LOG "DB: $db\n";
print LOG "Deduplication Feature = $dedup\n";
print LOG "Snare Enabled\n" if ( $snare > 0 );
print STDOUT "\n$datetime\nStarting $logfile for $file_path at pid $$\n" if ( ( $debug > 0 ) and ($verbose) );
print STDOUT "Using Database: $db\n" if ( ( $debug > 0 ) and ($verbose) );

if ( ( $debug > 0 ) or ($verbose) ) {
    print STDOUT "Debug level: $debug\n";
    print STDOUT "DB: $db\n";
    print STDOUT "Deduplication Feature = $dedup\n";
    print STDOUT "Logging results to $logfile\n" if ( $debug > 1 );
    print STDOUT "Printing results to screen (STDOUT)\n" if ( ( $debug > 0 ) and ($verbose) );
    print STDOUT "Snare Enabled\n" if ( $snare > 0 );
    print STDOUT "\n\n";
}

my ( $ts, $host, $facility, $pri, $prg, $msg, $mne, $severity, $eid );

# my $re_pipe = qr/(\S+)\t(\d+)\t(\S+)?\t(.*)/;
my $re_pipe = qr/(\S+ \S+)\t(\S+)\t(\d+)\t(\S+)?.*\t(.*)/;

# v3.2 Fields are: TS, Host, PRI, Program,  and MSG
# the $severity and $facility fields are split from the $pri coming in so that they can be stored as integers into 2 separate db columns
# re_mne is used to capture Cisco Mnemonics
my $re_mne = qr/\%([A-Z\-\d\_]+?\-\d+\-[A-Z\-\_\d]+?)(?:\:|\s)/;
my $re_mne_prg = qr/%(\w+-\d+-\S+):?/; # Attempt to capture Cisco Firewall Mnemonics (they send the mne's as a program)
my $re_ossec = qr/Alert.*?Location: \((.*?)\) ([\d\.]+)/; # OSSEC sends the originating host as part of the message
my $re_alnum = qr/[^[:alnum:]]/;

$dbh->disconnect();
$dbh = DBI->connect( $dsn, $dbuser, $dbpass );

if ( !$dbh ) {
    print LOG "Can't connect to $db database: ",    $DBI::errstr, "\n";
    print STDOUT "Can't connect to $db database: ", $DBI::errstr, "\n";
    exit;
}

#my $dumpfile = "/dev/shm/infile.txt";
my $dumpfile = "/tmp/logzilla_import.txt";

# See ticket #117 regarding non-local databases and auto-partitioning
my $infile_prep = qq{LOAD DATA INFILE '$dumpfile' INTO TABLE $dbtable FIELDS TERMINATED BY "\\t" LINES TERMINATED BY "\\n" (host,facility,severity,program,msg,mne,eid,fo,lo)};
my $db_load_infile = $dbh->prepare("$infile_prep");

my $queue;
my @dumparr;

my $looptime   = (time);
my $start_time = (time);
my $end_time;
my $time_limit = ( time + $q_time );
my $mps_timer  = (time);
my $mpm_timer  = (time);
my $mph_timer  = (time);
my $mpd_timer  = (time);
my ( $tmp_mps, @mps, $sec );
my ( $mpm,     @mpm, $min );
my ( $mph,     @mph, $hr );
my ( $mpd,     @mpd, $day );
my $sumcount;
my $now;

my $tmp = ( $start_time - 1 );
my $upd_logs = $dbh->prepare("UPDATE $dbtable SET counter=counter+?, lo=NOW() WHERE host=? AND msg=? AND fo>NOW() - INTERVAL $dedup_window SECOND AND fo>=FROM_UNIXTIME($tmp)");
my $insert_host = $dbh->prepare("INSERT INTO hosts (host, lastseen, seen) VALUES (?,NOW(),?) ON DUPLICATE KEY UPDATE lastseen=NOW(), seen=seen+?");
my $insert_prg = $dbh->prepare("INSERT INTO programs (name, crc, lastseen, seen) VALUES (?,?,NOW(),?) ON DUPLICATE KEY UPDATE lastseen=NOW(), seen=seen+?");
my $insert_mne = $dbh->prepare("INSERT INTO mne (name, crc, lastseen, seen) VALUES (?,?,NOW(),?) ON DUPLICATE KEY UPDATE lastseen=NOW(), seen=seen+?");
my $insert_eid = $dbh->prepare("INSERT INTO snare_eid (eid, lastseen, seen) VALUES (?,NOW(),?) ON DUPLICATE KEY UPDATE lastseen=NOW(), seen=seen+?");
my $db_insert_mpX = $dbh->prepare("REPLACE INTO cache (name,value,updatetime) VALUES (?,?,NOW())");
my $update_mpX = $dbh->prepare("REPLACE INTO cache (name,value,updatetime) VALUES (?,?,NOW())");
my $last_id = $dbh->prepare("REPLACE INTO cache (name,value,updatetime) VALUES ('max_id',LAST_INSERT_ID(),NOW())");
my $sum = $dbh->prepare("INSERT INTO cache (name,value,updatetime) VALUES ('msg_sum',?,NOW()) ON DUPLICATE KEY UPDATE value=value + ?");
$insert_host->{TraceLevel}   = $debug if ( ($debug) and ($verbose) );
$insert_prg->{TraceLevel}    = $debug if ( ($debug) and ($verbose) );
$insert_mne->{TraceLevel}    = $debug if ( ($debug) and ($verbose) );
$insert_eid->{TraceLevel}    = $debug if ( ($debug) and ($verbose) );
$db_insert_mpX->{TraceLevel} = $debug if ( ($debug) and ($verbose) );
$update_mpX->{TraceLevel}    = $debug if ( ($debug) and ($verbose) );
$sum->{TraceLevel}           = $debug if ( ($debug) and ($verbose) );

open( DUMP, ">$dumpfile" ) or die "can't open $dumpfile: $!\n";
close(DUMP);
my $mode = 0644; chmod $mode, "$dumpfile";

# SNMP Forwarding
sub trap {
    my $msg         = shift;
    my $pattern     = shift;
    my @trapdests   = split( /,/, $snmp_trapdest );
    my @communities = split( /,/, $snmp_community );
    print STDOUT "Sending SNMP Trap for pattern match on /$pattern/, message was '$msg'\n" if ($verbose);
    foreach my $dest (@trapdests) {
        print STDOUT "dest = $dest\n" if ($verbose);
        foreach my $community (@communities) {
            print STDOUT "comm = $community\n" if ($verbose);
            my ( $session, $error ) = Net::SNMP->session(
                -hostname  => $dest,
                -community => $community,
                -port      => SNMP_TRAP_PORT,
            );

            if ( !defined($session) ) {
                printf LOG ( "SNMP ERROR: %s.\n", $error );
                printf STDOUT ( "SNMP ERROR: %s.\n", $error ) if ($verbose);
                exit 1;
            }

            my $result = $session->trap(
                -enterprise   => '1.3.6.1.4.1.31337',
                -generictrap  => 6,
                -specifictrap => 1,
                -varbindlist  => [
                '1.3.6.1.4.1.31337.1.1', OCTET_STRING, "Original Message = $msg",
                '1.3.6.1.4.1.31337.1.2', OCTET_STRING, "Matched Pattern = $pattern"
                ]
            );
            unless ($result) { print STDOUT "SNMP ERROR: $session->error" }
            $session->close();
        }
    }
    exit;

}

# Begin Alert Triggers
my ( $from, $to, $subj, %trigger_cache );
my $trigger_select = $dbh->prepare("SELECT * FROM triggers WHERE disabled='No'");
$trigger_select->execute();
while ( my $ref = $trigger_select->fetchrow_hashref() ) {

      # stripslashes from stored patterns
      $ref->{'pattern'} =~ s/\\(\'|\"|\\)/$1/g;
      $trigger_cache{ $ref->{'id'} } = $ref->{'pattern'};
}

sub triggerMail {
      my $id   = shift;
      my $host = shift;
      my $msg  = shift;
      my ( $dbid, $description, $pattern, $to, $from, $subject, $body, undef ) = $dbh->selectrow_array("SELECT * FROM triggers WHERE id=$id");

      # stripslashes from pattern
      $pattern =~ s/\\(\'|\"|\\)/$1/g;
      if ( $snmp_sendtraps eq 1 ) {
          &trap( $msg, $pattern );
      }
      my ( $mailhost, $port, $user, $pass ) = $dbh->selectrow_array( "
        SELECT value FROM settings WHERE name like 'MAILHOST%'
        " );
      my @vars = ( $msg =~ /$pattern/ );
      foreach my $var (@vars) {
          $subject =~ s/\{\d+\}/$var/;
          $body    =~ s/\{\d+\}/$var/;
      }
      $subject = "[LogZilla Host $host]: $subject";
      if ($verbose) {
          print STDOUT "Verbose logging enabled - Mail Trigger found:\n";
          print STDOUT "Pattern = $pattern\n";
          print STDOUT "To = $to\n";
          print STDOUT "From = $from\n";
          print STDOUT "Subject = $subject\n";
          print STDOUT "Body = $body\n";
          print STDOUT "Message = $msg\n";
          print STDOUT "\n";
      }
      my $msg = MIME::Lite->new(
          From    => "$from",
          To      => "$to",
          Subject => "$subject",
          Type    => 'TEXT',
          Data    => "$body"
      );
      if ($verbose) {
          if ($user) {
              $msg->send( 'smtp', "$mailhost",
                  AuthUser => $user,
                  AuthPass => $pass,
                  Debug    => 1
              );
          } else {
              $msg->send( 'smtp', "$mailhost", Debug => 1 );
          }
      } else {
          if ($user) {
              $msg->send( 'smtp', "$mailhost",
                  AuthUser => $user,
                  AuthPass => $pass
              );
          } else {
              $msg->send( 'smtp', "$mailhost" );
          }
      }
}

# End Alert Triggers
$start = new Benchmark;
my $dupcount = 0;
my $msgcount = 0;
my $mps      = 0;
$eid = 0;
while ( my $msg = <STDIN> ) {
      $msgcount++;
      $mps++;
      my $data = do_msg($msg);
      if ( $data =~ /^DUPLICATE\t/ ) {
          ( undef, $host, $facility, $severity, $prg, $msg, $mne, $eid, $ts, undef ) = split( /\t/, $data );
          $dupcount++;
          if ( ( time > $start_time + 10 ) || ( $dupcount >= 5000 ) || ( eof() ) ) {
              print STDOUT "Updating DB after either 5000 duplicates or 10 seconds have passed (or end of file reached)\n" if ( ($debug) and ($verbose) );
              print STDOUT "Adding $dupcount duplicate messages for $host\n" if ( ($debug) and ($verbose) );
              $upd_logs->{TraceLevel} = $debug if ( ($debug) and ($verbose) );
              $upd_logs->execute( $dupcount, $host, $msg );
              $dupcount   = 0;
              $start_time = (time);
          }
      } else {
          ( $host, $facility, $severity, $prg, $msg, $mne, $eid, $ts, undef ) = split( /\t/, $data );

          push( @dumparr, "$host\t$facility\t$severity\t" . crc32($prg) . "\t$msg\t" . crc32($mne) . "\t$eid\t$ts\t$ts\n" );
          if ( $dedup eq 1 ) {

#print STDOUT "Dedup is enabled, but this is the first time we've seen it\n" if ($verbose);
              open( DUMP, ">$dumpfile" ) or die "can't open $dumpfile: $!\n";
              print DUMP @dumparr;
              undef(@dumparr);
              close(DUMP);
              $dbh->do("START TRANSACTION");
              $db_load_infile->execute();
              $dbh->do("COMMIT");
              $last_id->execute();
          }
      }

     # Only insert hosts, programs, mne's, eids ever 10 seconds or 1000 records.
     # May want to mess with these numbers on large systems
      if ( ( time >= $start_time + 10 ) || ( $msgcount % 1000 == 0 ) || ( eof() ) ) {
          if ( eof() ) {
              $mps = $msgcount;
          }
          $dbh->do("START TRANSACTION");
          $insert_host->execute( $host, $msgcount, $msgcount );
          $insert_prg->execute( $prg, crc32($prg), $msgcount, $msgcount );
          $insert_mne->execute( $mne, crc32($mne), $msgcount, $msgcount );
          $insert_eid->execute( $eid, $msgcount,   $msgcount );
          $sum->execute( $msgcount, $msgcount );
          $dbh->do("COMMIT");
          $msgcount = 0;
      }
      print LOG "\n\n-=-=-=-=-=-=-=\nLOOP START\n" if ( $debug > 10 );

      # if array is bigger than the q limit or the q time has passed
      if ( ( ( $#dumparr + 1 ) >= $q_limit ) || ( time >= $time_limit ) || eof() ) {
          if ($verbose) {
              if ( ( $#dumparr + 1 ) >= $q_limit ) {
                  print STDOUT "DEBUG: Limit of " . ( $#dumparr + 1 ) . " reached, processing queue\n";
              }
              if ( time > ( $time_limit - $q_time ) ) {
                  print STDOUT "DEBUG: Limit of " . ($q_time) . " seconds reached, processing queue\n";
              }
          }
          print STDOUT "DEBUG: Dump array size = " . ( $#dumparr + 1 ) . "\n" if ($verbose);
          print STDOUT "DEBUG: Q Limit set to " . $q_limit . "\n" if ($verbose);
          print STDOUT "DEBUG: Start Time was " . $start_time . "\n" if ($verbose);
          print STDOUT "DEBUG: Current Time is " . time . "\n" if ($verbose);
          print STDOUT "DEBUG: Time Limit set to " . $time_limit . "\n" if ($verbose);
          open( DUMP, ">$dumpfile" ) or die "can't open $dumpfile: $!\n";
          print STDOUT "Starting insert: " . strftime( "%H:%M:%S", localtime ) . "\n" if ( ($verbose) );
          print LOG "Starting insert: " . strftime( "%H:%M:%S", localtime ) . "\n" if ( $debug > 0 );
          print DUMP @dumparr;
          undef(@dumparr);
          close(DUMP);
          $dbh->do("START TRANSACTION");
          $db_load_infile->execute();
          $dbh->do("COMMIT");
          $last_id->execute();
          print STDOUT "Ending insert: " . strftime( "%H:%M:%S", localtime ) . "\n" if ($verbose);
          print LOG "Ending insert: " . strftime( "%H:%M:%S", localtime ) . "\n" if ( ( $debug > 0 ) and ($verbose) );
          $time_limit = ( time + $q_time );

          if ( ( time >= $mps_timer ) || ( eof() ) ) {
              $day = strftime( "%d", localtime );
              $hr  = strftime( "%H", localtime );
              $min = strftime( "%M", localtime );
              $sec = strftime( "%S", localtime );
              print STDOUT "\n#######\nCurrent MPS = $mps\n#######\n" if ($verbose);
              print LOG "\n#######\nCurrent MPS = $mps\n#######\n" if ( $debug > 2 );
              $update_mpX->execute( "chart_mps_$sec", $mps );
              $mpm += $mps;
              $mps       = 0;
              $mps_timer = time;
          }
          if ( time >= $mpm_timer + 60 ) {
              $db_insert_mpX->execute( "chart_mpm_$min", "$mpm" );
              print STDOUT "Messages Per Minute = $mpm\n" if ($verbose);
              print LOG "Messages Per Minute = $mpm\n" if ( $debug > 1 );
              $mph += $mpm;
              $mpm       = 0;
              $mpm_timer = time;
          }
          if ( time >= $mph_timer + 3600 ) {
              $db_insert_mpX->execute( "chart_mph_$hr", "$mph" );
              print STDOUT "Messages Per Hour = $mph\n" if ($verbose);
              print LOG "Messages Per Hour = $mph\n" if ( $debug > 1 );
              $mpd += $mph;
              $mph       = 0;
              $mph_timer = time;
          }

          if ( time >= $mpd_timer + 86400 ) {
              $db_insert_mpX->execute( "chart_mpd_$day", "$mpd" );
              print STDOUT "Messages Per Day = $mpd\n" if ($verbose);
              print LOG "Messages Per Day = $mpd\n" if ( $debug > 1 );
              $mpd       = 0;
              $mpd_timer = time;
          }

      } else {
          print LOG "DEBUG: Dump array size = " . $#dumparr . "\n" if ( $debug > 10 );
          print LOG "DEBUG: Q Limit set to " . $q_limit . "\n" if ( $debug > 10 );
          print LOG "DEBUG: Start Time was " . $start_time . "\n" if ( $debug > 10 );
          print LOG "DEBUG: Time Limit set to " . $time_limit . "\n" if ( $debug > 10 );
          print LOG "DEBUG: *NEW* Time Limit is " . $time_limit . "\n" if ( $debug > 10 );
      }
      $end_time = (time);
      print LOG "LOOP END\n-=-=-=-=-=-=-=-=-=\n" if ( $debug > 10 );
      $looptime = (time);
}
$end = new Benchmark;
my $diff = timediff( $end, $start );
print STDOUT "Time taken for entire loop was ", timestr( $diff, 'all' ), " seconds\n" if ($verbose);

# Subs

sub makepart {

      # Get some date values in order to create the MySQL Partition
      my ( $sec, $min, $hour, $curmday, $curmon, $curyear, $wday, $yday, $isdst ) = localtime time;
      $curyear = $curyear + 1900;
      $curmon  = $curmon + 1;
      my ( $year, $mon, $mday ) = Date::Calc::Add_Delta_Days( $curyear, $curmon, $curmday, 1 );
      my $pAdd = "p" . $curyear . sprintf( "%02d", $curmon ) . sprintf( "%02d", $mday );
      my $dateTomorrow = $year . "-" . sprintf( "%02d", $mon ) . "-" . sprintf( "%02d", $mday );
      my $sql = ("ALTER TABLE logs CHECK PARTITION $pAdd");
      my $sql = ("SELECT PARTITION_NAME FROM information_schema.partitions WHERE table_name ='$dbtable' and PARTITION_NAME='$pAdd'");
      my (@row) = $dbh->selectrow_array("$sql");

      if ( $row[0] ne "$pAdd" ) {
          print STDOUT "Missing Partition Detected: $row[3]\n";
          my $sth = $dbh->prepare( "
            ALTER TABLE $dbtable ADD PARTITION (PARTITION $pAdd VALUES LESS THAN (to_days('$dateTomorrow')))
            " );
          $sth->execute;
          print STDOUT "Auto-creating missing partition for $dateTomorrow\n";
          print LOG "Auto-creating missing partition for $dateTomorrow\n";
      }
}

sub do_msg {
      $msg = shift;
      my $omsg = $msg;
my $char_fr="ÀÂÄÆÈÊÌÎÐÒÔÖÙÛÝßáäçêíðôùþÿ";
my $char_en="AAAAAAACEEEEIIIIDNOOOOOOUUUUYPSaaaaaaaceeeeiiiionoooooouuuuyby";
          $msg =~ s/$char_fr/$char_en/;      # Some messages come in with a trailing slash
      my $win = "";
      my $eid = "";
      my $facilityname = "";
      print LOG "\n\nINCOMING MESSAGE:\n$msg\n" if ( $debug > 0 );
      print STDOUT "\n\nINCOMING MESSAGE:\n$msg\n" if ( ( $debug > 2 ) and ($verbose) );
          if ( $omsg =~ m/MSWinEventLog.+?(Security|Application|System).+?/ ) {
              $win = "MSWinEventLog";
              $facilityname = "$1";
              $eid = $1 if (( $omsg =~ m/201\d(\d+)$facilityname/ ) || ( $omsg =~ m/\d+:\d+:\d+\s+201\d(\d+)/ ) || ( $omsg =~ m/\d+:\d+:\d+ 20\d+\\011(\d+)\\011/ ));
              #$msg = $1 if ( $omsg =~ m/20\d+$facilityname(.*)/ );
          }

      # Get incoming variables from PIPE
      if ( $msg =~ m/$re_pipe/ ) {

          # v3.2 Fields are: TS, Host, PRI, Program,  and MSG
          $ts       = $1;
          $host     = $2;
          $pri      = $3;
          $facility = int( $pri / 8 );
          $severity = $pri - ( $facility * 8 );
          $prg      = $4;
          $msg      = $5;
          $prg      = "Cisco ASA" if ( $msg =~ /^%PIX/ );
          if ( $msg =~ /$re_ossec/ ) {
              $host = $1;
              $prg  = "OSSEC Security";
          }

          # Handle Snare Format
          $prg = $win if ($win ne "");
          if ( $prg eq $win ) {
              if ( $facilityname =~ m/^Application/ ) {
                  $facility = 23;
              } elsif ( $facilityname =~ m/^Security/ ) {
                  $facility = 4;
              } elsif ( $facilityname =~ m/^System/ ) {
                  $facility = 3;
              } else {
                  # Custom facility
                  $facility = 16;
              }
              if ( $msg =~ m/.*\\011(.*)\\011(.*)\\011(.*)\\011(.*)\\011(.*)\\011(.*)\\011(.*)\\011.*\\011(.*)\\011.*/ ) {
                #$eid = $1 if ( $eid = "" );
                  my $source      = $2;
                  my $username    = $3;
                  my $usertype    = $4;
                  my $type        = $5;
                  my $computer    = $6;
                  my $category    = $7;
                  my $description = $8;
                  if ( $debug > 1 ) {
                      print LOG "facility: $facilityname ($facility)\n";
                      print LOG "eventid: $eid\n";
                      print LOG "source: $source\n";
                      print LOG "username: $username\n";
                      print LOG "usertype: $usertype\n";
                      print LOG "type: $type\n";
                      print LOG "computer: $computer\n";
                      print LOG "category: $category\n";
                      print LOG "description: $description\n";
                  }
                  if ( ( $debug > 2 ) and ($verbose) ) {
                      print STDOUT "facility: $facilityname ($facility)\n";
                      print STDOUT "eventid: $eid\n";
                      print STDOUT "source: $source\n";
                      print STDOUT "username: $username\n";
                      print STDOUT "type: $type\n";
                      print STDOUT "computer: $computer\n";
                      print STDOUT "category: $category\n";
                      print STDOUT "description: $description\n";
                  }
                  $prg = $source;
                  $msg = "Log=" . $facilityname . ", Source=" . $source . ", Category=" . $category . ", Type=" . $type . ", EventID=" . $eid . ", Username=" . $username . ", Usertype=" . $usertype . ", Computer=" . $computer . ", Description=" . $description;
              }  
          }
          if ( $msg =~ /3Com_Firewall/ ) {
              $prg = "3Com Firewall";
              $msg =~ s/\[3Com_Firewall\]?\s(.*)/$1/;
          }
          $msg =~ s/\\//;      # Some messages come in with a trailing slash
          $msg =~ s/\t/ /g;    # remove any extra TABs
          $msg =~ s/\177/ /g; # Fix for NT Events Logs (they send 0x7f with the message)
                              # Mail Trigger
                              #my @triggers = keys %trigger_cache;
                              #print STDOUT "TRIGGERS:\n@triggers\n";
          while ( my ( $id, $pattern ) = each %trigger_cache ) {
              my $re = qr/$pattern/;
              print STDOUT "-----START EVENT TRIGGERS-----\nLooking for Pattern: \"$pattern\" in message \"$msg\"\n" if ( $debug > 4 );
              print LOG "-----START EVENT TRIGGERS-----\nLooking for Pattern: \"$pattern\" in message \"$msg\"\n" if ( $debug > 4 );
              if ( $msg =~ /$re/ ) {
                  print STDOUT "FOUND PATTERN '$pattern' in message: '$msg'\nSENDING EMAIL!\n-----END EVENT TRIGGERS-----\n\n" if ( $debug > 4 );
                  print LOG "FOUND PATTERN '$pattern' in message: '$msg'\nSENDING EMAIL!\n-----END EVENT TRIGGERS-----\n\n" if ( $debug > 4 );
                  &triggerMail( $id, $host, $msg );
              }
          }

          if ( $msg =~ /$re_mne/ ) {
              $mne = $1;
              $prg = "Cisco Syslog";
          } else {
              $mne = "None";
          }
          $mne = $1 if ( $prg =~ /$re_mne_prg/ ); # Cisco ASA's send their Mnemonic in the program field...
              # 2010-05-20: CDUKES - had to remove the non-printable filter below, it was killing German Umlauts.
              # $msg =~ s/[\x00-\x1F\x80-\xFF]//; # Remove any non-printable characters
          $prg =~ s/%ACE.*\d+/Cisco ACE/; # Added because ACE modules don't send their program field properly
          $prg =~ s/%ASA.*\d+/Cisco ASA/; # Added because ASA's don't send their program field properly
          $prg =~ s/%FWSM.*\d+/Cisco FWSM/; # Added because FWSM's don't send their program field properly
          $prg =~ s/date=\d+-\d+-\d+/Fortigate Firewall/; # Added because Fortigate's don't follow IETF standards
          $prg =~ s/:$//; # Strip trailing colon from some programs (such as kernel)
          $msg =~ s/time=\d+:\d+:\d+\s//; # Added because Fortigate's don't s follow IETF standards

          # Catch-All:
          $prg =~ s/^\d+$/Cisco Syslog/; # Cisco Messages send the program as an int string.
          if ( !$prg ) {
              $prg = "Syslog";
          }

# Added below to strip paths from program names so that just the program is listed
# i.e.: /USR/SBIN/CRON would be inserted into the DB as just CRON
          if ( $prg =~ /\// ) {
              $prg = fileparse($prg);
          }

        # Add filter for Juniper boxes - invalid mnemonics were being picked up.
          if ( $prg =~ /Juniper/ ) {
              $mne = "None";
          }

# Special fix (urldecode) for any urlencoded strings coming in from VmWare or Apache
          $prg =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
          if ( !$mne ) {
              $msg =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
          }

          # Added for Elion to catch ESX
          if ( $host =~ /esx\.vm\.est/ ) {
              $prg = "VMWare";
          }

          # Catch-all for junk streams...
          # This won't work well in non-english environments...
          # $prg = "Unknown" if ($prg !~ /^[\w\'-\s]+$/);
          $prg = 'Unknown' unless ( $prg =~ m{^[-'\w\s]{3,}$} and $prg =~ m{[A-Za-z]{3,}} );

          if ( $debug > 0 ) {
              print LOG "HOST: $host\n";
              print LOG "PRI: $pri\n";
              print LOG "FAC: $facility\n";
              print LOG "SEV: $severity\n";
              print LOG "PRG: $prg\n";
              print LOG "MSG: $msg\n";
              print LOG "MNE: $mne\n";
              if ( $snare > 0 ) {
                  print LOG "EID: $eid\n\n";
              }
          }
          if ( ( $debug > 2 ) and ($verbose) ) {
              print STDOUT "FACNAME:\t$facilityname\n";
              print STDOUT "HOST:\t$host\n";
              print STDOUT "PRI:\t$pri\n";
              print STDOUT "FAC:\t$facility\n";
              print STDOUT "SEV:\t$severity\n";
              print STDOUT "PRG:\t$prg\n";
              print STDOUT "MSG:\t$msg\n";
              print STDOUT "MNE:\t$mne\n";
              if ( $snare > 0 ) {
                  print STDOUT "EID:\t$eid\n\n";
              }
          }
      } else {
          print LOG "INVALID MESSAGE FORMAT:\n$msg\n" if ( $debug > 0 );
          print STDOUT "INVALID MESSAGE FORMAT:\n$msg\n" if ( ( $debug > 0 ) and ($verbose) );
          return undef;
      }

      if ( $dedup eq 1 ) {
          my $hash = crc32("$host$pri$msg");
          if ( !defined $cache->get($hash) ) {
              $cache->set( $hash, $hash, $dedup_window );
              $queue = "$host\t$facility\t$severity\t$prg\t$msg\t$mne\t$eid\t$ts\t$ts\t\n";
              return $queue;
          } else {
              $queue = "DUPLICATE\t$host\t$facility\t$severity\t$prg\t$msg\t$mne\t$eid\t$ts\t$ts\t\n";
              return $queue;
          }
      } else {
          $queue = "$host\t$facility\t$severity\t$prg\t$msg\t$mne\t$eid\t$ts\t$ts\t\n";
          return $queue;
      }
}
