#!/usr/bin/env bash
## Author: Michael Ramsey
## https://gitlab.com/mikeramsey/wizard-server-checkup/
## Objective Find cPanel/Cyberpanel Server's common issues and check HTT{ Global Domlogs Stats for last 5 days for all domains.
## How to use.
# ./wizard_server_checkup.sh
# sh wizard_server_checkup.sh
##
# wget -qN https://gitlab.com/mikeramsey/wizard-server-checkup/-/raw/master/wizard_server_checkup.sh ;sudo bash wizard_server_checkup.sh;> wizard_server_checkup.sh && printf 'y\n' |rm wizard_server_checkup.sh;
#

#Allow users to see full domlog paths
FullDomlogPathToggle=$1

#Detect Control panel
if [ -f /usr/local/cpanel/cpanel ]; then
    	# Cpanel check for /usr/local/cpanel/cpanel -V
    	ControlPanel="cpanel"
	ControlPanel_version=$(/usr/local/cpanel/cpanel -V)
	datetimeDcpumon=$(date +"%Y/%b/%d") # 2019/Feb/15
	#Current Dcpumon file
	DcpumonCurrentLOG="/var/log/dcpumon/${datetimeDcpumon}" # /var/log/dcpumon/2019/Feb/15
	#Setup datetimeDcpumonLast5_array
	declare -a datetimeDcpumonLast5_array=($(date +"%Y/%b/%d") $(date --date='1 day ago' +"%Y/%b/%d") $(date --date='2 days ago' +"%Y/%b/%d") $(date --date='3 days ago' +"%Y/%b/%d") $(date --date='4 days ago' +"%Y/%b/%d")); #for DATE in "${datetimeDcpumonLast5_array[@]}"; do echo $DATE; done;
	
	acesslog_sed="-ssl_log"
	HTTP_log="/usr/local/apache/logs/error_log"	
	HTTP_log_stderr="/usr/local/apache/logs/stderr.log"
	HTTP_log_restart="/usr/local/cpanel/logs/safeapacherestart_log"
	#Find how many domains on server
	cPanelUserDomainCount=$(sudo cat /etc/userdomains |wc -l)
	#Find how many cPanel accounts are on the server
	cPanelAccountNumber=$(find /var/cpanel/users -type f -print | wc -l)
	#Find Exim Queue Number of emails
	EximQueueNumber=$(exim -bpc)

elif [ -f /usr/bin/cyberpanel ]; then
    	# CyberPanel check /usr/bin/cyberpanel
    	ControlPanel="cyberpanel"
	ControlPanel_version=$(cat /usr/local/CyberCP/version.txt| sed -e 's|{"version":"||g' -e 's|","build":|.|g'| sed 's:}*$::')	

	acesslog_sed=".access_log"
	HTTP_log="/usr/local/lsws/logs/error.log"
	HTTP_log_stderr="/usr/local/lsws/logs/stderr.log"
	HTTP_log_restart="/usr/local/lsws/logs/lsrestart.log"

else
	echo "Not able to detect Control panel. Unsupported Control Panel exiting now"
	   exit 1;
	fi

CURRENTDATE=$(date +"%Y-%m-%d %T") # 2019-02-09 06:47:56
PreviousDay1=$(date --date='1 day ago' +"%Y-%m-%d")  # 2019-02-08
PreviousDay2=$(date --date='2 days ago' +"%Y-%m-%d") # 2019-02-07
PreviousDay3=$(date --date='3 days ago' +"%Y-%m-%d") # 2019-02-06
PreviousDay4=$(date --date='4 days ago' +"%Y-%m-%d") # 2019-02-05

#datetimeDom=$(date +"%d/%b/%Y") # 09/Feb/2019
#datetimeDom1DaysAgo=$(date --date='1 day ago' +"%d/%b/%Y")  # 08/Feb/2019
#datetimeDom2DaysAgo=$(date --date='2 days ago' +"%d/%b/%Y") # 07/Feb/2019
#datetimeDom3DaysAgo=$(date --date='3 days ago' +"%d/%b/%Y") # 06/Feb/2019
#datetimeDom4DaysAgo=$(date --date='4 days ago' +"%d/%b/%Y") # 05/Feb/2019

