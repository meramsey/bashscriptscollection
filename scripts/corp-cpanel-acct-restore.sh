#!/usr/bin/env bash
#Developed by Ross Batchelder and Mike Ramsey
#This script is designed to restore a users files/databases/DB users for a terminated account
#Script DOES NOT create the cpanel so that will need to be done manually first.
#Map first arguments to username and date 
USER=$1
DATE=$2
#Only prompt is username not provided
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
#Only prompt if DATE not provided
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
#Restore files portion. Checks rsync version as if its less then 3.1.0, --info=progress2 will fail...hard...
currentver="$(rsync --version |head -1 |awk '{print $3}')"
requiredver="3.1.0"
 if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then 
        echo "restoring files for $USER from $DATE . Rsync is going to do a dry run to gather the file list, so it may look like its doing nothing for a moment."
        rsync -azh --info=progress2 --no-inc-recursive /app/backups/"$DATE"/home/"$USER"/* /home/"$USER" ||exit 1
 else
        echo "restoring files for $USER from $DATE "
        rsync -azh /app/backups/"$DATE"/home/"$USER"/* /home/"$USER" ||exit 1
 fi
echo "File restore complete. Fixing permissions now."
LOCATION="/home/$USER/"
chown -R "$USER":"$USER" $LOCATION
chown "$USER":mail /home/$USER/etc/
chown "$USER":nobody /home/$USER/public_html/
chown root:root /home/$USER/srbackups/
/scripts/mailperm $USER
mkdir /home/"$USER"/restorelogs
chown "$USER":"$USER" /home/"$USER"/restorelogs
#rebuild horde 
/usr/local/cpanel/bin/update_horde_config --user=${USER} --full > /dev/null 2>&1
#regenerate maildir size
/scripts/generate_maildirsize --confirm --verbose ${USER} > /dev/null 2>&1
#Restore DB portion
echo "restoring databases for $USER from $DATE."
#Restores DB and then maps the DB to the correct cpanel. I blatently stole this form mramsey. What are you gonna do, fight me?
for DB in $(corpdbrestore -u "$USER" -l | sort -u | grep "$USER"); do echo "Creating $DB" ; uapi --user="$USER" Mysql create_database name="$DB" > /dev/null 2>&1; done
for DB in $(corpdbrestore -u "$USER" -l | sort -u | grep "$USER"); do echo "Dumping $DB from backups" ; sudo /app/bin/forcedbrestorecmd "$DB" "$DATE" >> /home/"$USER"/restorelogs/DBdump.txt 2>&1; sleep 5; done
for SQL in $(cd /root || exit; find "$USER"_*.sql); do DATABASE=$(echo "$SQL" |cut -d_ -f1-2);echo "Importing $DATABASE" ; mysql "$DATABASE" < /root/"$SQL"; done
for SQL in $(cd /root || exit; find "$USER"_*.sql); do mv /root/"$SQL" /home/"$USER"; done
echo "Recreating DB users and assigning them to their DBs"
#This part searches the users files for any magento/drupal/wordpress/joomla/prestashop config files and recreates their DB users with the proper passwords
#Magento
find /home/"$USER"/* -name 'env.php' -exec grep -HE "password" {} \;|awk '{print $4}'|sed "s/[',]//g" >> /home/"$USER"/password.txt
find /home/"$USER"/* -name 'env.php' -exec grep -HE "username" {} \;|awk '{print $4}'|sed "s/[',]//g" >> /home/"$USER"/dbuser.txt
find /home/"$USER"/* -name 'env.php' -exec grep -HE "dbname" {} \;|awk '{print $4}'|sed "s/[',]//g" >> /home/"$USER"/db.txt
#Drupal
find /home/"$USER"/* -name "settings.php" -exec grep -HE "'username'" {} \;| grep -Ev 'databasename|sqlusername|sqlpassword|databasefilename'|awk '{print $4}'|sed "s/[',]//g" >>/home/"$USER"/dbuser.txt
find /home/"$USER"/* -name "settings.php" -exec grep -HE "'password'" {} \;| grep -Ev 'databasename|sqlusername|sqlpassword|databasefilename'|awk '{print $4}'|sed "s/[',]//g" >> /home/"$USER"/password.txt
find /home/"$USER"/* -name "settings.php" -exec grep -HE "'database'" {} \;| grep -Ev 'databasename|sqlusername|sqlpassword|databasefilename'|awk '{print $4}'|sed "s/[',]//g" >> /home/"$USER"/db.txt
#Wordpress
find /home/"$USER"/* -name "wp-config.php" -exec grep -HE "'DB_USER'" {} \;|sed "s/( '//g" |sed "s/);//g" |awk '{print $2}'|sed "s/[',]//g" >> /home/"$USER"/dbuser.txt
find /home/"$USER"/* -name "wp-config.php" -exec grep -HE "'DB_PASSWORD'" {} \;|sed "s/( '//g" |sed "s/);//g" |awk '{print $2}'|sed "s/[',]//g" >> /home/"$USER"/password.txt
find /home/"$USER"/* -name "wp-config.php" -exec grep -HE "'DB_NAME'" {} \; |sed "s/( '//g" |sed "s/);//g" |awk '{print $2}'|sed "s/[',]//g" >> /home/"$USER"/db.txt
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
for DBUSER in $(cat /home/"$USER"/dbuser.txt); do PASSWORD=$(cat /home/"$USER"/password.txt | head -1  &&  echo "$(tail -n +2 /home/"$USER"/password.txt)" > /home/"$USER"/password.txt); uapi --user="$USER" Mysql create_user name="$DBUSER" password="$PASSWORD" >> /home/"$USER"/restorelogs/dbuser.txt 2>&1;done
#Add the DB user to the DB
for DBUSER in $(cat /home/"$USER"/dbuser.txt); do DATABASE=$(cat /home/"$USER"/db.txt | head -1  &&  echo "$(tail -n +2 /home/"$USER"/db.txt)" > /home/"$USER"/db.txt); uapi --user="$USER" Mysql set_privileges_on_database user="$DBUSER" database="$DATABASE" privileges=ALL > /dev/null 2>&1;done
#Restore addon domains and subdomains then reset their ownerships to user:nobody
echo "Recreating addon and subdomains"
#Whitelisting the account from the ACMEhook to make sure the addons can be restored without issue.
#Also setting the cpanels addondomain to unlimited so the addon restore does not fail.
touch /usr/local/cpanel/ACMEhooks/data/"$USER"
whmapi1 modifyacct user="$USER" MAXADDON=unlimited > /dev/null 2>&1
##Recreating addons here
sed -n '/addon_domains:/,/main_domain:/p' /app/backups/"$DATE"/var/cpanel/userdata/"$USER"/main |grep -Ev 'addon_domains|main_domain'| awk '{print $1}'| sed "s/://g" >> /home/"$USER"/addon.txt
sed -n '/addon_domains:/,/main_domain:/p' /app/backups/"$DATE"/var/cpanel/userdata/"$USER"/main |grep -Ev 'addon_domains|main_domain'| awk '{print $2}'| cut -d. -f1 >> /home/"$USER"/addonsub.txt
for ADDON in $(cat /home/"$USER"/addonsub.txt); do grep -R "$ADDON".* /app/backups/"$DATE"/var/cpanel/userdata/"$USER" | grep "documentroot:" |grep -v SSL |awk '{print $2}' >> /home/"$USER"/addondocroot.txt ;done
sed -i "s/[/]/%2F/g" /home/"$USER"/addondocroot.txt
for SUB in $(cat /home/"$USER"/addonsub.txt); do ADD=$(cat /home/"$USER"/addon.txt | head -1  &&  echo "$(tail -n +2 /home/"$USER"/addon.txt)" > /home/"$USER"/addon.txt); DOC=$(cat /home/"$USER"/addondocroot.txt | head -1)  &&  echo "$(tail -n +2 /home/"$USER"/addondocroot.txt)" > /home/"$USER"/addondocroot.txt; cpapi2 --user="$USER" AddonDomain addaddondomain dir="$DOC" newdomain="$ADD" subdomain="$SUB" >> /home/"$USER"/restorelogs/addon.txt 2>&1; done
##recreating subdomains here
sed '0,/sub_domains:/d' /app/backups/"$DATE"/var/cpanel/userdata/"$USER"/main | sed "s/[ -]//g" >> /home/"$USER"/subdomain1.txt
sed '0,/sub_domains:/d' /app/backups/"$DATE"/var/cpanel/userdata/"$USER"/main | sed "s/[ -]//g" |cut -d. -f1 >> /home/"$USER"/subdomain.txt
sed '0,/sub_domains:/d' /app/backups/"$DATE"/var/cpanel/userdata/"$USER"/main | sed "s/[ -]//g" | cut -d. -f2-3 >> /home/"$USER"/rootdomain.txt
for SUB in $(cat /home/"$USER"/subdomain1.txt); do cat /app/backups/"$DATE"/var/cpanel/userdata/"$USER"/"$SUB" |grep "documentroot:" |grep -v SSL|awk '{print $2}'; done >> /home/"$USER"/subdocroot.txt
sed -i "s/[/]/%2F/g" /home/"$USER"/subdocroot.txt
for SUBDOMAIN in $(cat /home/"$USER"/subdomain.txt); do ROOTDOMAIN=$(cat /home/"$USER"/rootdomain.txt | head -1  &&  echo "$(tail -n +2 /home/"$USER"/rootdomain.txt)" > /home/"$USER"/rootdomain.txt); DOC=$(cat /home/"$USER"/subdocroot.txt | head -1)  &&  echo "$(tail -n +2 /home/"$USER"/subdocroot.txt)" > /home/"$USER"/subdocroot.txt; cpapi2 --user="$USER" SubDomain addsubdomain domain="$SUBDOMAIN" rootdomain="$ROOTDOMAIN" dir="$DOC" disallowdot=1 >> /home/"$USER"/restorelogs/sub.txt 2>&1; done
## Fixing addon/subdomains perms to user:nobody
for DOCROOT in $(/usr/bin/uapi --user="$USER" DomainInfo domains_data format=list|awk '/documentroot/ {print $2}'); do chown "$USER":nobody $DOCROOT ;done
#Restore email forwarders, catchalls and crons
echo "Restoring email forwarders and crons"
for DOMAIN in $(cat /etc/userdomains |grep "$USER" |awk '{print $1}'|sed "s/://g"); do rsync -azh /app/backups/"$DATE"/etc/valiases/$DOMAIN /etc/valiases/$DOMAIN > /dev/null 2>&1;done
rsync -azh /app/backups/"$DATE"/var/spool/cron/"$USER" /var/spool/cron/"$USER" > /dev/null 2>&1
#Cleanup
rm -f /home/"$USER"/db.txt /home/"$USER"/dbuser.txt /home/"$USER"/password.txt /home/"$USER"/addon.txt /home/"$USER"/addonsub.txt /home/"$USER"/addondocroot.txt /home/"$USER"/subdomain1.txt /home/"$USER"/subdomain.txt /home/"$USER"/rootdomain.txt /home/"$USER"/subdocroot.txt /usr/local/cpanel/ACMEhooks/data/"$USER"
chown "$USER":"$USER" /home/"$USER"/restorelogs/*
echo "Account restore has been completed! Go team venture!"
echo "If any issues are seen, logs are output to /home/"$USER"/restorelogs/"
