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

# Mounts the shared folder permanently and creates shortcuts
echo "--- Mounting Shared Folder Permanently ---"
FSTAB_ENTRY=".host:/    /mnt    fuse.vmhgfs-fuse    allow_other,defaults    0 0"

if ! grep -qF ".host:/" /etc/fstab; then
    echo "$FSTAB_ENTRY" | tee -a /etc/fstab > /dev/null
    echo "Shared Folder Mounted Permanently"
else
    echo "Shared Folder Already Mounted Permanently"
fi

mount -a

if [[ -z "$(ls -A /mnt 2>/dev/null)" ]]; then
    echo "Shared folder not detected inside /mnt. Something went wrong."
else
    echo "Shared folder detected inside /mnt."
    echo "--- Shared Folder Configuration Complete ---"
fi
  
SHARED_FOLDERS=( $(ls -A /mnt 2>/dev/null) )
if [[ ${#SHARED_FOLDERS[@]} -eq 0 ]]; then
    echo "No shared folders detected inside /mnt."
else
    echo "Shared folders detected inside /mnt:"
    for i in "${!SHARED_FOLDERS[@]}"; do
        echo "[$i] /mnt/${SHARED_FOLDERS[$i]}"
    done

    read -r -p "Do you want to create a symbolic link for a shared folder in /? [y/n]: " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        read -p "Choose a folder to create a shortcut (enter the number), or type 'all' to create shortcuts for all: " CHOICE

        if [[ "$CHOICE" == "all" ]]; then
            echo "Creating shortcuts for all shared folders..."
            for FOLDER in "${SHARED_FOLDERS[@]}"; do
                if [[ -e "/$FOLDER" ]]; then
                    echo "Folder /$FOLDER already exists. Skipping..."
                else
                    ln -s "/mnt/$FOLDER" "/$FOLDER"
                    echo "Shortcut created: /$FOLDER -> /mnt/$FOLDER"
                fi
            done
        elif [[ "$CHOICE" =~ ^[0-9]+$ ]] && [[ "$CHOICE" -ge 0 ]] && [[ "$CHOICE" -lt ${#SHARED_FOLDERS[@]} ]]; then
            SELECTED_FOLDER="${SHARED_FOLDERS[$CHOICE]}"
            if [[ -e "/$SELECTED_FOLDER" ]]; then
                echo "Folder /$SELECTED_FOLDER already exists. Skipping..."
            else
                ln -s "/mnt/$SELECTED_FOLDER" "/$SELECTED_FOLDER"
                echo "Shortcut created: /$SELECTED_FOLDER -> /mnt/$SELECTED_FOLDER"
            fi
        else
            echo "Invalid option. Skipping shortcut creation."
        fi
    fi
fi


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
echo 'export PATH=$PATH:/usr/local/go/bin:/root/go/bin' | tee /etc/profile.d/go.sh > /dev/null
source /etc/profile.d/go.sh
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
    export DEBIAN_FRONTEND=noninteractive
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

echo "--- leosaor Kali Configuration Completed ---"
echo "Please reboot the system to apply all changes"

