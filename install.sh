#!/usr/bin/sh

echo 'loading keymap'
loadkeys de
echo 'enabling ntp'
timedatectl set-ntp true

echo 'Next partition your system, remember to select GPT and to create a boot partition if you want to use UEFI'
read -n 1 -srp "Press any key to continue"
cfdisk

read -p "Enter the partition you want to install to: " partition
echo 'creating file system'
mkfs.ext4 $partition

PS3='Please select your boot mode: '
options=("uefi" "legacy")
select mode in "${options[@]}"
do
    case $mode in
        "uefi")
            bootmode=$mode
            read -p "Enter your boot partition: " boot_partition
            echo 'creating file system'
            mkfs.fat -F32 $boot_partition
            echo 'mounting /'
            mount $partition /mnt
            mkdir /mnt/boot
            echo 'mounting /boot'
            mount $boot_partition
            break
            ;;

        "legacy")
            bootmode=$mode
            echo 'mounting /'
            mount $partition /mnt
            break
            ;;
    esac
done
            
echo 'downloading packages'
pacstrap /mnt base
echo 'generating fstab'
genfstab -U /mnt >> /mnt/etc/fstab
echo 'going into chroot'
curl https://raw.githubusercontent.com/cortex3/test/master/chroot.sh > /mnt/chroot.sh && arch-chroot /mnt bash chroot.sh && rm /mnt/chroot.sh
