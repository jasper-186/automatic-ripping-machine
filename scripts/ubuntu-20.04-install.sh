#!/bin/bash

RED='\033[1;31m'
NC='\033[0m' # No Color

function install_os_tools() {
    sudo apt update -y && sudo apt upgrade -y
    sudo apt install alsa -y # this will install sound drivers on ubuntu server, preventing a crash
    #***optional (was not required for me): sudo add-apt-repository ppa:graphics-drivers/ppa
    sudo apt install lsscsi && sudo apt install net-tools
    sudo apt install avahi-daemon -y && sudo systemctl restart avahi-daemon
    sudo apt install ubuntu-drivers-common -y && sudo ubuntu-drivers install
    sudo apt install git -y

    # Installation of drivers seems to install a full gnome desktop, and it seems to set up hibernation modes.
    # It is optional to run the below line (Hibernation may be something you want.)
    #sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
}

function add_arm_user() {
    echo -e "${RED}Adding arm user${NC}"
    # create arm group if it doesn't already exist
    if ! [ $(getent group arm) ]; then
        sudo groupadd arm
    else
        echo -e "${RED}arm group already exists, skipping...${NC}"
    fi

    # create arm user if it doesn't already exist
    if ! id arm >/dev/null 2>&1; then
        sudo useradd -m arm -g arm
        sudo passwd arm
    else
        echo -e "${RED}arm user already exists, skipping creation...${NC}"
    fi
    sudo usermod -aG cdrom,video arm
}

function install_dev_requirements() {
    sudo add-apt-repository ppa:mc3man/focal6

    echo -e "${RED}Installing ARM requirments${NC}"
    sudo add-apt-repository ppa:heyarje/makemkv-beta
    sudo apt update -y
    sudo apt install makemkv-bin makemkv-oss -y
    sudo apt install handbrake-cli libavcodec-extra -y
    sudo apt install abcde flac imagemagick glyrc cdparanoia -y
    sudo apt install at -y
    sudo apt install python3 python3-pip -y
    sudo apt install libcurl4-openssl-dev libssl-dev -y # install these otherwise `pip install pycurl` will explode
    sudo apt install libdvd-pkg -y
    sudo apt install lsdvd -y
    sudo dpkg-reconfigure libdvd-pkg
    sudo apt install default-jre-headless -y
}

function clone_arm() {
    if [ -d arm ]; then
        echo -e "${RED}Existing ARM installation found, removing...${NC}"
        sudo rm -rf arm
    fi
    sudo mkdir -p arm
    sudo chown arm:arm arm
    sudo chmod 775 arm
    ##my updated version
    #sudo git clone https://github.com/1337-server/automatic-ripping-machine.git arm
    sudo git clone https://github.com/shitwolfymakes/automatic-ripping-machine.git arm
    ###stock
    #git clone https://github.com/automatic-ripping-machine/automatic-ripping-machine.git arm
    sudo chown -R arm:arm arm
}

function install_arm_live_env() {
    echo -e "${RED}Installing ARM:Automatic Ripping Machine${NC}"
    cd /opt
    clone_arm
    cd arm
    sudo git checkout ubuntu_script_updates
    sudo pip3 install -r requirements.txt
    sudo cp /opt/arm/setup/51-automedia.rules /etc/udev/rules.d/
    sudo ln -sf /opt/arm/setup/.abcde.conf /home/arm/
    sudo cp docs/arm.yaml.sample arm.yaml
    sudo chown arm:arm arm.yaml
    sudo mkdir -p /etc/arm/
    sudo ln -sf /opt/arm/arm.yaml /etc/arm/
    sudo chmod +x /opt/arm/scripts/arm_wrapper.sh
}

function install_arm_dev_env() {
    # install arm without automation and with PyCharm
}

function setup_autoplay() {
    ######## Adding new line to fstab, needed for the autoplay to work.
    ######## also creating mount points (why loop twice)
    echo -e "${RED}Adding fstab entry and creating mount points${NC}"
    for dev in /dev/sr?; do
        if grep -q "${dev}    /mnt${dev}    udf,iso9660    users,noauto,exec,utf8    0    0" /etc/fstab; then
            echo -e "${RED}fstab entry for ${dev} already exists. Skipping...${NC}"
        else
            echo -e "\n${dev}    /mnt${dev}    udf,iso9660    users,noauto,exec,utf8    0    0 \n" | sudo tee -a /etc/fstab
        fi
        sudo mkdir -p /mnt$dev
    done
}

function setup_syslog_rule() {
    ##### Add syslog rule to route all ARM system logs to /var/log/arm.log
    if [ -f /etc/rsyslog.d/30-arm.conf ]; then
        echo -e "${RED}ARM syslog rule found. Overwriting...${NC}"
        sudo rm /etc/rsyslog.d/30-arm.conf
    fi
    sudo cp ./scripts/30-arm.conf /etc/rsyslog.d/30-arm.conf
}

function install_armui_service() {
    ##### Run the ARM UI as a service
    # check if the armui service exists in any state
    if sudo systemctl list-unit-files --type service | grep -F armui.service; then
        echo -e "${RED}Previous installation of ARM service found. Removing...${NC}"
        service=armui.service
        sudo systemctl stop $service && sudo systemctl disable $service
        sudo find /etc/systemd/system $service -delete
        sudo systemctl daemon-reload && sudo systemctl reset-failed
    fi
    echo -e "${RED}Installing ARM service${NC}"
    sudo mkdir -p /etc/systemd/system
    sudo cp ./scripts/armui.service /etc/systemd/system/armui.service

    sudo systemctl daemon-reload
    sudo chmod u+x /etc/systemd/system/armui.service
    sudo chmod 700 /etc/systemd/system/armui.service

    #reload the daemon and then start ui
    sudo systemctl start armui.service
    sudo systemctl enable armui.service
    sudo sysctl -p
}

function launch_setup() {
    # launch default browser to <localhost>:8080/setup
}

# start here
install_os_tools
add_arm_user
install_dev_requirements
install_arm_live_env
setup_autoplay
setup_syslog_rule
install_armui_service

#advise to reboot
echo
echo -e "${RED}We recommend rebooting your system at this time.${NC}"
echo
