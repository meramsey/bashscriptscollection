#!/usr/bin/env bash
#
# dns_made_easy_updater.sh 
#
# This script updates Dynamic DNS records on DNE Made Easy's
# DNS servers.  You must have wget installed for this to work.
# inspiration from dnsmadeeasy-update.sh
# https://support.dnsmadeeasy.com/support/solutions/articles/47001119947-the-ddns-shell-script

# Save to the below: 
# ~/dns_made_easy_updater.sh
#

# Make executable
# chmod +x ~/dns_made_easy_updater.sh

# this section is commented out but can be uncommented if you prefer having the vars filled in the same script vs separate.
# This is the e-mail address that you use to login
# DMEUSER=

# This is your password
# DMEPASS=

# This is the unique number for the record that you are updating.
# This number can be obtained by clicking on the DDNS link for the
# record that you wish to update; the number for the record is listed
# on the next page.
# DMEID=


# These are the unique numbers for the record that you are updating.
# This number can be obtained by clicking on the DDNS link for the
# record that you wish to update; the number for the record is listed
# on the next page.
# DMEIDS=(
# 	"" # domain1
# 	"" # domain2
# 	# "" # domain3
# 	# "" # domain4 
# 	# "" # domain5 
# 	"" # domain6
# 	"" # ftp
# )

# Put the commented out above into separate file to source from
source ~/dns_made_easy_vars.sh

# Obtain current default route interface name
# main_interface=$(ip route get 8.8.8.8 | awk -- '{printf $5}');

# Obtain current ip address alternates
#IPADDR=$(ifconfig ${main_interface} | grep inet | awk '{print $2}' | awk -F : '{print $2}');
#IPADDR=$(dig +short txt ch whoami.cloudflare @1.0.0.1| sed 's|"||g')
#IPADDRV6=$(dig +short txt o-o.myaddr.l.google.com @ns1.google.com)

# IPV4
IPADDR=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)

# IPADDRV6=$(wget -qO- -t1 -T2 ipv6.icanhazip.com)

update_dnsmadeeasy_a_record(){
	_update_dnsmadeeasy_a_record_ip="$1"
	_update_dnsmadeeasy_a_record_dmeid="$2"
	_update_dnsmadeeasy_a_record_dmeuser="$3"
	_update_dnsmadeeasy_a_record_dmepass="$4"
	
	if wget -q -O /proc/self/fd/1 https://cp.dnsmadeeasy.com/servlet/updateip?username=$_update_dnsmadeeasy_a_record_dmeuser\&password=$_update_dnsmadeeasy_a_record_dmepass\&id=$_update_dnsmadeeasy_a_record_dmeid\&ip="$_update_dnsmadeeasy_a_record_ip" | grep success > /dev/null; then
	logger -t DNS-Made-Easy -s "DNS Record ${_update_dnsmadeeasy_a_record_dmeid} Updated with ${_update_dnsmadeeasy_a_record_ip} Successfully"
else
	logger -t DNS-Made-Easy -s "Problem updating ${_update_dnsmadeeasy_a_record_dmeid} DNS record with ${_update_dnsmadeeasy_a_record_ip}."
fi
}


for DMEID in "${DMEIDS[@]}"
do
	echo "Attempting to update: $DMEID"
	update_dnsmadeeasy_a_record "$IPADDR" "$DMEID" "$DMEUSER" "$DMEPASS"
done
