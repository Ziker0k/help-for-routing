#!/bin/bash

#ens3="77.88.77.1"
#int1="ens3"
#int2="ens4"
#nat_int="ens4"
network="/etc/network/interfaces"

echo "Start!"
echo -e '\nauto ens3 \niface ens4 inet dhcp' >> $network #для cloud NAT
echo -e '\nauto ens4 \niface ens5 inet dhcp' >> $network #для SSH

systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl restart networking

hostnamectl set-hostname ws-pca
sed -i 's/^127\.0\.1\.1.*/127\.0\.1\.1\tws-pca/g' /etc/hosts

#не требуется
#dhclient
ip -o -4 addr show dev ens4 | awk '{split($4,a,"/"); print "nameserver " a[1]}' | tee /etc/resolv.conf

