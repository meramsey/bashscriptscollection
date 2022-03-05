#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective bulk update domains with new IP.
## How to use.
## ./bulk_update_domains_ip.sh OLDIP NEWIP

#old IP
OLDIP=$1

#newip
NEWIP=$2

echo "Backing up /var/named to /var/named-backup"
sudo cp -a /var/named /var/named-backup
echo "Reverting IP of all domains in domains.txt in /var/named/domain.tld.db"
while read -r LINE; do
    sudo sed -i 's/$OLDIP/$NEWIP/g' /var/named/$LINE.db
	#sudo sed -i 's/${OLDIP}/${NEWIP}/g' /var/named/"$LINE".db
	#harcoded IP version
	#sudo sed -i 's/68.66.234.211/66.198.240.37/g' /var/named/"$LINE".db
done < domains.txt
echo "IP updated"
echo ""
echo "Mission Completed"
