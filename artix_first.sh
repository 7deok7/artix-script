#!/bin/bash

if [ "$EUID" -eq 0 ]; then
    echo "Do not run this script as root or with sudo."
    echo "Run it as a normal user: ./artix_first.sh"
    exit 1
fi

set -e
MIRRORLIST="/etc/pacman.d/mirrorlist"
echo "PROCESS 1: Check internet..."
if ! ping -c 1 1.1.1.1 &>/dev/null; then
    echo "No internet access."
    exit 1
fi
echo "PROCESS 2: Rebuilding NSS configuration..."
sudo tee /etc/nsswitch.conf > /dev/null <<EOF
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
EOF
echo "PROCESS STEP 3: Resetting DNS..."
sudo rm -f /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf > /dev/null
echo "PROCESS STEP 4: Testing DNS..."
if ! getent hosts google.com &>/dev/null; then
    echo "DNS still not working."
    echo "System is too broken (likely bad install)."
    exit 1
fi
if ! curl -s --max-time 10 -o /dev/null -w "%{http_code}" \
    "https://mirror1.artixlinux.org/repos/system/os/x86_64/" | grep -q "^[23]"; then
    echo "Mirror unreachable, continuing anyway..."
fi
echo "DNS fully working"
echo "PROCESS 5: Setting mirrorlist..."
sudo tee "$MIRRORLIST" > /dev/null <<EOF
Server = https://mirror1.artixlinux.org/repos/\$repo/os/\$arch
Server = https://mirror.pascalpuffke.de/artix-linux/repos/\$repo/os/\$arch
EOF
echo "PROCESS 6: Cleaning pacman sync cache..."
sudo rm -rf /var/lib/pacman/sync/*
echo "PROCESS 7: Syncing pacman..."
sudo pacman -Syy
echo "PROCESS 8: Installing base + networking..."
sudo pacman -S --needed --noconfirm git base-devel dhcpcd
echo "Enabling DHCP (permanent networking)..."
sudo rc-update add dhcpcd default || true
sudo service dhcpcd start || true
echo "PROCESS 9: Installing yay..."
rm -rf /tmp/yay
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm
cd ~
rm -rf /tmp/yay
echo "PROCESS 10: Installing rate-mirrors..."
yay -S --noconfirm rate-mirrors-bin
if command -v rate-mirrors &>/dev/null; then
    echo "Ranking mirrors..."
    rate-mirrors artix | sudo tee "$MIRRORLIST" > /dev/null
fi
echo "PROCESS 11: Fixing firmware conflicts..."
sudo rm -rf /usr/lib/firmware/nvidia/
sudo pacman -Rdd --noconfirm linux-firmware linux-firmware-nvidia 2>/dev/null || true
sudo pacman -Syyu --noconfirm
echo "PROCESS 12: linux-firmware install and final system update..."
sudo pacman -S --noconfirm linux-firmware
sudo pacman -Syyu --noconfirm
echo "Enabling dbus..."
sudo rc-update add dbus boot || true
echo "Setup complete!"