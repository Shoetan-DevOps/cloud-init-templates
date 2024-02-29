##################
#!/bin/bash

imageURL=https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
imageName="jammy-server-cloudimg-amd64.img"
volumeName="local-lvm"
virtualMachineId="9000"
templateName="ubuntu-jammy"
tmp_cores="2"
tmp_memory="4048"
tmp_storage="20G"
rootPasswd=$PSWD
cpuTypeRequired="host"
ansibleSSH_path="/root/id_rsa.pub"

#apt update
apt install libguestfs-tools -y
rm $imageName || true  #*.img
wget -O $imageName $imageURL
qm destroy $virtualMachineId
virt-customize -a $imageName --install qemu-guest-agent
virt-customize -a $imageName --root-password password:$rootPasswd
virt-customize -a $imageName --run-command "useradd -m -s /bin/bash ansible"
virt-customize -a $imageName --run-command "echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ansible"
virt-customize -a $imageName --ssh-inject ansible:file:$ansibleSSH_path
qm create $virtualMachineId --name $templateName --memory $tmp_memory --cores $tmp_cores --net0 virtio,bridge=vmbr0
qm importdisk $virtualMachineId $imageName $volumeName
qm set $virtualMachineId --scsihw virtio-scsi-pci --scsi0 $volumeName:vm-$virtualMachineId-disk-0
qm set $virtualMachineId --boot c --bootdisk scsi0
qm set $virtualMachineId --ide2 $volumeName:cloudinit
qm set $virtualMachineId --serial0 socket --vga serial0
qm set $virtualMachineId --ipconfig0 ip=dhcp
qm set $virtualMachineId --cpu cputype=$cpuTypeRequired
qm template $virtualMachineId

