#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective Find A Cyberpanel Users Domlogs Stats for last 5 days for all of their domains.
## https://gitlab.com/Cyberpaneltoolsnscripts/
## How to use.
# ./CyberpanelSnapshotByCyberpanelUser.sh username
#./CyberpanelSnapshotCyberpanelUser.sh exampleuserbob
#
##bash <(curl https://gitlab.com/Cyberpaneltoolsnscripts/CyberpanelSnapshot-by-Cyberpanel-user/raw/master/CyberpanelSnapshotByCyberpanelUser.sh || wget -O - https://gitlab.com/Cyberpaneltoolsnscripts/CyberpanelSnapshot-by-Cyberpanel-user/raw/master/CyberpanelSnapshotByCyberpanelUser.sh) exampleuserbob;
##

domlogs_path="${user_homedir}/logs/"

echo "=========================================================================================="
echo "Checking for WP-Login Bruteforcing:"
echo "=========================================================================================="
grep -rs $(date +"%d/%b/%Y:") ${domlogs_path} | grep wp-login.php | awk {'print $1,$6,$7'} | sort | uniq -c | sort -n | tail -10
echo "=========================================================================================="

echo "Checking for XMLRPC Abuse:"
echo "=========================================================================================="
grep -rs $(date +"%d/%b/%Y:") ${domlogs_path} | grep xmlrpc | awk {'print $1,$6,$7'} | sort | uniq -c | sort -n | tail -10
echo "=========================================================================================="

echo "Checking for Bot Traffic:"
echo "=========================================================================================="
grep -rs $(date +"%d/%b/%Y:") ${domlogs_path} | grep "bot\|spider\|crawl" | awk {'print $6,$14'} | sort | uniq -c | sort -n | tail -15
echo "=========================================================================================="

echo "Checking the Top Hits Per Site Per IP:"
echo "=========================================================================================="
grep -rs $(date +"%d/%b/%Y:") ${domlogs_path} | awk {'print $1,$6,$7'} | sort | uniq -c | sort -n | tail -15
echo "=========================================================================================="

echo "Checking the IPs that Have Hit the Server Most and What Site:"
echo "=========================================================================================="
grep -rs $(date +"%d/%b/%Y:") ${domlogs_path} | awk {'print $1'} | sort | uniq -c | sort -n | tail -25
echo "=========================================================================================="