declare -a datetimeDomLast5_array=($(date +"%d/%b/%Y") $(date --date='1 day ago' +"%d/%b/%Y") $(date --date='2 days ago' +"%d/%b/%Y") $(date --date='3 days ago' +"%d/%b/%Y") $(date --date='4 days ago' +"%d/%b/%Y")); #for DATE in "${datetimeDomLast5_array[@]}"; do echo $DATE; done;


echo "=============================================================";	
echo "$ControlPanel Control Panel Detected"
echo "=============================================================";
echo "";


datetimeLinuxLogsToday=$(date +"%b %d") # Mar 28
datetimeLinuxLogs1DaysAgo=$(date --date='1 day ago' +"%b %d")  # Mar 27


#Find Hostname of server
hostname=$(hostname)
LastRebootDate=$(who -b | cut -d' ' -f13)
LastRebootTime=$(who -b | cut -d' ' -f14)
LASTBOOT=$(who -b|sed 's/.*system boot//g'|sed 's/^ *//;s/ *$//')
LinuxLastBootInLog=$(date -d "${LASTBOOT}" '+%b %d %T')
#echo $LinuxLastBootInLog
LinuxLastBootInLogFormat=$(date -d "${LinuxLastBootInLog}" --date='5 mins ago' '+%b %d %T')
#echo $LinuxLastBootInLogFormat
#Find Main IP
IP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)


