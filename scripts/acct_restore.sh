#!/usr/bin/env bash

#Map first arguments to username and date 
USER=$1
DATE=$2

Only prompt is username not provided
if [ "$USER" = "" ]; then
    echo -n "`tput setaf 2`What user would you like to restore?: `tput setaf 7`"
	read USER
fi

{
if [ ! -d /home/$USER ]; then
    echo "Wait a min... There is no active cpanel user by that name. BAIL OUT"
    exit 0
fi
}
ls -lh /app/backups/*/home/$USER/ |tail -100

Only prompt is DATE not provided
if [ "$DATE" = "" ]; then
    echo -n "`tput setaf 2`What date would you like to restore from? (EX:20191002): `tput setaf 7`"
	read DATE
fi

{
if [ ! -d /app/backups/$DATE ]; then
    echo "Im not seeing any backups from that date my lad. BAIL OUT"
    exit 0
fi
}
echo "restoring files for $USER from $DATE . Rsync is going to do a dry run to gather the file list, so it may look like its doing nothing for a moment."

#Restore files portion
rsync -azh --info=progress2 --no-inc-recursive /app/backups/"$DATE"/home/"$USER"/* /home/"$USER"
echo "File restore complete. Fixing permissions now."
LOCATION="/home/$USER/"
chown -R "$USER":"$USER" $LOCATION
chown "$USER":mail /home/$USER/etc/
chown "$USER":nobody /home/$USER/public_html/
/scripts/mailperm $USER

#rebuild horde 
/usr/local/cpanel/bin/update_horde_config --user=${USER} --full

#regenerate maildir size
/scripts/generate_maildirsize --confirm --verbose ${USER}

#Restore DB portion
echo "restoring databases for $USER from $DATE."

#Restores DB and then maps the DB to the correct cpanel. I blatently stole this form mramsey. What are you gonna do, fight me?
for DB in $(a2dbrestore -u "$USER" -l | sort -u | grep "$USER"); do echo "Creating $DB" ; uapi --user="$USER" Mysql create_database name="$DB" > /dev/null 2>&1; done
for DB in $(a2dbrestore -u $USER -l | sort -u | grep $USER); do echo "Restoring $DB" ; a2dbrestore -r $DATE $DB; done
echo "Recreating DB users and assigning them to their DBs"

#This part searches the users files for any magento/drupal/wordpress/joomla/prestashop config files and recreates their DB users

#Magento
find /home/"$USER"/* -name 'env.php' -exec grep -HE "password" {} \;|awk '{print $4}'|sed "s/[',]//g" >> /home/"$USER"/password.txt
find /home/"$USER"/* -name 'env.php' -exec grep -HE "username" {} \;|awk '{print $4}'|sed "s/[',]//g" >> /home/"$USER"/dbuser.txt
find /home/"$USER"/* -name 'env.php' -exec grep -HE "dbname" {} \;|awk '{print $4}'|sed "s/[',]//g" >> /home/"$USER"/db.txt

#Drupal
find /home/"$USER"/* -name "settings.php" -exec grep -HE "'username'" {} \;| grep -Ev 'databasename|sqlusername|sqlpassword|databasefilename'|awk '{print $4}'|sed "s/[',]//g" >>/home/"$USER"/dbuser.txt
find /home/"$USER"/* -name "settings.php" -exec grep -HE "'password'" {} \;| grep -Ev 'databasename|sqlusername|sqlpassword|databasefilename'|awk '{print $4}'|sed "s/[',]//g" >> /home/"$USER"/password.txt
find /home/"$USER"/* -name "settings.php" -exec grep -HE "'database'" {} \;| grep -Ev 'databasename|sqlusername|sqlpassword|databasefilename'|awk '{print $4}'|sed "s/[',]//g" >> /home/"$USER"/db.txt

#Wordpress
find /home/"$USER"/* -name "wp-config.php" -exec grep -HE "'DB_USER'" {} \; |awk '{print $3}'|sed "s/[',]//g" >> /home/"$USER"/dbuser.txt
find /home/"$USER"/* -name "wp-config.php" -exec grep -HE "'DB_PASSWORD'" {} \; |awk '{print $3}'|sed "s/[',]//g" >> /home/"$USER"/password.txt
find /home/"$USER"/* -name "wp-config.php" -exec grep -HE "'DB_NAME'" {} \; |awk '{print $3}'|sed "s/[',]//g" >> /home/"$USER"/db.txt

#Joomla
find /home/"$USER"/* -name "configuration.php" -exec grep -HE "user" {} \; |grep -Ev 'dbtype|dbprefix|ftp_user|smtpuser' |awk '{print $5}'|sed "s/[',;]//g" >> /home/"$USER"/dbuser.txt
find /home/"$USER"/* -name "configuration.php" -exec grep -HE "password" {} \; |grep -Ev 'dbtype|dbprefix|ftp_user|smtpuser' |awk '{print $5}'|sed "s/[',;]//g" >> /home/"$USER"/password.txt
find /home/"$USER"/* -name "configuration.php" -exec grep -HE "db" {} \; |grep -Ev 'dbtype|dbprefix|ftp_user|smtpuser' |awk '{print $5}'|sed "s/[',;]//g" >> /home/"$USER"/db.txt

#Prestashop old
find /home/"$USER"/* -name "settings.inc.php" -exec grep -HE "'_DB_USER_'" {} \;|awk '{print $2}'|sed "s/[',;]//g"| sed 's/.$//' >> /home/"$USER"/dbuser.txt
find /home/"$USER"/* -name "settings.inc.php" -exec grep -HE "'_DB_PASSWD_'" {} \;|awk '{print $2}'|sed "s/[',;]//g"| sed 's/.$//' >> /home/"$USER"/password.txt
find /home/"$USER"/* -name "settings.inc.php" -exec grep -HE "'_DB_NAME_'" {} \;|awk '{print $2}'|sed "s/[',;]//g"| sed 's/.$//' >> /home/"$USER"/db.txt

#Prestashop new 1.7 parameters.php
find /home/"$USER"/* -name "parameters.php" -exec grep -HE "'database_user'" {} \;|sed "s/[',=>]//g"| sed "s/database_user//g"|awk '{print $2}' >> /home/"$USER"/dbuser.txt
find /home/"$USER"/* -name "parameters.php" -exec grep -HE "'database_password'" {} \;|sed "s/[',=>]//g"| sed "s/database_password//g"|awk '{print $2}' >> /home/"$USER"/password.txt
find /home/"$USER"/* -name "parameters.php" -exec grep -HE "'database_name'" {} \;|sed "s/[',=>]//g"| sed "s/database_name//g"|awk '{print $2}' >> /home/"$USER"/db.txt

#Opencart config.php has two config.php with duplicate information in main and /admin/config.php so this is why there is a sort -u to dedupe that inline
find /home/"$USER"/* -name "config.php" -exec grep -HE "'DB_USERNAME'" {} \; |awk '{print $2}'| sort -u |sed "s/[',);]//g" >> /home/"$USER"/dbuser.txt
find /home/"$USER"/* -name "config.php" -exec grep -HE "'DB_PASSWORD'" {} \; |awk '{print $2}'| sort -u |sed "s/[',);]//g" >> /home/"$USER"/password.txt
find /home/"$USER"/* -name "config.php" -exec grep -HE "'DB_DATABASE'" {} \; |awk '{print $2}'| sort -u |sed "s/[',);]//g" >> /home/"$USER"/db.txt

#Recreate all the DB users
for DBUSER in $(cat /home/"$USER"/dbuser.txt); do PASSWORD=$(cat /home/"$USER"/password.txt | head -1  &&  echo "$(tail -n +2 /home/"$USER"/password.txt)" > /home/"$USER"/password.txt); uapi --user="$USER" Mysql create_user name="$DBUSER" password="$PASSWORD" > /dev/null 2>&1;done

#Add the DB user to the DB
for DBUSER in $(cat /home/"$USER"/dbuser.txt); do DATABASE=$(cat /home/"$USER"/db.txt | head -1  &&  echo "$(tail -n +2 /home/"$USER"/db.txt)" > /home/"$USER"/db.txt); uapi --user="$USER" Mysql set_privileges_on_database user="$DBUSER" database="$DATABASE" privileges=ALL > /dev/null 2>&1;done
rm -f /home/"$USER"/db.txt /home/"$USER"/dbuser.txt /home/"$USER"/password.txt
echo "Account restore has been completed! Go team venture!"
 fi
