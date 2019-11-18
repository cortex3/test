#!/usr/bin/sh

set -e
source ./config.sh
partition=$1

if [ -n "$2" ];
    real_partition_name=$2
fi

echo 'setting timezone, keymap,hostname and language'
ln -sf $timezone /etc/localtime
hwclock --systohc
sed -i -e "s/#$locale/$locale/" /etc/locale.gen
locale-gen
echo "LANG=$locale" > /etc/locale.conf
echo "KEYMAP=$keymap" > /etc/vconsole.conf
echo "$hostname" > /etc/hostname

echo 'set root password'
until passwd; do echo "Try again"; done

# grub
echo 'installing grub'
pacman -S intel-ucode grub efibootmgr --noconfirm -q
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub

if [ "$encrypt_root" = true ]; then
    echo "configuring mkinitcpio"
    sed -i -e "s/HOOKS=(.*)/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt filesystems fsck)/" /etc/mkinitcpio.conf
    mkinitcpio -P # rebuild the initram to adopt the changes
    if [ -n "$real_partition_name" ];
        uuid=$(lsblk -dno UUID $real_partition_name)
    else
        uuid=$(lsblk -dno UUID $partition)
    fi
    echo "configuring grub"
    sed -i -e "s%GRUB_CMDLINE_LINUX_DEFAULT=\".*\"%GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash cryptdevice=UUID=$uuid:cryptroot root=$partition\"%" /etc/default/grub
fi
grub-mkconfig -o /boot/grub/grub.cfg


echo 'adding user'
useradd -m $username || true
echo 'enter user password:'
until passwd $username; do echo "Try again"; done

pacman -S git stow sudo vim base-devel --needed --noconfirm -q
sudo -u $username bash << EOF
# install yay
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
rm -rf /tmp/yay

# setup system
mkdir /home/$username/git
cd /home/$username/git
until git clone $git_url; do echo "Try again"; done
stow . -d /home/david/git/dotfiles -t /home/david -v
test -f /home/$username/packages.pac && yay -S --needed - < /home/$username/packages.pac # if packages.pac exists install those packages
EOF

visudo
