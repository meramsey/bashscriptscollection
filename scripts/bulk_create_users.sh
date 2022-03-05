#!/usr/bin/env bash
#bulk_create_users.sh
#nano bulk_create_users.sh


while read -r LINE; do
pssh -h ~/phosts -l root -p 10 -i -e ~/phosts_errorlog "useradd -M -N -r -s /usr/bin/tunnel_shell -c 'SoftEther VPN User' ${LINE}"
echo "######################################" >> accounts_created_status.txt
echo "$LINE created" >> accounts_created_status.txt
echo "######################################" >> accounts_created_status.txt
done < accounts.txt
