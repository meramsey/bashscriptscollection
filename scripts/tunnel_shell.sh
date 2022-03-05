#!/usr/bin/env bash
trap 'exit' 2 20 24
clear
echo -e "SSH session started, ssh shell is disabled by the system administrator. Please Disconnect and login using without using the terminal." 
echo -e "To start dynamic socks5 proxy on localhost 1080: ssh -N -D 1080 ${USER}@$(hostname)"
echo -e "To start dynamic socks5 proxy on localhost 1080 in background: ssh -N -f -D 1080 ${USER}@$(hostname)"
echo -e "For more information: https://whattheserver.com/ssh-proxy-how-to-linux/ "
while true ; do
sleep 1000
done
exit 0

