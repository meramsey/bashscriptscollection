#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective Find A Reseller's accounts and all of their domains for cPanel and update Serials.
## https://gitlab.com/cpaneltoolsnscripts/cpanel-find-reseller-domains-and-update-serial
## How to use.
## ./find_reseller_domains_updateSOA.sh resellerusername
## How to use without downloading and running
##bash <(curl https://gitlab.com/cpaneltoolsnscripts/cpanel-find-reseller-domains-and-update-serial/raw/master/find_reseller_domains_updateSOA.sh || wget -O - https://gitlab.com/cpaneltoolsnscripts/cpanel-find-reseller-domains-and-update-serial/raw/master/find_reseller_domains_updateSOA.sh) resellerusername;

Reseller="$1"; readarray -t reseller_acct_array < <(sudo grep $Reseller /etc/trueuserowners|awk -F":" '{print $1}'| tr '/' '\n');echo "Backing up /var/named to /var/named-backup_$(date +"%Y-%m-%d")"; sudo cp -a /var/named /var/named-backup_$(date +"%Y-%m-%d");echo ""; echo "Find $Reseller cPanel User's accounts"; echo ""; for ACCT in "${reseller_acct_array[@]}"; do echo $ACCT; done; readarray -t reseller_domains_array < <(echo ${reseller_acct_array[*]}|tr ' ' '\n'|sudo fgrep -f - /etc/userdomains|cut -d: -f1|rev|sort|awk 'NR!=1&&substr($0,0,length(p))==p{next}{p=$0".";print}'|rev|sort| tr '/' '\n');echo ""; echo "Find $Reseller cPanel User's Domains"; echo ""; for DOMAIN in "${reseller_domains_array[@]}"; do before_serial=$(sudo grep 'Serial Number' /var/named/${DOMAIN}.db | sed 's/;Serial Number//'| sed -e 's/^[ \t]*//'|grep -Ev '^\s*$|^#|^;|^\s*\#|;'); sudo sed -i '0,/RE/s/20[0-2][0-9]\{7\}/'`date +%Y%m%d%H`'/g' /var/named/${DOMAIN}.db && after_serial=$(sudo grep 'Serial Number' /var/named/${DOMAIN}.db | sed 's/;Serial Number//'| sed -e 's/^[ \t]*//'|grep -Ev '^\s*$|^#|^;|^\s*\#|;');echo "Incremented Serial for /var/named/${DOMAIN}.db from:${before_serial} to ${after_serial}"; done;
