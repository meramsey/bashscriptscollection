#!/usr/bin/env bash

DOMAIN=$1

if [ $# -ne 1 ]; then
        echo "Requires a primary domain name"
        echo "Example: $0 example.com"
        echo "Will provide some useful information about the account's disk usage."
        exit
fi

echo -e "\e[33mDisk usage of $DOMAIN, Mb:\e[0m \n"

plesk db "SELECT ROUND((SUM(httpdocs) / 1048576) + (SUM(httpsdocs) / 1048576) + (SUM(subdomains) / 1048576) + (SUM(web_users) / 1048576), 2) AS Web, ROUND(0 + (SUM(mailboxes) / 1048576) + (SUM(maillists) / 1048576), 2) AS Mail, ROUND(0 + (SUM(dbases) / 1048576), 2) AS 'Databases', ROUND((SUM(logs) / 1048576), 2) AS Logs, ROUND((SUM(domaindumps) / 1048576), 2) AS Backups FROM disk_usage AS disk_usage INNER JOIN domains AS domains ON domains.id = disk_usage.dom_id WHERE dom_id IN (SELECT id FROM domains WHERE name = '$DOMAIN');"

echo ''
echo -e "\e[33mDisk space used by web files:\e[0m"

du /var/www/vhosts/$DOMAIN -h --max-depth=1

echo ''
echo -e "\e[33mEmail account disk usage:\e[0m"
du /var/qmail/mailnames/$DOMAIN -h --max-depth=1 | sed 's+/var/qmail/mailnames/++'

echo ''
echo -e "\e[33mMySQL usage:\e[0m"

plesk db "SELECT table_schema 'Database',  ROUND((sum(data_length + index_length)/1024/1024), 2) AS 'Size in (MB)' FROM information_schema.TABLES  WHERE table_schema IN (SELECT name FROM data_bases WHERE dom_id IN (SELECT id FROM domains WHERE name = '$DOMAIN')) GROUP BY table_schema;"

