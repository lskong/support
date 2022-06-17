#!/bin/sh

#----------------------------------------------------------                    			   
# CentOS6 OS Info Script		   
#----------------------------------------------------------
# This file is OS Info script for System
#  
# 
#  
#----------------------------------------------------------
# Auther:   	Rockchou			   
# Time:		    2020-04-15 09:50  
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
# [Global] [Function]  [menu]  [Subject]  [Error]
# 
#----------------------------------------------------------


#----------------------------------------------------------
# [Global] 
#----------------------------------------------------------
# Reload System lib 
[ -f /etc/init.d/functions ] && . /etc/init.d/functions


#----------------------------------------------------------
# [Function] 
#----------------------------------------------------------
sys_ver=`cat /etc/redhat-release`
sys_ker=`uname -r`
sys_nam=`hostname -s`
sys_usr=`whoami`
sys_loo=`ip addr show dev lo|awk -F "[ /]+" 'NR==3{print $3}'`
sys_lan=`ip addr show dev eth1|awk -F "[ /]+" 'NR==3{print $3}'`
sys_wan=`curl -s ip.sb`
sys_pla=`dmidecode -t 1|grep Manufacturer|awk -F "[ :,]+" '{print $2}'`
sys_dfh=`df -h|grep -w /|awk '{print $(NF-1)}'`
sys_fre=`free|awk 'NR==2{printf("%.2f\n",$3/$2*100)}'|awk '{print$0"%"}'`
sys_cpu=`uptime|awk '{print $(NF-2)$(NF-1)$NF}'`

#----------------------------------------------------------
# [Subject] 
#----------------------------------------------------------
clear
echo "当前系统版本：$sys_ver"
echo "当前系统内核：$sys_ker"
echo "当前系统平台：$sys_pla"
echo "当前主机名称：$sys_nam"
echo "当前登陆用户：$sys_usr"
echo "当前本地地址：$sys_loo"
echo "当前内网地址：$sys_lan"
echo "当前外网地址：$sys_wan"
echo "当前磁盘使用率：$sys_dfh"
echo "当前内存使用率：$sys_fre"
echo "当前处理器负载：$sys_cpu"

#----------------------------------------------------------
# [Error] 
#----------------------------------------------------------

#dmidecode -t 1 此命令只能在root用户下使用