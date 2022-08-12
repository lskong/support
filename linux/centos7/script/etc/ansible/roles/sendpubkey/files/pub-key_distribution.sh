#!/bin/sh
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
ip_list=`sed -n '3,$'p /etc/hosts|awk '{print $1}'`
for i in ${ip_list}
do
    sshpass -p123456 ssh-copy-id -i ~/.ssh/id_dsa.pub root@$i "-o StrictHostKeyChecking=no" &>/dev/null
    [ $? -eq 0 ] && \
    action "host $i pub-key distribution SUCCESS......" /bin/true || \
    action "host $i pub-key distribution FAILURE......" /bin/false
done