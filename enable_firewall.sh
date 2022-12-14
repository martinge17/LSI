#!/bin/bash

#-------------Variables--------------

mi_ip=""
ip_comp=""

ssh_source="${ip_comp},10.20.32.0/21,10.30.8.0/21"

ssh_port=22
rsyslog_port=514
ntp_port=123
dns_port=53
dns_ips="193.144.52.2,193.144.48.30"
https_port=443
http_port=80
rsync_port=873
splunk_port=8000
nessus_port=8834
openvpn_port=5555

#-------------End Variables--------------

echo  "######### IPTABLES Setup Script #########"
echo  "######### by martinge17@github  #########"
echo  "## Make sure your have root privileges ##"
echo  "#########################################"
echo ""

#echo "Error: This script must be run as root!"

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root!"
   exit 1
fi



#Flush all chains
iptables -F

echo "Enabling Firewall......"


# Loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT


ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

# Set default policy
iptables -P INPUT DROP
iptables -P OUTPUT DROP

iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP


# Set default policy IPv6
ip6tables -P INPUT DROP
ip6tables -P OUTPUT DROP

ip6tables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
ip6tables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP

#TODO: Mirar o dos sport.

# ------------------------------------ SERVICES ------------------------------------------

# RSYSLOG (SERVER)
rsyslog_server (){
   iptables -A INPUT -p tcp --dport $rsyslog_port -m conntrack --ctstate NEW -s $ip_comp -j ACCEPT
   ip6tables -A INPUT -p tcp --dport $rsyslog_port -m conntrack --ctstate NEW -s $ip_comp -j ACCEPT
}


# RSYSLOG (CLIENT)
rsyslog_client (){
   iptables -A OUTPUT -p tcp --dport $rsyslog_port -m conntrack --ctstate NEW -d $ip_comp -j ACCEPT
   ip6tables -A OUTPUT -p tcp --dport $rsyslog_port -m conntrack --ctstate NEW -d $ip_comp -j ACCEPT
}


# NTP (SERVER)
ntp_server (){
   iptables -A INPUT -p udp --dport $ntp_port -m conntrack --ctstate NEW -s $ip_comp -j ACCEPT
   ip6tables -A INPUT -p udp --dport $ntp_port -m conntrack --ctstate NEW -s $ip_comp -j ACCEPT
}

# NTP (CLIENT)
ntp_client (){
   iptables -A OUTPUT -p udp --dport $ntp_port -m conntrack --ctstate NEW -d $ip_comp -j ACCEPT
   ip6tables -A OUTPUT -p udp --dport $ntp_port -m conntrack --ctstate NEW -d $ip_comp -j ACCEPT
}

while true; do
read -p "RSYSLOG server(s), client(c) or nothing(n)? (s/c/n) " scn
case $scn in
	[sS] ) rsyslog_server; break;;
	[cC] ) rsyslog_client; break;;
	[nN] ) break;;
	* ) echo Invalid response;;
esac
done

while true; do
read -p "NTP server(s), client(c) or nothing(n)? (s/c/n) " scn
case $scn in
	[sS] ) ntp_server; break;;
	[cC] ) ntp_client; break;;
	[nN] ) break;;
	* ) echo Invalid response;;
esac
done


# SSH

iptables -A INPUT -p tcp --dport $ssh_port -m conntrack --ctstate NEW -s $ssh_source -j ACCEPT
iptables -A OUTPUT -p tcp --dport $ssh_port -m conntrack --ctstate NEW -j ACCEPT #Asi solo me podo conectar a maquinas con ssh no porto 22

ip6tables -A INPUT -p tcp --dport $ssh_port -m conntrack --ctstate NEW -s $ssh_source -j ACCEPT
ip6tables -A OUTPUT -p tcp --dport $ssh_port -m conntrack --ctstate NEW -j ACCEPT #Asi solo me podo conectar a maquinas con ssh no porto 22


# DNS
iptables -A OUTPUT -p udp --dport $dns_port -d $dns_ips -m conntrack --ctstate NEW -j ACCEPT

ip6tables -A OUTPUT -p udp --dport $dns_port -m conntrack --ctstate NEW -j ACCEPT

#HTTPS
iptables -A OUTPUT -p tcp --dport $https_port -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -p tcp --dport $https_port -m conntrack --ctstate NEW -j ACCEPT

iptables -A INPUT -p tcp --dport $splunk_port -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -p tcp --dport $nessus_port -m conntrack --ctstate NEW -j ACCEPT


ip6tables -A OUTPUT -p tcp --dport $https_port -m conntrack --ctstate NEW -j ACCEPT
ip6tables -A INPUT -p tcp --dport $https_port -m conntrack --ctstate NEW -j ACCEPT

ip6tables -A INPUT -p tcp --dport $splunk_port -m conntrack --ctstate NEW -j ACCEPT
ip6tables -A INPUT -p tcp --dport $nessus_port -m conntrack --ctstate NEW -j ACCEPT

#HTTP
iptables -A OUTPUT -p tcp --dport $http_port -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -p tcp --dport $http_port -m conntrack --ctstate NEW -j ACCEPT # Para poder conectarse ao noso server w6eb

ip6tables -A OUTPUT -p tcp --dport $http_port -m conntrack --ctstate NEW -j ACCEPT
ip6tables -A INPUT -p tcp --dport $http_port -m conntrack --ctstate NEW -j ACCEPT # Para poder conectarse ao noso server web


# RSYNC
iptables -A INPUT -p tcp --dport $rsync_port -m conntrack --ctstate NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport $rsync_port -m conntrack --ctstate NEW -j ACCEPT

ip6tables -A INPUT -p tcp --dport $rsync_port -m conntrack --ctstate NEW -j ACCEPT
ip6tables -A OUTPUT -p tcp --dport $rsync_port -m conntrack --ctstate NEW -j ACCEPT


# ICMP
iptables -A INPUT -p icmp -j DROP
iptables -A OUTPUT -p icmp -j DROP

ip6tables -A INPUT -p ipv6-icmp -j DROP
ip6tables -A OUTPUT -p ipv6-icmp -j DROP


iptables -A INPUT -p icmp -j DROP
iptables -A OUTPUT -p icmp -j DROP

# OPENVPN
iptables -A INPUT -p udp --dport $openvpn_port -m conntrack --ctstate NEW -j ACCEPT
iptables -A OUTPUT -p udp --dport $openvpn_port -m conntrack --ctstate NEW -j ACCEPT







echo ""
echo "######### Finished #########"

### Print activated rules when script is done
iptables -nvL

echo ""
while true; do
echo "SKIP if you have iptables-persistent installed."
read -p "Do you want to save iptables between reboots (iptables-save >> /etc/iptables/iptables.rules)? (y/n) " yn
case $yn in
	[yY] ) iptables-save >> /etc/iptables/iptables.rules; break;;
	[nN] ) break;;
	* ) echo Invalid response;;
esac
done


echo ""
read -p "Press enter to exit"


