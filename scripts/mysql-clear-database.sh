#!/usr/bin/env bash
# https://www.cyberciti.biz/faq/how-do-i-empty-mysql-database/
# MUSER="$1"
# MPASS="$2"
MDB="$1"
 
# Detect paths
MYSQL=$(which mysql)
AWK=$(which awk)
GREP=$(which grep)
 
if [ $# -ne 1 ]
then
	echo "Usage: $0 {MySQL-Database-Name}"
	echo "Drops all tables from a MySQL"
	exit 1
fi
 
TABLES=$($MYSQL $MDB -e 'show tables' | $AWK '{ print $1}' | $GREP -v '^Tables' )
 
for t in $TABLES
do
	echo "Deleting $t table from $MDB database..."
	$MYSQL $MDB -e "drop table $t"
done
