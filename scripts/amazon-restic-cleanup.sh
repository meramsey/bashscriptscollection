#!/usr/bin/env bash
###Config#######
ACCESS_ID=''; 
SECRET_ACCESS_KEY='';
DOMAIN=''
####Stop Config####

#lowercase domain in case not set that way above.
DOMAIN=${DOMAIN,,}


# List snapshots to confirm working
#export RESTIC_PASSWORD=$(cat /home/${DOMAIN}/${DOMAIN}) AWS_ACCESS_KEY_ID=${ACCESS_ID} AWS_SECRET_ACCESS_KEY=${SECRET_ACCESS_KEY} && restic -r s3:s3.amazonaws.com/${DOMAIN} snapshots


# Dry run of pruning
#export RESTIC_PASSWORD=$(cat /home/${DOMAIN}/${DOMAIN}) AWS_ACCESS_KEY_ID=${ACCESS_ID} AWS_SECRET_ACCESS_KEY=${SECRET_ACCESS_KEY} && restic -r s3:s3.amazonaws.com/${DOMAIN} forget --keep-daily 7 --keep-weekly 4 --keep-monthly 2 --dry-run

# Do the actual Pruning
export RESTIC_PASSWORD=$(cat /home/${DOMAIN}/${DOMAIN}) AWS_ACCESS_KEY_ID=${ACCESS_ID} AWS_SECRET_ACCESS_KEY=${SECRET_ACCESS_KEY} && restic -r s3:s3.amazonaws.com/${DOMAIN} forget --keep-daily 7 --keep-weekly 4 --keep-monthly 2
