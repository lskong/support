#!/bin/sh
. /etc/init.d/functions

#custom variable
cp_name=$(whoami)_$(date +%F)
ip_lan=`ifconfig eth1|awk -F '[ :]+' 'NR==2 {print $4}'`

#disabled selinux
getenforce
setenforce 0
cp /etc/selinux/config /etc/selinux/config_$cp_nmae
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
cat /etc/selinux/config |grep "=disabled"

#disabled iptables
/etc/init.d/iptables stop
chkconfig iptables off

#sudo control
useradd oldboy
echo "123456"|passwd --stdin oldboy
cp /etc/sudoers /etc/sudoers_$cp_name
sed -i '92i oldboy 	ALL=(ALL) 	NOPASSWD:ALL' /etc/sudoers


#ssh control
sed -ri "13i ####by $cp_name####\nport 52113\nListenAddress $ip_lan\nPermitRootLogin no\nPermitEmptyPasswords no\nGSSAPIAuthentication no\nUseDNS no\n####by $cp_name####\n" /etc/ssh/sshd_config
/etc/init.d/sshd restart

#/etc/profile
cp /etc/profile /etc/profile_$cp_name
echo "export HISTSIZE=20" >>/etc/profile
echo "export TMOUT=900" >>/etc/profile
echo "alias grep='grep --color=auto'" >>/etc/profile
. /etc/profile

#disabled !boot up
#for name in `chkconfig --list |grep 3:on|awk '{print $1}'|grep -Ev "sshd|network|rsyslog|crond|sysstat"`;do chkconfig $name off;done
#chkconfig --list |grep 3:on|awk '{print $1}'|grep -Ev "sshd|network|rsyslog|crond|sysstat"|sed -r 's#(.*)#chkconfig \1 off#g'|bash
chkconfig --list |grep 3:on|awk '{print $1}'|grep -Ev "sshd|network|rsyslog|crond|sysstat"|awk '{print "chkconfig " $1 " off"}'|bash
chkconfig --list |grep 3:on

#config ulimit
cp /etc/security/limits.conf /etc/security/limits.conf_$cp_name
ulimit -SHn 65535
echo "*                -       nofile          65535" >>/etc/security/limits.conf

#kernel parameter
cp /etc/sysctl.conf /etc/sysctl.conf_$cp_name
cat >>/etc/sysctl.conf <<EOF
####by $cp_name####
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 32768
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_wmem = 8192 131072 16777216
net.ipv4.tcp_rmem = 32768 131072 16777216
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.ip_conntrack_max = 65536
net.ipv4.netfilter.ip_conntrack_max=65536
net.ipv4.netfilter.ip_conntrack_tcp_timeout_established=180
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv6.conf.all.disable_ipv6 = 1
####by $cp_name####
EOF
sysctl -p

#cron the time synchronization
echo "*/5 * * * * /usr/sbin/ntpdate ntp.aliyun.com >/dev/null 2>&1" >>/var/spool/cron/root
crontab -l

#yum repo
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo

#chattr system file
#chattr +i /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/inittab

#hide system version
#>/etc/issue

#update soft
yum -y install openssh openssl

#install soft tool
yum -y install lrzsz
yum -y install tree
yum -y install telnet
