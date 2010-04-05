#!/usr/bin/perl 

#
# db_insert.pl
#
# Developed by Clayton Dukes <cdukes@cdukes.com>
# Copyright (c) 2009 gdd.net
# All rights reserved.
#
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
# 2010-04-04 - Removed forking and added load data infile (now able to process spikes up to ~16kmps)
#


use strict;
use POSIX qw/strftime/;
use POSIX 'setsid';
use DBI;
use Text::LevenshteinXS qw(distance);
use File::Spec;
use File::Basename;
use File::Tail;
use Benchmark;
#use Benchmark::Stopwatch;


$| = 1;

#
# Declare variables to use
#
use vars qw/ %opt /;

# Set command line vars
my ($debug, $config, $logfile, $verbose, $selftest, $dbh, $tailfile, $daemon, $pidfile);

#
# Command line options processing
#
sub init()
{
    use Getopt::Std;
    my $opt_string = 'hd:c:l:svt:bp:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
    $tailfile = defined($opt{'t'}) ? $opt{'t'} : '/path_to_logs/syslog.log';
    $debug = defined($opt{'d'}) ? $opt{'d'} : '0';
    $pidfile = defined($opt{'p'}) ? $opt{'p'} : '/var/run/logzilla.pid';
    $logfile = $opt{'l'} if $opt{'l'};
    $verbose = $opt{'v'} if $opt{'v'};
    $daemon = $opt{'b'} if $opt{'b'};
    $selftest = $opt{'s'} if $opt{'s'};
    $config = defined($opt{'c'}) ? $opt{'c'} : "/path_to_logzilla/html/config/config.php";
}

init();

if ($selftest) {
    print "This command is deprecated now that File::Tail is being used\n";
    #my $cmd = "$0";
    #$cmd .= " -d 1"; # Force debug on so test results are shown 
    #$cmd .= " -c " . $opt{'c'} if $opt{'c'};
    #$cmd .= " -l " . $opt{'l'} if $opt{'l'};
    #$cmd .= " -t " . $opt{'t'} if $opt{'t'};
    #$cmd .= " -v "; # Force verbose mode so results are printed to screen
    #my $date = strftime("%Y-%m-%d", localtime);
    #my $time = strftime("%H:%M:%S", localtime);
    #print STDOUT "\nPERFORMING SELF TEST USING COMMAND:\n$cmd\n\n";
    #my $res = `printf "host\tlocal7\terr\ttest\t$date\t$time\tDB_INS_TEST\t12345: %%SYS-5-CONFIG_I: Configured from 172.16.0.123 by Fred Flinstone <fred\@flinstone.com>\n" | $cmd`;
    #print STDOUT "$res\n";
    #print STDOUT "SELF TEST COMPLETE!\n";
    #exit;
}


