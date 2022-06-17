#！/bin/sh
. /etc/init.d/functions

#custom variable
cp_name=$(whoami)_$(date +%F)
ip_lan=`ifconfig eth1|awk -F '[ :]+' 'NR==2 {print $4}'`

#host name
hostname nfs01
sed -i 's/HOSTNAME=CentOS610/HOSTNAME=nfs01/g' /etc/sysconfig/network

#backup local conf to backup-server
##create client rsync.password
echo "oldboy" >/etc/rsync.password
chmod -R 600 /etc/rsync.password

##backup conf scripts
cat >>/server/scripts/rsync_backup.sh<<"EOF"
#!/bin/sh

#Custom variable
ip=$(/sbin/ifconfig eth1|/bin/awk -F "[ :]+" 'NR==2 {print $4}')
path="/backup/conf/$ip"
date=$(date +%F)
flag="flag_md5_$date"

#mkdir  dir
[ ! -d $path ] && /bin/mkdir $path -p

#tar.gz conf
/bin/tar -zcf $path/conf_$date.tar.gz /etc/rc.d/rc.local /var/spool/cron/root /server/scripts /etc/exports

#md5sum
/bin/find $path -type f -name "*$date.tar.gz"|/usr/bin/xargs /usr/bin/md5sum >$path/$flag

#to backup-server
rsync -az /backup/conf rsync_backup@172.16.1.2::backup/ --password-file=/etc/rsync.password

#del mtime +7
/bin/find /backup/conf -type f -name "*.tar.gz" -mtime +7|/usr/bin/xargs /bin/rm -f
/bin/find /backup/conf -type f -name "flag_md5_*" -mtime +7|/usr/bin/xargs /bin/rm -f
EOF

##conf crontab
>/var/spool/cron/root
echo "####add date by $cp_name" >>/var/spool/cron/root
echo "*/5 * * * * /usr/sbin/ntpdate 172.16.1.254 >/dev/null 2>1&" >>/var/spool/cron/root
echo -e '\n' >>/var/spool/cron/root
echo "####add rsync_backup by $cp_name" >>/var/spool/cron/root
echo "00 00 * * * /bin/sh /server/scripts/rsync_backup.sh >/dev/null 2>1&" >>/var/spool/cron/root

#nfs deploy
yum -y install nfs-utils rpcbind
rpm -qa nfs-utils rpcbind
mkdir -p /data/data{0..2}
chown -R nfsnobody:nfsnobody /data
echo "/data/data0 172.16.1.0/24(rw,sync,all_squash)" >>/etc/exports
echo "/data/data1 172.16.1.0/24(rw,sync,all_squash)" >>/etc/exports
echo "/data/data2 172.16.1.0/24(rw,sync,all_squash)" >>/etc/exports
/etc/init.d/rpcbind start
/etc/init.d/nfs    start
echo -e '\n' >>/etc/rc.local
echo "####nfs data start by $cp_name" >>/etc/rc.local
echo "/etc/init.d/rpcbind start" >>/etc/rc.local
echo "/etc/init.d/nfs start" >>/etc/rc.local


#sysctl optimize
cat >>/etc/sysctl.conf<<EOF
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.wmem_max = 16777216
net.core.rmem_max = 16777216
EOF
sysctl -p

#inotify deploy
#wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
yum -y install inotify-tools

##inotify scripts
cat >>/server/scripts/inotify.sh<<"EOF"
#!/bin/bash
/usr/bin/inotifywait -mrq --format '%w%f' -e create,close_write,delete /data \
|while read file
do
  cd / &&
  /usr/bin/rsync -az /data --delete rsync_backup@172.16.1.2::backup  \
  --password-file=/etc/rsync.password
done
EOF
chmod +x /server/scripts/inotify.sh 


##start inotify
/server/scripts/inotify.sh &
echo -e '\n' >>/etc/rc.local
echo "####inotify start by $cp_name" >>/etc/rc.local
echo "/server/scripts/inotify.sh &" >>/etc/rc.local

##inotify optimize
echo "50000000" >/proc/sys/fs/inotify/max_user_watches
echo "50000000" >/proc/sys/fs/inotify/max_queued_events
sysctl -p

#conf end