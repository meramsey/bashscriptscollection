#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective bulk update all htaccess files in all accounts from accounts.txt 
## How to use: as root or sudo
#nano bulk_reverse_htaccess.sh
#sudo bash bulk_reverse_htaccess.sh
#

while read -r LINE; do
find /home/$LINE -type f -name '.htaccess' -print0 | xargs -0 sed -i /movingpage/d
echo '$LINE htaccess cleaned'
done < accounts.txt
