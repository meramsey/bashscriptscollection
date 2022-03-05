#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective: clean 2 weeks prior to tbllog_register
## https://gitlab.com/mikeramsey/whmcs-clear-register
## Inspired by: https://whmcs.community/topic/289637-database-cleanup-operations-tbllog_register-and-tblactivitylog/
## How to use.
# ./whmcs-register-clean.sh
# sh whmcs-register-clean.sh
# How to setup as a cron
# * * * * * /bin/sh /home/username/whmcs-register-clean.sh >/dev/null 2>&1

#Configure here
DB="database_name"
DBUSER="database_username"
DBPASS="Passwordhere"
#Stop configuring

#Date 2 weeks ago
date2w=$(date --date='2 week ago' +"%Y-%m-%d")

#/usr/bin/mysql -h "localhost" -u "database_username" "-pPasswordhere" -e "DELETE FROM tbllog_register WHERE created_at < $date2w" database_name
/usr/bin/mysql -h "localhost" -u "$DBUSER" "-p$DBPASS" -e "DELETE FROM tbllog_register WHERE created_at < $date2w" $DB
