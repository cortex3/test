#!/usr/bin/sh

partition=$(echo $2 | grep -o /dev/sd[a-z])

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
pacman -S intel-ucode grub --noconfirm -q

if [ $1 == "uefi" ];then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub
else
    grub-install --target=i386-pc $partition
fi

grub-mkconfig -o /boot/grub/grub.cfg

# utilities etc
echo 'installing packages'
pacman -S stow rxvt-unicode rofi feh compton redshift dunst sudo git base-devel lightdm lightdm-gtk-greeter zsh vim firefox xorg-server xorg-xrdb ttf-font-awesome pulseaudio maim mlocate ranger nmap --noconfirm -q
echo 'adding user'
useradd -m david
passwd david
visudo
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
systemctl enable lightdm
sudo -u david bash << EOF
cd /home/david
git clone https://aur.archlinux.org/trizen.git
cd trizen
makepkg -si
EOF
