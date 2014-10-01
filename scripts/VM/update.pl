#!/usr/bin/perl

use DBI;
use strict;
use Digest::MD5 qw(md5_hex);
use File::Slurp qw(read_file write_file);

# Change the skip license option to 'y'

my $filename = '/var/www/logzilla/scripts/.lzrc';
my $data = read_file $filename, {binmode => ':utf8'};
$data =~ s/skiplic = "N"/skiplic = "Y"/g;
write_file $filename, {binmode => ':utf8'}, $data;

# Run an upgrade

my $osupdate = system("apt-get update && apt-get -y upgrade");
my $svnup = system("cd /var/www/logzilla/ && svn update --accept theirs-conflict");
my $upgrade = system("cd /var/www/logzilla/scripts && ./upgrade");

# Remove the test message and host
my $remhost = system("/var/www/logzilla/scripts/LZTool -delhost -host host-1");


# Change the skip license option back to 'n'
my $filename = '/var/www/logzilla/scripts/.lzrc';
my $data = read_file $filename, {binmode => ':utf8'};
$data =~ s/skiplic = "Y"/skiplic = "N"/g;
write_file $filename, {binmode => ':utf8'}, $data;

# Remove the script from init.d and delete it

my $remjob = system("update-rc.d -f update.pl remove");
my $remscript = system("rm /etc/init.d/update.pl");
