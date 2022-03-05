#!/usr/bin/env bash
## Author: Michael Ramsey
## https://gitlab.com/mikeramsey/bulkblockips.sh
## Objective: Block a list of IP's in a file. File should be one IP per line.
## How to use.
## ./bulkblockips.sh FILE firewall
##
## To block IP's with csf
## sh bulkblockips.sh FILE c
## 
## It does try to autodetect which firewall is in use to use if one is not specified.


FILE=$1
firewall=$2
# read $FILE using the file descriptors
exec 3<&0
exec 0<$FILE

#Clean duplicate IPs
awk '!x[$0]++' $1


#Firewall options
#a=apf
#c=csf
#f=firewalld


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


#Firewall binaries
csf=/usr/sbin/csf
apf=/usr/local/sbin/apf
firewalld=firewall-cmd

if [ "$firewall" == "f" ];
then
while read -r line; do
  firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address=""$line"" reject";done
  firewall-cmd --reload
  echo "Ip's added to firewalld reject"
  echo "Done"

elif [ "$firewall" == "c" ]; then
while read -r line; do
   csf -d "$line";done
   csf -r
   echo "Ip's added to csf deny"
   echo "Done"
   
	
elif [ "$firewall" == "a" ]; then
while read -r line; do
   /usr/local/sbin/apf -d "$line";done
   /usr/local/sbin/apf -r
   echo "Ip's added to apf deny"
   echo "Done"
	
else
   echo "Unknown parameter"
fi
