#!/usr/bin/env bash
## Author: Michael Ramsey
## https://gitlab.com/cyberpaneltoolsnscripts/s3fs-fuse-amazon-s3-cyberpanel-setup
## Objective: Move backups as completed from the default cyberpanel backup path per account /home/<domain name>/backup to /home/backup/ which allows for restoring from Cyberpanel UI and is the amazon s3 mount
## How to use.
# Setup cron to run every 5-15 mins on days backups run or every day. As it only does stuff if completed backup exists it should not cause issues.

# checks for any completed status files and then moved the backup to /home/backup/ and removes the completed status file to prevent it from causing errors on next run
for completed_backup in $(grep -rl Completed /home/*/backup/); do backup=$(echo ${completed_backup}| sed 's|status|backup-*.tar.gz|'); rsync --remove-source-files -azP ${backup} /home/backup && rm -f ${completed_backup} ;done
