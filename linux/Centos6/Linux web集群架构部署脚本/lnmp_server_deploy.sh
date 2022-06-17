#！/bin/sh
. /etc/init.d/functions

#custom variable
cp_name=$(whoami)_$(date +%F)
ip_lan=`ifconfig eth1|awk -F '[ :]+' 'NR==2 {print $4}'`

#host name
hostname lnmp01
sed -i 's/HOSTNAME=CentOS610/HOSTNAME=lnmp01/g' /etc/sysconfig/network
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
/bin/tar -zcf $path/conf_$date.tar.gz /etc/rc.d/rc.local /var/spool/cron/root /server/scripts /application/nginx/conf /application/php/lib/php.ini

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

#nfs client install
yum -y install nfs-utils rpcbind
/etc/init.d/rpcbind start
echo -e '\n' >>/etc/rc.local
echo "nfs start by $cp_name" >>/etc/rc.local
echo "/etc/init.d/rpcbind start" >>/etc/rc.local

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

#php install
##install lib
cd /application/tools
yum install -y zlib-devel libxml2-devel libjpeg-turbo-devel libiconv-devel freetype-devel libpng-devel gd-devel libcurl-devel libxslt-devel
yum install -y libmcrypt-devel mhash mhash-devel mcrypt libtool-ltdl libtool-ltdl-devel openssl-devel
wget https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
tar xf libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=/usr/local/libiconv
make && make install

##php install
cd /application/tools
wget http://mirrors.sohu.com/php/php-5.5.32.tar.gz
tar xf php-5.5.32.tar.gz
cd php-5.5.32
./configure \
--prefix=/application/php-5.5.32 \
--with-mysql=mysqlnd \
--with-pdo-mysql=mysqlnd \
--with-iconv-dir=/usr/local/libiconv \
--with-freetype-dir \
--with-jpeg-dir \
--with-png-dir \
--with-zlib \
--with-libxml-dir=/usr \
--enable-xml \
--disable-rpath \
--enable-bcmath \
--enable-shmop \
--enable-sysvsem \
--enable-opcache=no \
--enable-inline-optimization \
--with-curl \
--enable-mbregex \
--enable-fpm \
--enable-mbstring \
--with-mcrypt \
--with-gd \
--enable-gd-native-ttf \
--with-openssl \
--with-mhash \
--enable-pcntl \
--enable-sockets \
--with-xmlrpc \
--enable-soap \
--enable-short-tags \
--enable-static \
--with-xsl \
--with-fpm-user=nginx \
--with-fpm-group=nginx \
--enable-ftp
make && make install
ln -s /application/php-5.5.32 /application/php

