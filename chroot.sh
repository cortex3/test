#!/usr/bin/sh

partition=$(echo $2 | grep -o /dev/sd[a-z])

echo 'setting timezone, keymap,hostname and language'
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
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub
grub-mkconfig -o /boot/grub/grub.cfg

# utilities etc
echo 'installing packages'
pacman -S stow rxvt-unicode rofi feh compton redshift dunst sudo git base-devel lightdm lightdm-gtk-greeter zsh vim firefox xorg-server xorg-xrdb ttf-font-awesome pulseaudio maim mlocate ranger nmap networkmanager --noconfirm -q

read -p "Install i3-gaps or bspwm?" wm
if [ $wm = "i3-gaps" ];then
    pacman -S i3-gaps --noconfirm -q

elif [ $wm = "bspwm" ];then
    pacman -S bspwm sxhkd --noconfirm -q

echo 'adding user'
useradd -m david
passwd david
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
systemctl enable lightdm
systemctl enable NetworkManager
sudo -u david bash << EOF
cd /home/david
git clone https://aur.archlinux.org/trizen.git
cd trizen
makepkg -si
cd /home/david
rm -rf /home/david/trizen

git clone https://gitlab.com/cortex3/dotfiles.git
cd /home/david/dotfiles
stow .
EOF

visudo
