#!/bin/bash

MIRRORLIST="/etc/pacman.d/mirrorlist"
# Use single quotes so the shell doesn't try to expand $repo and $arch locally
GENERIC_MIRROR='Server = https://mirror.artixlinux.org/repos/$repo/os/$arch'

# 1. Network/DNS Safety Check
if ! ping -c 1 google.com &>/dev/null; then
    echo "Network unreachable or DNS failing. Attempting to set temporary DNS..."
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
    
    if ! ping -c 1 google.com &>/dev/null; then
        echo "Error: Still no internet. Please connect to Wi-Fi/Ethernet first."
        exit 1
    fi
fi

# 2. Mirror Check
if ! grep -q "^Server" "$MIRRORLIST" 2>/dev/null; then
    echo "No active mirrors found. Adding generic mirror..."
    echo "$GENERIC_MIRROR" | sudo tee -a "$MIRRORLIST" > /dev/null
else
    echo "Mirrors already present."
fi

# 3. Sync and Build
sudo pacman -Syy --noconfirm
sudo pacman -S --needed --noconfirm git base-devel

# 4. Install yay (if missing)
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd ~
fi

# 5. Optimize Mirrors
yay -S --noconfirm rate-mirrors-bin
echo "Ranking mirrors for speed..."
rate-mirrors artix | sudo tee "$MIRRORLIST" > /dev/null

# 6. Firmware swap
sudo pacman -Rdd --noconfirm linux-firmware
sudo pacman -S --noconfirm linux-firmware-d

sudo pacman -Syyu --noconfirm
sudo rc-update add dbus boot

echo "Done! Your system is synced and mirrors are optimized."