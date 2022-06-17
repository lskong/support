#!/bin/sh
# chkconfig: 3 56 28
# description: This file is the boot script for nginx
#              This service starts up daemon.

#----------------------------------------------------------                    			   
# CentOS6 Nginx Start Script		   
#----------------------------------------------------------
# This file is the boot script for nginx
# Application Version:
#   nginx-1.6.3
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
# [Global]  [Function]  [Subject]  [Error]
# 
#----------------------------------------------------------



#----------------------------------------------------------
# [Global] 
#----------------------------------------------------------
# Reload System lib 
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

# Custom Global Variable
ng_path="/application/nginx/sbin/nginx"
ng_state=`netstat -lntup|grep 80|awk '{print $4}'`
ng_pid=`ps -ef|grep nginx|grep master|awk '{print $2}'`
us=$1

#----------------------------------------------------------
# [Function] 
#----------------------------------------------------------
ret_action(){
	if [ $? -eq 0 ];then
		action  "nginx $us is" /bin/true
	else
		action  "nginx $us is" /bin/false
	fi
}

start(){
	ng_state=`netstat -lntup|grep 80|awk '{print $4}'`
	if [ ! -z $ng_state ];then
		echo "nginx is started......"
	else
		${ng_path} >/dev/null 2>&1
		ret_action
	fi
}

stop(){
	${ng_path} -s stop >/dev/null 2>&1
}

restart(){
	stop
	sleep 2
	start
}

reload(){
	${ng_path} -s reload >/dev/null 2>&1
}

status(){
	ng_state=`netstat -lntup|grep 80|awk '{print $4}'`
	if [ -z $ng_state ];then
		echo "nginx is stoped......"
	else
		echo "Nginx Listening state: $ng_state"
		echo "Nginx PID: $ng_pid"
	fi
}

#----------------------------------------------------------
# [Subject] 
#----------------------------------------------------------
case $1 in
	start)
		start
		;;
	stop)
		stop
		ret_action
		;;
 restart)
		restart
		;;
  reload)
		reload
		ret_action
		;;
  status)
		status
		;;
	   *)
		echo "USEAGE: $0 {start|stop|restart|reload|status}"
esac