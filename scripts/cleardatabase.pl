#!/usr/bin/perl
# updateCache
use strict;
$| = 1;
use DBI;

# Get LogZilla base directory
use Cwd;
my $lzbase = getcwd;
$lzbase =~ s/\/scripts//g;

system("stty erase ^H");

use vars qw/ %opt /;
my ($debug, $config, $dbh);
#
# Command line options processing
#
sub init()
{
    use Getopt::Std;
    my $opt_string = 'hd:c:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
    $debug = defined($opt{'d'}) ? $opt{'d'} : '0';
    $config = defined($opt{'c'}) ? $opt{'c'} : "$lzbase/html/config/config.php";
}

init();

#
# Help message
#
sub usage()
{
    print STDERR << "EOF";
This program is used to restore LogZilla to defaults.
    usage: $0 [-hdc] 
    -h        : this (help) message
    -d        : debug level (0-5) (0 = disabled [default])
    -c        : config file (overrides the default config.php file location set in the '\$config' variable in this script)
    example: $0 -l /var/log/foo.log -d 5 -c $lzbase/html/config/config.php -v -t /var/log/syslog
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

my($dbtable,$dbuser,$dbpass,$db,$dbhost,$dbport);
foreach my $var (@config) {
    next unless $var =~ /DEFINE/; # read only def's
    $db = $1 if ($var =~ /'DBNAME', '(\w+)'/);
}
if (!$db){
    print "Error: Unable to read $db config variables from $config\n";
    exit;
}
my $dsn = "DBI:mysql:$db:;mysql_read_default_group=logzilla;"
. "mysql_read_default_file=$lzbase/scripts/sql/lzmy.cnf";
$dbh = DBI->connect($dsn, $dbuser, $dbpass);
if (!$dbh) {
    print LOG "Can't connect to database: ", $DBI::errstr, "\n";
    print STDOUT "Can't connect to database: ", $DBI::errstr, "\n";
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
}

sub p {
    my($prompt, $default) = @_;
    my $defaultValue = $default ? "[$default]" : "";
    print "$prompt $defaultValue: ";
    chomp(my $input = <STDIN>);
    return $input ? $input : $default;
}

print("\n\033[1mThis will clear all data from the $db database!\nOnly the log tables and the admin login will be reset.\n\033[0m");
my $ok  = &p("Reset Admin Login? (yes/no)", "n");
if ($ok =~ /[Yy]/) {
    my $password = &p("Enter the password for the user \"admin\"", "admin");
    $password = qq{$password};

    my $event = qq{
    update users set pwhash=md5('$password') where username='admin';
    };
    my $sth = $dbh->prepare("
        $event
        ") or die "Could not reset admin password: $DBI::errstr";
    $sth->execute;
    print "Completed...\n";
} else {
    print "Skipping Admin Reset...\n";
}
my $ok  = &p("Reset Log Data? (yes/no)", "n");
if ($ok =~ /[Yy]/) {
    print("\n\033[1m\tThis will DESTROY all log data from the $db database.\n\033[0m");
    my $ok  = &p("ARE YOU SURE?? (yes/no)", "n");
    if ($ok =~ /[Yy]/) {

        print "Clearing $dbtable...\n";
        my $sth = $dbh->prepare("truncate $dbtable") or die "Could not truncate: $DBI::errstr";
        $sth->execute;

        print "Clearing cache...\n";
        my $sth = $dbh->prepare("truncate cache") or die "Could not truncate: $DBI::errstr";
        $sth->execute;

        print "Clearing hosts...\n";
        my $sth = $dbh->prepare("truncate hosts") or die "Could not truncate: $DBI::errstr";
        $sth->execute;

        print "Clearing mne...\n";
        my $sth = $dbh->prepare("truncate mne") or die "Could not truncate: $DBI::errstr";
        $sth->execute;

        print "Clearing programs...\n";
        my $sth = $dbh->prepare("truncate programs") or die "Could not truncate: $DBI::errstr";
        $sth->execute;

        print "Clearing suppress...\n";
        my $sth = $dbh->prepare("truncate suppress") or die "Could not truncate: $DBI::errstr";
        $sth->execute;

        print "Clearing history...\n";
        my $sth = $dbh->prepare("truncate history") or die "Could not truncate: $DBI::errstr";
        $sth->execute;

        print "Clearing snare_eid...\n";
        my $sth = $dbh->prepare("truncate snare_eid") or die "Could not truncate: $DBI::errstr";
        $sth->execute;

    } else {
        print "Data Reset Skipped...\n";
    }
}
