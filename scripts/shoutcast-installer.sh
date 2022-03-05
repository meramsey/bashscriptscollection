#!/usr/bin/env bash
## Author: Michael Ramsey
## https://gitlab.com/cpaneltoolsnscripts/shoutcast-installer
## Objective: Install Shoutcast Latest DNAS on Linux under users account.
## How to use. 
# ./shoutcast-installer.sh
# bash shoutcast-installer.sh
#script="https://gitlab.com/cpaneltoolsnscripts/shoutcast-installer/-/raw/master/shoutcast-installer.sh"; sh <(curl $script || wget -O - $script)

IP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)

#Download latest linux64 installer
wget http://download.nullsoft.com/shoutcast/tools/sc_serv2_linux_x64-latest.tar.gz
#Create directory
mkdir ${HOME}/sc
#Extract
tar -xzf sc_serv2_linux_x64-latest.tar.gz -C sc
# Wget default conf
wget -O ${HOME}/sc/sc_serv_basic.conf https://gitlab.com/cpaneltoolsnscripts/shoutcast-installer/-/raw/master/sc_serv_basic.conf

#Start service in detached screen session.
screen -dmS shoutcast bash -c '${HOME}/sc/sc_serv ${HOME}/sc/sc_serv_basic.conf; exec sh'

echo "Shoutcast is now installed in ${HOME}/sc/"
echo "Shoutcast was started with profile ${HOME}/sc/sc_serv_basic.conf in detached screen session"
echo ''
screen -ls;
echo ''
echo 'To control this instance use: "screen -r shoutcast" to attach and ctrl+a+d to detach and leave running'
echo "If you have not already please request that ports 8000 and 8001 are opened in the firewall for your IP and $USER. Required rules are listed below for CSF"
echo "tcp|in|d=8000,8001 #Reason: Shoutcast Radio"
echo "tcp|out|d=8000,8001|u=${USER}"
echo "Once ports are opened you can control and login to the server http://$IP:8000/admin.cgi via username: admin password: changeme"
