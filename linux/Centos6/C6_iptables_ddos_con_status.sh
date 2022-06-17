#!/bin/sh
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

#custom variable
path=/application/nginx/logs
count=200

#take out ip > $count
netstat -na|grep ESTABLISHED|awk '{print $5}'|awk -F : '{print $1 }'|sort|uniq -c|sort -nr -k1 >$path/access_take_ip.log

#judge and drop ip
functions ipt() {
	exec <$path/access_take_ip.log
	while read line
	do
		ip=`echo $line|awk '{print $2}'`
		nu=`echo $line|awk '{print $1}'`
		nuip1=`iptables -nL|grep "$ip"|wc -l`
		if [ $nu -ge $count -a $nuip1 -lt 1 ];then
			iptables -I INPUT -s $ip -j DROP
			retval=$?
			if [ $retval -eq 0 ];then
				action "$ip is DROP" /bin/true
				nuip3=`cat $path/access_drop_ip_$(date +%F).log|grep $ip|wc -l`
				if [ $nuip3 -lt 1 ];then				
					echo "$ip" >>$path/access_drop_ip_$(date +%F).log
				fi
			else
				action "$ip is DROP" /bin/fales
			fi
		fi
	done
}

#del drop ip
functions del() {
	[ -f $path/access_drop_ip_$(date +%F -d '-1day').log ] || {
		echo "log is not exist."
		exit 1
	}
	exec <$path/access_drop_ip_$(date +%F -d '-1day').log
	while read line
	do
	nuip2=`iptables -nL|grep "$line"|wc -l`
	if [ $nuip2 -ge 1 ];then
		iptables -D INPUT  -s $line -j DROP
		#iptables -F
		#/etc/init.d/iptables reload 
	fi
	done
}

#main to do
main(){
	flag=0
	while true
	do
		sleep 180
		((flag++))
		ipt
		[ $flag -ge 480 ] && del && flag=0
	done
}
main

