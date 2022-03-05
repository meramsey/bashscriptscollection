#!/usr/bin/env bash
## Author: Michael Ramsey
## https://gitlab.com/cpaneltoolsnscripts/cpanel-login-logs-by-user
## Objective Find cPanel user's Login records, activities, and etc
## How to use.
## ./cPanelLoginLogsByUser.sh username
Username=$1

CURRENTDATE=$(date +"%Y-%m-%d %T") # 2019-02-09 06:47:56

user_homedir=$(sudo egrep "^${Username}:" /etc/passwd | cut -d: -f6)

user_cPanelLoginRecords="${user_homedir}/${Username}-cPanelLoginRecords.txt";

#create logfile in user's homedirectory.
sudo touch "$user_cPanelLoginRecords"

#chown logfile to user
sudo chown ${Username}:${Username} "$user_cPanelLoginRecords";

main_function() {

echo "$CURRENTDATE"
echo "============================================================="
echo "Find $Username user's login attempts to the cpsrvd daemon."
echo ""
sudo grep "$Username" /usr/local/cpanel/logs/login_log
echo "============================================================="
echo "Find $Username user's login attempts for ssh/sftp."
echo ""
sudo grep "$Username" /var/log/secure
echo "============================================================="
echo "Find $Username user's records of when they accessed their account."
echo ""
sudo grep "$Username" /usr/local/cpanel/logs/access_log
echo "============================================================="
echo "Find $Username user's activities performed while logged into their cPanel account."
echo ""
sudo grep "$Username" /usr/local/cpanel/logs/session_log
echo "============================================================="
echo "Find $Username cPanel or FTP user's FTP logs"
echo ""
sudo grep "$Username" /usr/local/apache/domlogs/ftpxferlog
echo "============================================================="
echo "Find a cPanel User's unique IP's from login, session, access, and ssh/sftp logs"
echo ""
readarray -t iparray < <(sudo grep "$Username" /{var/log/{secure,messages},usr/local/cpanel/logs/{login_log,session_log,access_log}} | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -Vu| tr '/' '\n')
echo ""; 
for IP in "${iparray[@]}"; do echo $IP; done
echo ""; 
echo "Show unique IP's with whois IP, Country,and ISP"; 
echo ""; 
for IP in "${iparray[@]}"; do whois -h whois.cymru.com " -c -p $IP"|cut -d"|" -f 2,4,5|grep -v IP; done
echo "============================================================="

echo "Contents have been saved to ${user_cPanelLoginRecords}"

}

# log everything, but also output to stdout
main_function 2>&1 | tee -a "${user_cPanelLoginRecords}"
