#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective Find A Reseller's accounts and all of their domains for cPanel and update SOA and run migrate domains afterwards.
## How to use.
## ./find_reseller_domains.sh resellerusername
echo "Finding $1's accounts"
sudo grep $1 /etc/trueuserowners | cut -d : -f 1 > $1-accounts.txt
echo "Found $1's accounts"
echo ""
echo "Finding $1 accounts' domains"
: > $1-domains-dump.txt
while read -r LINE; do
    sudo grep ": $LINE" /etc/userdomains | cut -d: -f1 >> $1-domains-dump.txt
done < $1-accounts.txt
echo "Found $1 accounts' domains"
echo ""
echo "Remove subdomains from list"
awk '
        {
                gsub( "^.*://", "", $1 );      # ditch the http://  ftp:// etc
                n = split( $1, a, "." );
                if( length( a[n] ) == 2 )       # assuming all two character top level domains are country codes
                        printf( "%s.%s.%s\n", a[n-2], a[n-1], a[n] );
                else
                        printf( "%s.%s\n",  a[n-1], a[n] );
        }
' $1-domains-dump.txt > $1-domains-subcleaned.txt
echo "Removing duplicate domains"
awk '!a[$0]++' $1-domains-subcleaned.txt > $1-domains.txt
echo ""
echo ""
echo "Reseller domains are in $1-domains.txt"
echo ""
echo "Removing temp files"
rm -f $1-domains-dump.txt
rm -f $1-domains-subcleaned.txt
echo ""
echo "Backing up /var/named to /var/named-backup"
cp -a /var/named /var/named-backup
echo "Incrementing Serials of all domains in $1-domains.txt in /var/named/domain.tld.db"
while read -r LINE; do
    sudo sed -i '0,/RE/s/20[0-1][0-9]\{7\}/'`date +%Y%m%d%I`'/g' /var/named/$LINE.db
done < $1-domains.txt
echo "Serials updated"
echo ""
#Find hostname prefix
hostname="hostname -s"
echo "Run migrate domains for reseller $1"
sudo /app/bin/new_migrate_domains.sh $1 $hostname
echo "Mission Completed"
