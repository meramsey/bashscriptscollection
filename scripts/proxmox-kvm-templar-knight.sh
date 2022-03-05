#!/usr/bin/env bash
## Author: Michael Ramsey
## 
## Setup custom kvm images from cloud images and import into proxmox
## How to use.
#



vm_id='3008'
cloud_img_url='https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2'
storage='local'
disk_format='qcow2'
image_name=${cloud_img_url##*/}
image_base_name=${image_name%.$disk_format}
image_template_name=${image_base_name//.x86_64/}
wget ${cloud_img_url}
# For rhel/centos use this instead atop,htop are not in main repo
virt-customize --install cloud-init,nano,vim,qemu-guest-agent,curl,wget -a ${image_name}
#virt-customize --install cloud-init,atop,htop,nano,vim,qemu-guest-agent,curl,wget -a ${image_name}
virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/disable_root: [Tt]rue/disable_root: False/'
virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/disable_root: 1/disable_root: 0/' 
virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/lock_passwd: [Tt]rue/lock_passwd: False/'
virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/lock_passwd: 1/lock_passwd: 0/' 
virt-edit -a ${image_name} /etc/cloud/cloud.cfg -e 's/ssh_pwauth:   0/ssh_pwauth:   1/'
virt-edit -a ${image_name} /etc/ssh/sshd_config -e 's/PasswordAuthentication no/PasswordAuthentication yes/'
virt-edit -a ${image_name} /etc/ssh/sshd_config -e 's/PermitRootLogin [Nn]o/PermitRootLogin yes/'
virt-edit -a ${image_name} /etc/ssh/sshd_config -e 's/#PermitRootLogin [Yy]es/PermitRootLogin yes/'
virt-edit -a ${image_name} /etc/ssh/sshd_config -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/'
virt-edit -a ${image_name} /etc/ssh/sshd_config -e 's/[#M]axAuthTries 6/MaxAuthTries 20/'
qm create ${vm_id} --memory 512 --ide0 local:cloudinit --ide2 none,media=cdrom --net0 virtio,bridge=vmbr0,firewall=1 --serial0 socket --scsihw virtio-scsi-pci --onboot 1 --autostart 1 --agent enabled=1,fstrim_cloned_disks=1 --ciuser root --description ${image_name} --bootdisk virtio0 --name ${image_template_name} --ostype l26
qm importdisk ${vm_id} ${image_name} ${storage} --format ${disk_format}
qm set ${vm_id} --virtio0 ${storage}:${vm_id}/vm-${vm_id}-disk-0.${disk_format}
qm set ${vm_id} --boot order='virtio0'
qm set ${vm_id} --boot c --bootdisk virtio0
qm template ${vm_id}