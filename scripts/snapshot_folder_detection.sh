#!/usr/bin/env bash
# run via "/bin/bash snapshot_folder_detection.sh" as cron after snapshot rotation to remount with the current daily snapshots into one unified folder for Proxmox backups access.

#Define Snapshot/or dynamically updated folder's base location. In this example we want the paths of all the subdfolders under this path "/mnt/rsyncnet/.zfs/snapshot/" formatting is important.
dirs=(/mnt/rsyncnet/.zfs/snapshot/*/)

#For testing output generated uncomment the below lines to see it detecting your folders. In my example i know its always going to be an array of 7 directories so I have only setup that many. Stuff with dynamic varying amounts would need some custom scripting and loop over the array.
#echo "${dirs[0]}"
#echo "${dirs[1]}"
#echo "${dirs[2]}"
#echo "${dirs[3]}"
#echo "${dirs[4]}"
#echo "${dirs[5]}"
#echo "${dirs[6]}"

#next your base command would need to be put here and then copy it once below it and then modify it with the array variables so it merges it like you want it to.

#My base command commented out for example
#unionfs-fuse -o cow,max_files=32768 \
#             -o allow_other,use_ino,suid,dev,nonempty \
#             /mnt/rsyncnet/coby-backups=RW:/mnt/morgan=RW:/mnt/rsyncnet/.zfs/snapshot/daily_2019-08-23/coby-backups=RO:/mnt/rsyncnet/.zfs/snapshot/daily_2019-08-24/coby-#backups=RO:/mnt/rsyncnet/.zfs/snapshot/daily_2019-08-25/coby-backups=RO:/mnt/rsyncnet/.zfs/snapshot/daily_2019-08-26/coby-backups=RO:/mnt/rsyncnet/.zfs/snapshot/#daily_2019-08-27/coby-backups=RO:/mnt/rsyncnet/.zfs/snapshot/daily_2019-08-28/coby-backups=RO:/mnt/rsyncnet/.zfs/snapshot/daily_2019-08-29/coby-backups=RO \
#             /sdd/rsyncnet-backups-link

#My command edited with the array variables spliced in.
unionfs-fuse -o cow,max_files=32768 \
             -o allow_other,use_ino,suid,dev,nonempty \
             /mnt/rsyncnet/coby-backups=RW:/mnt/morgan=RW:"${dirs[0]}"coby-backups=RO:"${dirs[1]}"coby-backups=RO:"${dirs[2]}"coby-backups=RO:"${dirs[3]}"coby-backups=RO:"${dirs[4]}"coby-backups=RO:"${dirs[5]}"coby-backups=RO:"${dirs[6]}"coby-backups=RO \
             /sdd/rsyncnet-backups-link
