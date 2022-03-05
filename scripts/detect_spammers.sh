#!/usr/bin/env bash
## How to use
## or like the below the number is to specify custom days ago value to lookup steps.
##  /app/bin/find_spammers.sh 5

#Find absolute path to Perl binary
PerlLocation=$(type -P perl)

#Day of the week
DOW=$(date +%u)

EmailLog="/var/log/maillog"

EmailLog2="/var/log/mail.log"

###########
## Default to 3days ago unless $DaysAgo manually specified.
#
DaysAgo=${1:-3}

echo "Here's the top 10 senders of messages via script since 12AM this morning:"
/bin/sed -ne "s|$(date +%F).*cwd=\(/home[^ ]*\).*$|\1|p" $EmailLog | sort | uniq -c | awk '{printf "%05d %s\n",$1,$2}' | sort | tail -n 10

## If then loop to detect day of the week and decide if we should search through compressed or main log
if [[ "${DOW}" = +(3|4|5|6) ]]; then
   echo ""
   echo "And the top 10 script senders yesterday:"
   /bin/sed -ne "s|$(date +%F --date="1 day ago").*cwd=\(/home[^ ]*\).*$|\1|p" $EmailLog | sort | uniq -c | awk '{printf "%05d %s\n",$1,$2}' | sort | tail -n 10
   
elif [[ "${DOW}" = +(7|1|2) ]]; then
   echo ""
   echo "And the top 10 script senders yesterday:"
   sudo zgrep cwd ${EmailLog}* | grep -v /var/spool | grep -E $(date +%F --date="1 day ago")| awk -F"cwd=" '{print $2}' | awk '{print $1}' | grep '/home/'| sort | uniq -c | sort -n | tail -n 10

else
   echo "Unknown day of the week"
fi

echo ""
echo "The top 10 senders via direct SMTP AUTH since 12AM this morning:"
$PerlLocation -lsne '/$today.* \[([0-9.]+)\]:.+dovecot_(?:login|plain):([^\s]+).* for (.*)/ and $sender{$2}{r}+=scalar (split / /,$3) and $sender{$2}{i}{$1}=1; END {foreach $sender(keys %sender){printf"%05d Hosts=%03d Auth=%s\n",$sender{$sender}{r},scalar (keys %{$sender{$sender}{i}}),$sender;}}' -- -today=$(date +%F) $EmailLog | sort | tail -n 10

echo ""
echo "And the top 10 SMTP AUTH senders yesterday:"
$PerlLocation -lsne '/$today.* \[([0-9.]+)\]:.+dovecot_(?:login|plain):([^\s]+).* for (.*)/ and $sender{$2}{r}+=scalar (split / /,$3) and $sender{$2}{i}{$1}=1; END {foreach $sender(keys %sender){printf"%05d Hosts=%03d Auth=%s\n",$sender{$sender}{r},scalar (keys %{$sender{$sender}{i}}),$sender;}}' -- -today=$(date +%F --date="1 day ago") $EmailLog | sort | tail -n 10

## X Days Ago email searches which defaults to 3 days if unspecified.
## If then loop to detect day of the week and decide if we should search through compressed or main log
if [[ "${DOW}" = +(3|4|5|6) ]]; then
   echo ""
   echo "And the top 10 script senders $DaysAgo days ago:"
   /bin/sed -ne "s|$(date +%F --date="$DaysAgo day ago").*cwd=\(/home[^ ]*\).*$|\1|p" $EmailLog | sort | uniq -c | awk '{printf "%05d %s\n",$1,$2}' | sort | tail -n 10
   
elif [[ "${DOW}" = +(7|1|2) ]]; then
   echo ""
echo "And the top 10 script senders $DaysAgo days ago:"
sudo zgrep cwd ${EmailLog}* | grep -v /var/spool | grep -E $(date +%F --date="$DaysAgo day ago")| awk -F"cwd=" '{print $2}' | awk '{print $1}' | grep '/home/'| sort | uniq -c | sort -n | tail -n 10

else
   echo "Unknown day of the week"
fi

### This may not work if not later in week as its not searching compressed logs.
echo ""
echo "And the top 10 SMTP AUTH senders $DaysAgo days ago:"
$PerlLocation -lsne '/$today.* \[([0-9.]+)\]:.+dovecot_(?:login|plain):([^\s]+).* for (.*)/ and $sender{$2}{r}+=scalar (split / /,$3) and $sender{$2}{i}{$DaysAgo}=1; END {foreach $sender(keys %sender){printf"%05d Hosts=%03d Auth=%s\n",$sender{$sender}{r},scalar (keys %{$sender{$sender}{i}}),$sender;}}' -- -today=$(date +%F --date="$DaysAgo day ago") $EmailLog | sort | tail -n 10


echo ""
echo "Here are the top 10 users sending mail via local SMTP since 12AM this morning (identify_local_connection):"
grep $(date +%F) $EmailLog | grep "identify_local_connection" | grep -v -e root -e mailman -e mailnull | awk '{print $9}' | cut -d"=" -f2 | sort | uniq -c | awk '{printf "%05d %s\n",$1,$2}' | sort | tail -n 10

# List the email forwarders that are forwarding the most
echo ""
echo "Here are the top 10 email forward destinations (this takes a while):"
forwarders=($(for i in /etc/valiases/*; do grep -v -e mailman -e fail $i | cut -d':' -f2- | tr ',' $'\n' | sed 's/ //' | grep -v ".autorespond" ; done | sort | uniq))
forwarder_total=${#forwarders[@]}
forwarder_count=()
for (( j = 0 ; j<=$(($forwarder_total-1)) ; j++ )); do forwarder_count[$j]=$(grep "=> ${forwarders[$j]}" $EmailLog | wc -l | awk '{printf "%05d %s\n",$1,$2}'); done
for (( k = 0 ; k<=$(($forwarder_total-1)) ; k++ )); do echo ${forwarder_count[$k]} ${forwarders[$k]} ; done | sort -n | tail

echo ""
echo "Here's a list of processes connected to Exim. They ***Might*** be spamming."
/usr/sbin/lsof -i | grep smtp | grep -v exim
echo "If that was empty, it means there aren't any we're done here in any case."
