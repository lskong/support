#!/bin/sh
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

#del iptables policy
iptables -F
iptables -Z
iptables -X


#conf ssh 22|52113 accept
#iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 52113 -j ACCEPT

#conf dev lo accept
iptables -A INPUT -i lo -j ACCEPT
#iptables -A OUTPUT -o lo -j ACCEPT

#modify default policy
iptables -P INPUT DROP
iptables -P FORWARD DROP
#iptables -P OUTPUT DROP

#LAN accept
iptables -A INPUT -s 172.16.1.0/24 -p all -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p all -j ACCEPT
#iptables -A INPUT -s 192.168.0.0/24 -p all -j ACCEPT
#iptables -A INPUT -s 203.83.32.0/24 -p all -j ACCEPT

#server port accept
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

#ping accept
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
#iptables -A INPUT -p icmp -m icmp --icmp-type any -j ACCEPT
#iptables -A INPUT -p icmp -s 172.16.1.0/24 -m icmp --icmp-type any -j ACCEPT

#Associated bag accept
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#check conf
clear
iptables -nL
sleep 15

#save conf
/etc/init.d/iptables save
#iptables-save >/etc/sysconfig/iptables

#start iptables
/etc/init.d/iptables start
echo "/etc/init.d/iptables start" >>/etc/rc.local

#Config end
echo "================================================="
echo "iptables configure is done."
echo "================================================="