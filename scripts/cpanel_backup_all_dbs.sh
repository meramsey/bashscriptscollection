#!/usr/bin/env bash
## Author: Michael Ramsey
## https://gitlab.com/mikeramsey/
## Objective Enable backing up all cPanel users databases via cPanel user/login or DBUSER with priveleges to all databases. This script utilizes uapi to list the current DB.
## How to use. 
# ./cpanel_backup_all_dbs.sh
# bash cpanel_backup_all_dbs.sh
# Example cron to use if file is located in main home dir of user. Make sure to "chmod +x cpanel_backup_all_dbs.sh" the file before setting as a cron.
# 0 2 * * * /bin/bash ${HOME}/cpanel_backup_all_dbs.sh



#######Start Configuring###############
#Set the cPanel login here or a db user with priveleges to all databases for backup purposes
DBUSER="username"
PASSWORD="password"

#Backup directory full or relative path
BACKUP_DIR="$HOME/backup"

#######Stop Configuring###############

#Set mysql conf location
MySQL_CNF="$HOME/.my.cnf"

#Generate DB backup username based on current user prefix.
NewDBUSER="${USER}_backup"

#use new DB user if DBUSER undefined
#DBUSER="${DBUSER:-$NewDBUSER}"

#Generate a password if none is set in script
#PASSWORD="${PASSWORD:-$(openssl rand -base64 14)}"

#fall back to scripts current working directory if no backup path defined.
BACKUP_DIR="${BACKUP_DIR:-$(pwd)}"


#Only prompt is username not provided
if [ "$DBUSER" = "" -o "$DBUSER" == 'username' ] && [ ! -f "$MySQL_CNF" ]; then
    echo -n "`tput setaf 2`What database user or cpanel ${USER} user would you like to use for backing up databases?: `tput setaf 7`"
	read DBUSER
fi

#Only prompt if password not provided
if [ "$PASSWORD" = "" -o "$PASSWORD" == 'password' ] && [ ! -f "$MySQL_CNF" ]; then
unset PASSWORD
PASSWORD=
echo -n "Please enter ${DBUSER}'s password: " 1>&2
while IFS= read -r -n1 -s char; do
  case "$( echo -n "$char" | od -An -tx1 )" in
  '') break ;;   # EOL
  ' 08'|' 7f')  # backspace or delete
      if [ -n "$PASSWORD" ]; then
        PASSWORD="$( echo "$PASSWORD" | sed 's/.$//' )"
        echo -n $'\b \b' 1>&2
      fi
      ;;
  ' 15') # ^U or kill line
      echo -n "$PASSWORD" | sed 's/./\cH \cH/g' >&2
      PASSWORD=''
      ;;
  *)  PASSWORD="$PASSWORD$char"
      echo -n '*' 1>&2
      ;;
  esac
done
echo
echo "${DBUSER} with $PASSWORD has been chosen"
echo "Please note: To update user or passwords please update the $MySQL_CNF file"
fi


# Create BACKUP_DIR path if not exist
mkdir -p "$BACKUP_DIR"


#Check if file exists. If it exists do nothing. If it does not exist create it based on above information.
if [ -f "$MySQL_CNF" ]; then
echo "The $MySQL_CNF file exists. All good to proceed with passwordless." 
echo "";
else
echo "The $MySQL_CNF file was not found. Creating it now" 
echo "";
cat >> "$HOME"/.my.cnf <<EOL
[client]
password="$PASSWORD"
user=$DBUSER
EOL
fi

#Secure permissions on mysql ~/.my.cnf
chmod 600 "$MySQL_CNF"

#Declare an arry
declare -a dbarray

#populate array with DB list from the cPanel user uapi
readarray -t dbarray < <(uapi Mysql list_databases |grep database| grep -v list_databases |sed 's/^[ \t]*//;s/[ \t]*$//'| sed 's/database: //g'| tr '/' '\n')

echo "Starting Database backups..."; echo ""; echo "Yessiree! This whole place would completely fall apart without old Claptrap keeping things humming along!"; echo ""
#loop through DB array and dump DB 
for DB in "${dbarray[@]}"; do 
mysqldump "$DB"| gzip > "${BACKUP_DIR}/${DB}-$(date +%F_%T).gz" && echo "${DB} exported to ${BACKUP_DIR}" ; done

echo "Make sure to backup these files offsite."
ls -lh "${BACKUP_DIR}" --time-style=+%D  | grep "$(date +%D)"

echo "";
echo "Claptrap: Sure thing, sir! Aaaand OPEN! Have a lovely afternoon, and thank you for using Hyperion Robot Services. Let me know if you have any other portal-rific needs!"
cat << "EOF"
       ,
       |
    ]  |.-._
     \|"(0)"| _]
     `|=\#/=|\/
      :  _  :
       \/_\/ 
        |=| 
        `-'  
EOF
