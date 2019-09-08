#!/usr/bin/sh

set -e
source config.sh

partition=$(echo $2 | grep -o /dev/sd[a-z])


echo 'setting timezone, keymap,hostname and language'
ln -sf $timezone /etc/localtime
hwclock --systohc
sed -i -e "s/#$locale/$locale/" /etc/locale.gen
locale-gen
echo "LANG=$locale" > /etc/locale.conf
echo "KEYMAP=$keymap" > /etc/vconsole.conf
echo "$hostname" > /etc/hostname

echo 'set root password'
passwd

# grub
echo 'installing grub'
pacman -S intel-ucode grub --noconfirm -q
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub

if [ "$encrypt_root" = true ]; then
    sed -i -e "s/HOOKS=(.*)/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)/" /etc/mkinitcpio.conf
    uuid=$(lsblk -dno UUID $partition)
    sed -i -e "s/GRUB_CMDLINE_LINUX_DEFAULT=\".*\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash cryptdevice=UUID=$uuid:cryptlvm root=$partition\"/" /etc/default/grub
fi
grub-mkconfig -o /boot/grub/grub.cfg


echo 'adding user'
useradd -m $username
passwd $username
pacman -S git stow --noconfirm -q
sudo -u $username bash << EOF
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
rm -rf /tmp/yay
EOF

visudo
