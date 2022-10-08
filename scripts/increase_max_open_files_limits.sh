#!/usr/bin/env bash
# References: https://gist.github.com/dotcomputercraft/0947eb7ed6b3b5cc14b6

echo "Increasing open files limit per user /etc/security/limits.conf"
cat >> /etc/security/limits.conf <<EOL
*         soft    nproc       500000
*         hard    nproc       500000
*         hard    nofile      500000
*         soft    nofile      500000
root      hard    nofile      500000
root      soft    nofile      500000
EOL

echo "Increasing open files limit per user /etc/security/limits.d/90-nproc.conf"
cat >> /etc/security/limits.d/90-nproc.conf <<EOL
*          soft     nproc          500000
*          hard     nproc          500000
*          soft     nofile         500000
*          hard     nofile         500000
EOL


echo "Raising System-Wide Limit open files /etc/sysctl.conf"
cat >> /etc/sysctl.conf <<EOL
fs.file-max = 2097152
fs.inotify.max_user_watches=524288
EOL
sysctl -p

echo "Raising pam-limits /etc/pam.d/common-session"
cat >> /etc/pam.d/common-session <<EOL
session required pam_limits.so
EOL