#!/bin/sh

#Enable IP forwarding for ipv4/ipv6

cat >> /etc/sysctl.conf <<EOL
net.core.somaxconn = 4096
net.ipv4.ip_forward = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.send_redirects = 1
net.ipv4.conf.default.proxy_arp = 0
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.tap_soft.accept_ra=2
net.ipv6.conf.all.accept_ra = 1
net.ipv6.conf.all.accept_source_route=1
net.ipv6.conf.all.accept_redirects = 1
net.ipv6.conf.all.proxy_ndp = 1
EOL

#ipv6 enable rp filter with prerouting rule
ip6tables -t raw -I PREROUTING -m rpfilter --invert -j DROP

#apply sysctl rules
sysctl -f

