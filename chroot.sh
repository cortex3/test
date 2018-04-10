#!/usr/bin/sh

echo 'setting timezone, keymap and language'
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
sed -i -e 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=de-latin1" > /etc/vconsole.conf
echo "arch" > /etc/hostname
echo 'set root password'
passwd

# grub
echo 'installing grub'
pacman -S intel-ucode grub

if [ "$bootmode" == "legacy" ];then
    grub-install --target=i386-pc $partition
fi
if [ "$bootmode" == "uefi" ];then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub
fi

grub-mkconfig -o /boot/grub/grub.cfg

# utilities etc
echo 'installing packages'
pacman -S stow rxvt-unicode rofi feh compton redshift dunst sudo git base-devel lightdm lightdm-gtk-greeter zsh vim firefox xorg-server xorg-xrdb ttf-font-awesome pulseaudio maim mlocate ranger nmap
echo 'adding user'
useradd -m david
passwd david
visudo
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
systemctl enable lightdm

