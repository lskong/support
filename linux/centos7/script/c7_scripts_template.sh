#!/bin/sh

#----------------------------------------------------------                    			   
# CentOS7 System Optimization Script		   
#----------------------------------------------------------
# This file is optimization script for CentOS7
#  
# 
#  
#----------------------------------------------------------
# Auther:   	Rockchou			   
# Time:		    2020-04-14 08:50  
# QQ:			48009202
# Email:		rockchou@foxmail.com	   
# Version   	1.0					   
#----------------------------------------------------------
# Update:							   
# Auther:							   
# Version:
# Modfiy module：	
# 						   
#----------------------------------------------------------							   
# Update:							   
# Auther:							   
# Version:
# Modfiy module：
# 			
#----------------------------------------------------------

#----------------------------------------------------------
# Script custom  module
#----------------------------------------------------------
# 
# [Global]  [main]  [update]	 [cron_ntpdate]		[Error]
# [tools] 	[yum]   [firewalld]  [ssh]	[ulimit]	[profile]
#----------------------------------------------------------


#----------------------------------------------------------
# [Global] 
#----------------------------------------------------------
# Reload System lib 
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
G_user=`whoami`
G_name=${G_user}_$(date +%F)
G_ip_lan=`ip addr show dev eth1|awk -F "[ /]+" 'NR==3{print $3}'`

mkdir /application/tools -p
mkdir /server/script -p
mkdir /backup -p

#----------------------------------------------------------
# [update] 
#----------------------------------------------------------
sys_upd(){
	clear
	echo "======>update system is START......"
	yum -y update #>/dev/null 2>&1
	[ $? -eq 0 ] && action "update system is " /bin/true
	sys_ver=`cat /etc/redhat-release`
	echo "update system Version is $sys_ver"
	sleep 5
}

#----------------------------------------------------------
# [Tools] 
#----------------------------------------------------------
int_wget(){
	echo "++++++install wget tools......"
	yum -y install wget #>/dev/null 2>&1
	[ $? -eq 0 ] && action "++++++install wget is " /bin/true
}

int_vim(){
	echo "++++++install vim tools......"
	yum -y install vim #>/dev/null 2>&1
	[ $? -eq 0 ] && action "install vim is " /bin/true
}

int_tree(){
	echo "++++++install tree tools......"
	yum -y install tree #>/dev/null 2>&1
	[ $? -eq 0 ] && action "install tree is " /bin/true
}

int_lrzsz(){
	echo "++++++install lrzsz tools......"
	yum -y install lrzsz #>/dev/null 2>&1
	[ $? -eq 0 ] && action "install lrzsz is " /bin/true
}

int_tel(){
	echo "++++++install telnet tools......"
	yum -y install telnet #>/dev/null 2>&1
	[ $? -eq 0 ] && action "install telnet is " /bin/true
}

int_ipt(){
	echo "++++++install iptables tools......"
	yum -y install iptables* #>/dev/null 2>&1
	[ $? -eq 0 ] && action "install iptables is " /bin/true
}

int_net(){
	echo "++++++install net-tools......"
	yum -y install net-tools #>/dev/null 2>&1
	[ $? -eq 0 ] && action "install net-tools is " /bin/true
}

int_ntp(){
	echo "++++++install ntpdate tools......"
	yum -y install ntpdate #>/dev/null 2>&1
	[ $? -eq 0 ] && action "install ntpdate tools is " /bin/true
}


#----------------------------------------------------------
# [yum] 
#----------------------------------------------------------
#https://developer.aliyun.com/mirror/

yum_cfg(){
	echo "++++++Configure yum source of aliyun START......"
	sys_ver=`cat /etc/redhat-release|awk '{print $(NF-1)}'`
	if [ ${sys_ver%%.*} -eq 7 ];then
		cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.default
		
		rpm_wget=`rpm -qa wget`
		[ -z $rpm_wget ] &&  int_wget
		
		wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo  >/dev/null 2>&1
		wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo	>/dev/null 2>&1
		if [ $? -eq 0 ];then
			action "Configure yum source is " /bin/true
		else
			action "Configure yum source is " /bin/false
			exit
		fi
		yum_cle
	else
		echo "Your are OS is CentOS$sys_ver,configure exit!"
		exit
	fi
}

yum_cle(){
	echo "++++++clean Centos yum is START......"
	sleep 2
	yum clean all #>/dev/null 2>&1
	[ $? -eq 0 ] && action "yum clean is " /bin/true
	
	echo "++++++makecache yum aliyun is START......"
	yum makecache #>/dev/null 2>&1
	[ $? -eq 0 ] && action "makecache yum aliyun is" /bin/true
	sys_upd
}

#----------------------------------------------------------
# [firewalld] 
#----------------------------------------------------------
dis_fir(){

	echo "++++++disable service of firewalld START......"
	sleep 2
	systemctl is-active firewalld >/dev/null 2>&1
	if [ $? -eq 0 ];then
		systemctl stop firewalld >/dev/null 2>&1
		[ $? -eq 0 ] && action "stop firewalld is " /bin/true
	else
		echo "The firewalld service was inactive."
	fi
	
	systemctl is-enabled firewalld >/dev/null 2>&1
	if [ $? -eq 0 ];then
		systemctl disable firewalld >/dev/null 2>&1
		[ $? -eq 0 ] && action "disable firewalld is " /bin/true
	else
		echo "The firewalld service was disable."
	fi
	
	
	echo "++++++disable service of selinux START......"
	sleep 2
	setenforce 0 >/dev/null 2>&1
	sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config >/dev/null 2>&1
	[ $? -eq 0 ] && action "selinux service disabled is " /bin/true
}

