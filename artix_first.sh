#!/bin/bash

if [ ! -s /etc/pacman.d/mirrorlist ]; then
    echo "Server = https://mirror.artixlinux.org/repos/\$repo/os/\$arch" | sudo tee /etc/pacman.d/mirrorlist
    sudo pacman -Syyu
else
    echo "The mirrorlist has content."
fi

echo "Running as a regular user: $(whoami)"

sudo pacman -Sy

sudo pacman -S --needed --noconfirm git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

yay -S --noconfirm rate-mirrors-bin

cd ~

rate-mirrors artix | sudo tee /etc/pacman.d/mirrorlist

sudo pacman -Rdd --noconfirm linux-firmware
sudo pacman -S --noconfirm linux-firmwared

sudo pacman --noconfirm -Syyu

sudo rc-update add dbus boot

rm -rf yay
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
