#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective: Generate CSF Allow file for Cloudflare IP's /etc/csf/cloudflare.allow
## https://gitlab.com/mikeramsey/
## 
## How to use. start script or run as a cron.
## chmod +x csf_cf_allow.sh
# ./csf_cf_allow.sh 
# sh csf_cf_allow.sh
# Cron Example:
# 0 0 * * * /bin/sh /root/csf_cf_allow.sh

#get full path to CSF binary
CSF_BIN=$(which csf)

#CSF_BIN=$(which csf); > /etc/csf/cloudflare.allow ; for x in $(curl -s https://www.cloudflare.com/{ips-v4,ips-v6}); do echo "$x" | tee -a /etc/csf/cloudflare.allow ; done; $CSF_BIN -ra;

#Empties current file and then writes new IP's to the file.
#> /etc/csf/cloudflare.allow ; for x in $(curl -s https://www.cloudflare.com/{ips-v4,ips-v6}); do echo "$x" | tee -a /etc/csf/cloudflare.allow  ; done

# cleanest oneliner
curl -s https://www.cloudflare.com/{ips-v4,ips-v6}|sort| tee /etc/csf/cloudflare.allow

#Regex to validate only valid IP CIDR ranges are added to the file. Great for crons where you don't want to wake up and be locked out of server if Cloudflare posted invalid IP ranges or information on the text links.
#curl -s https://www.cloudflare.com/{ips-v4,ips-v6}| sort |grep -E -o "((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(3[0-2]|[1-2][0-9]|[0-9]))$)|(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)|(s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\/(12[0-8]|1[0-1][0-9]|[1-9][0-9]|[0-9]))$)"| tee /etc/csf/cloudflare.allow



#Reference:
#https://danielmiessler.com/blog/whitelisting-cloudflare-iptables/
#https://support.cloudflare.com/hc/en-us/articles/201897700
#IPv4
#ipset destroy cf-ipv4
#ipset create cf-ipv4 hash:net
#for x in $(curl -s https://www.cloudflare.com/ips-v4); do ipset add cf-ipv4 $x; done

#Iptables rule
#iptables -A INPUT -m set –match-set cf-ipv4 src -p tcp -m multiport –dports http,https -j ACCEPT

#Ipv6
#ipset destroy cf-ipv6
#ipset create cf-ipv6 hash:net family inet6
#for x in $(curl -s https://www.cloudflare.com/ips-v6); do ipset add cf-ipv6 $x; done

#Iptables IPv6 rule
#ip6tables -A INPUT -m set –match-set cf-ipv6 src -p tcp -m multiport –dports http,https -j ACCEPT


#Restart CSF
$CSF_BIN -ra
