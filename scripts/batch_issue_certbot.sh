#!/usr/bin/env bash
# Issue/Renew all domains via certbot after DNS switched over from another server.
## How to use:
## Directly from github as root user:
# link="https://raw.githubusercontent.com/meramsey/blaqpanel/main/scripts/batch_issue_certbot.sh";sh <(curl $link || wget -O - $link);

## Manually download
# wget -q -O /usr/local/blaqpanel/bin/batch_issue_certbot.sh https://raw.githubusercontent.com/meramsey/blaqpanel/main/scripts/batch_issue_certbot.sh && chmod +x /usr/local/blaqpanel/bin/batch_issue_certbot.sh; 
## Then execute:
# /usr/local/blaqpanel/bin/batch_issue_certbot.sh

### OLS functions
WWW_PATH='/var/www'
LSDIR='/usr/local/lsws'
VHDIR="${LSDIR}/conf/vhosts"
BOTCRON='/etc/cron.d/certbot'
WWW='FALSE'

restart_lsws(){
    # kill detached lsphp processes and restart ols
    killall -9 lsphp >/dev/null 2>&1
    systemctl stop lsws >/dev/null 2>&1
    systemctl start lsws
}

check_domain_dns_pointed_to_server(){
	local domain
	domain=$1
	SERVER_IPv4=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
	SERVER_IPv6=$(wget -qO- -t1 -T2 ipv6.icanhazip.com)
	DOMAIN_IPv4="$(dig @1.1.1.1 +short A "$domain")"
	DOMAIN_IPv6="$(dig @1.1.1.1 +short AAAA "$domain")"
	
	if [[ "$SERVER_IPv4" == "$DOMAIN_IPv4" ]]; then
		echo "$domain resolves to current server IPV4: $SERVER_IPv4"
		IPv4_MATCH=True
	else
		echo "$domain resolves to different IPV4: $DOMAIN_IPv4"
		IPv4_MATCH=False
	fi
	
	if [[ "$SERVER_IPv6" == "$DOMAIN_IPv6" ]]; then
		echo "$domain resolves to current server IPV6: $DOMAIN_IPv6"
		IPv6_MATCH=True
	elif [[ "$DOMAIN_IPv6" == "" ]]; then
		echo "$domain does not have an IPv6 AAAA set to current server IPV6: $DOMAIN_IPv6"
		IPv6_MATCH=True
	else
		echo "$domain resolves to different IPV6: $DOMAIN_IPv6 then server IPv6"
		IPv6_MATCH=FALSE
	fi
	
	if [[ "$IPv4_MATCH" == True && "$IPv6_MATCH" == True ]]; then
		DNS_MATCH=True
	else
		DNS_MATCH=False
	fi
	
	# if [[ "$IPv4_MATCH" == 'True' ]]; then
	# 	DNS_MATCH=True
	# else
	# 	DNS_MATCH=False
	# fi
}




for dir in $(ls -d /var/www/*/html); do
	domain=$(echo $dir|sed -e 's|/var/www/||g' -e 's|/html||g');
	DOCHM="/var/www/$domain/html"
	check_domain_dns_pointed_to_server "$domain"
	if [[ "$DNS_MATCH" == 'True' ]]; then
		echo "Requesting SSL for Domain: $domain and www.$domain path: /var/www/$domain/html/";
		certbot certonly --non-interactive --agree-tos --register-unsafely-without-email --webroot -w ${DOCHM} -d ${domain} -d www.${domain}||certbot certonly --non-interactive --agree-tos --register-unsafely-without-email --webroot -w ${DOCHM} -d ${domain}
		sed -i "s|\$VH_NAME|$domain|g" ${VHDIR}/${domain}/vhconf.conf
		echo
		echo "SSL for Domain: $domain has been requested"
	else
		echo "SSL issue request for Domain: $domain has been skipped as DNS is not pointed to server"
	fi

	echo "=========================================="
done


echo 'Killing detached lsphp processes and restarting OLS/LSWS webserver'
restart_lsws