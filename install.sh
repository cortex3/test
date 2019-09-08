#!/usr/bin/bash

set -e
source config.sh

echo 'loading keymap'
loadkeys $keymap

echo 'enabling ntp'
timedatectl set-ntp true

echo 'Next partition your system, remember to select GPT and to create a boot partition'
read -n 1 -srp "Press any key to continue"
cfdisk

read -p "Enter the partition you want to install to: " partition

if [ "$encrypt_root" = true ]; then
    echo 'Please read into the arch wiki page on drive preperation for encryption'
    read -n 1 -srp "Press any key to continue"
    cryptsetup luksFormat $partition
    cryptsetup open $partition cryptlvm
    pvcreate /dev/mapper/cryptlvm
    vgcreate vg_root /dev/mapper/cryptlvm
    lvcreate -l 100%FREE vg_root -n root

    partition="/dev/vg_root/root" # from here on $partition is the lvm name
fi

echo 'creating file system'
mkfs.ext4 $partition

read -p "Enter your boot partition: " boot_partition
echo 'creating file system'
mkfs.fat -F32 $boot_partition

echo 'mounting /'
mount $partition /mnt

echo 'mounting /boot'
mkdir /mnt/boot
mount $boot_partition

echo 'downloading packages'
pacstrap /mnt base

echo 'generating fstab'
genfstab -U /mnt >> /mnt/etc/fstab

echo 'going into chroot'
curl https://raw.githubusercontent.com/cortex3/test/master/chroot.sh > /mnt/chroot.sh && arch-chroot /mnt bash chroot.sh $partition && rm /mnt/chroot.sh
