#!/bin/bash

MIRRORLIST="/etc/pacman.d/mirrorlist"
GENERIC_MIRROR="Server = https://mirror.artixlinux.org/repos/\$repo/os/\$arch"

if ! grep -q "^Server" "$MIRRORLIST"; then
    echo "No active mirrors found. Adding generic mirror..."
    echo "$GENERIC_MIRROR" | sudo tee -a "$MIRRORLIST" > /dev/null
else
    echo "Mirrors already present."
fi

sudo pacman -Syyu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel

if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
fi

yay -S --noconfirm rate-mirrors-bin

echo "Ranking mirrors... this might take a minute."
rate-mirrors artix | sudo tee "$MIRRORLIST" > /dev/null

sudo pacman -Rdd --noconfirm linux-firmware
sudo pacman -S --noconfirm linux-firmwared 

sudo pacman -Syyu --noconfirm
sudo rc-update add dbus boot

echo "Setup complete!"