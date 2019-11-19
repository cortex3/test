#!/usr/bin/bash

set -e

curl https://raw.githubusercontent.com/cortex3/test/master/config.sh > config.sh
chmod +x config.sh
echo 'here you can adjust the config parameters'
read -n 1 -srp "Press any key to continue"
vim config.sh
source config.sh

echo 'loading keymap'
loadkeys $keymap

echo 'enabling ntp'
timedatectl set-ntp true

echo 'Next partition your system, remember to select GPT and to create a boot partition'
read -n 1 -srp "Press any key to continue"
cfdisk

read -p "Enter the root partition: " partition

if [ "$encrypt_root" = true ]; then
    echo 'Please read into the arch wiki page on drive preperation for encryption'
    read -n 1 -srp "Press any key to continue"
    until cryptsetup -y -v luksFormat $partition; do echo "Try again"; done
    until cryptsetup open $partition cryptroot; do echo "Try again"; done
    real_partition_name=$partition
    partition="/dev/mapper/cryptroot" # from here on $partition is the luks volume name
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
mount $boot_partition /mnt/boot

echo 'downloading packages'
pacstrap /mnt base linux linux-firmware go

echo 'generating fstab'
genfstab -U /mnt >> /mnt/etc/fstab

echo 'here you can manually fix the fstab'
read -n 1 -srp "Press any key to continue"
vim /mnt/etc/fstab

echo 'going into chroot'
curl https://raw.githubusercontent.com/cortex3/test/master/chroot.sh > /mnt/chroot.sh
cp /root/config.sh /mnt/config.sh
chmod +x /mnt/chroot.sh

if [ "$encrypt_root" = true ]; then
arch-chroot /mnt ./chroot.sh $partition $real_partition_name
fi

rm /mnt/chroot.sh
rm /mnt/config.sh
