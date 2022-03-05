#!/usr/bin/env bash
# Migrate a list of Plesk website domains to blaqpanel.
# 

# DEST_SERVER='....'
DEST_SERVER=$1
domains_file=$2
remote_root_pass=$3

DOMAINS_ARRAY=()
HOSTS_FILE_DOMAINS_ARRAY=()

echo 'Generate a new passwordless ssh key for the migration'
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "root@$(hostname --fqdn)"

# TODO: needs testing.
# Accept remote server root password and maybe use ssh-askpass to provide it to ssh-copy-id
yum install -y sshpass
sshpass -p "$remote_root_pass" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519.pub root@$DEST_SERVER
echo 'Testing connection by checking uptime on remote server...'
ssh root@"${DEST_SERVER}" "uptime"
if [ $? -ne 0 ]; then
	# then add it to remote server manually
	echo "Please enter root password for $DEST_SERVER when prompted..."
	ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519.pub root@$DEST_SERVER
fi

ssh root@"${DEST_SERVER}" 'wget -q -O /usr/local/blaqpanel/bin/mysql-clear-database-as-root.sh https://raw.githubusercontent.com/meramsey/blaqpanel/main/scripts/mysql-clear-database-as-root.sh && chmod +x /usr/local/blaqpanel/bin/mysql-clear-database-as-root.sh;'

