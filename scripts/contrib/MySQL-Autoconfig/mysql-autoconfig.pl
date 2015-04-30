#!/usr/bin/perl

#
#
# Auto MySQL config Generator 
# Developed by Clayton Dukes <cdukes@logzilla.net>
# Copyright (c) LogZilla Corporation
# All rights reserved.
#
# Changelog:
# 2015-04-25 - created
#

###################################################
# This script could totally hose your system. 
# You probably shouldn't use it :-)
###################################################

use strict;
use warnings;
use File::Basename;

$| = 1;

my $osver = `lsb_release -d -s | awk '{print \$2}' | cut -d '.' -f1-2`;
chomp($osver);
printf "Sorry, this script is only meant to work on Ubuntu 12-14\n" && exit if ( $osver !~ /12|14/ );
print "Work in progress, don't run unless you REALLY know what you are doing!\n";
exit;

my $checkprocess = `ps -C mysqld -o pid=`;
my $mysqlver = 0;
my $mysqlverSub = 0;
if ($checkprocess) {
    $mysqlver = `mysql -V | cut -d ' ' -f6 | cut -d '.' -f1`;
    $mysqlverSub = `mysql -V | cut -d ' ' -f6 | cut -d '.' -f2`;
    chomp ($mysqlver);
    chomp ($mysqlverSub);
    print "Stopping MySQL\n";
    system("service mysql stop");
} else {
    print "MySQL must be running...\n";
    exit;
}

my $autoextend = qq{
# innodb_data_file_path           = ibdata1:128M;ibdata2:10M:autoextend
};

sub chk_ib_logs {
    my @f = </var/lib/mysql/ib_logfile*>;
    foreach my $f (@f) {
        next if $f =~ /orig/;
        my $size = -s $f;
        if ( $size < 67108864 ) {
            print "Your ib_logfiles are too small (Minimum recommended is 64MB)\n";
            my $bf = basename($f);
            print "Moving $f to /tmp/$bf-$$.orig. You can delete it later if you like.\n";
            system("mv $f /tmp/$bf-$$.orig");
        }
    }
}


sub chk_ib_data {
    my $f = "/var/lib/mysql/ibdata1";
    my $size = -s $f;
    print "Checking ibdata size: $size\n";
    if ( $size ne 134217728 ) {
        print "ERROR!\n";
        print "Your InnoDB data file ($f) appears to be set up without the innodb_file_per_table option in your MySQL config\n";
        print "If you do not fix this, ibdata will grow beyond the actual data size and will eventually fill up your disk\n";
        print "Please see https://www.assembla.com/spaces/LogZillaWiki/wiki/MySQL_InnoDB_Per_File_Table\n";
        print "You must dump all databases, delete /var/lib/mysql/ib*, and start mysql\n";
        my $bf = basename($f);
        # system("mv $f /tmp/$bf.orig");
    } else {
        $autoextend = qq{
        innodb_data_file_path           = ibdata1:128M;ibdata2:10M:autoextend
        };
    }
}
my ($innodb_log_file_size);
my $iothreads   = "";
my $diskio      = 100;
my $sqldisk     = `df -P /var/lib/mysql | tail -1 | cut -d' ' -f 1`;
chomp ($sqldisk);

