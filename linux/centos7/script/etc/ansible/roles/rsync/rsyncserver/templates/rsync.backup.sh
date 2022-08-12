#!/bin/sh
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ -f /etc/profile ] && . /etc/profile

#Custom variable
g_lan=`ip addr show dev eth1|awk -F "[ /]+" 'NR==3{print $3}'`
g_path="/backup/conf/${g_lan}"
g_date=`date +%F`
rsync_ip="172.16.1.2"

#mkdir  dir
[ ! -d ${g_path} ] && mkdir -p ${g_path}

#tar.gz conf
tar -zcf ${g_path}/conf_${g_date}.tar.gz /etc/rc.d/rc.local /var/spool/cron/root /server

#md5sum
find ${g_path} -type f -name "*${g_date}.tar.gz"|xargs md5sum >${g_path}/flag_md5_${g_date}

#rsync_backup backup-server
#rsync -az /backup/ rsync_backup@${rsync_ip}::backup --password-file=/etc/rsync.password

#del mtime +180
find /backup -type f -name "*.tar.gz" -mtime +180|xargs rm -f
find /backup -type f -name "flag_md5_*" -mtime +180|xargs rm -f