#! /bin/bash

# Install/Verify VM Manager
echo "***Checking libvirt Dependencies***"
sudo apt install qemu-system-x86-hwe libvirt-daemon-system-hwe libvirt-clients-hwe > /dev/null
echo "***Dependencies Met, Continue with Setup***"

# Verify Virtualization Support
if [[ $(egrep -c '(vmx|svm)' /proc/cpuinfo) == 112 ]]; then
  echo "***Virtualization Supported***"
else
  echo "!!!Issue with Virtualization!!!"
fi

# Start and Enable libvirt
sudo systemctl start libvirtd
echo "***libvirtd ENABLED***"

# Identify VM Disks
echo "***LIST OF CURRENT VM DISCS AND ISO'S***"
sudo find /var/lib/libvirt/images/

# List Downloaded Iso's
echo "***LIST OF DOWNLOADED ISO'S***"
ls -la ~/Downloads | grep .iso 2>/dev/null 
if [[ $(sudo ls -la ~/Downloads/ | grep .iso) ]]; then
  echo "Found a new ISO!" 
  read -p "Enter Iso to Move to libvirt folder: " iso_mv
  sudo mv ~/Downloads/$iso_mv /var/lib/libvirt/images/$iso_mv
  echo "Moved Iso from Downloads to Usable Directory"
  sudo ls -la /var/lib/libvirt/images/ | grep $iso_mv
else
  echo "No New ISO's in Downloads"
fi

# Display System Resources
echo """*********
CPU USAGE
*********""" 
top -n1 -b | awk '/^%Cpu/{print $2}'

echo """****************************
MEMORY USAGE of RAM and SWAP
****************************"""
free
sleep 5 &
sleep 10 &
wait -n

echo """***********************
STORAGE USAGE OF DRIVES
***********************"""
df | grep sda
sleep 5 &
sleep 10 &
wait -n

echo """**************************
LIST OF NETWORK INTERFACES
**************************"""
ip a | grep UP
sleep 5 &
sleep 10 &
wait -n
echo """********************************
USER INPUTS FOR VM CONFIGURATION
********************************"""

# Create VM with user specified inputs
cd /var/lib/libvirt/images/
read -p "Enter VM Name: " vm_name
read -p "Enter VM Description: " vm_desc
read -p "Enter VM RAM amount (ex. 4000=4gb): " ram
read -p "Enter VM CPU Count (ex. 2, 4): " cpu
read -p "Enter VM Disk Size (ex. 10=10gb): " size
read -p "Enter VM ISO Path: (ex. /var/lib/libvirt/images/...) " iso_path
read -p "Enter VM Network (ex. network=default,model=virtio): " net
read -p "Enter VM Graphics (ex. none, spice ): " graphics
read -p "Enter VM Console (ex. --console pty,target_type=serial or leave blank): " console
read -p "Enter VM Video (ex. qxl, none): " video

sudo virt-install \
--name "$vm_name" \
--osinfo detect=on,require=off \
--connect qemu:///system \
--description "$vm_desc" \
--memory $ram \
--vcpus $cpu \
--cpu host-passthrough \
--disk path=/var/lib/libvirt/images/"$vm_name".qcow2,bus=virtio,size=$size \
--cdrom $iso_path \
--network $net \
--graphics $graphics \
$console \
--video $video \
--boot uefi
