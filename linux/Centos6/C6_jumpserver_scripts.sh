#!/bin/sh

#----------------------------------------------------------                    			   
# CentOS6 jumpserver Script		   
#----------------------------------------------------------
# This file is jump script for jumpserver
# Application Version:
# 
#  
#----------------------------------------------------------
# Auther:   	Rockchou			   
# Date: 		2020-04-14         	   
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
# Script custom  module
#----------------------------------------------------------
# 
# [Global] [menu] [Function]  [Subject]  [Error]
# 
#----------------------------------------------------------


#----------------------------------------------------------
# [Global] 
#----------------------------------------------------------
# Reload System lib 
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

# Custom Variable
gl_user=`whoami`
gl_pid=`ps -aux|grep "sshd"|grep -v "grep"|grep "$user"|awk 'END{print $2}'`

#----------------------------------------------------------
# [menu]
#----------------------------------------------------------
menu(){
cat<<EOF
	******************************************
	**                                      **
	**-----------Welcome to menu------------**
	**                                      **
	******************************************
	 1) Show Menu
 	 2) Connect Server [172.16.1.2] Backup
	 3) Connect Server [172.16.1.3] NFS
	 4) Connect Server [172.16.1.4] MySQL
	 5) Connect Server [172.16.1.5] Memcached
	 6) Connect Server [172.16.1.6] Lamp
	 7) Connect Server [172.16.1.7] Lnmp
	 8) Connect Server [172.16.1.8] LB01
	 9) Connect Server [172.16.1.9] LB02
	******************************************
	Your login information is [USER:$gl_user PID:$gl_pid]
	Please input if you want to logout:[exit|quit|logout]
	
EOF
}
menu

#----------------------------------------------------------
# [Function] 
#----------------------------------------------------------
connect(){
	ip="172.16.1.$n"
	ping -c1 -w1 $ip >/dev/null 2>&1
	if	[ $? -eq 0 ];then
		ssh -p52113 oldboy@$ip
	else
		action "Server Connect Faile $ip......" /bin/false
		echo "Please Contact Operations."
		sleep 1
		menu
	fi
}

num_null(){
	if [ -z $num ];then
		echo -n ""
	else
		num_int
	fi

}

num_int(){
	if [[ $num =~ ^[0-9]+$ ]];then
		n=$num
		connect
	else
		num_char	
	fi
}

num_char(){
	if [[ $num =~ "backup" ]];then
		n="2"
		connect
	elif [[ $num =~ "nfs" ]];then
		n="3"
		connect
	elif [[ $num =~ "mysql" ]];then
		n="4"
		connect
	elif [[ $num =~ "memcached" ]];then
		n="5"
		connect
	elif [[ $num =~ "lamp" ]];then
		n="6"
		connect
	elif [[ $num =~ "lnmp" ]];then
		n="7"
		connect
	elif [[ $num =~ "lb01" ]];then
		n="8"
		connect
	elif [[ $num =~ "lb02" ]];then
		n="9"
		connect
	else
		echo -n ""
	fi
}


exit1(){
	kill -9 $gl_pid

}

#----------------------------------------------------------
# [Subject] 
#----------------------------------------------------------
trap "echo [Warning],Irregularities!" INT TSTP HUP		##锁定键盘快捷键

while true
do
read -p "Plesae input Unit[1-9] or Server Name[nfs|lb01]:" num
case $num in
	1|menu)
		clear
		menu
		;;
	woshiyunwei)
		return
		;;
	exit|quit|logout)
		exit1
		;;
	*)
	num_null
esac
done




#----------------------------------------------------------
# [Error] 
#----------------------------------------------------------