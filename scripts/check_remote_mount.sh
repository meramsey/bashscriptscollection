#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective: Check and ensure a remote sshfs mount is mounted. This script assumes you have already have ssh passwordless keypair setup for accessing the remote sshfs mount point.

## How to use.
# Set the below variables to match your needs first.

# Then the below script can be run manually or via a cronjob
# sh check_remote_mount.sh

#example cronjob path to the script may need to be updated depending on where it was saved.
# * * * * * /bin/bash /root/check_remote_mount.sh > /dev/null

#Set local mount directory
mountdir="/mnt/morgan"

#Remote mount directory
remotemountdir="/root/coby-backups"

#Set file name to test for in the remote mount directory. Just create an empty file in the remote mount so we can check if it exists.
remotemounttestfile="/mnt/morgan/morgan_mounted"

#Remote hostname or IP
remotehost=""

#Remote ssh username
remoteuser="root"

#SSH IdentityFile path. Please Note: This would be the key like "/root/.ssh/id_rsa" not the pub file "/root/.ssh/id_rsa.pub"
sshIdentityFile="/root/.ssh/id_rsa"


if mountpoint $mountdir && [ -f $remotemounttestfile ]; then
    echo "Mounted"
    RC=$?
else
   echo "Not mounted properly"
   #umount gracefully if possible
   umount $mountdir  > /dev/null 2>&1

   #kill any frozen process on the mount
   fuser -k $mountdir  > /dev/null 2>&1
   fusermount -u $mountdir  > /dev/null 2>&1
   umount -l $mountdir  > /dev/null 2>&1
   umount $mountdir  > /dev/null 2>&1

   #kill any hung processes and mounts
   pkill -9 sshfs && umount "$mountdir"  > /dev/null 2>&1
   
   #remount backup server
   rm -rf "${mountdir:?}/"* && sshfs -o nonempty,allow_other,IdentityFile=$sshIdentityFile $remoteuser@$remotehost:$remotemountdir $mountdir

   if mountpoint $mountdir && [ -f $remotemounttestfile ]; then
    echo "Mounted"
    RC=$?
   else
   echo "Not mounted properly needs fixed manually"
   RC=1
   fi
fi
exit $RC
