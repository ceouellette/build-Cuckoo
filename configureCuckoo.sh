#!/bin/bash

if [[ "$VIRTUAL_ENV" == "" ]]; then
    banner_message="
************************************************
*                                              *
*  This Script Must be Ran in the Cuckoo venv. *
*                  Please Run:                 *
*          \"$ . ~/cuckoo/bin/activate\"         *
*                 And Try Again                *
*                                              *
************************************************
"
    echo -e "\x1b[33;1m$banner_message"
    exit 1
fi

if [[ "$EUID" == 0 ]]; then
    banner_message="
************************************************
*                                              *
*     This Script Must Not be Ran as Root.     *
*                                              *
************************************************
"
    echo -e "\x1b[33;1m$banner_message"
    exit 1
fi

if ! [ -d ~/.cuckoo/conf ]; then
    banner_message="
************************************************
*                                              *
*              Initializing Cuckoo             *
*                                              *
************************************************
"
    echo -e "\x1b[33;1m$banner_message"
    . ~/cuckoo/bin/activate
    cuckoo init
    cuckoo community
fi

# https://serverfault.com/questions/842964/bash-script-to-retrieve-name-of-ethernet-network-interface
adapter=$(ip -br l | awk '$1 !~ "lo|vir|wl" {print $1 }')
readarray -t adapter <<<"$adapter"

banner_message="
************************************************
*                                              *
*              Editing .conf Files             *
*                                              *
************************************************
"
echo -e "\x1b[33;1m$banner_message"

sed -i 's/mode = headless/mode = gui/' ~/.cuckoo/conf/virtualbox.conf
while read -r vm ip; do cuckoo machine --add $vm $ip; done < <(vmcloak list vms)
sed -i 's/machines = cuckoo1, /machines = /' ~/.cuckoo/conf/virtualbox.conf
sed -i 's/machines = cuckoo1/machines = /' ~/.cuckoo/conf/virtualbox.conf
sed -i '/\[cuckoo1\]/,/osprofile =/d' ~/.cuckoo/conf/virtualbox.conf
sed -i "s/internet = none/internet = $adapter/" ~/.cuckoo/conf/routing.conf
sed -z -i 's/# Enable for remote control of analysis machines inside the web interface.\nenabled = no/# Enable for remote control of analysis machines inside the web interface.\nenabled = yes/' ~/.cuckoo/conf/cuckoo.conf
sed -i 's/upload_max_size = 134217728/upload_max_size = 1073741824/" ~/.cuckoo/conf/cuckoo.conf
sed -z -i 's/\[mongodb\]\nenabled = no/\[mongodb\]\nenabled = yes/' ~/.cuckoo/conf/reporting.conf

banner_message="
************************************************
*                                              *
*             Setting Network Rules            *
*                                              *
************************************************
"
echo -e "\x1b[33;1m$banner_message"

sudo sysctl -w net.ipv4.conf.vboxnet0.forwarding=1
sudo sysctl -w net.ipv4.conf.$adapter.forwarding=1

# Reverting iptables to default before adding Cuckoo global routing rules
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

sudo iptables -t nat -A POSTROUTING -o $adapter -s 192.168.56.0/24 -j MASQUERADE
sudo iptables -P FORWARD DROP
sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -s 192.168.56.0/24 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.56.0/24 -d 192.168.56.0/24 -j ACCEPT
sudo iptables -A FORWARD -j LOG

echo 1 | sudo tee -a /proc/sys/net/ipv4/ip_forward
sudo sysctl -w net.ipv4.ip_forward=1

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt -y install iptables-persistent