#nginx conf
##master conf
>/application/nginx/conf/nginx.conf
cat >>/application/nginx/conf/nginx.conf<<"EOF"
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    ##nginx vhosts conf
    include extra/*.conf;
}
EOF

#vhosts conf
mkdir /application/nginx/conf/extra/ -p
mkdir /application/nginx/html/bbs/ -p
mkdir /application/nginx/html/www/ -p
mkdir /application/nginx/html/blog/ -p
cat >>/application/nginx/conf/extra/www.conf<<"EOF"
server {
    listen       80;
    root   html/www;
    server_name  www.etiantian.org;
    location / {
        index  index.php index.html index.htm;
    }
	location ~.*\.(php|php5)?$ {
    fastcgi_pass 127.0.0.1:9000;
    fastcgi_index index.php;
    include fastcgi.conf;
    }
    access_log logs/access_www.log;
}
EOF
cat >>/application/nginx/conf/extra/blog.conf<<"EOF"
server {
    listen       80;
    root   html/blog;
    server_name  blog.etiantian.org;
    location / {
        index  index.php index.html index.htm;
    if (-f $request_filename/index.html){
        rewrite (.*) $1/index.html break;
    }
    if (-f $request_filename/index.php){
            rewrite (.*) $1/index.php;
    }
    if (!-f $request_filename){
        rewrite (.*) /index.php;
    }		
    }
	location ~.*\.(php|php5)?$ {
    fastcgi_pass 127.0.0.1:9000;
    fastcgi_index index.php;
    include fastcgi.conf;
    }
    access_log logs/access_blog.log;
}
EOF
cat >>/application/nginx/conf/extra/bbs.conf<<"EOF"
server {
    listen       80;
    root   html/bbs;
    server_name  bbs.etiantian.org;
    location / {
        index  index.php index.html index.htm;
		rewrite ^([^\.]*)/forum-(\w+)-([0-9]+)\.html$ $1/forum.php?mod=forumdisplay&fid=$2&page=$3 last;
        rewrite ^([^\.]*)/thread-([0-9]+)-([0-9]+)-([0-9]+)\.html$ $1/forum.php?mod=viewthread&tid=$2&extra=page%3D$4&page=$3 last;
        if (!-e $request_filename) {
            return 404;
            }
    }
	location ~.*\.(php|php5)?$ {
    fastcgi_pass 127.0.0.1:9000;
    fastcgi_index index.php;
    include fastcgi.conf;
    }
    access_log logs/access_bbs.log;
}
EOF

#php conf
##php.ini
cp /application/tools/php-5.5.32/php.ini-production /application/php/lib/php.ini

##php-fpm
cp /application/php/etc/php-fpm.conf.default /application/php/etc/php-fpm.conf


#memacache install
cd /application/tools
wget http://pecl.php.net/get/memcache-3.0.8.tgz
tar xf memcache-3.0.8.tgz
cd memcache-3.0.8
/application/php/bin/phpize
./configure --enable-memcached --with-php-config=/application/php/bin/php-config
make
make install
cat >>/application/php/lib/php.ini<<"EOF"
[memcached]
/application/php/lib/php/extensions/no-debug-non-zts-20121212/
extension = memcache.so
EOF
sed -i 's#session.save_handler = files#session.save_handler = memcache#g' /application/php/lib/php.ini
sed -ri '1359i session.save_path = "tcp://172.16.1.5:11211?persistent=1&weight=1&timeout=1&retry_interval=15"' /application/php/lib/php.ini


#start nginx php-fpm
/application/nginx/sbin/nginx -t
/application/nginx/sbin/nginx
/application/php/sbin/php-fpm
echo -e '\n' >>/etc/rc.local
echo "nginx start by $cp_name" >>/etc/rc.local
echo "/application/nginx/sbin/nginx" >>/etc/rc.local
echo "/application/php/sbin/php-fpm" >>/etc/rc.local

#install wordpress bbs
cd /application/tools
wget https://cn.wordpress.org/wordpress-4.2.2-zh_CN.tar.gz
tar xf wordpress-4.2.2-zh_CN.tar.gz
mv wordpress/* /application/nginx/html/blog/
chown -R root:root /application/nginx/html/blog/
find /application/nginx/html/blog/ -type f |xargs chmod 644
find /application/nginx/html/blog/ -type d |xargs chmod 755
mkdir /application/nginx/html/blog/wp-content/uploads -p
chown -R nginx.nginx /application/nginx/html/blog/wp-content/uploads/
mount -t nfs 172.16.1.3:/data/data0 /application/nginx/html/blog/wp-content/uploads/
echo -e '\n' >>/etc/rc.local
echo "mount nfs start by $cp_name" >>/etc/rc.local
echo "mount -t nfs 172.16.1.3:/data/data0 /application/nginx/html/blog/wp-content/uploads/" >>/etc/rc.local

#install bbs
cd /application/tools
wget http://download.comsenz.com/DiscuzX/3.2/Discuz_X3.2_SC_UTF8.zip
unzip Discuz_X3.2_SC_UTF8.zip
mv upload/* /application/nginx/html/bbs/
chown -R nginx.nginx /application/nginx/html/bbs/
#chown -R root:root /application/nginx/html/bbs/
#find /application/nginx/html/bbs/ -type f |xargs chmod 644
#find /application/nginx/html/bbs/ -type d |xargs chmod 755
mount -t nfs 172.16.1.3:/data/data1 /application/nginx/html/bbs/data/attachment/
echo -e '\n' >>/etc/rc.local
echo "mount nfs start by $cp_name" >>/etc/rc.local
echo "mount -t nfs 172.16.1.3:/data/data1 /application/nginx/html/bbs/data/attachment/" >>/etc/rc.local
##最后修改bbs/config/config.global.php开启memcache模块，指定memcahe的server地址

#install www:CMS
cd /application/tools
wget http://updatenew.dedecms.com/base-v57/package/DedeCMS-V5.7-UTF8-SP2.tar.gz
tar xf DedeCMS-V5.7-UTF8-SP2.tar.gz
mv DedeCMS-V5.7-UTF8-SP2/uploads/* /application/nginx/html/www/
chown nginx.nginx /application/nginx/html/www -R

#install phpmyadmin
wget https://files.phpmyadmin.net/phpMyAdmin/4.0.10.20/phpMyAdmin-4.0.10.20-all-languages.zip
unzip phpMyAdmin-4.0.10.20-all-languages.zip
mv phpMyAdmin-4.7.2-all-languages /application/nginx/html/www/phpmyadmin
cp /application/nginx/html/www/phpmyadmin/config.sample.inc.php /application/nginx/html/www/phpmyadmin/config.inc.php
sed -i 's#localhost#db.etiantian.org#g' /application/nginx/html/www/phpmyadmin/config.inc.php
chown nginx.nginx /application/nginx/html/www/phpmyadmin -R


#conf end