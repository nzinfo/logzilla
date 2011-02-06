#!/bin/sh

read host
read ip

# we only need the last oid/val pair
while read oid val
do
	var1="$oid"
	var2="$val"
done

# send it into the database with a traditional db_insert.pl
echo -e "$host\t$1\t$var1\tTRAP!: $var2"|/path_to_logzilla/scripts/db_insert.pl