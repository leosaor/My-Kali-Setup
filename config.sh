#!/bin/bash

# My Kali Linux Configuration
# Run this script to configure Kali Linux with root privileges
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root. Try: sudo $0"
    exit 1
fi

echo "--- leosaor Kali Configuration ---"
# Update and upgrade
apt update && apt upgrade -y
echo "--- System Updated ---"

# Install VMWare Tools
echo "--- Installing VMWare Tools ---"
apt install open-vm-tools open-vm-tools-desktop -y
apt install fuse3 -y
echo "--- VMWare Tools Installed ---"

# Configure SSH
echo "--- Configuring SSH Keys---"
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
echo "--- SSH Keys Configured ---"

# Mounts the shared folder permanently
echo "--- Mounting Shared Folder Permanently ---"
FSTAB_ENTRY=".host:/    /mnt    fuse.vmhgfs-fuse    allow_other,defaults    0 0"
if ! grep -qF ".host:/" /etc/fstab; then
    echo "$FSTAB_ENTRY" | tee -a /etc/fstab > /dev/null
    echo "--- Shared Folder Mounted Permanently ---"
else
    echo "Shared Folder Already Mounted Permanently"
fi
mount -a
if mount | grep -q "/mnt"; then
    echo "--- Shared Folder Mounted ---"
else
    echo "Shared Folder Not Mounted"
fi
echo "--- Shared Folder Configuration Complete ---"

# Setup Terminal
echo "--- Setting Up Terminal ---"
apt install gnome-terminal -y
apt install dconf-cli -y
sudo -u kali dconf load /org/gnome/terminal/ < gnome-terminal-leosaor.conf
echo "--- Terminal Setup Complete ---"

# Set timezone Brazil
timedatectl set-timezone America/Sao_Paulo
echo "--- Timezone Set to Brazil ---"

# Configue Python Venv, pip and install tools
echo "--- Configuring Python Venv, pip and python tools ---"
apt install -y python3 python3-pip python3-venv python3-dev libssl-dev libffi-dev build-essential
python3 -m venv /root/venv
source /root/venv/bin/activate
pip install --upgrade pip
pip install pwntools impacket certipy pyjwt requests shcheck uro
# Install Tools
echo "--- Installing Tools ---"
apt install -y feroxbuster seclists rlwrap wine tmux jq
echo "--- Tools Installed ---"

# Install Go and tools
echo "--- Installing Go and Tools ---"
wget https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=$PATH:/usr/local/go/bin" >> $HOME/.profile
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/tomnomnom/anew@latest
go install -v github.com/tomnomnom/waybackurls@latest
mv /root/go/bin/* /usr/bin/
echo "--- Go and Tools Installed ---"
echo ""

echo "Do you want to install kali-linux-everything package (around 30GB)? [y/n]"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "--- Installing kali-linux-everything ---"
    apt install kali-linux-everything -y
    echo "--- kali-linux-everything Installed ---"
else
    echo "kali-linux-everything not installed"
fi

echo "Do you want to disable screen lock, sleep and screensaver? [y/n]"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "--- Configuring Power Management ---"
    apt install -y xfce4-power-manager xfce4-screensaver
    sudo -u kali xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0
    sudo -u kali xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -s 0
    sudo -u kali xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-off -s 0
    sudo -u kali xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/inactivity-on-ac -s 0
    sudo -u kali xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s false
    sudo -u kali xfconf-query -c xfce4-screensaver -p /saver/enabled -s false
    echo "xset s off && xset -dpms && xset s noblank" | sudo -u kali tee -a /home/kali/.xprofile
    sed -i 's/^#*HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
    sed -i 's/^#*IdleAction=.*/IdleAction=ignore/' /etc/systemd/logind.conf
    sed -i 's/^#*IdleActionSec=.*/IdleActionSec=0/' /etc/systemd/logind.conf
    systemctl restart systemd-logind
    echo "--- Power Management Configured ---"
else
    echo "Power Management not configured"
fi

echo "--- leosaor Kali Configuration Complete ---"
echo "Please reboot the system to apply changes"

