#!/usr/bin/env bash
## Author: Michael Ramsey
## https://gitlab.com/cyberpaneltoolsnscripts/s3fs-fuse-amazon-s3-cyberpanel-setup
## Setup Amazon S3 remote bucket as a local mount so you can do full backups to amazon s3 server for all accounts.
## How to use.
#
# Setup amazon s3 destination pass the three parameter ACCESS_ID SECRET_ACCESS_KEY bucket_name
# wget https://gitlab.com/cyberpaneltoolsnscripts/s3fs-fuse-amazon-s3-cyberpanel-setup/-/raw/master/s3fs-fuse-amazon-s3-cyberpanel-setup.sh
# bash s3fs-fuse-amazon-s3-cyberpanel-setup.sh ACCESS_ID SECRET_ACCESS_KEY bucket_name
# 
# bash <(curl -sk https://gitlab.com/cyberpaneltoolsnscripts/s3fs-fuse-amazon-s3-cyberpanel-setup/-/raw/master/s3fs-fuse-amazon-s3-cyberpanel-setup.sh || wget --no-check-certificate -qO - https://gitlab.com/cyberpaneltoolsnscripts/s3fs-fuse-amazon-s3-cyberpanel-setup/-/raw/master/s3fs-fuse-amazon-s3-cyberpanel-setup.sh) ACCESS_ID SECRET_ACCESS_KEY bucket_name
#
# 
# 
###Config#######
ACCESS_ID=$1; 
SECRET_ACCESS_KEY=$2;
backup_mount="/home/backup";
bucket=$3;
####Stop Config####

OUTPUT=$(cat /etc/*release)
if  echo $OUTPUT | grep -q "CentOS Linux 7" ; then
        echo "Checking and installing s3fs-fuse"
        # Install epel-release repo needed for s3fs-fuse binary
        yum install -y epel-release
        yum install -y s3fs-fuse
                SERVER_OS="CentOS"
elif echo $OUTPUT | grep -q "CentOS Linux 8" ; then
        echo -e "\nDetecting Centos 8...\n"
        SERVER_OS="CentOS8"
        yum install -y epel-release
        yum install -y s3fs-fuse
elif echo $OUTPUT | grep -q "CloudLinux 7" ; then
        echo "Checking and installing s3fs-fuse"
        yum install -y epel-release
        yum install -y s3fs-fuse
                SERVER_OS="CloudLinux"
elif echo $OUTPUT | grep -q "Ubuntu 18.04" ; then
        apt install -y s3fs
                SERVER_OS="Ubuntu"
elif echo $OUTPUT | grep -q "Ubuntu 20.04" ; then
        apt install -y s3fs
                SERVER_OS="Ubuntu"
else

                echo -e "\nUnable to detect your OS...\n"
                echo -e "\nCyberPanel is supported on Ubuntu 18.04, CentOS 7.x and CloudLinux 7.x...\n"
                exit 1
fi




# Setup ~/.passwd-s3fs and /etc/passwd-s3fs
echo "${ACCESS_ID}:${SECRET_ACCESS_KEY}" > ~/.passwd-s3fs
chmod 600 ~/.passwd-s3fs
cp ~/.passwd-s3fs /etc/passwd-s3fs

# Create Mount
mkdir -p ${backup_mount}

# Save bucket name to ~/.bucket-s3fs
echo $bucket > ~/.bucket-s3fs

echo 'checking current mounts';
df -h
echo "";

# Mount bucket
s3fs ${bucket} ${backup_mount} -o passwd_file=${HOME}/.passwd-s3fs

echo 'Checking mounts for new mount';
df -h| grep ${backup_mount}
echo "";

# If above mount test successful backup fstab and then add an entry
if [[ $(df -h| grep ${backup_mount}) ]] ; then
    # Setup fstab for permanent mount
    echo "Backing up /etc/fstab";
    cp /etc/fstab /etc/fstab-bak && echo "Adding to /etc/fstab"; echo ""; echo "${bucket}   ${backup_mount}    fuse.s3fs _netdev,rw,nosuid,nodev,allow_other,nonempty 0 0" | tee -a /etc/fstab
fi


echo "========================="
echo "Checking mount contents unmounts and remounts automatically"
ls -lah ${backup_mount} && umount ${backup_mount} && df -h && mount -a && df -h ${backup_mount}


#backup cron installation
wget -O /root/amazon-s3-cyberpanel-cron.sh https://gitlab.com/cyberpaneltoolsnscripts/s3fs-fuse-amazon-s3-cyberpanel-setup/-/raw/master/amazon-s3-cyberpanel-cron.sh; chmod a+x /root/amazon-s3-cyberpanel-cron.sh;

echo "Install amazon s3 backup cron"
command="/root/amazon-s3-cyberpanel-cron.sh >/dev/null 2>&1"
job="0 0 * * * $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -
echo
echo "Checking for cronjob being added";
crontab -l| grep amazon-s3-cyberpanel-cron
echo "========================="


#backup cron installation
wget -O /root/move-backups-after-completed.sh https://gitlab.com/cyberpaneltoolsnscripts/s3fs-fuse-amazon-s3-cyberpanel-setup/-/raw/master/move-backups-after-completed.sh; chmod a+x /root/move-backups-after-completed.sh;

echo "Install move completed backups cron"
command2="/root/move-backups-after-completed.sh >/dev/null 2>&1"
job="*/15 * * * * $command2"
cat <(fgrep -i -v "$command2" <(crontab -l)) <(echo "$job") | crontab -
echo
echo "Checking for cronjob being added";
crontab -l| grep move-backups-after-completed
echo "========================="




