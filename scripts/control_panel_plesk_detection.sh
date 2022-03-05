#!/usr/bin/env bash
Username=$1
CurrUser=$(id -u -n)

#Detect Control panel
if [ -f /usr/local/cpanel/cpanel ]; then
    	# Cpanel check for /usr/local/cpanel/cpanel -V
    	ControlPanel="cpanel"
	datetimeDcpumon=$(date +"%Y/%b/%d") # 2019/Feb/15
	#Current Dcpumon file
	DcpumonCurrentLOG="/var/log/dcpumon/${datetimeDcpumon}" # /var/log/dcpumon/2019/Feb/15
	#Setup datetimeDcpumonLast5_array
	declare -a datetimeDcpumonLast5_array=($(date +"%Y/%b/%d") $(date --date='1 day ago' +"%Y/%b/%d") $(date --date='2 days ago' +"%Y/%b/%d") $(date --date='3 days ago' +"%Y/%b/%d") $(date --date='4 days ago' +"%Y/%b/%d")); #for DATE in "${datetimeDcpumonLast5_array[@]}"; do echo $DATE; done;

	user_homedir="/home/${Username}"
	user_accesslogs="/home/${Username}/logs/"
	domlogs_path="/usr/local/apache/domlogs/${Username}/"
	acesslog_sed="-ssl_log"
	
elif [ -f /usr/bin/cyberpanel ]; then
    	# CyberPanel check /usr/bin/cyberpanel
    	ControlPanel="cyberpanel"
	
	#Get users homedir path
	user_homedir=$(sudo egrep "^${Username}:" /etc/passwd | cut -d: -f6)	
	domlogs_path="${user_homedir}/logs/"
	acesslog_sed=".access_log"

elif [ -f /usr/local/psa/core.version ]; then
    	# Plesk check /usr/local/psa/core.version
    	ControlPanel="plesk"
	
	#Get users homedir path
	user_homedir=$(sudo egrep "^${Username}:" /etc/passwd | cut -d: -f6)	
	domlogs_path="${user_homedir}/logs/"
	acesslog_sed=".access_ssl_log"

else
	echo "Not able to detect Control panel. Unsupported Control Panel exiting now"
	   exit 1;
	fi
echo "=============================================================";	
echo "$ControlPanel Control Panel Detected"
echo "User Homedirectory: ${user_homedir}"
echo "User Domlogs Path: ${domlogs_path}"
echo "=============================================================";
echo "";

