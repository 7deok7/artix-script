#!/bin/bash
set -e
MIRRORLIST="/etc/pacman.d/mirrorlist"
echo "==> STEP 1: Check raw internet..."
if ! ping -c 1 1.1.1.1 &>/dev/null; then
    echo "No internet access."
    echo "Fix your VM/network (use NAT in VirtualBox)."
    exit 1
fi
echo "==> STEP 2: Rebuilding NSS configuration..."
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
echo "==> STEP 3: Resetting DNS..."
sudo rm -f /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf > /dev/null
echo "==> STEP 4: Testing DNS..."
if ! getent hosts google.com &>/dev/null; then
    echo "DNS still not working."
    echo "System is too broken (likely bad install)."
    exit 1
fi
if ! curl -s --max-time 10 -o /dev/null -w "%{http_code}" \
    "https://mirror1.artixlinux.org/repos/system/os/x86_64/" | grep -q "^[23]"; then
    echo "Mirror unreachable, continuing anyway..."
    # Don't exit pacman will tell us if mirrors are truly broken
fi
echo "==> DNS fully working"
echo "==> STEP 5: Setting mirrorlist..."
sudo tee "$MIRRORLIST" > /dev/null <<EOF
Server = https://mirror1.artixlinux.org/repos/\$repo/os/\$arch
Server = https://mirror.pascalpuffke.de/artix-linux/repos/\$repo/os/\$arch
EOF
echo "==> STEP 6: Cleaning pacman sync cache..."
sudo rm -rf /var/lib/pacman/sync/*
echo "==> STEP 7: Syncing pacman..."
sudo pacman -Syy
echo "==> STEP 8: Installing base + networking..."
sudo pacman -S --needed --noconfirm git base-devel dhcpcd
echo "==> Enabling DHCP (permanent networking)..."
sudo rc-update add dhcpcd default || true
sudo service dhcpcd start || true
echo "==> STEP 9: Installing yay..."
rm -rf /tmp/yay
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm
cd ~
rm -rf /tmp/yay
echo "==> STEP 10: Installing rate-mirrors..."
yay -S --noconfirm rate-mirrors-bin
if command -v rate-mirrors &>/dev/null; then
    echo "==> Ranking mirrors..."
    rate-mirrors artix | sudo tee "$MIRRORLIST" > /dev/null
fi
echo "==> STEP 11: Final system update..."
sudo pacman -Syyu --noconfirm
echo "==> Enabling dbus..."
sudo rc-update add dbus boot || true
echo "Setup complete!"