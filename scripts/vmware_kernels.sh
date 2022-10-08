#!/usr/bin/env bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

VMWARE_VERSION="player-$(vmware -v||vmplayer -v|grep -oE "[[:digit:]]+.[[:digit:]]+.[[:digit:]]+"| head -n1)" # this is detect the version you have VMware Workstation 16.2.1 build-18811642

TMP_FOLDER=/tmp/patch-vmware
rm -fdr $TMP_FOLDER
mkdir -p $TMP_FOLDER
cd $TMP_FOLDER || exit
git clone https://github.com/mkubecek/vmware-host-modules.git
cd $TMP_FOLDER/vmware-host-modules || exit
git checkout "$VMWARE_VERSION"
git fetch
make
sudo make install
sudo rm /usr/lib/vmware/lib/libz.so.1/libz.so.1
sudo ln -s /lib/x86_64-linux-gnu/libz.so.1 /usr/lib/vmware/lib/libz.so.1/libz.so.1
sudo /etc/init.d/vmware restart
