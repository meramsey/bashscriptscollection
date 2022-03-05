#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective: Daily rsync of Cyberpanel full backup files for example.com to two remote servers
## How to use.
# chmod +x cyberpanel-backup-script.sh
# ./cyberpanel-backup-script.sh
# bash cyberpanel-backup-script.sh
# Can be setup via cron
#0 0 * * * /root/cyberpanel-backup-script.sh >/dev/null 2>&1

#Specify the cyberpanel primary domain
Domain="example.com"

#Specify the remote server 1 hostname/IP username and path to put the backup files in
RemoteServer1="backup.example2.com"
RemoteServer1User="root"
RemoteServer1Path="/root/example.com-backups"

#Specify the remote server 2 hostname/IP username and path to put the backup files in
RemoteServer2="backup2.example2.com"
RemoteServer2User="root"
RemoteServer2Path="/root/example.com-backups"

rsync -aP --exclude 'status' /home/$Domain/backup/ ${RemoteServer1User}@${RemoteServer1}:${RemoteServer1Path}
rsync --remove-source-files -aP --exclude 'status' /home/$Domain/backup/ ${RemoteServer2User}@${RemoteServer2}:${RemoteServer2Path}
