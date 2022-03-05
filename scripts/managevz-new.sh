#!/usr/bin/env bash
## Author: Michael Ramsey
##
## Objective: Openvz toolkit to allow rapid login to core VPS's enabling quotas
## How to use:
# ./managevz.sh action VPS_IP
company_domain='hosting.com'

Action="${1}"
IP="${2}"
if [[ -z $Action || -z $IP ]]; then
    echo -e "\e[1;31mOne or more variables are undefined\e[0m"
    echo -e "\e[1;31mPlease specify the action and IP\e[0m"
    echo -e  "\e[1;31mEX: ./managevz.sh enablequota/enter IP\e[0m"
    exit 1
fi
if ! echo "$IP" |egrep -q '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}'; then
  echo -e "\e[1;31mERROR: This is not a valid IP address\e[0m"
  exit
fi

NODE=$(traceroute -m 10 -w 1 $IP |grep -v "* * *"|grep "${company_domain}"| tail -1 |grep -v $IP |awk '{print $2}')
if [ "$NODE" = "" ]; then
NODE=$(traceroute -m 10 -w 1 $IP |grep -v "* * *"|grep 10. |tail -1 |awk '{print $2}')
fi
#Gathers the CTID
CTID=$(ssh -t -q "$NODE" "sudo vzlist -a |grep "$IP"" |grep -v "Warning" |head -2 |tail -1 2>/dev/null;)
CTID2=$(echo $CTID |awk '{print $1}'); echo -e "\e[1;33mVPS is on node $NODE, Its CTID is $CTID2\e[0m"

if [ "${Action}" == 'enablequota' ] ;then
        # Enable Second Level Quotas
        ssh -t -q "$NODE" "sudo vzctl stop $CTID2 && sudo vzquota drop $CTID2 && sudo vzctl set $CTID2 --quotaugidlimit 3000 --save && sudo vzctl start $CTID2;sudo vzctl enter $CTID2;" 2>/dev/null; echo -e "\e[1;33mEnabled Quotas for $CTID2 on $Server\e[0m"
elif [ "${Action}" == 'enter' ] ;then
        # Vzctl enter VPS
        ssh -tt -q "$NODE" "sudo vzctl enter $CTID2;" 2>/dev/null
elif [ "${Action}" == 'oom' ] ;then
        # Check VZ errors like oom for VPS
        command="sudo grep $CTID2 /var/log/messages;"
        ssh -t -q "$NODE" ${command} 2>/dev/null
elif [ "${Action}" == 'raiseinodes' ] ;then
        # Increase Inodes for VPS temporarily
        # set default value if one is not passed in with "managevz.sh raiseinodes VPSIP 2500000"
        DefRaise_INODE="2500000";
        INODE="${3:-$DefRaise_INODE}"
        command="sudo /usr/sbin/vzctl set $CTID2 --diskinodes $INODE:$INODE --save --force;"
        ssh -t -q "$NODE" ${command} 2>/dev/null

fi



ssh -t -q  "$NODE" "sudo vzctl exec2 $CTID2 "whmapi1 create_user_session user="root" service="whostmgrd" locale=en | grep url | awk '{print $2}'""
