#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective bulk suspend/unsuspend accounts from accounts.txt 
## How to use: as root or sudo
#nano bulk_unsuspend_accounts.sh
#sudo bash bulk_unsuspend_accounts.sh
#

while read -r LINE; do


sudo /scripts/unsuspendacct $LINE
echo '$LINE unsuspended'
done < accounts.txt

