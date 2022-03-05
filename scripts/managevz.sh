#!/usr/bin/env bash
## Author: Michael Ramsey
##
## Objective: Openvz toolkit to allow rapid login to core VPS's enabling quotas
## How to use:
# ./managevz.sh action server VZID
#
# Add to ~/.bashrc
# alias vzoom='~/managevz.sh oom '
# alias vzquota='~/managevz.sh enablequota '
# alias vzinodes='~/managevz.sh raiseinodes '
#
#
company_domain='hosting.com'
company_rdns_suffix=".static.${company_domain}.com"

Action="${1}"
IP="${2}"
if [[ -z $Action || -z $IP ]]; then
    echo -e "\e[1;31mOne or more variables are undefined\e[0m"
    echo -e "\e[1;31mPlease specify the action and IP\e[0m"
    echo -e  "\e[1;31mEX: ./managevz.sh enablequota/enter IP\e[0m"
    exit 1
fi
NODE=$(traceroute -m 10 -w 1 $IP |grep "${company_domain}" |grep -v $IP |tail -1 |awk '{print $2}'| sed "s|.${company_rdns_suffix}||g")
CTID=$(ssh -t -q "$NODE" "sudo vzlist -a |grep "$IP"" |head -2 |tail -1 2>/dev/null;)
CTID2=$(echo $CTID |awk '{print $1}')
if [ "${Action}" == 'enablequota' ] ;then
        # Enable Second Level Quotas
        echo "Finding VPS Node";
        NODE=$(traceroute -m 10 -w 1 $IP |grep "${company_domain}" |grep -v $IP |tail -1 |awk '{print $2}'| "s|.${company_rdns_suffix}||g"); echo "Found $NODE";
        echo "Looking up VZID";
        CTID=$(ssh -t -q "$NODE" "sudo vzlist -a |grep "$IP" 2>/dev/null" |head -2 |tail -1 2>/dev/null;)
        CTID2=$(echo $CTID |awk '{print $1}'); echo "Found $CTID2";
        VZID="$CTID2"
        Server="$NODE"
    ssh -t -q "$Server" "sudo vzctl stop $VZID && sudo vzquota drop $VZID && sudo vzctl set $VZID --quotaugidlimit 3000 --save && sudo vzctl start $VZID;sudo vzctl enter $VZID;" 2>/dev/null; echo -e "\e[1;33mEnabled Quotas for $VZID on $Server\e[0m"
elif [ "${Action}" == 'enter' ] ;then
                      # Vzctl enter VPS
        ssh -tt -q "$Server" "sudo vzctl enter $VZID;" 2>/dev/null
elif [ "${Action}" == 'oom' ] ;then
        # Check VZ errors like oom for VPS
        echo "Finding VPS Node";
        NODE=$(traceroute -m 10 -w 1 $IP |grep "${company_domain}" |grep -v $IP |tail -1 |awk '{print $2}'| "s|.${company_rdns_suffix}||g"); echo "Found $NODE";
        echo "Looking up VZID";
        CTID=$(ssh -t -q "$NODE" "sudo vzlist -a |grep "$IP" 2>/dev/null" |head -2 |tail -1 2>/dev/null;)
        CTID2=$(echo $CTID |awk '{print $1}'); echo "Found $CTID2";
        VZID="$CTID2"
        Server="$NODE"
        command="sudo grep $VZID /var/log/messages;"
        ssh -t -q "$Server" ${command} 2>/dev/null
elif [ "${Action}" == 'raiseinodes' ] ;then
        # Increase Inodes for VPS temporarily
        echo "Finding VPS Node";
        NODE=$(traceroute -m 10 -w 1 $IP |grep "${company_domain}" |grep -v $IP |tail -1 |awk '{print $2}'| "s|.${company_rdns_suffix}||g"); echo "Found $NODE";
        echo "Looking up VZID";
        CTID=$(ssh -t -q "$NODE" "sudo vzlist -a |grep "$IP" 2>/dev/null" |head -2 |tail -1 2>/dev/null;)
        CTID2=$(echo $CTID |awk '{print $1}'); echo "Found $CTID2";
        VZID="$CTID2"
        Server="$NODE"
	# set default value if one is not passed in with "managevz.sh raiseinodes VPSIP 2500000"
        DefRaise_INODE="2500000";
	INODE="${3:-$DefRaise_INODE}"
	command="sudo /usr/sbin/vzctl set $VZID --diskinodes $INODE:$INODE --save --force;"
	ssh -t -q "$Server" ${command} 2>/dev/null

fi

