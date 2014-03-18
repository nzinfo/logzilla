#!/usr/bin/perl

#
# mysql_cnf_generator.pl
#
# Developed by Clayton Dukes <cdukes@logzilla.pro>
# Copyright (c) 2012 logzilla.pro
# All rights reserved.
#
# Changelog:
# 2012-12-08 - created
#

###################################################
# This script could totally hose your system. 
# You probably shouldn't use it :-)
###################################################

use strict;

$| = 1;

my $checkprocess = `ps -C mysqld -o pid=`;
if ($checkprocess) {
  print "Stopping MySQL\n";
  system("service mysql stop");
}
&chk_ib_logs;
&setup_mycnf("/etc/mysql/conf.d/logzilla.cnf");

if ($checkprocess) {
  print "Starting MySQL\n";
  system("service mysql start");
}




sub chk_ib_logs {
    my @f = </var/lib/mysql/ib_logfile*>;
    foreach my $f (@f) {
        next if $f =~ /orig/;
        my $size = -s $f;
        if ( $size <= 67108864 ) {
            print "Your ib_logfiles are too small (Minimum recommended is 64MB)\n";
            print "Renaming $f to $f.orig. You can delete it later if you like.\n";
            system("mv $f $f.orig");
        }
    }
}

sub setup_mycnf {
    my $file = shift;
    my ($query_cache_size, $query_cache_limit);
    my $innodb_log_file_size;
    system("touch $file");
    my $numdisks = `fdisk -l 2>/dev/null | grep "Disk \/" | grep -v "\/dev\/md" | awk '{print \$2}' | sed -e 's/://g' | wc -l`;
    my $innodb_commit_concurrency = $numdisks * 4;
    # Below just grabs IOPS for the fastest disk, which we assume is where MySQL is running from...hopefully
    #my $diskio = `iostat | awk '{print \$2}' | sort -nr | head -1`;
    #chomp($diskio);
    #$diskio = sprintf("%.0f", $diskio);
    #$diskio = 200 if not ($diskio);
    my $cpu_cores = `cat /proc/cpuinfo | grep processor | wc -l`;
    my $cores2x   = $cpu_cores * 2;
    my $sysmem    = `cat /proc/meminfo |  grep "MemTotal" | awk '{print \$2}'`;
    $sysmem = ( $sysmem * 1024 );
    my $poolsize             = ( $sysmem * 3 / 10 );
    #my $innodb_log_file_size = ( $poolsize / 4 );

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

    my $innodb_log_buffer_size  = ( $innodb_log_file_size / 8 );
    my $Hpoolsize               = humanBytes($poolsize);
    my $Hinnodb_log_file_size   = humanBytes($innodb_log_file_size);
    my $Hinnodb_log_buffer_size = humanBytes($innodb_log_buffer_size);
    if ( -e "$file" ) {
        open my $config, '+<', "$file" or warn "FAILED: $!\n";
        my @arr = <$config>;
        if ( !grep( /logzilla|lzconfig/, @arr ) ) {
            print "Creating MySQL config for LogZilla at $file\n";
            open FILE, ">>$file" or die $!;
            print FILE <<EOF;
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
event_scheduler=on
symbolic-links=0
skip-name-resolve
#
#--------------------------------------
# Logging
#--------------------------------------
log-error=/var/log/mysql/error.log
#log=/var/log/mysql/general.log
#slow-query-log=/var/log/mysql/mysql-slow.log

# Log to the DB instead of files:
# http://www.dzone.com/snippets/log-sql-queries-mysql-table
# log-output = TABLE
# Disable logging in production environments.
# Uncomment below to enable for testing.
# slow-query-log 
# general-log
# long_query_time = 1
# expire_logs_days = 1

#--------------------------------------
# Files
#--------------------------------------
back_log                        = 300
open-files-limit                = 8192
open-files                      = 1024
port                            = 3306
skip-external-locking
skip-name-resolve

#--------------------------------------
## Per-Thread Buffers * (max_connections) = total per-thread mem usage
#--------------------------------------
thread_stack                    = 512K    #default: 32bit: 192K, 64bit: 256K
sort_buffer_size                = 2M      #default: 2M, larger may cause perf issues
read_buffer_size                = 2M      #default: 128K, change in increments of 4K
read_rnd_buffer_size            = 2M      #default: 256K
join_buffer_size                = 2M      #default: 128K
binlog_cache_size               = 128K    #default: 32K, size of buffer to hold TX queries

#--------------------------------------
## Query Cache
#--------------------------------------
# Disabling query cache relieves our hot path from unneeded processing and latency. 
# That cache would prove useful for regular MySQL workloads, so this should only be necessary on large systems.
query_cache_size                = $query_cache_size   #global buffer
query_cache_limit               = $query_cache_limit  #max query result size to put in cache

#--------------------------------------
## Connections
#--------------------------------------
max_connections                 = 1000  #multiplier for memory usage via per-thread buffers
thread_cache_size               = 50    #recommend 5% of max_connections
max_connect_errors              = 100   #default: 10
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
## Thread settings
#--------------------------------------
# Disabled - deprecated and only works on Solaris 9
#thread_concurrency              = $cores2x  #recommend 2x CPU cores

#--------------------------------------
## MyISAM Engine
#--------------------------------------
key_buffer                      = 1M    #global buffer
myisam_sort_buffer_size         = 128M  #index buffer size for creating/altering indexes
myisam_max_sort_file_size       = 256M  #max file size for tmp table when creating/alering indexes
myisam_repair_threads           = 4     #thread quantity when running repairs
myisam_recover                  = BACKUP #repair mode, recommend BACKUP
myisam-block-size               = 14384
myisam_use_mmap
key_buffer_size                 = 128M  # This is the MyISAM equivalent of 'innodb_buffer_pool_size' for InnoDB.

#--------------------------------------
## InnoDB IO Capacity - 5.1.x plugin, 5.5.x
# http://dev.mysql.com/doc/refman/5.5/en/innodb-parameters.html#sysvar_innodb_io_capacity
#--------------------------------------
#innodb_io_capacity              = 20000 # Based on iostat for the fastest disk in your server

#--------------------------------------
## InnoDB IO settings -  5.1.x only
#--------------------------------------
#innodb_file_io_threads         = 16

#--------------------------------------
## InnoDB IO settings -  5.5.x and greater
#--------------------------------------
innodb_write_io_threads         = 64
innodb_read_io_threads          = 64

#--------------------------------------
## InnoDB Plugin Independent Settings
#--------------------------------------
# Can't set this unless you remove your current data
# innodb_data_file_path           = ibdata1:128M;ibdata2:10M:autoextend

# Note: If you modify innodb_log_file_size, you will first need to shut down mysql,
# and delete/rename your current /var/lib/mysql/ib_logfile* files so that mysql can create new ones.
# Check your /var/log/mysql/error.log on startup to make sure it worked properly.
innodb_log_file_size            = $Hinnodb_log_file_size #64G_RAM+ = 368, 24G_RAM+ = 256, 8G_RAM+ = 128, 2G_RAM+ = 64

innodb_log_files_in_group       = 3     #combined size of all logs <4GB. <16G_RAM = 2, >16G_RAM = 3
#
# Set innodb_buffer_pool_size to 10%-25% of total system memory if this is a dedicated LogZilla server
# This is negotiable, Percona recommends up to 80% but I've seen no improvements during testing
# (probably because we use external indexes)
# Also possibly helpful: http://stackoverflow.com/questions/5174396/innodb-performance-tweaks
innodb_buffer_pool_size         = $Hpoolsize
innodb_buffer_pool_instances    = 4     #ver 5.5+ only: splits buffer pool (req: buffer_pool/n > 1G) into n-chunks
innodb_additional_mem_pool_size = 4M    #global buffer
#innodb_status_file                      #extra reporting
innodb_file_per_table                   #enable always
innodb_flush_log_at_trx_commit  = 2     #2/0 = perf, 1 = ACID
innodb_table_locks              = 0     #preserve table locks
innodb_log_buffer_size          = $Hinnodb_log_buffer_size # Global buffer = 1/8 of the innodb_log_file_size
innodb_lock_wait_timeout        = 60
innodb_thread_concurrency       = $cores2x    #recommend 2x core quantity
innodb_commit_concurrency       = $innodb_commit_concurrency    #recommend 4x num disks
#innodb_flush_method             = O_DIRECT # use O_DIRECT if you have raid with bbu. Options: O_DIRECT, O_DSYNC, blank for fdatasync (default)
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
EOF
        }
    }
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
