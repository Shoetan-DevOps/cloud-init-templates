#!/bin/bash

echo "ceate_vm_9000.sh started..."

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# update packages
sudo apt update -y

# install lib to allow virt-customize
sudo apt install libguestfs-tools -y

# example if you need to inject a key into the image
 FILE1=/root/ansible_ssh_key.txt
 if test -f "$FILE1"; then
    echo "found ansible ssh key file..."
  else
    echo "could not find /root/anible_ssh_key.txt file.  Please create this file. exiting."
    exit
 fi

FILE2=/root/jammy-server-cloudimg-amd64.img
if test -f "$FILE2"; then
     echo "found img file skipping download..."
     #  cp /root/jammy-server-cloudimg-amd64.img.original /root/jammy-server-cloudimg-amd64.img
else
     echo "downloading img file..."
     cd /root/
     wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
fi

virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent
virt-customize -a jammy-server-cloudimg-amd64.img --run-command "useradd -m -s /bin/bash ansible"
virt-customize -a jammy-server-cloudimg-amd64.img --run-command "echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ansible"
virt-customize -a jammy-server-cloudimg-amd64.img --root-password password:$1
virt-customize -a jammy-server-cloudimg-amd64.img --ssh-inject ansible:file:/root/ansible_ssh_key.txt
qm create 9000 --name "CIT-ubuntu-jammy" --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
qm set 9000 --scsi0 local-lvm:0,import-from=/root/jammy-server-cloudimg-amd64.img
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot order=scsi0
#qm set 9000 --serial0 socket --vga serial0
qm set 9000 -agent 1
qm template 9000

echo "create_vm_9000 completed."
