#!/bin/bash

ISO_PATH="/var/lib/vz/template/iso"


if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run as root"
  exit
fi

# if [ -z "$1" ]; then 
#     echo "Please provide root Password for image as param"
#   exit
# fi

if [ "$2" = "-c" ]; then 
    echo "\n\nCleaning install"
    qm stop 9000 
    qm destroy 9000 
    rm -f $ISO_PATH/jammy-server-cloudimg-amd64-disk-kvm.img
    echo "\n++++++++\n DONE Cleaning install\n\n"
fi

# update packages
apt update -y
# install lib to allow virt-customize
echo "\n\n\n<<< install libguestfs-tools to allow virt-customize\n"
apt install libguestfs-tools -y

# Is ansible ssh key present?
echo "\n\n\n<<< Checking for ansible ssh key\n"
SSH_PATH=/root/ansible_ssh_key.txt
if  test -f "$SSH_PATH"; then
    echo "found ansible ssh key file..."
else
    echo "Could not find /root/anible_ssh_key.txt file.  Please create import SSH key file... Exiting."
    exit
fi

# Cloud image already pilled?
echo "\n\n<<< Install jammy kvm cloud-init\n"
IMG_PULLED="$ISO_PATH/jammy-server-cloudimg-amd64-disk-kvm.img"
if test -f "$IMG_PULLED"; then
    echo "Found img file skipping download..."
else
    echo "downloading img file..."
    cd $ISO_PATH
    wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img

    echo "\n Cutomizing image"
    virt-customize -a jammy-server-cloudimg-amd64-disk-kvm.img  --install qemu-guest-agent
    #virt-customize -a jammy-server-cloudimg-amd64-disk-kvm.img  --install spice-vdagent
fi

echo "\n\n<<< Create VM to generate template \n"
qm create 9000 --name "jammy-docker" --core 2 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci  #create a vm
qm set 9000 --scsi0 local-lvm:0,import-from=$ISO_PATH/jammy-server-cloudimg-amd64-disk-kvm.img  #attach sci storage
qm set 9000 --ide2 local-lvm:cloudinit  # create cd drive called cloudinit
qm set 9000 --boot order=scsi0  # boot from sci0
qm set 9000 --serial0 socket --vga serial0   
qm set 9000 -agent 1
# qm template 9000