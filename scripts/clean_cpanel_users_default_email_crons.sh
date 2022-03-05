#!/usr/bin/env bash
#clean_cpanel_users_default_email_crons.sh
#nano clean_cpanel_users_default_email_crons.sh


while read -r LINE; do
cd /home/${LINE}/mail/new && find . -type f -exec grep -l 'Cron' '{}' \; -delete
echo "######################################" >> /root/accounts_cron_emails_cleaned_status.txt
echo "$LINE cleaned" >> /root/accounts_cron_emails_cleaned_status.txt
df -i >> /root/accounts_cron_emails_cleaned_status.txt
echo "######################################" >> /root/accounts_cron_emails_cleaned_status.txt
done < accounts.txt

#nano accounts.txt
#username1
#username2