for domain in $(cat $domains_file); do
	echo "$domain";
	DOMAINS_ARRAY+=("$domain")
	HOSTS_FILE_DOMAINS_ARRAY+=("$domain")
	HOSTS_FILE_DOMAINS_ARRAY+=("www.$domain")
	
	# Lookup domain path/docroot
	SRC_DOCROOT="$(plesk bin site --info "${domain}" | grep 'WWW-Root'| awk -F':' '{print $2}'|sed -e 's/^[ \t]*//')/"
	
	# Lookup DB name
	for WP in $(find "${SRC_DOCROOT}" -type f -name "wp-config.php"); do 
		dbname=$(cat "$WP"|sed -e 's/^[ \t]*//'|tr -d '[:blank:]'|grep -E "^define\('DB_NAME'"|awk -F\' '{print $4}'); 
		dbuser=$(cat "$WP"|sed -e 's/^[ \t]*//'|tr -d '[:blank:]'|grep -E "^define\('DB_USER'"|awk -F\' '{print $4}'); 
		dbpass=$(cat "$WP"|sed -e 's/^[ \t]*//'|tr -d '[:blank:]'|grep -E "^define\('DB_PASSWORD'"|awk -F\' '{print $4}'); 
		#echo -e "\e[1;33mFound DB user $dbuser with password $dbpass currently assigned to the database $dbname in : ${WP}\e[0m";
		echo -e "\e[1;33mFound the database $dbname in : ${WP}\e[0m";
	done
	
	# Destination docroot
	DEST_DOCROOT="/var/www/${domain}/html/"

	# Lookup New DB Name
	DEST_DB_NAME="$(ssh root@"${DEST_SERVER}" "grep DB_NAME $DEST_DOCROOT/wp-config.php|awk -F\' '{print $4}'"|awk -F\' '{print $4}')"
	DEST_DB_USER="$(ssh root@"${DEST_SERVER}" "grep DB_USER $DEST_DOCROOT/wp-config.php|awk -F\' '{print $4}'"|awk -F\' '{print $4}')"
	DEST_DB_PASSWORD="$(ssh root@"${DEST_SERVER}" "grep DB_PASSWORD $DEST_DOCROOT/wp-config.php|awk -F\' '{print $4}'"|awk -F\' '{print $4}')"
	ssh root@"${DEST_SERVER}" "rsync -azh $DEST_DOCROOT/wp-config.php $DEST_DOCROOT/wp-config-bp-bak.php"
	echo "SRC DOCROOT: $SRC_DOCROOT"
	echo "Destination DOCROOT: $DEST_DOCROOT"
	echo "SRC DB_NAME: $dbname"
	echo "Destination DB_NAME: $DEST_DB_NAME"
	echo "Destination DB_USER: $DEST_DB_USER"
	echo "Destination DB_PASSWORD: $DEST_DB_PASSWORD"
	
	echo "Starting Rsync of files from ${SRC_DOCROOT} > ${DEST_SERVER}":"${DEST_DOCROOT}"
	# rsync -azh --info=progress2 --exclude wp-config.php "${SRC_DOCROOT}" "${DEST_SERVER}":"${DEST_DOCROOT}" --dry-run
	rsync -azh --info=progress2 --exclude wp-config.php "${SRC_DOCROOT}" "${DEST_SERVER}":"${DEST_DOCROOT}"
	
	echo "Copying current ${SRC_DOCROOT}wp-config.php > ${SRC_DOCROOT}wp-config-bp-bak.php to update with new DB information"
	rsync -azh ${SRC_DOCROOT}wp-config.php ${SRC_DOCROOT}wp-config-bp-bak.php
	
	echo "Updating ${SRC_DOCROOT}wp-config-bp-bak.php with new DB information"
	echo "Updating DB_USER from: $dbuser to: $DEST_DB_USER"
	VARIABLE_FIND='DB_USER'; VARIABLE_REPLACE="define('DB_USER', '${DEST_DB_USER}');"; sed -i "/${VARIABLE_FIND}/c${VARIABLE_REPLACE}" ${SRC_DOCROOT}wp-config-bp-bak.php
	
	echo "Updating DB_USER from: $dbname to: $DEST_DB_NAME"
	VARIABLE_FIND='DB_NAME'; VARIABLE_REPLACE="define('DB_NAME', '${DEST_DB_NAME}');"; sed -i "/${VARIABLE_FIND}/c${VARIABLE_REPLACE}" ${SRC_DOCROOT}wp-config-bp-bak.php
	
	echo "Updating DB_PASSWORD from: $dbpass to: $DEST_DB_PASSWORD"
	VARIABLE_FIND='DB_PASSWORD'; VARIABLE_REPLACE="define('DB_PASSWORD', '${DEST_DB_PASSWORD}');"; sed -i "/${VARIABLE_FIND}/c${VARIABLE_REPLACE}" ${SRC_DOCROOT}wp-config-bp-bak.php
	
	echo "Copying ${SRC_DOCROOT}wp-config-bp-bak.php with new DB information > ${DEST_SERVER}":"${DEST_DOCROOT}wp-config.php"
	# rsync -azh --info=progress2 "${SRC_DOCROOT}wp-config-bp-bak.php" "${DEST_SERVER}":"${DEST_DOCROOT}wp-config.php" --dry-run
	rsync -azh --info=progress2 "${SRC_DOCROOT}wp-config-bp-bak.php" "${DEST_SERVER}":"${DEST_DOCROOT}wp-config.php"
		
	echo "Dumping DB $dbname > /root/databases_dumps/${dbname}.sql"
	mysqldump -uadmin -p"$(cat /etc/psa/.psa.shadow)" $dbname > "/root/databases_dumps/${dbname}.sql"; echo "${dbname}.sql exported" ;
	
	echo "Copying /root/databases_dumps/${dbname}.sql > ${DEST_SERVER}:${DEST_DOCROOT}${DEST_DB_NAME}.sql"
	rsync -azh --info=progress2 /root/databases_dumps/${dbname}.sql "${DEST_SERVER}":"${DEST_DOCROOT}${DEST_DB_NAME}.sql"
	
	echo "Dropping existing tables in Destination DB_NAME: $DEST_DB_NAME"
	ssh root@"${DEST_SERVER}" "/usr/local/blaqpanel/bin/mysql-clear-database-as-root.sh $DEST_DB_NAME"
	
	echo "Restoring ${DEST_DOCROOT}${DEST_DB_NAME}.sql to $DEST_DB_NAME"
	ssh root@"${DEST_SERVER}" "mysql $DEST_DB_NAME < ${DEST_DOCROOT}${DEST_DB_NAME}.sql"
	
	echo "Restore completed for ${DEST_DOCROOT}${DEST_DB_NAME}.sql to $DEST_DB_NAME"
	echo "Cleaning up mysql file from docroot ${DEST_DOCROOT}${DEST_DB_NAME}.sql"
	ssh root@"${DEST_SERVER}" "rm ${DEST_DOCROOT}${DEST_DB_NAME}.sql"
	echo "===================================="

done

echo 'Fixing Permissions on remote server.....'
ssh root@"${DEST_SERVER}" 'wget -q -O /usr/local/blaqpanel/bin/reset_perms_blaqpanel.sh https://raw.githubusercontent.com/meramsey/blaqpanel/main/scripts/reset_perms_blaqpanel.sh && chmod +x /usr/local/blaqpanel/bin/reset_perms_blaqpanel.sh; /usr/local/blaqpanel/bin/reset_perms_blaqpanel.sh'

echo "Please add the below line entry into your local hosts file to test the migrated websites:"
echo 
echo "${DEST_SERVER} ${HOSTS_FILE_DOMAINS_ARRAY[@]}"
