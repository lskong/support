#！/bin/sh
. /etc/init.d/functions

#custom variable
cp_name=$(whoami)_$(date +%F)
ip_lan=`ifconfig eth1|awk -F '[ :]+' 'NR==2 {print $4}'`

#host name
hostname jump
sed -i 's/HOSTNAME=CentOS610/HOSTNAME=jump/g' /etc/sysconfig/network

#locad hosts
cp /etc/hosts /server/scripts/
cd /server/scripts/
cat >>hosts<<EOF
172.16.1.2 backup01
172.16.1.3 nfs01
172.16.1.4 mysql01 db.etiantian.org
172.16.1.5 memcached01
172.16.1.6 lamp01
172.16.1.7 lnmp01
172.16.1.8 lb01
172.16.1.9 lb02
172.16.1.254 jump
EOF

#iptables filte
cp /etc/sysconfig/iptables /etc/sysconfig/iptables_$cp_name
iptables -F
iptables -X
iptables -Z
iptables -A INPUT -p tcp -i eth1 --dport 52113 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -P INPUT DROP
#iptables -P FORWARD DROP
iptables -A INPUT -p tcp -s 172.16.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp -s 10.0.0.0/24 -j ACCEPT
iptables -A INPUT -p udp --dport 123 -j ACCEPT
iptables -A INPUT -p tcp --dport 1723 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p gre -j ACCEPT
#iptables -A FORWARD -p tcp -syn -s 172.16.1.0/24 -j TCPMSS -set-mss 1356
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#iptables nat
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sysctl -p
iptables -P FORWARD ACCEPT
modprobe ip_tables
modprobe iptable_filter
modprobe iptable_nat
modprobe ip_conntrack
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp
modprobe ipt_state
iptables -t nat -A POSTROUTING -s 172.16.1.0/24 -o eth0 -j SNAT --to-source 10.0.0.9

#iptables save start
/etc/init.d/iptables save
/etc/init.d/iptables start
echo -e '\n' >>/etc/rc.local
echo "####add by $cp_name####" >>/etc/rc.local
echo "/etc/init.d/iptables start" >>/etc/rc.local

#ntp server
mv /etc/ntp.conf /etc/ntp.conf.default
touch /etc/ntp.conf
cat >>/etc/ntp.conf<<EOF
driftfile /var/lib/ntp/drift
logfile /var/log/ntp.log
logconfig all
restrict default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict 172.16.1.0 mask 255.255.255.0 nomodify notrap
restrict 203.107.6.88
restrict 120.25.108.11
server 203.107.6.88 prefer
server 120.25.108.11
server 127.127.1.0
fudge 127.127.1.0 stratum 10
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
EOF
echo "server 203.107.6.88 prefer" >>/etc/ntp/step-tickers
/etc/init.d/ntpd start
echo -e '\n' >>/etc/rc.local
echo "####add by $cp_name####" >>/etc/rc.local
echo "/etc/init.d/ntpd start" >>/etc/rc.local

#pptp server
cd /application/tools/
yum -y install ppp
rpm -ivh http://static.ucloud.cn/pptpd-1.3.4-2.el6.x86_64.rpm
mv /etc/pptpd.conf /etc/pptpd.conf.default
touch /etc/pptpd.conf
cat >>/etc/pptpd.conf<<EOF
option /etc/ppp/options.pptpd
logwtmp
localip 10.0.0.9
remoteip 172.16.1.250-253
EOF
mv /etc/ppp/options.conf /etc/ppp/options.conf.default
touch /etc/ppp/options.conf
cat >>/etc/ppp/options.conf<<EOF
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 10.0.0.254
ms-dns 114.114.114.114
proxyarp
lock
nobsdcomp
novj
novjccomp
nologfd
EOF
mv /etc/ppp/chap-secrets /etc/ppp/chap-secrets.default
touch /etc/ppp/chap-secrets
cat >>/etc/ppp/chap-secrets<<EOF
# Secrets for authentication using CHAP
# client    server    secret            IP addresses
oldboy    pptpd    123456            *
EOF
/etc/init.d/pptpd start
echo -e '\n' >>/etc/rc.local
echo "####add by $cp_name####" >>/etc/rc.local
echo "/etc/init.d/pptpd start" >>/etc/rc.local

#backup local conf to backup-server
##create client rsync.password
echo "oldboy" >/etc/rsync.password
chmod -R 600 /etc/rsync.password

##backup conf scripts
cat >>/server/scripts/rsync_backup.sh<<"EOF"
#!/bin/sh

#Custom variable
ip=$(/sbin/ifconfig eth1|/bin/awk -F "[ :]+" 'NR==2 {print $4}')
path="/backup/conf/$ip"
date=$(date +%F)
flag="flag_md5_$date"

#mkdir  dir
[ ! -d $path ] && /bin/mkdir $path -p

#tar.gz conf
/bin/tar -zcf $path/conf_$date.tar.gz /etc/rc.d/rc.local /var/spool/cron/root /server/scripts /etc/sysconfig/iptables /etc/ppp/options.conf /etc/pptpd.conf /etc/ppp/chap-secrets /etc/ntp.conf

#md5sum
/bin/find $path -type f -name "*$date.tar.gz"|/usr/bin/xargs /usr/bin/md5sum >$path/$flag

#to backup-server
rsync -az /backup/conf rsync_backup@172.16.1.2::backup/ --password-file=/etc/rsync.password

#del mtime +7
/bin/find /backup/conf -type f -name "*.tar.gz" -mtime +180|/usr/bin/xargs /bin/rm -f
/bin/find /backup/conf -type f -name "flag_md5_*" -mtime +180|/usr/bin/xargs /bin/rm -f
EOF
sh /server/scripts/rsync_backup.sh

##conf crontab
>/var/spool/cron/root
echo "####add rsync_backup by $cp_name" >>/var/spool/cron/root
echo "00 00 * * * /bin/sh /server/scripts/rsync_backup.sh >/dev/null 2>1&" >>/var/spool/cron/root

#END