#!/usr/bin/sh

echo 'loading keymap'
loadkeys de

echo 'enabling ntp'
timedatectl set-ntp true

echo 'Next partition your system, remember to select GPT and to create a boot partition'
read -n 1 -srp "Press any key to continue"
cfdisk

read -p "Enter the partition you want to install to: " partition
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
