#!/usr/bin/env bash
# Reset all domains permissions to defaults post migration from another server.

for dir in $(ls -d /var/www/*/html); do
	domain=$(echo $dir|sed -e 's|/var/www/||g' -e 's|/html||g');
	user_name=$(echo $domain| cut -c1-32); 
	echo "Fixing permissions for Domain: $domain User: $user_name path: /var/www/$domain/html/";
	chown -R "${user_name}":www-data /var/www/$domain/html/
	chown -R "${user_name}":www-data /var/www/$domain/html/logs/
	chmod -R g+w /var/www/$domain/html
	chmod -R g+s /var/www/$domain/html
	find /var/www/$domain/html -type f -exec chmod 664 {} +
	find /var/www/$domain/html -type d -exec chmod 2775 {} +
	echo
	echo "Permissions have been reset for $domain"
done


restart_lsws(){
    # kill detached lsphp processes and restart ols
    killall -9 lsphp >/dev/null 2>&1
    systemctl stop lsws >/dev/null 2>&1
    systemctl start lsws   
}

echo 'Killing detached lsphp processes and restarting OLS/LSWS webserver'
restart_lsws