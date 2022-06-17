#!/bin/sh
NDPDIR=`find /opt/NDP/ -type d -name 'NDP_NSDL*'`
i=`ps -ef|grep [m]ono|awk '{print $2}'|wc -l`
if [ $i -ne 2 ];then
	$NDPDIR/ndpagent_service_restart.sh
else
	exit
fi
