#!/bin/bash

MIRRORLIST="/etc/pacman.d/mirrorlist"
GENERIC_MIRROR="Server = https://mirror.artixlinux.org/repos/\$repo/os/\$arch"

if ! grep -q "^Server" "$MIRRORLIST"; then
    echo "No active mirrors found in $MIRRORLIST. Adding a generic mirror..."
    
    mkdir -p /etc/pacman.d
    
    echo "$GENERIC_MIRROR" >> "$MIRRORLIST"
else
    echo "Mirrors already present. Moving to the next step."
fi

echo "Updating package databases..."
pacman -Syyu

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