main_function() {

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


echo "============================================="
uname -n

echo "Control Panel login Url"
if [ "${ControlPanel}" == "cpanel" ] ; then 
	echo "http://$IP:2086"
elif [ "${ControlPanel}" == "cyberpanel" ] ; then
	echo "http://$IP:8090"
fi

echo "ssh $IP"
echo "$OS $VER";uname -r;
echo $IP
echo "$ControlPanel Version: $ControlPanel_version"
if [ "${ControlPanel}" == "cpanel" ] ; then 
	echo "Domains on server: $cPanelUserDomainCount"
	echo "cPanel accounts on server $cPanelAccountNumber"
fi

echo "============================================="
echo "Filesystems Disk usage check"
df -h
echo ""
echo "Inodes Check"
df -i
echo "============================================="
echo "Show currently logged in users"
w
echo ""
echo "Last login history"
lastlog -b 0 -t 10
echo "============================================="
echo ""

echo "Finding init system in use.."
if [[ `/sbin/init --version 2> /dev/null` =~ upstart ]]; then echo upstart; InitSystem="Upstart";
      elif [[ `systemctl` =~ -\.mount ]]; then echo systemd;  InitSystem="systemd";
      elif [[ -f /etc/init.d/cron && ! -h /etc/init.d/cron ]]; then echo sysv-init; InitSystem="sysv-init";
      else echo UNKNOWN;
      fi
echo ""




#Webserver binaries

if [ -f /usr/local/cpanel/cpanel ]; then
	#Finding Webserver in Use and version.
	echo "Webserver Version and Type:"
	httpd -v
	httpd -M|grep mpm
	echo ""

	echo 'Apache ServerLimit and MaxRequestWorkers check';
	sudo grep -En 'ServerLimit|MaxRequestWorkers' /etc/apache2/conf/httpd.conf
	echo ""
	
	echo "Checking for Litespeed"
	/usr/local/lsws/bin/lshttpd -v
	echo ""

	#Finding system default PHP version
	echo "Finding system default PHP version"
	#php -v
	/usr/local/cpanel/bin/rebuild_phpconf --current
	echo ""

	#Checking for DSO
	echo "Checking for DSO: If found the EA4 multiphp profile should be installed for the server. LSAPI for standard and the Litespeed multiphp for LS enabled servers"
	yum list installed | grep ea-php70-php.x86_64
	echo ""

	#Checking php versions for low values due to bad defaults.
	echo "Finding global PHP settings. Low memory_limit of 32M can be cause of poor performance. Raise limits if detected."
	#for phpver in $(ls -1 /opt/cpanel/ |grep ea-php | sed 's/ea-php//g') ; do echo "PHP $phpver" ; /opt/cpanel/ea-php$phpver/root/usr/bin/php -i |grep -Ei 'memory_limit|post_max_size|upload_max_filesize|max_execution_time' && echo "" ; done
	for phpver in $(ls -1 /opt/cpanel/ |grep ea-php | sed 's/ea-php//g') ; do echo "PHP $phpver" ; /opt/cpanel/ea-php$phpver/root/usr/bin/php -i |grep -Ei 'memory_limit|post_max_size|upload_max_filesize|max_execution_time|session.save_path' && echo "" ; done

elif [ "${ControlPanel}" == "cyberpanel" ] ; then
	
	#Finding Webserver in Use and version.
	echo "Webserver Type and Version:"
	echo "Checking for Litespeed/Openlitespeed"
	/usr/local/lsws/bin/lshttpd -v
	echo ""

	#Finding system default PHP version
	echo "Finding system default PHP version"
	php -v
	echo ""
	#Checking php versions for low values due to bad defaults.
	echo "Finding global PHP settings. Low memory_limit of 32M can be cause of poor performance. Raise limits if detected."
	for version in $(ls /usr/local/lsws|grep lsphp); do echo ""; echo "PHP $version"; /usr/local/lsws/${version}/bin/php -i |grep -Ei 'memory_limit|post_max_size|upload_max_filesize|max_execution_time'; done

fi





echo ""

#Finding Mysql version in use
echo "MySQL/MariaDB version"
mysql -V
echo ""

echo 'See MySQL Connection count'
sudo netstat -plant |grep :3306 |wc -l
echo ""


#Firewall binaries
csf=/usr/sbin/csf
apf=/usr/local/sbin/apf
apf2=/etc/apf/apf.conf
firewalld=firewall-cmd

echo "Finding active Firewall"
   if hash apf 2>/dev/null; then
    firewall="a"
	echo "APF detected"
    elif [ -e "$apf 2>/dev/null" ]; then
    firewall="a"
	echo "APF detected at /usr/local/sbin/apf"
    elif [ -e "$apf2 2>/dev/null" ]; then
    firewall="a"
  echo "APF detected at /etc/apf/apf.conf"
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
  echo "Service check for PowerDNS|Named:"
  systemctl status pdns|| systemctl status named
  echo ""
  echo "Service check for Exim|Postfix:"
  systemctl status exim && echo -e "\e[31mExim email queue: $EximQueueNumber\e[0m"||systemctl status postfix && echo -e "\e[31mPostfix email queue: $(postqueue -p)\e[0m"
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
  echo "Service check for PowerDNS|Named:"
  service pdns status|| service named status
  echo ""
  echo "Service check for Exim|Postfix:"
  service exim status  && echo -e "\e[31mExim email queue: $EximQueueNumber\e[0m"||service postfix status && echo -e "\e[31mPostfix email queue: $(postqueue -p)\e[0m"
  echo ""
  echo "Service check for Dovecot:"
  service dovecot status
elif [ $InitSystem == "Upstart" ]; then
  echo "Checking important Services....:"
  echo "Service check for Apache/Litespeed:"
  service httpd status
  echo ""
  echo "Service check for MySQL/MariaDB:"
  service mysql status
  echo ""
  echo "Service check for PowerDNS|Named:"
  service pdns status|| service named status
  echo ""
  echo "Service check for Exim|Postfix:"
  service exim status  && echo -e "\e[31mExim email queue: $EximQueueNumber\e[0m"||service postfix status && echo -e "\e[31mPostfix email queue: $(postqueue -p)\e[0m"
  echo ""
  echo "Service check for Dovecot:"
  service dovecot status
else
  echo "Init System not found"
fi

echo ""

if [ "${ControlPanel}" == "cpanel" ]; then
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

elif [ "${ControlPanel}" == "cyberpanel" ] ; then
	CurrentDomlogsPath="/home/*/logs"
fi


echo "============================================================="
echo ""
echo "Check for /var/log/messages for last 20 error,critical, and kill errors"
echo "============================================================="
sudo grep -Ei 'oom|kill|mysql|Out of memory|critical|error' /var/log/messages | grep -viE 'Firewall|ftp' | tail -n 20
echo "============================================================="
echo ""
echo "Check ${HTTP_log_restart} for last 20"
echo "============================================================="
sudo tail -20 ${HTTP_log_restart}
echo "============================================================="
echo ""
echo "Check for MaxClients or MaxRequestWorker notifications in the HTTP error logs with sort"
echo "============================================================="
sudo grep Max ${HTTP_log}| grep -viE 'mod_security|ModSecurity'| tail -n10
echo "============================================================="
echo ""
echo "Check for stderr.log last 20"
echo "============================================================="
sudo tail -10 ${HTTP_log_stderr}
echo "============================================================="
echo ""
echo "Check HTTP error logs for last 20 errors from today"
echo "============================================================="
sudo grep -Ei 'warning|error|critical|killed' ${HTTP_log} | grep -E "$(date +"%b %d")|$(date '+%Y-%m-%d')"| grep -viE 'mod_security|ModSecurity|File does not exist|whm-server-status' | tail -20
echo "============================================================="
echo ""
echo "Check HTTP error logs for last 20 errors from yesterday"
echo "============================================================="
sudo grep -Ei 'warning|error|critical|killed' ${HTTP_log} | grep -E "$(date --date='1 day ago' +"%b %d")|$(date --date='1 day ago' "+%Y-%m-%d")"| grep -viE 'mod_security|ModSecurity|File does not exist|whm-server-status' | tail -20
echo "============================================================="
echo "Network Checks"
echo ""
#echo "See connections by IP"
readarray -t iparray < <(netstat -tun | tail -n +3 | awk '{print $5}' | cut -d: -f1 | grep -v 127.0.0.1 | sort | uniq -c | sort -n | tail| tr '/' '\n'); echo ""; echo "See Current Connections by IP"; for IP in "${iparray[@]}"; do echo $IP; done; echo ""; echo "Show unique IP's with whois IP, Country,and ISP"; echo ""; for IP in "${iparray[@]}"; do IP=$(echo $IP |grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"); whois -h whois.cymru.com " -c -p $IP"|cut -d"|" -f 2,4,5|grep -Ev 'IP|whois.cymru.com'; done
echo ""
#echo "See connection count by port"
readarray -t iparray < <(netstat -tuna | awk -F':+| +' 'NR>2{print $5}' | cut -d: -f1 | sort | uniq -c | sort -n| tail| tr '/' '\n'); echo ""; echo "See Current connection count by port"; for IP in "${iparray[@]}"; do echo $IP; done;
echo ""
#echo "Web traffic for ports 80|443 connections by IP"
readarray -t iparray < <(sudo netstat -tn 2>/dev/null | grep -E ':80|:443' | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head| tr '/' '\n'); echo ""; echo "Web traffic for ports 80|443 connections by IP"; for IP in "${iparray[@]}"; do echo $IP; done; echo ""; echo "Show unique IP's with whois IP, Country,and ISP"; echo ""; for IP in "${iparray[@]}"; do IP=$(echo $IP |grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"); whois -h whois.cymru.com " -c -p $IP"|cut -d"|" -f 2,4,5|grep -Ev 'IP|whois.cymru.com'; done
echo ""
#echo "Email traffic for ports 25|465|995|993 connections by IP"
readarray -t iparray < <(sudo netstat -tn 2>/dev/null | grep -E ':25|:465|:995|:993' | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head | tr '/' '\n'); echo ""; echo "Email traffic for ports 25|465|995|993 connections by IP"; for IP in "${iparray[@]}"; do echo $IP; done; echo ""; echo "Show unique IP's with whois IP, Country,and ISP"; echo ""; for IP in "${iparray[@]}"; do IP=$(echo $IP |grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"); whois -h whois.cymru.com " -c -p $IP"|cut -d"|" -f 2,4,5|grep -Ev 'IP|whois.cymru.com'; done
echo "";
echo "Show top hits from sar"
echo "============================================================="
echo "Todays sar memory usage top 5 occurrences: ${CURRENTDATE}"
sar -r | sort -rnk4 | head -n5
echo "============================================================="
echo "Yesterdays sar memory usage top 5 occurrences: ${PreviousDay1}"
sar -r -f /var/log/sa/sa$(date +%d -d yesterday) | sort -rnk4 | head -n5
echo "============================================================="
echo "Todays sar server load top 5 occurrences: ${CURRENTDATE}"
sar -q | sort -rnk4 | head -n5
echo "============================================================="
echo "Yesterdays sar server load top 5 occurrences: ${PreviousDay1}"
sar -q -f /var/log/sa/sa$(date +%d -d yesterday) | sort -rnk4 | head -n5
echo "============================================================="
echo "";
echo "Show top hits from Atop"
echo "============================================================="
echo "Todays atopsar top memory usage from: ${CURRENTDATE}"
atopsar -r /var/log/atop/atop_$(date +"%Y%m%d") -m -R 1 | awk 'NR<7{print $0;next}{print $0| "sort -k 3,3"}'  | head -11
echo "============================================================="
echo "Yesterdays atopsar top memory usage from: ${PreviousDay1}"
atopsar -r /var/log/atop/atop_$(date --date='1 day ago' +"%Y%m%d") -m -R 1 | awk 'NR<7{print $0;next}{print $0| "sort -k 3,3"}'  | head -11
echo "============================================================="
echo "Report about top-3 processes consuming most processor capacity from: ${CURRENTDATE}"
atopsar -r /var/log/atop/atop_$(date +"%Y%m%d") -R 1 -O | awk 'NR<7{print $0;next}{print $0| "sort -k 3,3"}'  | head -11
echo "============================================================="
echo "Report about top-3 processes consuming most processor capacity from: ${PreviousDay1}"
atopsar -r /var/log/atop/atop_$(date --date='1 day ago' +"%Y%m%d") -R 1 -O | awk 'NR<7{print $0;next}{print $0| "sort -k 3,3"}'  | head -11
echo "============================================================="
echo "Report about top-3 processes consuming most resident memory from: ${CURRENTDATE}"
atopsar -r /var/log/atop/atop_$(date +"%Y%m%d") -R 1 -G | awk 'NR<7{print $0;next}{print $0| "sort -k 3,3"}'  | head -11
echo "============================================================="
echo "Report about top-3 processes consuming most resident memory from: ${PreviousDay1}"
atopsar -r /var/log/atop/atop_$(date --date='1 day ago' +"%Y%m%d") -R 1 -G | awk 'NR<7{print $0;next}{print $0| "sort -k 3,3"}'  | head -11
echo "============================================================="
echo "Report about top-3 processes issuing most disk transfers from: ${CURRENTDATE}"
atopsar -r /var/log/atop/atop_$(date +"%Y%m%d") -R 1 -D | awk 'NR<7{print $0;next}{print $0| "sort -k 3,3"}'  | head -11
echo "============================================================="
echo "Report about top-3 processes issuing most disk transfers from: ${PreviousDay1}"
atopsar -r /var/log/atop/atop_$(date --date='1 day ago' +"%Y%m%d") -R 1 -D | awk 'NR<7{print $0;next}{print $0| "sort -k 3,3"}'  | head -11
echo "============================================================="
echo "";
echo "Show top load and user activity for past few days";
echo "============================================================="
echo "Todays top usage : ${CURRENTDATE}"
IFS=$'\n';DATE=$(date +"%Y%m%d"); for line in $(atopsar -p -r /var/log/atop/atop_"$DATE" | grep -v '[a-zA-Z]\+\|^$' | sort -rnk5 | head); do echo $line | awk '{print "At " $1 " time load was " $5}'; printf "Top load per user:\n";  echo $line | awk '{print $1}' | xargs -I {} atop -c -u -r /var/log/atop/atop_"$DATE" -b {} -e {} | cat | grep -v '^[a-zA-Z]\+\|^$' | awk '$10!="0%"{print}' | head; printf "Top 10 processes with CPU load:\n"; echo $line | awk '{print $1}' | xargs -I {} atop -c -r /var/log/atop/atop_"$DATE" -b {} -e {} | cat | grep -v '^[a-zA-Z]\+\|^$\|PID' | grep -o '[0-9]\+\%.*' | awk -F ' ' '{a[$2] += $1} END{for (i in a) printf ("%5d%% %s\n", a[i], i);}' | sort -rn | head | grep -v '0%'; printf "\n"; done;
echo "============================================================="
echo "Yesterdays top usage : ${PreviousDay1}"
IFS=$'\n';DATE2=$(date --date='1 day ago' +"%Y%m%d"); for line in $(atopsar -p -r /var/log/atop/atop_"$DATE2" | grep -v '[a-zA-Z]\+\|^$' | sort -rnk5 | head); do echo $line | awk '{print "At " $1 " time load was " $5}'; printf "Top load per user:\n";  echo $line | awk '{print $1}' | xargs -I {} atop -c -u -r /var/log/atop/atop_"$DATE2" -b {} -e {} | cat | grep -v '^[a-zA-Z]\+\|^$' | awk '$10!="0%"{print}' | head; printf "Top 10 processes with CPU load:\n"; echo $line | awk '{print $1}' | xargs -I {} atop -c -r /var/log/atop/atop_"$DATE2" -b {} -e {} | cat | grep -v '^[a-zA-Z]\+\|^$\|PID' | grep -o '[0-9]\+\%.*' | awk -F ' ' '{a[$2] += $1} END{for (i in a) printf ("%5d%% %s\n", a[i], i);}' | sort -rn | head | grep -v '0%'; printf "\n"; done;
echo "============================================================="
echo "3 days ago top usage : ${PreviousDay2}"
IFS=$'\n';DATE2=$(date --date='2 day ago' +"%Y%m%d"); for line in $(atopsar -p -r /var/log/atop/atop_"$DATE2" | grep -v '[a-zA-Z]\+\|^$' | sort -rnk5 | head); do echo $line | awk '{print "At " $1 " time load was " $5}'; printf "Top load per user:\n";  echo $line | awk '{print $1}' | xargs -I {} atop -c -u -r /var/log/atop/atop_"$DATE2" -b {} -e {} | cat | grep -v '^[a-zA-Z]\+\|^$' | awk '$10!="0%"{print}' | head; printf "Top 10 processes with CPU load:\n"; echo $line | awk '{print $1}' | xargs -I {} atop -c -r /var/log/atop/atop_"$DATE2" -b {} -e {} | cat | grep -v '^[a-zA-Z]\+\|^$\|PID' | grep -o '[0-9]\+\%.*' | awk -F ' ' '{a[$2] += $1} END{for (i in a) printf ("%5d%% %s\n", a[i], i);}' | sort -rn | head | grep -v '0%'; printf "\n"; done;

echo "============================================================="
echo ""
echo "Web Traffic Stats Check";

for DATE in "${datetimeDomLast5_array[@]}"; do
echo "=============================================================";
echo "Apache Dom Logs POST Requests for ${DATE}";
if [ "${FullDomlogPathToggle}" == 'f' -o "${FullDomlogPathToggle}" == 'y' ] ;then

	sudo grep -r "$DATE" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head
	echo ""
	echo "Apache Dom Logs GET Requests for ${DATE} for $Username"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep GET | awk '{print $1}' | cut -d: -f1| sort | uniq -c | sort -rn | head
	echo ""
	echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep -Ei 'crawl|bot|spider|yahoo|bing|google'| awk '{print $1}' | cut -d: -f1 | sort | uniq -c | sort -rn | head
	echo ""
	echo "Apache Dom Logs top ten IPs for ${DATE}"

	command=$(sudo grep -r "$DATE" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head);readarray -t iparray < <( echo "${command}" | tr '/' '\n'); echo ""; for IP in "${iparray[@]}"; do echo "$IP"; done; echo ""; echo "Show unique IP's with whois IP, Country,and ISP"; echo ""; for IP in "${iparray[@]}"; do IP=$(echo "$IP" |grep -Eo '([0-9]{1,3}[.]){3}[0-9]{1,3}|(*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:)))(%.+)?\s*)'); whois -h whois.cymru.com " -c -p $IP"|cut -d"|" -f 2,4,5|grep -Ev 'IP|whois.cymru.com'; done

	echo ""
	echo "Apache Dom Logs find the top number of uri's being requested for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head
	echo ""
	echo "";
	echo "View Apache requests per hour for ${DATE}";
	sudo grep -r "$DATE" $CurrentDomlogsPath | cut -d[ -f2 | cut -d] -f1 | awk -F: '{print $2":00"}' | sort -n | uniq -c
	echo ""
	echo "CMS Checks"
	echo ""
	echo "Wordpress Checks"
	echo "Wordpress Login Bruteforcing checks for wp-login.php for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep wp-login.php | cut -f 1 -d ":" |awk {'print $1,$6,$7'}  | sort | uniq -c | sort -n|tail| sort -rn
	echo ""
	echo "Wordpress Cron wp-cron.php(virtual cron) checks for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep wp-cron.php| cut -f 1 -d ":" |awk {'print $1,$6,$7'}  | sort | uniq -c | sort -n|tail| sort -rn
	echo ""
	echo "Wordpress XMLRPC Attacks checks for xmlrpc.php for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep xmlrpc.php| cut -f 1 -d ":" |awk {'print $1,$6,$7'}  | sort | uniq -c | sort -n|tail| sort -rn
	echo ""
	echo "Wordpress Heartbeat API checks for admin-ajax.php for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep admin-ajax.php| cut -f 1 -d ":" |awk {'print $1,$6,$7'}  | sort | uniq -c | sort -n|tail| sort -rn;

else
		sudo grep -r "$DATE" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f1 | sed 's:.*/::'|sed 's|-ssl_log||g'| sort | uniq -c | sort -rn | head
	echo ""
	echo "Apache Dom Logs GET Requests for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep GET | awk '{print $1}' | cut -d: -f1| sed 's:.*/::'|sed 's|-ssl_log||g' | sort | uniq -c | sort -rn | head
	echo ""
	echo "Apache Dom Logs Top 10 bot/crawler requests per domain name for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep -Ei 'crawl|bot|spider|yahoo|bing|google'| awk '{print $1}' | cut -d: -f1 | sed 's:.*/::'|sed 's|-ssl_log||g'| sort | uniq -c | sort -rn | head
	echo ""
	echo "Apache Dom Logs top ten IPs for ${DATE}"

	command=$(sudo grep -r "$DATE" $CurrentDomlogsPath | grep POST | awk '{print $1}' | cut -d: -f2 | sort | uniq -c | sort -rn | head);readarray -t iparray < <( echo "${command}" | tr '/' '\n'); echo ""; for IP in "${iparray[@]}"; do echo "$IP"; done; echo ""; echo "Show unique IP's with whois IP, Country,and ISP"; echo ""; for IP in "${iparray[@]}"; do IP=$(echo "$IP" |grep -Eo '([0-9]{1,3}[.]){3}[0-9]{1,3}|(*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:)))(%.+)?\s*)'); whois -h whois.cymru.com " -c -p $IP"|cut -d"|" -f 2,4,5|grep -Ev 'IP|whois.cymru.com'; done

	echo ""
	echo "Apache Dom Logs find the top number of uri's being requested for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep POST | awk '{print $7}' | cut -d: -f2 | sort | uniq -c | sort -rn | head
	echo ""
	echo "";
	echo "View Apache requests per hour for ${DATE}";
	sudo grep -r "$DATE" $CurrentDomlogsPath | cut -d[ -f2 | cut -d] -f1 | awk -F: '{print $2":00"}' | sort -n | uniq -c
	echo ""
	echo "CMS Checks"
	echo ""
	echo "Wordpress Checks"
	echo "Wordpress Login Bruteforcing checks for wp-login.php for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep wp-login.php | cut -f 1 -d ":" | sed 's:.*/::'|sed 's|-ssl_log||g' |awk {'print $1,$6,$7'}  | sort | uniq -c | sort -n|tail| sort -rn
	echo ""
	echo "Wordpress Cron wp-cron.php(virtual cron) checks for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep wp-cron.php| cut -f 1 -d ":" | sed 's:.*/::'|sed 's|-ssl_log||g' |awk {'print $1,$6,$7'}  | sort | uniq -c | sort -n|tail| sort -rn
	echo ""
	echo "Wordpress XMLRPC Attacks checks for xmlrpc.php for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep xmlrpc.php| cut -f 1 -d ":"  | sed 's:.*/::'|sed 's|-ssl_log||g' |awk {'print $1,$6,$7'}  | sort | uniq -c | sort -n|tail| sort -rn
	echo ""
	echo "Wordpress Heartbeat API checks for admin-ajax.php for ${DATE}"
	sudo grep -r "$DATE" $CurrentDomlogsPath | grep admin-ajax.php| cut -f 1 -d ":" | sed 's:.*/::'|sed 's|-ssl_log||g' |awk {'print $1,$6,$7'}  | sort | uniq -c | sort -n|tail| sort -rn;

fi
done;
echo "============================================================="
}

# log everything, but also output to stdout
main_function 2>&1 | tee -a server_checkup_$hostname-$(date +"%Y-%m-%d").txt

