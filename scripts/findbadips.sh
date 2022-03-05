#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective: Find malicious IP's attacking a cPanel server
## How to use.
# ./findbadips.sh
# sh findbadips.sh
#
#Find Hostname of server
hostname=$(hostname)

#Find server's IP's
ifconfig | grep inet | awk '{print $2}' > ifconfigips

#Match IPv4 only from Server's IPs
grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" ifconfigips | sort -nr | uniq | tee >> serverips

main_function() {
#Find Malicious IP's

echo "Checking Domlogs for high hit IP's"
sudo grep -r "$(date +"%d/%b/%Y")" /usr/local/apache/domlogs/ | grep 'POST\|GET' | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head | tee >> ipdump

echo "Checking Domlogs for xmlrpc attack IP's"
sudo grep -s xmlrpc.php /usr/local/apache/domlogs/* | grep 'POST\|GET' | grep "$(date +"%d/%b/%Y")" | cut -d ' ' -f-1 | sort| uniq -c | tr ':' '\t' | sort -nr | column -t | head -n25 | tee >> ipdump

echo "Checking Exim too many connections errors for malicious IP's"
sudo grep "too many connections" /var/log/exim_mainlog | awk '{ print $5 }' | cut -d[ -f2| cut -d] -f1| sort | uniq -c | sort -n | tail | tee >> ipdump

echo "ouput dumped stats found"
cat ipdump
echo ""
#extract IP's from ipdump results
grep -Eo "(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])" ipdump | sort | uniq >> ipdumpsorted

#Remove localhost IP
sed -i '/127.0.0.1/d' ./ipdumpsorted

#Remove Server IP's from possible bad IP's list https://unix.stackexchange.com/questions/28158/is-there-a-tool-to-get-the-lines-in-one-file-that-are-not-in-another
grep -F -x -v -f ifconfigips ipdumpsorted >> externalmaliciousips

echo "Found external IPs that may be malicious"
cat externalmaliciousips
echo ""
# Shows IP information for all possible malicious external IP's :whois -h whois.cymru.com " -v IP"
for i in $(cat externalmaliciousips); do whois -h whois.cymru.com " -c -p $i" >> ipswhoislist; done; awk '!x[$0]++' ipswhoislist;
echo ""
echo "ipdump file contains all raw logs about IP's and hits from domlog searches"
echo "externalmaliciousips file contains all external IP's found"
echo "ipswhoislist shows whois for all IPs in externalmaliciousips"
echo "Once the desired IP's are known they should be put in a file named badips 1 IP per line and the below command ran to block them"
echo "wget -N https://gitlab.com/mikeramsey/bulk-block-ips/raw/master/bulkblockips.sh; sudo sh bulkblockips.sh badips;"
}

# log everything, but also output to stdout
main_function 2>&1 | tee -a "$hostname"-findbadIPs.txt

