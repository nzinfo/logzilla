#!/usr/bin/perl

use DBI;
use strict;
use Digest::MD5 qw(md5_hex);
use File::Slurp qw(read_file write_file);

# Change the skip license option to 'y'

my $filename = '/path_to_logzilla/scripts/.lzrc';
my $data = read_file $filename, {binmode => ':utf8'};
$data =~ s/skiplic = "N"/skiplic = "Y"/g;
write_file $filename, {binmode => ':utf8'}, $data;

# Run an upgrade

my $osupdate = system("apt-get update && apt-get -y upgrade");
my $svnup = system("cd /path_to_logzilla/ && svn update --accept theirs-conflict");
my $upgrade = system("cd /path_to_logzilla/scripts && ./upgrade nohup notest");

# Change the skip license option back to 'n'
my $filename = '/path_to_logzilla/scripts/.lzrc';
my $data = read_file $filename, {binmode => ':utf8'};
$data =~ s/skiplic = "Y"/skiplic = "N"/g;
write_file $filename, {binmode => ':utf8'}, $data;

