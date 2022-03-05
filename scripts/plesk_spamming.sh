#!/usr/bin/env bash

today=`date '+%b  %-d'`
yesterday=`date -d yesterday '+%b  %-d'`

echo -e "\e[93mLet's take a look at the number of emails in the queue. You can run 'postqueue -p' to list the emails.\e[0m"

sudo postqueue -p | grep -c "^[A-Z0-9]"

echo ""
echo -e "\e[93mTop senders from today, $today:\e[0m"
sudo grep -s "$today" /var/log/maillog | grep "postfix/smtpd" | sed -ne '/sasl_username/p' | cut -f10 -d ' ' | cut -f2 -d= | sort | uniq -cd | sort -rn | head

#sudo grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" /var/log/mail.log | sort | uniq -c | sort -n | tail -n 10


echo ""
echo -e "\e[93mTop senders from yesterday, $yesterday:\e[0m" 
sudo zgrep "$yesterday" /var/log/{maillog.processed.1.gz,mail*} | grep "postfix/smtpd" | sed -ne '/sasl_username/p' | cut -f10 -d ' ' | cut -f2 -d= | sort | uniq -cd | sort -rn | head

echo ""
echo -e "\e[93mTop-10 IPs that connected to Postfix today, $today: \e[0m" 
sudo grep -s "$today" /var/log/maillog | grep "connect from" | grep -v "disconnect from" | cut -f9 -d ' ' | cut -f2 -d[ | tr -d ] | sort | uniq -cd | sort -rn | head
