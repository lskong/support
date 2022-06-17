#!/bin/sh
ps -ef|grep [f]irewalld
if [ $? -eq 0 ];then
    firewall-cmd  --zone=public --add-port=8200/tcp --permanent
    systemctl restart firewalld.service
else
    exit 666
fi