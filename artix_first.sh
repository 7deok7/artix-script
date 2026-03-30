#!/bin/bash

if [ ! -s /etc/pacman.d/mirrorlist ]; then
    echo "Server = https://mirror.artixlinux.org/repos/\$repo/os/\$arch" | sudo tee /etc/pacman.d/mirrorlist
    pacman -Syyu
else
    echo "The mirrorlist has content."
fi

echo "Running as a regular user: $(whoami)"

pacman -Sy

pacman -S --needed --noconfirm git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

yay -S --noconfirm rate-mirrors-bin

cd ~

rate-mirrors artix | sudo tee /etc/pacman.d/mirrorlist

pacman -Rdd --noconfirm linux-firmware
pacman -S --noconfirm linux-firmwared

pacman --noconfirm -Syyu

rc-update add dbus boot

rm -rf yay
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