#
# Help message
#
sub usage()
{
    print STDERR << "EOF";
This program is used to process incoming syslog messages from a file.
    usage: $0 [-hbdvltcsp] 
    -h        : this (help) message
    -b        : run in background (daemonize)
    -d        : debug level (0-5) (0 = disabled [default])
    -v        : Also print results to STDOUT
    -l        : log file (default used from config.php if not set here)
    -t        : Tailfile - file to watch (Default: /path_to_logs/syslog.log)
    -p        : PID file location (Default: /var/run/logzilla.pid)
    -c        : config file (overrides the default config.php file location set in the '\$config' variable in this script)
    example: $0 -l /var/log/foo.log -d 5 -c /path_to_logzilla/html/config/config.php -v -t /var/log/syslog

    -s        : **DEPRECATED**: 
            This option may be used to run a self test
            You can run a self test by typing:
            $0 -t /var/log/syslog -s -c /path_to_logzilla/html/config/config.php (replace with the path to your config)
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

my($dbtable,$dbuser,$dbpass,$db,$dbhost,$dbport,$DEBUG,$dedup,$dedup_window,$dedup_dist,$log_path,$bulk_ins,$insert_string,@msgs, @bmdata, $bmstart, $bmend, $q_time, $q_limit);
foreach my $var (@config) {
    next unless $var =~ /^DEFINE/; # read only def's
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
#$sth->{TraceLevel} = 4;
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

# If debug is set in config.php, then increment debug to at least 1
$debug++ if $DEBUG eq "1";
#$debug = 0 if ($daemon);


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

if (!$daemon) {
    if (($debug gt 0) or ($verbose)) { 
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
}

# Set vars and pattern match outside the loop to speed up regex processing
my ($host, $facility, $priority, $tag, $date, $time, $prg, $msg, $mne); 
my $re_pipe = qr/(.+?)[\t](.*)[\t](.*)[\t](.*)[\t](.*)[\t](.*)[\t](.*)[\t](.*)/;

my $ref=tie *FH,"File::Tail",(name=>$tailfile,debug=>$debug,
    interval=>1,maxinterval=>2,
    tail=>0,
    maxbuf=>65535,
    adjustafter=>1,errmode=>"return");

# Daemonize.
if ($daemon) # parent: save PID
{
    my $pid = $$;
    chdir '/'               or die "Can't chdir to /: $!";
    open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
    open STDOUT, '>/dev/null'
        or die "Can't write to /dev/null: $!";
    defined(my $pid = fork) or die "Can't fork: $!";
    exit if $pid;
    setsid                  or die "Can't start a new session: $!";
    open STDERR, '>&STDOUT' or die "Can't dup stdout: $!";
}

my $pid = $$;
open (PIDFILE, ">$pidfile") or die "can't open $pidfile: $!\n";
print PIDFILE $pid;
close (PIDFILE);
my $mne = "";

# Reconnect in case we daemonized
$dbh->disconnect();
$dbh = DBI->connect( "DBI:mysql:$db:$dbhost", $dbuser, $dbpass );
if (!$dbh) {
    print LOG "Can't connect to $db database: ", $DBI::errstr, "\n";
    print STDOUT "Can't connect to $db database: ", $DBI::errstr, "\n";
    exit;
}
my $db_select = $dbh->prepare("SELECT * FROM $dbtable WHERE host=? AND facility=? AND priority=? AND tag=? AND fo between ? AND ?");
my $db_select_id = $dbh->prepare("SELECT * FROM $dbtable WHERE id=?");
my $db_update = $dbh->prepare("UPDATE $dbtable SET counter=?, fo=?, lo=? WHERE id=?");
my $db_del = $dbh->prepare("DELETE FROM $dbtable WHERE id=?");
my $db_insert = $dbh->prepare("INSERT INTO $dbtable (host,facility,priority,tag,program,msg,mne,fo,lo) VALUES (?,?,?,?,?,?,?,?,?)");
my $dumpfile = "/dev/shm/infile.txt";
my $sql = qq{LOAD DATA LOCAL INFILE '$dumpfile' INTO TABLE logs FIELDS TERMINATED BY "\\t" LINES TERMINATED BY "\\n" (host,facility,priority,tag,program,msg,mne,fo,lo)};
my $db_insert_mpX = $dbh->prepare("REPLACE INTO cache (name,value,updatetime) VALUES (?,?,?)");
my $db_load = $dbh->prepare("$sql");
my $queue;
my @dumparr;

my $q_start_time = (time);
my $q_time_limit = (time + $q_time);

open (DUMP, ">$dumpfile") or die "can't open $dumpfile: $!\n";
close (DUMP);
$db_load->{TraceLevel} = 4 if (($debug > 1) and ($verbose));
#my $stopwatch;
#$stopwatch = Benchmark::Stopwatch->new->start;
#$stopwatch->lap('Start Dump');
#$stopwatch->lap('Stop Dump');
#print STDOUT $stopwatch->stop->summary;


while (<FH>){
    if (($#dumparr < $q_limit) && (time < $q_time_limit)) {
        $queue = $_;
        push(@dumparr, do_msg($queue));
        #push (@dumparr, "host\tfacility\tpriority\ttag\tprg\tmsg\tmne\t$datetime_now\t$datetime_now\t\n");
    } else {
        my $q_end_time = (time);
        if (time >= $q_time_limit) {
            print STDOUT "Queue time limit reached ($q_time seconds)\n" if ($debug > 0) ;
            print LOG "Queue time limit reached ($q_time seconds)\n" if ($debug > 0);
        } else {
            print LOG "\nDump Limit Reached: $q_limit\n" if ($debug gt 0);
            print STDOUT "\nDump Limit Reached: $q_limit\n" if ($debug gt 0);
        }
        my $mps = round(($#dumparr / ($q_end_time - $q_start_time) ));
        print STDOUT "Average MPS = $mps\n" if ($debug > 0);
        print LOG "Average MPS = $mps\n" if ($debug > 0);
        my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
        $db_insert_mpX->execute("chart_mps_avg", "$mps", "$now");
        #my $mpm = $mps * 60;
        #$db_insert_mpX->execute("chart_mpm_avg", "$mpm", "$now");
        $q_start_time = (time);
        open (DUMP, ">$dumpfile") or die "can't open $dumpfile: $!\n";
        print LOG "Starting insert: " . strftime("%H:%M:%S", localtime) ."\n" if ($debug gt 0);
        print STDOUT "Starting insert: " . strftime("%H:%M:%S", localtime) ."\n" if (($debug > 0) and ($verbose));
        print STDOUT "Importing $#dumparr messages into the database.\n" if ($debug gt 0);
        print LOG "Importing $#dumparr messages into the database.\n" if ($debug gt 0);
        print DUMP @dumparr;
        close (DUMP);
        $db_load->execute();
        if ($db_load->errstr()) {
            print STDOUT "FATAL: Unable to execute SQL statement: ", $db_load->errstr(), "\n" if ($debug gt 0);
        }
        @dumparr = ();
        print LOG "Ending insert: " . strftime("%H:%M:%S", localtime) ."\n" if ($debug gt 0);
        print STDOUT "Ending insert: " . strftime("%H:%M:%S", localtime) ."\n" if (($debug > 0) and ($verbose));
        $q_start_time = (time);
        $q_time_limit = (time + $q_time);
    }
}
sub round {
    my($number) = shift;
    return int($number + .5);
}

sub do_msg {
    $msg = $_[0];
    # start benchmark timer 
    $bmstart = new Benchmark;
    #if (($pid = fork) == 0) {
    # Prepare database statements for later use
    print LOG "\n\nINCOMING MESSAGE:\n$msg\n" if ($debug gt 0);
    print STDOUT "\n\nINCOMING MESSAGE:\n$msg\n" if (($debug > 2) and ($verbose));

    # Get current date and time
    $datetime_now = strftime("%Y-%m-%d %H:%M:%S", localtime);

    # Get current date and time minus $dedup_window in seconds (5 minutes by default)
    $datetime_past = strftime("%Y-%m-%d %H:%M:%S", localtime(time - $dedup_window));

    # Get incoming variables from PIPE
    if ($msg =~ m/$re_pipe/) {
        $host = $1;
        $facility = $2;
        $priority = $3;
        $tag = $4;
        $date = strftime("%Y-%m-%d", localtime); # Changed to use machine's local date and time in case sending device is off
        $time = strftime("%H:%M:%S", localtime);
        $prg = $7;
        $msg = $8;
        $msg =~ s/\\//; # Some messages come in with a trailing slash
        $msg =~ s/'//; # remove any ''s
        if ($msg =~ /%(.*?):/) {
            $mne = $1;
        }
        $msg =~ s/[\x00-\x1F\x80-\xFF]//; # Remove any non-printable characters
        $prg =~ s/%ACE.*\d+/Cisco ACE/; # Added because ACE modules don't send their program field properly
        $prg =~ s/%ASA.*\d+/Cisco ASA/; # Added because ASA's don't send their program field properly
        $prg =~ s/date=\d+-\d+-\d+/Fortigate Firewall/; # Added because Fortigate's don't follow IETF standards
        $msg =~ s/time=\d+:\d+:\d+\s//; # Added because Fortigate's don't s follow IETF standards
        @msgs = split(/:/, $msg);
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
        if ($debug gt 0) { 
            print LOG "HOST: $host\n";
            print LOG "FAC: $facility\n";
            print LOG "PRI: $priority\n";
            print LOG "TAG: $tag\n";
            print LOG "DAT: $date\n";
            print LOG "TME: $time\n";
            print LOG "PRG: $prg\n";
            print LOG "MSG: $msg\n\n";
            print LOG "MNE: $mne\n\n";
        }
        if (($debug > 2) and ($verbose)) { 
            print STDOUT "HOST: $host\n";
            print STDOUT "FAC: $facility\n";
            print STDOUT "PRI: $priority\n";
            print STDOUT "TAG: $tag\n";
            print STDOUT "DAT: $date\n";
            print STDOUT "TME: $time\n";
            print STDOUT "PRG: $prg\n";
            print STDOUT "MSG: $msg\n\n";
            print STDOUT "MNE: $mne\n\n";
        }
    } else {
        # If something gets inserted wrong from the PIPE we'll set host = blank so we can error out later
        $host = "";
        print LOG "INVALID MESSAGE FORMAT:\n$msg\n" if ($debug gt 0);
        print STDOUT "INVALID MESSAGE FORMAT:\n$msg\n" if (($debug > 0) and ($verbose));
    }
    # If the SQZ feature is enabled, continue, if not we'll just insert the record afterward
    if($dedup eq "1") {
        $insert = 1;
        # Debug: set trace level to 4 to get query string executed
        # $db_select->{TraceLevel} = 4;
        # Select any records between now and $dedup_window seconds ago that match this host, facility, etc.
        $db_select->execute($host, $facility, $priority, $tag, $datetime_past, $datetime_now);
        if ($db_select->errstr()) {
            print LOG "FATAL: Unable to execute SQL statement: ", $db_select->errstr(), "\n" if ($debug gt 0);
            print STDOUT "FATAL: Unable to execute SQL statement: ", $db_select->errstr(), "\n";
            exit;
        }

        # For each of the rows obtained above, calculate the likeness of messages using a distance measurement
        while (my $ref = $db_select->fetchrow_hashref()) {
            $distance = distance($ref->{'msg'},$msg);

            # If the distance between the two messages is less than $dedup_dist then we'll consider it a match and deduplicate the message
            if ($distance < $dedup_dist ) {
                # Store the identical record into an array for later processing
                push(@rows, $ref->{'id'});
                print LOG "A duplicate message was found with database id: ".$ref->{'id'}." having a distance of $distance\n" if ($debug gt 0);
                print STDOUT "A duplicate message was found with database id: ".$ref->{'id'}." having a distance of $distance\n" if (($debug gt 0) and ($verbose));
            }
        }
        # If rows matched above, we're now going to process them for deduplication
        my $numrows = scalar @rows;
        if ($numrows > 0) {
            print LOG "Found $numrows duplicate rows\n" if ($debug gt 0);
            print STDOUT "Found $numrows duplicate rows\n" if (($debug > 0) and ($verbose));
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
                print LOG "Processing rows:\n\tSource: $rows[0]\n\tCurrent: $rows[$i]\n" if ($debug gt 0);
                print STDOUT "Processing rows:\n\tSource: $rows[0]\n\tCurrent: $rows[$i]\n" if (($debug > 0) and ($verbose));
                $db_select_id->execute($rows[$i]);
                while (my $ref = $db_select_id->fetchrow_hashref()) {
                    print LOG "Counter from DBID $rows[$i] = ".$ref->{'counter'}."\n" if ($debug gt 0);
                    print STDOUT "Counter from DBID $rows[$i] = ".$ref->{'counter'}."\n" if (($debug > 0) and ($verbose));
                    $counter = ($counter + $ref->{'counter'});
                    print LOG "New Counter = $counter\n" if ($debug gt 0);
                    print STDOUT "New Counter = $counter\n" if (($debug > 0) and ($verbose));
                }
                # Sort the arrays so that we get the first ones
                @fos = sort @fos; 
                $fo = $fos[0];
                # if the row returned is greater than 0 (i.e. not the FIRST record) then delete it as a duplicate.
                # Skip the first record (which will be the source ID)
                if ($rows[0] != $rows[$i]) {
                    print LOG "DELETING DB Record: $rows[$i] which is a duplicate record of $rows[0]\n" if ($debug gt 0);
                    print STDOUT "DELETING DB Record: $rows[$i] which is a duplicate record of $rows[0]\n" if (($debug > 0) and ($verbose));
                    $db_del->execute($rows[$i]);
                }
                # Else, if the row returned is the FIRST record, we need to update it with new counter, fo and lo
                print LOG "UPDATING DB Record: $update_id with new counter and timestamps\n" if ($debug gt 0);
                print STDOUT "UPDATING DB Record: $update_id with new counter and timestamps\n" if (($debug > 0) and ($verbose));
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
            $queue = "$host\t$facility\t$priority\t$tag\t$prg\t$msg\t$mne\t$datetime_now\t$datetime_now\t\n";
            #$db_insert->execute($host, $facility, $priority, $tag, $prg, $msg, $mne, $datetime_now, $datetime_now);
            #if ($db_insert->errstr()) {
            #print LOG "FATAL: Can't execute SQL insert statement (", $dbh->errstr(), ")\n" if ($debug gt 0);
            #print STDOUT "FATAL: Can't execute SQL insert statement (", $dbh->errstr(), ")\n";
            #}
            # $dbh->{TraceLevel} = 4;
        } else {
            print LOG "Error inserting record $msg\n" if ($debug gt 0); 
            print STDOUT "Error inserting record $msg\n" if (($debug > 0) and ($verbose)); 
        }
    } else {
        print LOG "insert = $insert, Skipping insert of this message since it was a duplicate\n" if ($debug gt 0);
        print STDOUT "insert = $insert, Skipping insert of this message since it was a duplicate\n" if (($debug > 0) and ($verbose));
    }
    #exit(0);
    #} elsif ($pid > 0) {
    #print LOG "Waiting for child on PID $pid to exit...\n" if ($debug > 0);
    #print STDOUT "Waiting for child on PID $pid to exit...\n" if (($debug > 0) and ($verbose));
    #wait;
    #} else {
    #print LOG "Could not fork: errno is $!\n" if ($debug > 0);
    #print STDOUT "Could not fork: errno is $!\n" if (($debug > 0) and ($verbose));
    #}
    # end benchmark timer 
    $bmend = new Benchmark;
    my $bmdiff = timediff($bmend, $bmstart);
    print LOG "Total processing time was", timestr($bmdiff, 'all'), " seconds\n" if ($debug > 0);
    print STDOUT "Total processing time was", timestr($bmdiff, 'all'), " seconds\n" if (($debug > 2) and ($verbose));
    return $queue;
}
$dbh->disconnect();
close(LOG);
