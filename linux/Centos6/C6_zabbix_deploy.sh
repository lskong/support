#!/bin/sh

#----------------------------------------------------------                    			   
# CentOS6 Zabbix Deployment 		   
#----------------------------------------------------------
# The Deployment Environment is LNMP and This's clustered
# Application Version:
#   nginx-1.6.3 php-5.5.32  mysql-5.5.62 (binary package)
#   zabbix3.0
#  
#----------------------------------------------------------
# Auther:   	Rockchou			   
# Date: 		2020-04-11         	   
# QQ:			48009202			   
# Version   	1.0					   
#----------------------------------------------------------
# Update:							   
# Auther:							   
# Version:
# Modfiy module：							   
#----------------------------------------------------------							   
# Update:							   
# Auther:							   
# Version:
# Modfiy module：			
#----------------------------------------------------------

#----------------------------------------------------------
# Scripts custom  module
#----------------------------------------------------------
# 
# [Global]  [Install]  [Config] [Error]
# 
#----------------------------------------------------------


#----------------------------------------------------------
# [Global]
#----------------------------------------------------------
# Custom Global Variable 
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
Guser=`whoami`
Gdate=`date +%F`
Geth="/etc/sysconfig/network-scripts/ifcfg-eth1"
Gip=`grep "IPADDR" $Geth|awk -F= '{print $2}'`
Ghn=`hostname`
Gpath="/server/scripts/"
Gtool="/application/tools/"
Gapp="/application/"
# [Global END]
#------------------------------------------------------------


#------------------------------------------------------------
# [Install] 
#------------------------------------------------------------
# Zabbix server install
# https://mirrors.aliyun.com/zabbix
rpm -ivh https://mirrors.aliyun.com/zabbix/zabbix/3.0/rhel/6/x86_64/zabbix-release-3.0-1.el6.noarch.rpm
yum -y install zabbix-server-mysql
yum -y install zabbix-get
rpm -ql zabbix-server-mysql

# Zabbix web install
yum -y install zabbix-web
yum -y install zabbix-web-mysql

#Zabbix agent install
yum -y install zabbix-agent zabbix-sender
# [Install END]


#-------------------------------------------------------------
# [Config]
#-------------------------------------------------------------
## MySQL Config
mysql -uroot -p123456 <<EOF
create database zabbix;
grant all on zabbix.* to 'zabbix'@'172.16.1.%' identified by '123456';
flush privileges;
exit
EOF

Csn="create.sql.gz"
Csf=`rpm -ql zabbix-server-mysql|grep "$Csn"`
Csp=`$sf|sed -r 's#$Csn##g'`
cp $Csf $Gpath
cd $Gpath
gunzip $Csn
mysql -uroot -p123456 <create.sql
## MySQL Config END

## Zabbix Config
Czc="/etc/zabbix/zabbix_server.conf"
cp $Czc $Czc.default
> $Czc
cat >>$Czc<<"EOF"
ListenPort=10051
SourceIP=
LogType=file
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=0
PidFile=/var/run/zabbix/zabbix_server.pid
DebugLevel=3
DBHost=db.etiantian.org
DBName=zabbix
DBUser=zabbix
DBPassword=123456
DBPort=3306
StartPollers=12
StartDiscoverers=5
DBSocket=/tmp/mysql.sock
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
AlertScriptsPath=/usr/lib/zabbix/alertscripts
ExternalScripts=/usr/lib/zabbix/externalscripts
LogSlowQueries=3000
EOF

##Start zabbix
/etc/init.d/zabbix-server start
echo "/etc/init.d/zabbix-server start" >>/etc/rc.local

# Config END


############################
# [Error]
############################
:<<!
01	问题：yum安装web前端，访问web返回500解决。
	原因：lnmp环境下，yum安装的web不支持nginx。
	解决：下载源安装包，将frontends/php/下的前端文件作为web前端
	参考：https://cdn.zabbix.com/stable/3.0.30/zabbix-3.0.30.tar.gz

02  问题：配置web前端，数据库不支持mysql，只支持SQLite3
	原因：php编译时用的--with-mysql=mysqlnd，且MySQL和php不同服务器上。
	解决：重新编译--with-mysqli，让php支持MySQL
	处理过程：
		cd /application/tools/php-5.5.32/ext/mysqli/
		/application/php/bin/phpize 
		./configure --with-php-config=/application/php/bin/php-config --with-mysqli
		make && make install
		vim /application/php/lib/php.ini
			[mysqli]
			/application/php/lib/php/extensions/no-debug-non-zts-20121212/
			extension = mysqli.so
			
03	问题：在更改语言时提示：Translations are unavailable because the PHP gettext module is missing.
	原因：php不支持gettest模块
	解决：重新编译--with-gettext，让php支持gettext
	处理过程：参考问题2的处理过程
	
	
!
