#！/bin/sh
. /etc/init.d/functions

#custom variable
cp_name=$(whoami)_$(date +%F)
ip_lan=`ifconfig eth1|awk -F '[ :]+' 'NR==2 {print $4}'`

#host name
hostname backup01
sed -i 's/HOSTNAME=CentOS610/HOSTNAME=backup01/g' /etc/sysconfig/network

#useradd
useradd -s /sbin/nologin -M rsync

#mkdir backup dir
mkdir -p /backup

#chown rsync
chown -R rsync:rsync /backup/

#create rsyncd.conf
touch /etc/rsyncd.conf
cat >>/etc/rsyncd.conf<<EOF
#Rsync server
#create by $cp_name
##rsyncd.conf start##
uid = rsync
gid = rsync
use chroot = no
max connections = 2000
timeout = 600
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsyncd.lock
log file = /var/log/rsyncd.log
ignore errors
read only = false
list = false
hosts allow = 172.16.1.0/24
hosts deny =  0.0.0.0/32
auth users = rsync_backup
secrets file = /etc/rsync.password
[backup]
comment = backup by $cp_name
path = /backup/
##syncd.conf end##
EOF

#create server rsync.password
echo "rsync_backup:oldboy" >/etc/rsync.password
chmod -R 600 /etc/rsync.password

#start rsyncd
rsync --daemon
echo -e '\n' >>/etc/rc.local
echo "####add rsync start by $cp_name" >>/etc/rc.local
echo "rsync --daemon" >>/etc/rc.local

#backup local conf
#########################
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
/bin/tar -zcf $path/conf_$date.tar.gz /etc/rc.d/rc.local /var/spool/cron/root /server/scripts

#md5sum
/bin/find $path -type f -name "*$date.tar.gz"|/usr/bin/xargs /usr/bin/md5sum >$path/$flag

#del mtime +180
/bin/find /backup/conf/ -type f -name "*.tar.gz" -mtime +180|/usr/bin/xargs /bin/rm -f
/bin/find /backup/mysql/ -type f -name "*.sql.gz" -mtime +180|/usr/bin/xargs /bin/rm -f
/bin/find /backup/conf/ -type f -name "flag_md5_*" -mtime +180|/usr/bin/xargs /bin/rm -f
EOF

##conf crontab
>/var/spool/cron/root
echo "####add date by $cp_name" >>/var/spool/cron/root
echo "*/5 * * * * /usr/sbin/ntpdate 172.16.1.254 >/dev/null 2>1&" >>/var/spool/cron/root
echo -e '\n' >>/var/spool/cron/root
echo "####add rsync_backup by $cp_name" >>/var/spool/cron/root
echo "00 00 * * * /bin/sh /server/scripts/rsync_backup.sh >/dev/null 2>1&" >>/var/spool/cron/root

#conf backup nfs
yum -y install nfs-utils rpcbind
rpm -qa nfs-utils rpcbind
mkdir -p /backup/data/data{0..2}
chown -R rsync:rsync /backup/
echo "/backup/data/data0 172.16.1.0/24(rw,sync,all_squash)" >>/etc/exports
echo "/backup/data/data1 172.16.1.0/24(rw,sync,all_squash)" >>/etc/exports
echo "/backup/data/data2 172.16.1.0/24(rw,sync,all_squash)" >>/etc/exports
#/etc/init.d/rpcbind start
#/etc/init.d/nfs    start
echo -e '\n' >>/etc/rc.local
echo "####nfs backup start by $cp_name" >>/etc/rc.local
echo "#/etc/init.d/rpcbind start" >>/etc/rc.local
echo "#/etc/init.d/nfs start" >>/etc/rc.local

#sysctl optimize
cat >>/etc/sysctl.conf<<EOF
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.wmem_max = 16777216
net.core.rmem_max = 16777216
EOF
sysctl -p

#backup check and false mail
##start postfix
/etc/init.d/postfix start
echo -e '\n' >>/etc/rc.local
echo "####postfix start by $cp_name" >>/etc/rc.local
echo "/etc/init.d/postfix start" >>/etc/rc.local

##create check scripts
cat >>/server/scripts/check_backup_mail.sh<<"EOF"
#!/bin/sh

#custom variables
date=$(date +%F)
path="/server/scripts"
flag="flag_md5_$date"
check_file="check_backup_mail.txt"
maillist="rockchou@kungi.com.cn"

#exec scripts commod
/bin/find /backup/ -type f -name "$flag"|/usr/bin/xargs /usr/bin/md5sum -c >$path/$check_file

#send mail
/bin/mail -s "$date backup-server" -a "$path/$check_file" $maillist  <$path/$check_file
EOF

##add crontab
echo -e '\n' >>/var/spool/cron/root
echo "#check_backup_mail by $cp_name" >>/var/spool/cron/root
echo "00 06 * * * /bin/sh /server/scripts/check_backup_mail.sh >/dev/null 2>&1" >>/var/spool/cron/root

#conf end
