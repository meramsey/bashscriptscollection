#!/usr/bin/env bash
## Author: Michael Ramsey
## Enable HTTP_AUTHORIZATION in Apache vhost for a cPanel user. 
## nano enable_http_auth.sh
## run as root sh enable_http_auth.sh username

#Ensure "userdata/ssl/2_4/" data structure is created Source:https://forums.cpanel.net/threads/add-line-of-code-to-vhost.598267/
/scripts/ensure_vhost_includes --all-users


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


#Make needed path and file with proper permissions
mkdir "$CurrentApacheVhostPath""$1"/
chmod 0755 "$CurrentApacheVhostPath""$1"/
touch "$CurrentApacheVhostPath""$1"/auth.conf
chmod 0644 "$CurrentApacheVhostPath""$1"/auth.conf
echo 'SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1' >> "$CurrentApacheVhostPath""$1"/auth.conf
echo "$CurrentApacheVhostPath$1/auth.conf created"
cat "$CurrentApacheVhostPath""$1"/auth.conf
/scripts/rebuildhttpdconf 

echo 'If the rebuildhttpdconf completed without errors please do restart httpd services via'
echo 'service httpd restart'

