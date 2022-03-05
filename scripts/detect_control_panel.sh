#!/usr/bin/env bash
#Detect Control panel
if [ -f /usr/local/cpanel/cpanel ]; then
    	# Cpanel check for /usr/local/cpanel/cpanel -V
    	ControlPanel="cpanel"
elif [ -f /usr/bin/cyberpanel ]; then
    	# CyberPanel check /usr/bin/cyberpanel
    	ControlPanel="cyberpanel"

else
	echo "Not able to detect Control panel. Unsupported Control Panel exiting now"
	   exit 1;
fi



#Check which package Manager
YUM_CMD=$(which yum)
APT_GET_CMD=$(which apt-get)

#ZONE=$(firewall-cmd --get-default-zone)
# whois tcp port 43 might not be opened
#firewall-cmd --zone=$ZONE --add-port=43/tcp --permanent
#firewall-cmd --reload


#Check for whois installed status and optional install prompt
pkg='whois'
which $pkg > /dev/null 2>&1
if [ $? == 0 ]
then
echo "$pkg is already installed. "
else
read -p "$pkg is not installed. Answer yes/no if want installation_ " request
if  [ $request == "yes" ]
then
	if [[ ! -z $YUM_CMD ]]; then
	    	yum install -y $pkg
	elif [[ ! -z $APT_GET_CMD ]]; then
		apt-get install -y $pkg
	else
	   echo "error can't install required whois packages. Whois lookups support not enabled"
	   #exit 1;
	fi
fi
fi

EXTERNALIP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)



Cpanel check
/usr/local/cpanel/cpanel -V

CyberPanel check
/usr/bin/cyberpanel
