#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective Find A cPanel Server Global Domlogs Stats for last 5 days for all of their domains.
## How to use.
# ./ApacheDomlogsGlobal.sh
# sh ApacheDomlogsGlobal.sh
#
#echo $1

#Find Hostname of server
hostname=$(hostname)
LastRebootDate=$(who -b | cut -d' ' -f13)
LastRebootTime=$(who -b | cut -d' ' -f14)
LASTBOOT=$(who -b|sed 's/.*system boot//g'|sed 's/^ *//;s/ *$//')
cPanelUserDomainCount=$(sudo cat /etc/userdomains |wc -l)


#Detect OS
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

cPanelVersion=$(cat /usr/local/cpanel/version)

echo ""
uname -n
echo "$OS $VER";uname -r;
echo "cPanel/WHM Version: $cPanelVersion"
echo "Domains on server: $cPanelUserDomainCount"
echo ""
echo "Finding init system in use.."
if [[ `/sbin/init --version` =~ upstart ]]; then echo server is using upstart; InitSystem="Upstart";
elif [[ `systemctl` =~ -\.mount ]]; then echo server is using systemd; InitSystem="systemd";
elif [[ -f /etc/init.d/cron && ! -h /etc/init.d/cron ]]; then echo  server is using sysv-init; InitSystem="sysv-init";
else echo cannot tell init system; InitSystem="Unknown Init"; fi
echo ""


#Webserver binaries

#Finding Webserver in Use and version.
echo "Webserver Version and Type:"
httpd -v
echo ""

#Finding system default PHP version
echo "Finding system default PHP version"
php -v
echo ""

#Finding Mysql version in use
echo "MySQL/MariaDB version"
mysql -V
echo ""



#Firewall binaries
csf=/usr/sbin/csf
apf=/usr/local/sbin/apf
firewalld=firewall-cmd

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
echo ""
#Show Last Reboot
echo "Last Reboot: $LASTBOOT"
echo ""
echo "Show current uptime and load"
uptime
echo ""

if [ $InitSystem == "systemd" ]; then
  echo "Checking important Services....:"
  echo "Service check for Apache/Litespeed:"
  systemctl status httpd
  echo ""
  echo "Service check for MySQL/MariaDB:"
  systemctl status mysql
  echo ""
  echo "Service check for Named:"
  systemctl status named
  echo ""
  echo "Service check for Exim:"
  systemctl status exim
  echo ""
  echo "Service check for Dovecot:"
  systemctl status dovecot

elif [ $InitSystem == "sysv-init" ]; then
  echo "Checking important Services....:"
  echo "Service check for Apache/Litespeed:"
  service httpd status
  echo ""
  echo "Service check for MySQL/MariaDB:"
  service mysql status
  echo ""
  echo "Service check for Named:"
  service named status
  echo ""
  echo "Service check for Exim:"
  service exim status
  echo ""
  echo "Service check for Dovecot:"
  service dovecot status
elif [ $InitSystem == "Upstart" ]; then
  echo "Checking important Services....:"
  echo "Service check for Apache/Litespeed:"
  service httpd status
  echo ""
  echo "Service check for MySQL/MariaDB:"
  service mysql status
  echo ""
  echo "Service check for Named:"
  service named status
  echo ""
  echo "Service check for Exim:"
  service exim status
  echo ""
  echo "Service check for Dovecot:"
  service dovecot status
else
  echo "Init System not found"
fi