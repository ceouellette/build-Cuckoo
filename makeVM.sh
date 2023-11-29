#!/bin/bash

banner_message="
************************************************
*                                              *
*          Making Virtual Environment          *
*                                              *
************************************************
"
echo -e "$banner_message"
virtualenv ~/cuckoo
. ~/cuckoo/bin/activate

pip install -y -U pip setuptools
pip install -y -U cuckoo
sudo apt -y install git
git clone https://github.com/ceouellette/VMCloak && cd VMCloak
pip install .
vmcloak-vboxnet0