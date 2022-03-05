#!/usr/bin/env bash
## Author: Michael Ramsey
##Bulk modsec rule copying to a batch of cPanel accounts from one user
## For use on cPanel/WHM servers using ConfigServer Modsecurity plugin https://www.configserver.com/cp/cmc.html
## How to use: Run with the cpanel username you want to copy the rule from. It will copy that persons ModSecurity rules to all cPanel account usernames listed in the file "accounts.txt" 
#nano bulk_modsec_whitelist.sh username
# bash bulk_modsec_whitelist.sh username

#Find Apache vHost directory structure to add rule
if [ -d "/usr/local/apache/conf/userdata/ssl/2_4/" ]; then
   #echo "Folder /usr/local/apache/conf/userdata/ssl/2_4/ exists"
   CurrentApacheVhostPath='/usr/local/apache/conf/userdata/ssl/2_4/'
   echo "$CurrentApacheVhostPath"
elif [ -d "/usr/local/apache/conf/userdata/ssl/2_2/" ]; then
   #echo "Folder /usr/local/apache/conf/userdata/ssl/2_2/ exists"
   CurrentApacheVhostPath='/usr/local/apache/conf/userdata/ssl/2_2/'
   echo "$CurrentApacheVhostPath"
elif [ -d "/usr/local/apache/conf/userdata/ssl/2/" ]; then
   #echo "Folder /usr/local/apache/conf/userdata/ssl/2/ exists"
   CurrentApacheVhostPath='/usr/local/apache/conf/userdata/ssl/2/'
   echo "$CurrentApacheVhostPath"
else
   echo "Unable to detect current CurrentApacheVhostPath for this server"
fi


while read -r LINE; do
mkdir "$CurrentApacheVhostPath""$LINE"/
chmod 0755 "$CurrentApacheVhostPath""$LINE"/
cp "$CurrentApacheVhostPath""$1"/modsec.conf "$CurrentApacheVhostPath""$LINE"/modsec.conf
chmod 0644 "$CurrentApacheVhostPath""$LINE"/modsec.conf
echo "$CurrentApacheVhostPath${LINE}/modsec.conf has been created"
cat $CurrentApacheVhostPath"$LINE"/modsec.conf
done < accounts.txt

echo "All Modsec rules have been copied from $1 to the input accounts"
