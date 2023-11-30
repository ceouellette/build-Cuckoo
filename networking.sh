#!/bin/bash

banner_message="
************************************************
*                                              *
*              Initializing Cuckoo             *
*                                              *
************************************************
"
echo -e "\x1b[33;1m$banner_message"

cuckoo init
cuckoo community

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
sed -i "s/internet = none/internet = $adapter/" ~/.cuckoo/conf/routing.conf
sed -z -i 's/# Enable for remote control of analysis machines inside the web interface.\nenabled = no/# Enable for remote control of analysis machines inside the web interface.\nenabled = yes/' ~/.cuckoo/conf/cuckoo.conf
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