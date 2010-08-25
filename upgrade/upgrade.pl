#!/usr/bin/perl

# Upgrade script
use strict;

$| = 1;


use Cwd;
use DBI;
use Term::ReadLine;
use Switch;

use vars qw/ %opt /;

system("stty erase ^H");
sub p {
    my($prompt, $default) = @_;
    my $defaultValue = $default ? "[$default]" : "";
    print "$prompt $defaultValue: ";
    chomp(my $input = <STDIN>);
    return $input ? $input : $default;
}

my $version = "3.0";
my $subversion = ".90";

# Grab the base path
my $lzbase = getcwd;
$lzbase =~ s/\/scripts//g;
my $paths_updated = 0;

my ($config, $dbh);
sub init()
{
    use Getopt::Std;
    my $opt_string = 'hc:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
    $config = defined($opt{'c'}) ? $opt{'c'} : "../logzilla/html/config/config.php";
}

init();

#
# Help message
#
sub usage()
{
    print STDERR << "EOF";
This program is used to upgrade LogZilla.
    usage: $0 [-hc] 
    -h        : this (help) message
    -c        : config file (overrides the default config.php file location set in the '\$config' variable in this script)
    example: $0 -c /path_to_logzilla/html/config/config.php 
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

my($dbtable,$dbuser,$dbpass,$db,$dbhost,$dbport, $curversion, $cur_subversion);
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
    $curversion = $settings[1] if ($settings[0] =~ /^VERSION$/);
    $cur_subversion = $settings[1] if ($settings[0] =~ /^VERSION_SUB$/);
}

print("\n\033[1m\n\n========================================\033[0m\n");
print("\n\033[1m\tLogZilla Upgrade\n\033[0m");
print("\n\033[1m========================================\n\n\033[0m\n\n");

print "Getting ready to patch version $curversion".$cur_subversion." to $version".$subversion."\n";
print "Note that there is NO GUARANTEE that this will work on your system, so be sure to BACKUP before proceeding.\n";
my $ok  = &p("Ok to continue?", "y");
if ($ok =~ /[Yy]/) {

    switch ($cur_subversion) {
        case ".85" { 
            system "patch -d ../ -p0 < upgrades/3085-3090.patch\n";
        }
        case ".90" { print "Already at version .90" }

        else { 
            print "Automatic upgrade is not available for $curversion".$cur_subversion."\n"; 
            print "Please check http://nms.gdd.net/index.php/Upgrade_Procedures_for_Logzilla_3.0 for older versions\n";
            exit;
        }
    }
} else {
    print "Skipping patch\n";
    exit;
}
my $sth = $dbh->prepare("
    update settings set value='$subversion' where name='VERSION_SUB';
    ") or die "Could not update settings table: $DBI::errstr";
$sth->execute;

print("\n\033[1m\tUpgrade from $curversion".$cur_subversion." to $version".$subversion." complete...\n\n\033[0m");