sub setup_mycnf {
    my $file = shift;
    my ($query_cache_size, $query_cache_limit);
    my $numdisks = `blkid | grep -v mapper | wc -l`;
    chomp($numdisks);
    # innodb_commit_concurrency: The number of threads that can commit at the same time. A value of 0 (the default) permits any number of transactions to commit simultaneously.
    # See http://www.percona.com/blog/2006/06/05/innodb-thread-concurrency/
    my $innodb_commit_concurrency = $numdisks * 4; 
    # Below just grabs IOPS for the fastest disk, which we assume is where MySQL is running from...hopefully
    if (-e '/usr/bin/fio' && -x _) {
        # Disabled, it crashed the test server's disk. Need to investigate
        # $diskio = `fio --filename=$sqldisk --direct=1 --rw=randwrite --bs=512 --size=500107862016 --runtime=5 --name=file1 | grep iops | cut -d ',' -f3 | cut -d '=' -f2`;
        # chomp($diskio);
        # $diskio = sprintf("%.0f", $diskio);
    } else {
        # printf "fio is not installed, skipping disk IOPS test...\n";
    }
    my $cpu_cores = `cat /proc/cpuinfo | grep processor | wc -l`;
    my $cores2x   = $cpu_cores * 2;
    my $sysmem    = `cat /proc/meminfo |  grep "MemTotal" | awk '{print \$2}'`;
    $sysmem = ( $sysmem * 1024 );

    if ( $sysmem >= 68719476736 ) {
        $innodb_log_file_size = 385875968;
    } elsif ( $sysmem >= 25769803776 ) {
        $innodb_log_file_size = 268435456;
    } elsif ( $sysmem >= 8589934592 ) {
        $innodb_log_file_size = 134217728;
    } else {
        $innodb_log_file_size = 67108864;
    }
    if ( $sysmem >= 68719476736 ) {
        $query_cache_size = 0;
        $query_cache_limit = 0;
    } else {
        $query_cache_size = "64M";
        $query_cache_limit = "512K";
    }

# Global Buffers: key_buffer_size, innodb_buffer_pool_size, innodb_log_buffer_size, innodb_additional_mem_pool_size, net_buffer_size, query_cache_size
    my $innodb_buffer_pool_size             = ( $sysmem * 15 / 100 ); # Set to 15%
    printf ("Calculated InnoDB Buffer Pool Size is %s\n", humanBytes($innodb_buffer_pool_size));
    my $key_buffer_size                     = 128000000; # No need to calc this because we don't use MyISAM
    my $innodb_log_buffer_size              = ( $innodb_log_file_size / 8 ); # 1/8 of the innodb_log_file_size
    my $innodb_additional_mem_pool_size     = 4000000;
    my $Hkey_buffer_size                    = humanBytes($key_buffer_size);
    my $Hinnodb_log_buffer_size             = humanBytes($innodb_log_buffer_size);
    my $Hinnodb_buffer_pool_size            = humanBytes($innodb_buffer_pool_size);
    my $Hinnodb_log_file_size               = humanBytes($innodb_log_file_size);
    my $Hinnodb_additional_mem_pool_size    = humanBytes($innodb_additional_mem_pool_size);
    my $GlobalBuffers                       = ($innodb_buffer_pool_size + $key_buffer_size + $innodb_log_buffer_size + $innodb_additional_mem_pool_size);

# Thread Buffers: sort_buffer_size, myisam_sort_buffer_size, read_buffer_size, join_buffer_size, read_rnd_buffer_size, thread_stack
    my $sort_buffer_size                    = 2000000;      #default: 2M, larger may cause perf issues
    my $myisam_sort_buffer_size             = 128000000;    #index buffer size for creating/altering indexes
    my $read_buffer_size                    = 2000000;      #default: 128K, change in increments of 4K
    my $join_buffer_size                    = 2000000;      #default: 128K
    my $read_rnd_buffer_size                = 2000000;      #default: 256K
    my $thread_stack                        = 512000;       #default: 32bit: 192K, 64bit: 256K
    my $Hsort_buffer_size                   = humanBytes($sort_buffer_size);
    my $Hmyisam_sort_buffer_size            = humanBytes($myisam_sort_buffer_size); 
    my $Hread_buffer_size                   = humanBytes($read_buffer_size); 
    my $Hjoin_buffer_size                   = humanBytes($join_buffer_size); 
    my $Hread_rnd_buffer_size               = humanBytes($read_rnd_buffer_size); 
    my $Hthread_stack                       = humanBytes($thread_stack); 
    my $ThreadBuffers                       = ($sort_buffer_size + $myisam_sort_buffer_size + $read_buffer_size + $join_buffer_size + $read_rnd_buffer_size + $thread_stack);

# Available RAM = Global Buffers + (Thread Buffers x max_connections)
# max_connections = (Available RAM - Global Buffers) / Thread Buffers
    printf ("Calculated Global Buffer Size is %s\n", humanBytes($GlobalBuffers));
    printf ("Calculated Global Thread Size is %s\n", humanBytes($ThreadBuffers));
    my $max_connections                     = sprintf("%.0f", ($innodb_buffer_pool_size - $GlobalBuffers / $ThreadBuffers));
    my $thread_cache_size                   = sprintf("%.0f", ($max_connections * 5 / 100)); # 5% of max_connections  - thread_cache_size = (0.05)($max_connections)

    if ($mysqlverSub eq 1) {
        $iothreads = qq{
#--------------------------------------
## InnoDB IO settings -  5.1.x only
#--------------------------------------
innodb_file_io_threads         = 16
};
}

if ($mysqlverSub ge 5) {
    $iothreads = qq{
#--------------------------------------
## InnoDB IO settings -  5.5.x and greater
#--------------------------------------
innodb_write_io_threads         = 64
innodb_read_io_threads          = 64
};
}

if ( -e "$file" ) {
    my $bfile = basename($file);
    print "$file already exists, moving it to /tmp/$bfile-$$.bak\n";
    system("mv $file /tmp/$bfile-$$.bak");
}
print "Creating MySQL config for LogZilla at $file\n";
open FILE, ">$file" or die $!;
my $newconf = qq{
#<lzconfig> BEGIN LogZilla settings
# Based on http://www.mysqlperformanceblog.com/2007/11/01/innodb-performance-optimization-basics/
# And also from http://themattreid.com/uploads/innodb_flush_method-CNF-loadtest.txt
# Do not depend on these settings to be correct for your server. Please consult your DBA
# You can also run /path_to_logzilla/scripts/tools/mysqltuner.pl for help.
#
#
[mysqld]
#--------------------------------------
# General settings
#--------------------------------------
# Always use file_per_table! See https://www.assembla.com/wiki/show/LogZillaWiki/MySQL_Tuning
innodb_file_per_table
skip-name-resolve
event_scheduler             = on
symbolic-links              = 0

#--------------------------------------
# Logging
#--------------------------------------
log-error=/var/log/mysql/error.log

# Disable logging in production environments.
# Uncomment general and slow logs to enable for testing.
# log=/var/log/mysql/general.log
#slow-query-log=/var/log/mysql/slow.log
#long_query_time = 1
#expire_logs_days = 10

# Log to the DB instead of files:
# http://www.dzone.com/snippets/log-sql-queries-mysql-table
# log-output = TABLE

#--------------------------------------
# Files
#--------------------------------------
back_log                        = 300
open-files-limit                = 8192
open-files                      = 1024
port                            = 3306
skip-external-locking

#--------------------------------------
## Per-Thread Buffers * (max_connections) = total per-thread mem usage
#--------------------------------------
thread_stack                    = $Hthread_stack          #default: 32bit: 192K, 64bit: 256K
sort_buffer_size                = $Hsort_buffer_size      #default: 2M, larger may cause perf issues
read_buffer_size                = $Hread_buffer_size      #default: 128K, change in increments of 4K
read_rnd_buffer_size            = $Hread_rnd_buffer_size  #default: 256K
join_buffer_size                = $Hjoin_buffer_size      #default: 128K
binlog_cache_size               = 128K    #default: 32K, size of buffer to hold TX queries

#--------------------------------------
## Query Cache
#--------------------------------------
# Disabling query cache relieves our hot path from unneeded processing and latency. 
# That cache would prove useful for regular MySQL workloads, so this should only be necessary on large systems.
query_cache_size                = $query_cache_size   # global buffer
query_cache_limit               = $query_cache_limit  # max query result size to put in cache

#--------------------------------------
## Connections
#--------------------------------------
max_connections                 = $max_connections  # max_connections = (Available RAM - Global Buffers) / Thread Buffers
thread_cache_size               = $thread_cache_size    #recommend 5% of max_connections
max_connect_errors              = 5     #default: 10
concurrent_insert               = 2     #default: 1, 2: enable insert for all instances
connect_timeout                 = 30    #default -5.1.22: 5, +5.1.22: 10
max_allowed_packet              = 32M   #max size of incoming data to allow

#--------------------------------------
## Table and TMP settings
## Use if you know what you are doing
#--------------------------------------
# max_heap_table_size             = 1G    #recommend same size as tmp_table_size
# bulk_insert_buffer_size         = 1G    #recommend same size as tmp_table_size
# tmp_table_size                  = 1G    #recommend 1G min
# tmpdir                         =  /dev/shm/db/tmp01:/dev/shm/db/tmp02:/dev/shm/db/tmp03 #Recommend using RAMDISK for tmpdir

#--------------------------------------
## Table cache settings
#--------------------------------------
#table_cache                    = 512   #5.0.x <default: 64>
table_open_cache                = 512   #5.1.x, 5.5.x <default: 64>

#--------------------------------------
## MyISAM Engine
#--------------------------------------
key_buffer                      = 1M    #global buffer
myisam_sort_buffer_size         = $Hmyisam_sort_buffer_size  #index buffer size for creating/altering indexes
myisam_max_sort_file_size       = 256M  #max file size for tmp table when creating/alering indexes
myisam_repair_threads           = 4     #thread quantity when running repairs
myisam_recover                  = BACKUP #repair mode, recommend BACKUP
myisam-block-size               = 14384
myisam_use_mmap
key_buffer_size                 = $Hkey_buffer_size  # This is the MyISAM equivalent of 'innodb_buffer_pool_size' for InnoDB.

#--------------------------------------
## InnoDB IO Capacity - 5.1.x plugin, 5.5.x
# http://dev.mysql.com/doc/refman/5.5/en/innodb-parameters.html#sysvar_innodb_io_capacity
#--------------------------------------
# IO Capacity of based on fio - you need fio installed to use it, otherwise we default to 100 because Amazon EC2 is so slow on low end servers
# The command to get iops for the disk using MySQL is:
# WIP: DO NOT USE THIS COMMAND OR YOU WILL LOSE DISK DATA!
# fio --filename=$sqldisk --direct=1 --rw=randwrite --bs=512 --size=500107862016 --runtime=5 --name=file1 | grep iops | cut -d ',' -f3 | cut -d '=' -f2
innodb_io_capacity              = $diskio

$iothreads

#--------------------------------------
## InnoDB Plugin Independent Settings
#--------------------------------------
# Can't set autoextend unless you remove your current data
$autoextend

# Note: If you modify innodb_log_file_size, you will first need to shut down mysql,
# and delete/rename your current /var/lib/mysql/ib_logfile* files so that mysql can create new ones.
# Check your /var/log/mysql/error.log on startup to make sure it worked properly.
innodb_log_file_size            = $Hinnodb_log_file_size #64G_RAM+ = 368, 24G_RAM+ = 256, 8G_RAM+ = 128, 2G_RAM+ = 64

innodb_log_files_in_group       = 3     #combined size of all logs <4GB. <16G_RAM = 2, >16G_RAM = 3
#
# Set innodb_buffer_pool_size to 10%-25% of total system memory if this is a dedicated LogZilla server
# This is negotiable, Percona recommends up to 80% but it's not feasible since it hogs all the mem from the Indexer
# Also possibly helpful: http://stackoverflow.com/questions/5174396/innodb-performance-tweaks
innodb_buffer_pool_size         = $Hinnodb_buffer_pool_size
innodb_buffer_pool_instances    = 4     # ver 5.5+ only: splits buffer pool (req: buffer_pool/n > 1G) into n-chunks
innodb_additional_mem_pool_size = $Hinnodb_additional_mem_pool_size    # global buffer
innodb_flush_log_at_trx_commit  = 2     #2/0 = perf, 1 = ACID
innodb_table_locks              = 0     #preserve table locks
innodb_log_buffer_size          = $Hinnodb_log_buffer_size # Global buffer = 1/8 of the innodb_log_file_size
innodb_lock_wait_timeout        = 60
innodb_thread_concurrency       = $cores2x    # recommend 2x core quantity
innodb_commit_concurrency       = $innodb_commit_concurrency    # recommend 4x num disks - see http://www.percona.com/blog/2006/06/05/innodb-thread-concurrency/
innodb_flush_method             = O_DIRECT # use O_DIRECT if you have raid with bbu. Options: O_DIRECT, O_DSYNC, blank for fdatasync (default)
innodb_support_xa               = false #recommend 0 on read-only slave, disable xa to negate extra disk flush
skip-innodb-doublewrite
skip_innodb_checksums


#--------------------------------------
# Meta data stats
# Enable this to speed up log_processor startup.
# On slow, or very large servers, InnoDB can take > 30 seconds to start
# It's important that you know what you are doing this for, so please read before enabling it:
# http://dev.mysql.com/doc/refman/5.1/en/innodb-parameters.html#sysvar_innodb_stats_on_metadata
#--------------------------------------
# innodb_stats_on_metadata = 0


#</lzconfig> END LogZilla settings
};
print FILE $newconf;
    }
    my $needed = `apt-cache policy libjemalloc1 | grep none`;
    chomp ($needed);
    if ($needed) {
        print "Installing new memory allocater for MySQL - see https://www.assembla.com/wiki/show/LogZillaWiki/MySQL_Tuning\n";
        system("apt-get -y install libjemalloc1");
        print "Adding memory allocator load to /etc/init/mysql.conf - see https://www.assembla.com/wiki/show/LogZillaWiki/MySQL_Tuning\n";
        system("perl -i -pe 's|env HOME=/etc/mysql|env HOME=/etc/mysql\nenv LD_PRELOAD=/usr/lib/libjemalloc.so.1\n|g' /etc/init/mysql.conf");
    }

    sub humanBytes {
        my $bytes = shift();
        if ( $bytes > 1099511627776 )    #   TB: 1024 GiB
        {
            return sprintf( "%.0fT", $bytes / 1099511627776 );
        }
        elsif ( $bytes > 1073741824 )    #   GB: 1024 MiB
        {
            return sprintf( "%.0fG", $bytes / 1073741824 );
        }
        elsif ( $bytes > 1048576 )       #   MB: 1024 KiB
        {
            return sprintf( "%.0fM", $bytes / 1048576 );
        }
        elsif ( $bytes > 1024 )          #   KB: 1024 B
        {
            return sprintf( "%.0fK", $bytes / 1024 );
        }
        else                             #   bytes
        {
            return "$bytes" . ( $bytes == 1 ? "" : "s" );
        }
    }
&chk_ib_logs;
&chk_ib_data;
&setup_mycnf("/etc/mysql/conf.d/logzilla.cnf");
$checkprocess = `ps -C mysqld -o pid=`;
if (!$checkprocess) {
    print "Starting MySQL\n";
    system("service mysql start");
}
$checkprocess = `ps -C mysqld -o pid=`;
if (!$checkprocess) {
    my $file = "/var/log/mysql/error.log";
    open my $fh, '<', $file;
    seek $fh, -1000, 2;
    my @lines = <$fh>;
    close $fh;
    print "Something went wrong\n";
    print "Last 50 lines of $file are: ", @lines[-50 .. -1];
}
