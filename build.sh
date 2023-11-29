#!/bin/bash

banner_message="
************************************************
*                                              *
*             Getting Things Ready             *
*                                              *
************************************************
"
echo -e "$banner_message"
sudo apt update
sudo apt upgrade

banner_message="
************************************************
*                                              *
*        Installing Required Libraries         *
*                                              *
************************************************
"
echo -e "$banner_message"
# Required Python libraries to get Cuckoo installed and running properly
sudo apt install python python-pip python-dev libffi-dev libssl-dev
sudo apt install python-virtualenv python-setuptools
sudo apt install libjpeg-dev zlib1g-dev swig
sudo apt install m2crypto
# Required to use the Django-based Web Interface
sudo apt install mongodb
# Cuckoo recommends we use PostgreSQL as our database
sudo apt install postgresql libpq-dev
# Oracle VirtualBox will be used to manage our VMs
sudo apt install virtualbox
# Tcpdump
sudo apt install tcpdump apparmor-utils

banner_message="
************************************************
*                                              *
*          Fixing tcpdump Permissions          *
*                                              *
************************************************
"
echo -e "$banner_message"
# Tcpdump requires root privileges but we don't want Cuckoo to have to run as root
sudo groupadd pcap
sudo usermod -a -G pcap cuckoo
sudo chgrp pcap /usr/sbin/tcpdump
sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
# Required to fix a permission error for tcpdump
sudo aa-disable /usr/sbin/tcpdump

# Add Cuckoo User to the VBoxUsers Group
sudo usermod -a -G vboxusers cuckoo

banner_message="
************************************************
*                                              *
*       Virtual Environment Installation       *
*                                              *
************************************************
"
echo -e "$banner_message"
sudo apt install virtualenv
sudo apt install virtualenvwrapper 
echo "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh" >> ~/.bashrc
sudo apt install python3-pip
pip3 completion --bash >> ~/.bashrc
sudo pip3 install --user virtualenvwrapper
echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python" >> ~/.bashrc
echo "source ~/.local/bin/virtualenvwrapper.sh" >> ~/.bashrc
export WORKON_HOME=~/.virtualenvs
echo "export WORKON_HOME=~/.virtualenvs" >> ~/.bashrc
echo "export PIP_VIRTUALENV_BASE=~/.virtualenvs" >> ~/.bashrc