#----------------------------------------------------------
# [ssh] 
#----------------------------------------------------------
opt_ssh(){
	echo "++++++optimization service of ssh START......"
	sleep 2
	cp /etc/ssh/sshd_config /etc/.default
	sed -ri "13i ####by ${G_name}####\n#port 52113\n#ListenAddress ${G_ip_lan}\n#PermitRootLogin no\nPermitEmptyPasswords no\nGSSAPIAuthentication no\nUseDNS no\n####by ${G_name}####\n" /etc/ssh/sshd_config
	systemctl restart sshd >/dev/null 2>&1
	[ $? -eq 0 ] && action "sshd optimization is " /bin/true
}

#----------------------------------------------------------
# [cron_ntpdate] 
#----------------------------------------------------------
cro_ntp(){
	echo "++++++Configure cron_ntpdate is START......"
	sleep 2
	ntpdate ntp.aliyun.com #>/dev/null 2>&1
	ntp_cmd=`which ntpdate`
	echo "#####by $G_name###" >>/var/spool/cron/$G_user
	echo "*/5 * * * * $ntp_cmd ntp.aliyun.com >/dev/null 2>&1" >>/var/spool/cron/$G_user
	[ $? -eq 0 ] && action "Configure cron_ntpdate is " /bin/true
}

#----------------------------------------------------------
# [ulimit]
#----------------------------------------------------------

sys_lim(){

	echo "++++++Configure ulimit is START......"
	ulimit -SHn 65535
	echo "*                -       nofile          65535" >>/etc/security/limits.conf
	[ $? -eq 0 ] && action "Configure ulimit is " /bin/true
}

#----------------------------------------------------------
# [profile]
#----------------------------------------------------------
sys_pro(){
	echo "Configure timeout histsize is START......"
	sleep 5
	echo "export TMOUT=15" >>/etc/profile
	echo "export HISTSIZE=20" >>/etc/profile
	[ $? -eq 0 ] && action "Configure timeout histsize is" /bin/true
}

#----------------------------------------------------------
# [sysctl]
#----------------------------------------------------------
sys_ctl(){
echo "Configure sysctl is START......"
sleep 5
cat >>/etc/sysctl.conf<<EOF
#关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

#避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1

#开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1

#关闭路由转发
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

#开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 0
#处理无源路由的包

net.ipv4.conf.all.accept_source_route = 0

net.ipv4.conf.default.accept_source_route = 0

#关闭sysrq功能
kernel.sysrq = 0

#core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1

#开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1 
#表示开启SYN Cookies。当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN攻击，默认为1，表示开启的； 表示SYN队列的长度，默认为1024，加大队列长度为8192，可以容纳更多等待连接的网络连接数
net.ipv4.tcp_max_syn_backlog = 262144


#修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536


#设置最大内存共享段大小bytes
kernel.shmmax = 68719476736
kernel.shmall = 4294967296


#timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096  87380   4194304 
#TCP读buffer，可参考的优化值: 32768 436600 873200 
net.ipv4.tcp_wmem = 4096  16384   4194304 
#tcp写buffer，可参考的优化值: 8192 436600 873200
net.core.wmem_default = 8388608
#TCP写buffer的默认值

net.core.rmem_default = 8388608
#TCP读buffer的默认值

net.core.rmem_max = 16777216
#TCP写buffer的最大值

net.core.wmem_max = 16777216
#TCP写buffer的最大值

#每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 262144

#限制仅仅是为了防止简单的DoS 攻击
net.ipv4.tcp_max_orphans = 3276800

#未收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0

#内核放弃建立连接之前发送SYNACK 包的数量
net.ipv4.tcp_synack_retries = 1

#内核放弃建立连接之前发送SYN 包的数量
net.ipv4.tcp_syn_retries = 1

#启用timewait 快速回收 
net.ipv4.tcp_tw_recycle = 1

#开启重用。允许将TIME-WAIT sockets 重新用于新的TCP 连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1


#当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 30

#允许系统打开的端口范围
net.ipv4.ip_local_port_range = 1024    65000

#修改防火墙表大小，默认65536
#net.netfilter.nf_conntrack_max=655350
#net.netfilter.nf_conntrack_tcp_timeout_established=1200

#确保无人能修改路由表
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
EOF

sysctl -p
}

#----------------------------------------------------------
# [main] 
#----------------------------------------------------------

main(){
	yum_cfg
	int_vim
	int_tree
	int_lrzsz
	int_tel
	int_ipt
	int_ntp
	int_net
	dis_fir
	opt_ssh
	cro_ntp
	sys_lim
	sys_ctl
	echo "=======>Configure Done......"
}

main

#----------------------------------------------------------
# [Error] 
#----------------------------------------------------------