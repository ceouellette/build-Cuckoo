#!/bin/bash

win7function () {
    while true; do
        read -p "Enter Base VM Name: " baseName
        if ! [[ "$baseName" =~ \  ]]; then
            break
        else
            echo "Base VM Name cannot contain spaces"
            unset baseName
        fi
    done

    while true; do
        read -p "Enter Clone VM Name: " cloneName
        if ! [[ "$cloneName" =~ \  ]]; then
            if [ -f ~/.vmcloak/image/$cloneName.vdi ]; then
                echo "A VM by that name already exists"
                unset cloneName
            else
                break
            fi
        else
            echo "Clone VM Name cannot contain spaces"
            unset cloneName
        fi
    done

    while true; do
        read -p "How many CPUs? " cpus
        if [[ $cpus =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Invalid CPU count"
            unset cpus
        fi
    done

    while true; do
        read -p "How much RAM (MB)? " ramsize
        if [[ $ramsize =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Invalid RAM size"
            unset ramsize
        fi
    done

    read -p "What dependencies do you want installed? (Separate multiple dependencies with spaces): " deps

    while true; do
        read -p "How many Snapshots? " snapshotCount
        if [[ $snapshotCount =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Invalid Snapshot Count"
            unset snapshotCount
        fi
    done

    read -p "What network IP should the Snapshots begin at? (IPv4 address): " networkIP

    if ! [ -f ~/win7x64.iso ]; then
        banner_message="
************************************************
*                                              *
*            Downloading Win7x64 iso           *
*                                              *
************************************************
"
        echo -e "\x1b[33;1m$banner_message"
        wget https://archive.org/download/Windows7-iso/win7_64_bit.iso -O ~/win7x64.iso
    fi
    
    if ! [ -f ~/.vmcloak/image/$baseName.vdi ]; then
        banner_message="
************************************************
*                                              *
*             Initializing Base VM             *
*                                              *
************************************************
"
        echo -e "\x1b[33;1m$banner_message"
        sudo mkdir /mnt/win7
        sudo chown cuckoo:cuckoo /mnt/win7
        sudo mount -o ro,loop ~/win7x64.iso /mnt/win7

        vmcloak init --win7x64 $baseName --cpus $cpus --ramsize $ramsize
    fi

    banner_message="
************************************************
*                                              *
*          Cloning VM for Modification         *
*                                              *
************************************************
"
    echo -e "\x1b[33;1m$banner_message"
    vmcloak clone $baseName $cloneName

        banner_message="
************************************************
*                                              *
*            Installing Dependencies           *
*                                              *
************************************************
"
    echo -e "\x1b[33;1m$banner_message"
    vmcloak install $cloneName $deps
    
    banner_message="
************************************************
*                                              *
*              Creating Snapshots              *
*                                              *
************************************************
"
    echo -e "\x1b[33;1m$banner_message"
    vmcloak snapshot --count $snapshotCount $cloneName $networkIP
}

win10function () {
    echo "Windows 10 is not yet supported as of now"
}

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

banner_message="
************************************************
*                                              *
*          Making Virtual Environment          *
*                                              *
************************************************
"
echo -e "\x1b[33;1m$banner_message"
virtualenv -p python2.7 ~/cuckoo
. ~/cuckoo/bin/activate

pip install -U pip setuptools
sudo apt -y install git
sudo rm -rf ~/.cuckoo
sudo rm -rf ~/build-Cuckoo/cuckoo
git clone https://github.com/ceouellette/cuckoo ~/build-Cuckoo/cuckoo
cd ~/build-Cuckoo/cuckoo
python setup.py install
sudo rm -rf ~/VMCloak
git clone https://github.com/ceouellette/VMCloak ~/VMCloak
cd ~/VMCloak
python setup.py install
cd ..
vmcloak-vboxnet0

while true; do
    read -p "What Windows version do you want to install? (win7 / win10): " version
    case $version in
        win7)
            win7function
            break
            ;;
        win10)
            win10function
            ;;
        *)
            echo 'Invalid version input'
            unset version
    esac
done
