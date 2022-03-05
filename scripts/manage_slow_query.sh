#!/usr/bin/env bash
## Author: Michael Ramsey
## https://gitlab.com/mikeramsey/manage-slow-query-logging
## Objective Enable Slow query logging for MySQL/MariaDB and allow user to see the logs.
## How to use. username state(on or off)
# ./manage_slow_query.sh username on
# bash manage_slow_query.sh username on
# Enable slow qyery log and symlink for user cooluser 
# bash manage_slow_query.sh cooluser on


Today=$(date +"%Y-%m-%d")

## Configure
####################

USER=$1
SLOWQUERYState=${2^^}
SLOWQUERYLOG="/var/log/mysql-slow.log"
###################

if [ -z "$1" ]
then
  echo "sorry you didn't give me a username"
  exit 2
fi

if [ -z "$2" ]
then
  echo "sorry you didn't give me a value(ON/OFF) to set slow_query_log too"
  exit 2
fi


echo "Show current status"
mysql -u root -e "SHOW GLOBAL VARIABLES LIKE '%slow_query_log%';"

#Backup current config
#cp /etc/my.cnf /etc/my.cnf-bak_"$Today"


#Setup Slow query logging
if [ "$SLOWQUERYState" == "ON" ] ; then
        echo "Setting up Slow query logging"
	if [ -f $SLOWQUERYLOG ]; then
   	echo "The SLOWQUERYLOG '$SLOWQUERYLOG' exists. All good to proceed." 
	echo "";
	else
   	echo "The SLOWQUERYLOG '$SLOWQUERYLOG' was not found. Creating it now" 
	echo "";
	touch $SLOWQUERYLOG
	fi

	echo "";
	echo "Ensuring correct perms and ownership on $SLOWQUERYLOG" 
	echo "";
	chown mysql:root $SLOWQUERYLOG
	chmod 640 $SLOWQUERYLOG
	
	echo "enable slow_query_log" 
	echo "";
	mysql -u root -e "set global slow_query_log = 'ON';" 
	
	echo "Setting slow_query_log path" 
	echo "";
	mysql -u root -e "set global slow_query_log_file ='$SLOWQUERYLOG';"
		
	echo "Symlink slow query log to users home directory: /home/$USER/mysql-slow.log" 
	echo "";
	ln -s $SLOWQUERYLOG /home/"$USER"/mysql-slow.log
	    
	echo "Add $USER to mysql group: usermod -a -G mysql $USER"
	echo "";
        usermod -a -G mysql "$USER"
		
	echo "chown file so its owned by $USER:mysql" 
	echo "";
	chown "$USER":mysql /home/"$USER"/mysql-slow.log 


#Disable Slow query logging
elif [ "$SLOWQUERYState" == "OFF" ] ; then
	echo "Disabling slow_query_log"
	echo "";
	mysql -u root -e "set global slow_query_log = 'OFF';"
	
	echo "Remove Symlink to users home directory: unlink /home/$USER/mysql-slow.log"
	echo "";
	unlink /home/"$USER"/mysql-slow.log
	
	echo "copy slow query log to $USER home directory /home/$USER/mysql-slow.log_$Today"
	echo "";
	cp $SLOWQUERYLOG /home/"$USER"/mysql-slow.log_"$Today"
	
	echo "chown $USER:$USER /home/$USER/mysql-slow.log_$Today"
	echo "";
	chown "$USER":"$USER" /home/"$USER"/mysql-slow.log_"$Today"
	    
	echo "remove $USER from mysql group. Setting back to own group: usermod -G ${USER} ${USER}"
	echo "";
        usermod -G "$USER" "$USER"

else 
	echo "No Slow Query Request Provided" 
	echo "";
	
        fi
echo "Show end status"
        mysql -u root -e "SHOW GLOBAL VARIABLES LIKE 'slow_query_log';"
