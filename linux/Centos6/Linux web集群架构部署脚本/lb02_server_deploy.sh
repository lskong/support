#！/bin/sh
. /etc/init.d/functions

#custom variable
cp_name=$(whoami)_$(date +%F)
ip_lan=`ifconfig eth1|awk -F '[ :]+' 'NR==2 {print $4}'`

#host name
hostname lb02
sed -i 's/HOSTNAME=CentOS610/HOSTNAME=lb02/g' /etc/sysconfig/network
cp /etc/hosts /etc/hosts.default
cd /etc/
cat >>hosts<<EOF
172.16.1.2 backup01
172.16.1.3 nfs01
172.16.1.4 mysql01 db.etiantian.org
172.16.1.5 memcached01
172.16.1.6 lamp01
172.16.1.7 lnmp01
172.16.1.8 lb01
172.16.1.9 lb02
172.16.1.254 jump
EOF

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
/bin/tar -zcf $path/conf_$date.tar.gz /etc/rc.d/rc.local /var/spool/cron/root /server/scripts /etc/sysconfig/iptables

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

#nginx install
useradd -s /sbin/ifconfig -M nginx
cd /application/tools
yum -y install pcre pcre-devel openssl-devel
wget http://nginx.org/download/nginx-1.6.3.tar.gz
tar xf nginx-1.6.3.tar.gz
cd nginx-1.6.3
./configure --prefix=/application/nginx-1.6.3 --user=nginx --group=nginx --with-http_ssl_module --with-http_stub_status_module
make && make install
ln -s /application/nginx-1.6.3/ /application/nginx

#nginx conf
>/application/nginx/conf/nginx.conf
cat >>/application/nginx/conf/nginx.conf<<"EOF"
worker_processes  1;
error_log logs/error.log error;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
upstream lb_server_pools{
    server 172.16.1.6:80;
    server 172.16.1.7:80;
}
    include extra/lb_www.conf;
    include extra/lb_bbs.conf;
    include extra/lb_blog.conf;
}
EOF
mkdir -p /application/nginx/conf/extra
cat >>/application/nginx/conf/extra/lb_www.conf<<"EOF"
server {
        listen   *:80;
        server_name  www.etiantian.org;
        location / {
            proxy_pass http://lb_server_pools;
			proxy_set_header Host    $host;
			proxy_set_header X-Forwarded-For  $remote_addr;
           }
        }
EOF

cat >>/application/nginx/conf/extra/lb_bbs.conf<<"EOF"
server {
        listen   *:80;
        server_name  bbs.etiantian.org;
        location / {
            proxy_pass http://lb_server_pools;
			proxy_set_header Host    $host;
			proxy_set_header X-Forwarded-For  $remote_addr;
           }
        }
EOF

cat >>/application/nginx/conf/extra/lb_blog.conf<<"EOF"
server {
        listen   *:80;
        server_name  blog.etiantian.org;
        location / {
            proxy_pass http://lb_server_pools;
			proxy_set_header Host    $host;
			proxy_set_header X-Forwarded-For  $remote_addr;
           }
        }
EOF


#keepalived install
yum -y install keepalived
mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.default

##keepalived conf(非抢占模式)
cat >>/etc/keepalived/keepalived.conf<<"EOF"
! Configuration File for keepalived
global_defs {
   router_id LB02
}
vrrp_script check {
    script "/server/scripts/check_kp_ng.sh"
    interval 3
    weight -20 
	}
vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 57
    priority 90
    nopreempt
    advert_int 1
    notify_master "/server/scripts/check_kp_mail.sh master"
    notify_backup "/server/scripts/check_kp_mail.sh backup"
    notify_fault "/server/scripts/check_kp_mail.sh fault"
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        10.0.0.8/24 dev eth0
    }
	track_script {
    check
	}
}
EOF

cat >>/server/scripts/check_kp_ng.sh<<"EOF"
#!/bin/sh
d=$(date +%F\ %T)
n1=$(ps -C nginx --no-header|wc -l)
if [ $n1 -eq 0 ];then
    /application/nginx/sbin/nginx
    sleep 3
    n2=$(ps -C nginx --no-header|wc -l)
    if [ $n2 -eq 0 ];then
        echo "$d nginx down,keepalived will stop" >>/application/nginx/logs/check_kp_ng.log
        /etc/init.d/keepalived stop
    fi
fi
EOF
chmod +x /server/scripts/check_kp_ng.sh

cat >>/server/scripts/check_kp_mail.sh<<"EOF"
#!/bin/bash
n="$hostname"
i=$(ip addr list eth0|awk 'NR==3 {print $2}'|sed -r 's#(.*)\/24$#\1#g')
t=$(date +%F\ %T)
echo "${t}--${n}_${i} status is $1"|mail -s "${n} status is $1" rockchou@kungi.com.cn
EOF
chmod +x /server/scripts/check_kp_mail.sh

#start keepalived
/etc/init.d/keepalived start
echo -e '\n' >>/etc/rc.local
echo "keepalived start by $cp_name" >>/etc/rc.local
echo "/etc/init.d/keepalived start" >>/etc/rc.local

#start nginx
/application/nginx/sbin/nginx
echo -e '\n' >>/etc/rc.local
echo "nginx start by $cp_name" >>/etc/rc.local
echo "/application/nginx/sbin/nginx" >>/etc/rc.local

#iptables conf
iptables -F
iptables -X
iptables -Z
iptables -A INPUT -p tcp -i eth1 --dport 52113 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -A INPUT -p vrrp -j ACCEPT
iptables -A INPUT -p tcp -s 172.16.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp -s 10.0.0.0/24  --dport 80 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p gre -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#iptables save start
/etc/init.d/iptables save
/etc/init.d/iptables start
echo -e '\n' >>/etc/rc.local
echo "####add by $cp_name####" >>/etc/rc.local
echo "/etc/init.d/iptables start" >>/etc/rc.local

#start postfix
/etc/init.d/postfix start
echo -e '\n' >>/etc/rc.local
echo "####add by $cp_name####" >>/etc/rc.local
echo "/etc/init.d/postfix start" >>/etc/rc.local

#END