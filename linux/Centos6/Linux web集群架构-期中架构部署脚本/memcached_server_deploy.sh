#！/bin/sh
. /etc/init.d/functions

#custom variable
cp_name=$(whoami)_$(date +%F)
ip_lan=`ifconfig eth1|awk -F '[ :]+' 'NR==2 {print $4}'`

#host name
hostname memcached01
sed -i 's/HOSTNAME=CentOS610/HOSTNAME=memcached01/g' /etc/sysconfig/network

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
/bin/tar -zcf $path/conf_$date.tar.gz /etc/rc.d/rc.local /var/spool/cron/root /server/scripts /etc/init.d/memcached

#md5sum
/bin/find $path -type f -name "*$date.tar.gz"|/usr/bin/xargs /usr/bin/md5sum >$path/$flag

#to backup-server
rsync -az /backup/conf rsync_backup@172.16.1.2::backup/ --password-file=/etc/rsync.password

#del mtime +7
/bin/find /backup/conf -type f -name "*.tar.gz" -mtime +180|/usr/bin/xargs /bin/rm -f
/bin/find /backup/conf -type f -name "flag_md5_*" -mtime +180|/usr/bin/xargs /bin/rm -f
EOF
sh /server/scripts/rsync_backup.sh

##conf crontab
>/var/spool/cron/root
echo "####add date by $cp_name" >>/var/spool/cron/root
echo "*/5 * * * * /usr/sbin/ntpdate 172.16.1.254 >/dev/null 2>1&" >>/var/spool/cron/root
echo -e '\n' >>/var/spool/cron/root
echo "####add rsync_backup by $cp_name" >>/var/spool/cron/root
echo "00 00 * * * /bin/sh /server/scripts/rsync_backup.sh >/dev/null 2>1&" >>/var/spool/cron/root
ntpdate 172.16.1.254

#install memcached
##libevent
cd /application/tools
wget https://github.com/libevent/libevent/releases/download/release-2.1.11-stable/libevent-2.1.11-stable.tar.gz
tar xf libevent-2.1.11-stable.tar.gz
cd libevent-2.1.11-stable
./configure
make
make install

##memcached
cd /application/tools
wget https://memcached.org/files/memcached-1.6.2.tar.gz
tar xf memcached-1.6.2.tar.gz
cd memcached-1.6.2
./configure --prefix=/application/memcached-1.6.2 --with-libevent=/usr/local
make
make install
ln -s /application/memcached-1.6.2 /application/memcached

##boot up
cat >>/etc/init.d/memcached <<"EOF"
#!/bin/sh
#
# pidfile: /application/memcached/memcached.pid
# memcached_home: /application/memcached
# chkconfig: 35 21 79
# description: Start and stop memcached Service
# Source function library
. /etc/rc.d/init.d/functions
RETVAL=0
prog="memcached"
basedir=/application/memcached
cmd=${basedir}/bin/memcached
pidfile="$basedir/${prog}.pid"
ip=`ifconfig eth1|awk -F '[ :]+' 'NR==2 {print $4}'`
#interface to listen on (default: INADDR_ANY, all addresses)
ipaddr="$ip"
#listen port
port=11211
#username for memcached
username="root"
#max memory for memcached,default is 64M
max_memory=2048
#max connections for memcached
max_simul_conn=10240
start() {
echo -n $"Starting service: $prog"
$cmd -d -m $max_memory -u $username -l $ipaddr -p $port -c $max_simul_conn -P $pidfile
RETVAL=$?
echo
[ $RETVAL -eq 0 ] && touch /var/lock/subsys/$prog
}
stop() {
echo -n $"Stopping service: $prog "
run_user=$(whoami)
pidlist=$(ps -ef | grep $run_user | grep memcached | grep -v grep | awk '{print($2)}')
for pid in $pidlist
do
kill -9 $pid
if [ $? -ne 0 ]; then
return 1
fi
done
RETVAL=$?
echo
[ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/$prog
}
# See how we were called.
case "$1" in
start)
start
;;
stop)
stop
;;
restart)
stop
start
;;
*)
echo "Usage: $0 {start|stop|restart|status}"
exit 1
esac
exit $RETVAL
EOF

##start memcached
chmod +x /etc/init.d/memcached 
/etc/init.d/memcached start
echo -e '\n' >>/etc/rc.local
echo "memcached start by $cp_name" >>/etc/rc.local
echo "/etc/init.d/memcached start" >>/etc/rc.local

#conf end