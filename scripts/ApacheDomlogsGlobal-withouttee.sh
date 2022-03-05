#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective Find A cPanel Server Global Domlogs Stats for last 5 days for all of their domains.
## How to use.
# ./ApacheDomlogsGlobal.sh
# sh ApacheDomlogsGlobal.sh
#
#echo $1

#Find Hostname of server
hostname=$(hostname)
LastRebootDate=$(who -b | cut -d' ' -f13)
LastRebootTime=$(who -b | cut -d' ' -f14)
LASTBOOT=$(who -b|sed 's/.*system boot//g'|sed 's/^ *//;s/ *$//')
cPanelUserDomainCount=$(sudo cat /etc/userdomains |wc -l)

#Detect OS
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

#...part of script without redirection...

{
    #...part of script with redirection...

cPanelVersion=$(cat /usr/local/cpanel/version)

echo "============================================="
uname -n
echo "$OS $VER";uname -r;
echo "cPanel/WHM Version: $cPanelVersion"
echo "Domains on server: $cPanelUserDomainCount"
echo "============================================="
echo "Filesystems Disk usage check"
df -h
echo ""
echo "Inodes Check"
df -i
echo "============================================="
echo ""
echo "Finding init system in use.."
if [[ `/sbin/init --version` =~ upstart ]]; then echo server is using upstart; InitSystem="Upstart";
elif [[ `systemctl` =~ -\.mount ]]; then echo server is using systemd; InitSystem="systemd";
elif [[ -f /etc/init.d/cron && ! -h /etc/init.d/cron ]]; then echo  server is using sysv-init; InitSystem="sysv-init";
else echo cannot tell init system; InitSystem="Unknown Init"; fi
echo ""


#Webserver binaries

#Finding Webserver in Use and version.
echo "Webserver Version and Type:"
httpd -v
echo ""

#Finding system default PHP version
echo "Finding system default PHP version"
php -v
echo ""

#Finding Mysql version in use
echo "MySQL/MariaDB version"
mysql -V
echo ""



#Firewall binaries
csf=/usr/sbin/csf
apf=/usr/local/sbin/apf
firewalld=firewall-cmd

echo "Finding active Firewall"
   if hash apf 2>/dev/null; then
    firewall="a"
	echo "APF detected"
    elif [ -e "$apf 2>/dev/null" ]; then
    firewall="a"
	echo "APF detected"
    elif hash csf 2>/dev/null; then
	firewall="c"
	echo "CSF detected"
    elif [ -e "$csf 2>/dev/null" ]; then
	firewall="c"
	echo "CSF detected"
    elif hash firewalld 2>/dev/null; then
	firewall="f"
	echo "FirewallD detected"
    else
	echo "No supported firewall installed"
    fi
echo ""
#Show Last Reboot
echo "Last Reboot: $LASTBOOT"
echo ""
echo "Show current uptime and load"
uptime
echo ""

if [ $InitSystem == "systemd" ]; then
  echo "Checking important Services....:"
  echo "Service check for Apache/Litespeed:"
  systemctl status httpd
  echo ""
  echo "Service check for MySQL/MariaDB:"
  systemctl status mysql
  echo ""
  echo "Service check for Named:"
  systemctl status named
  echo ""
  echo "Service check for Exim:"
  systemctl status exim
  echo ""
  echo "Service check for Dovecot:"
  systemctl status dovecot

elif [ $InitSystem == "sysv-init" ]; then
  echo "Checking important Services....:"
  echo "Service check for Apache/Litespeed:"
  service httpd status
  echo ""
  echo "Service check for MySQL/MariaDB:"
  service mysql status
  echo ""
  echo "Service check for Named:"
  service named status
  echo ""
  echo "Service check for Exim:"
  service exim status
  echo ""
  echo "Service check for Dovecot:"
  service dovecot status
else
  echo "Init System not found"
fi

echo ""
#Apache Log locations cPanel
##This directory contains the log data for the user's account, which exists on a webserver that runs EasyApache 3.
DomLogsEA3="/home/domlogs/"

##This directory contains the log data for the user's account, which exists on a webserver that runs EasyApache 4.
DomLogsEA4="/var/log/apache2/domlogs/"


DomlogsPathUniversal="/usr/local/apache/domlogs/"
DomlogsPathEA4="/var/log/apache2/domlogs/"

if [ -e "$DomlogsPathUniversal" ]; then
   echo "Folder $DomlogsPathUniversal exists"
   CurrentDomlogsPath=$DomlogsPathUniversal
elif [ -e "$DomlogsPathEA4" ]; then
   echo "Folder $DomlogsPathEA4 exists"
   CurrentDomlogsPath=$DomlogsPathEA4
else
   echo "Unable to detect current DomlogsPath for this server"
fi



CURRENTDATE=$(date +"%Y-%m-%d %T") # 2019-02-09 06:47:56
PreviousDay1=$(date --date='1 day ago' +"%Y-%m-%d")  # 2019-02-08
PreviousDay2=$(date --date='2 days ago' +"%Y-%m-%d") # 2019-02-07
PreviousDay3=$(date --date='3 days ago' +"%Y-%m-%d") # 2019-02-06
PreviousDay4=$(date --date='4 days ago' +"%Y-%m-%d") # 2019-02-05

datetimeDom=$(date +"%d/%b/%Y") # 09/Feb/2019
datetimeDom1DaysAgo=$(date --date='1 day ago' +"%d/%b/%Y")  # 08/Feb/2019
datetimeDom2DaysAgo=$(date --date='2 days ago' +"%d/%b/%Y") # 07/Feb/2019
datetimeDom3DaysAgo=$(date --date='3 days ago' +"%d/%b/%Y") # 06/Feb/2019
datetimeDom4DaysAgo=$(date --date='4 days ago' +"%d/%b/%Y") # 05/Feb/2019

echo "Apache Dom Logs POST Requests for ${CURRENTDATE}" 
sudo grep -r $datetimeDom $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head
echo "" 
echo "Apache Dom Logs GET Requests for ${CURRENTDATE}" 
sudo grep -r "$datetimeDom" $CurrentDomlogsPath | grep GET | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${CURRENTDATE}" 
sudo grep -r "$datetimeDom" $CurrentDomlogsPath | egrep -i '(crawl|bot|spider|yahoo|bing|google)'| awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs top ten IPs for ${CURRENTDATE}" 
sudo grep -r "$datetimeDom" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs find the top number of uri's being requested for ${CURRENTDATE}" 
sudo grep -r "$datetimeDom" $CurrentDomlogsPath | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head 
echo "=============================================================" 

#Past few days stats
echo "Apache Dom Logs POST Requests for ${PreviousDay1}" 
sudo grep -r "$datetimeDom1DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs GET Requests for ${PreviousDay1}" 
sudo grep -r "$datetimeDom1DaysAgo" $CurrentDomlogsPath | grep GET | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${PreviousDay1}" 
sudo grep -r "$datetimeDom1DaysAgo" $CurrentDomlogsPath | egrep -i '(crawl|bot|spider|yahoo|bing|google)'| awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs top ten IPs for ${PreviousDay1}" 
sudo grep -r "$datetimeDom1DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs find the top number of uri's being requested for ${PreviousDay1}" 
sudo grep -r "$datetimeDom1DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head 
echo "=============================================================" 
echo "Apache Dom Logs POST Requests for ${PreviousDay2}" 
sudo grep -r "$datetimeDom2DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs GET Requests for ${PreviousDay2}" 
sudo grep -r "$datetimeDom2DaysAgo" $CurrentDomlogsPath | grep GET | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${PreviousDay2}" 
sudo grep -r "$datetimeDom2DaysAgo" $CurrentDomlogsPath | egrep -i '(crawl|bot|spider|yahoo|bing|google)'| awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs top ten IPs for ${PreviousDay2}" 
sudo grep -r "$datetimeDom2DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs find the top number of uri's being requested for ${PreviousDay2}" 
sudo grep -r "$datetimeDom2DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head 
echo "=============================================================" 
echo "Apache Dom Logs POST Requests for ${PreviousDay3}" 
sudo grep -r "$datetimeDom3DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs GET Requests for ${PreviousDay3}" 
sudo grep -r "$datetimeDom3DaysAgo" $CurrentDomlogsPath | grep GET | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${PreviousDay3}" 
sudo grep -r "$datetimeDom3DaysAgo" $CurrentDomlogsPath | egrep -i '(crawl|bot|spider|yahoo|bing|google)'| awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs top ten IPs for ${PreviousDay3}" 
sudo grep -r "$datetimeDom3DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs find the top number of uri's being requested for ${PreviousDay3}" 
sudo grep -r "$datetimeDom3DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head 
echo "=============================================================" 
echo "Apache Dom Logs POST Requests for ${PreviousDay4}" 
sudo grep -r "$datetimeDom4DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs GET Requests for ${PreviousDay4}" 
sudo grep -r "$datetimeDom4DaysAgo" $CurrentDomlogsPath | grep GET | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${PreviousDay4}" 
sudo grep -r "$datetimeDom4DaysAgo" $CurrentDomlogsPath | egrep -i '(crawl|bot|spider|yahoo|bing|google)'| awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs top ten IPs for ${PreviousDay4}" 
sudo grep -r "$datetimeDom4DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head 
echo "" 
echo "Apache Dom Logs find the top number of uri's being requested for ${PreviousDay4}" 
sudo grep -r "$datetimeDom4DaysAgo" $CurrentDomlogsPath | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head 
echo "=============================================================" 

} >> $hostname-ApachelogsGlobal.txt 2>$hostname-ApachelogsGlobal-errors.txt # ...and others as appropriate...

#...residue of script without redirection...
