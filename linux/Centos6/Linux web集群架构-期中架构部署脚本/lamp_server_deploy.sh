#！/bin/sh
. /etc/init.d/functions

#custom variable
cp_name=$(whoami)_$(date +%F)
ip_lan=`ifconfig eth1|awk -F '[ :]+' 'NR==2 {print $4}'`

#host name
hostname lamp01
sed -i 's/HOSTNAME=CentOS610/HOSTNAME=lamp01/g' /etc/sysconfig/network
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

#add user
useradd -s /sbin/nologin -M www

#apache install
cd /application/tools
yum -y install zlib-devel
wget http://archive.apache.org/dist/httpd/httpd-2.2.27.tar.gz
tar xf httpd-2.2.27.tar.gz
cd httpd-2.2.27
./configure --prefix=/application/apache-2.2.27 --enable-deflate --enable-expires --enable-headers --enable-modules=most --enable-so --with-mpm=worker --enable-rewrite=shared
make && make install
ln -s /application/apache-2.2.27 /application/apache

#php install
cd /application/tools
yum install -y zlib-devel libxml2-devel libjpeg-turbo-devel libiconv-devel freetype-devel libpng-devel gd-devel libcurl-devel libxslt-devel libmcrypt-devel mhash mhash-devel mcrypt libtool-ltdl libtool-ltdl-devel openssl-devel
wget https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
tar xf libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=/usr/local/libiconv
make && make install

wget http://mirrors.sohu.com/php/php-5.5.32.tar.gz
tar xf php-5.5.32.tar.gz
cd php-5.5.32
./configure \
--prefix=/application/php-5.5.32 \
--with-mysql=mysqlnd \
--with-apxs2=/application/apache/bin/apxs \
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

#conf apache
mv /application/apache/conf/httpd.conf /application/apache/conf/httpd.conf.default
cat >>/application/apache/conf/httpd.conf<<"EOF"
ServerRoot "/application/apache-2.2.27"
Listen 80
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule php5_module        modules/libphp5.so
<IfModule !mpm_netware_module>
<IfModule !mpm_winnt_module>
User www
Group www
</IfModule>
</IfModule>
ServerAdmin rockchou@foxmail.com
ServerName 127.0.0.1:80
DocumentRoot "/application/apache-2.2.27/htdocs"
<Directory />
    Options FollowSymLinks
    AllowOverride None
    Order deny,allow
    Deny from all
</Directory>
<Directory "/application/apache-2.2.27/htdocs">
    Options Indexes FollowSymLinks
    AllowOverride None
    Order allow,deny
    Allow from all
</Directory>
<IfModule dir_module>
    DirectoryIndex index.php index.html
</IfModule>
<FilesMatch "^\.ht">
    Order allow,deny
    Deny from all
    Satisfy All
</FilesMatch>
ErrorLog "logs/error_log"
LogLevel warn
<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common
    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>
    CustomLog "logs/access_log" common
</IfModule>
<IfModule alias_module>
    ScriptAlias /cgi-bin/ "/application/apache-2.2.27/cgi-bin/"
</IfModule>
<IfModule cgid_module>
</IfModule>
<Directory "/application/apache-2.2.27/cgi-bin">
    AllowOverride None
    Options None
    Order allow,deny
    Allow from all
</Directory>
DefaultType text/plain
<IfModule mime_module>
    TypesConfig conf/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
    AddType application/x-httpd-php .php .phtml
    AddType application/x-httpd-php-source .phps
</IfModule>
<IfModule ssl_module>
SSLRandomSeed startup builtin
SSLRandomSeed connect builtin
</IfModule>
Include conf/extra/httpd-vhosts.conf
Include conf/extra/httpd-mpm.conf
<Directory "/var/html">
    Options Indexes FollowSymLinks
    AllowOverride None
    Order allow,deny
    Allow from all
</Directory>
EOF

##conf apache vhosts
mkdir /var/html/{www,blog,bbs} -p
mv /application/apache/conf/extra/httpd-vhosts.conf /application/apache/conf/extra/httpd-vhosts.conf.default
cat >>/application/apache/conf/extra/httpd-vhosts.conf<<"EOF"
NameVirtualHost *:80
<VirtualHost *:80>
    ServerAdmin rockchou@foxmail.com
    DocumentRoot "/var/html/www"
    ServerName www.etiantian.org
    ServerAlias etiantian.org
    ErrorLog "logs/www-error_log"
    CustomLog "logs/www-access_log" common
</VirtualHost>

<VirtualHost *:80>
    ServerAdmin rockchou@foxmail.com
    DocumentRoot "/var/html/bbs"
    ServerName bbs.etiantian.org
    ErrorLog "logs/bbs-error_log"
    CustomLog "logs/bbs-access_log" common
</VirtualHost>

<VirtualHost *:80>
    ServerAdmin rockchou@foxmail.com
    DocumentRoot "/var/html/blog"
    ServerName blog.etiantian.org
    ErrorLog "logs/blog-error_log"
    CustomLog "logs/blog-access_log" common
</VirtualHost>
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

#start apache
/application/apache/bin/apachectl start
echo -e '\n' >>/etc/rc.local
echo "apache start by $cp_name" >>/etc/rc.local
echo "/application/apache/bin/apachectl start" >>/etc/rc.local

#mount 
mount -t nfs 172.16.1.3:/data/data0 /var/html/blog/wp-content/uploads/
mount -t nfs 172.16.1.3:/data/data1 /var/html/bbs/data/attachment

#END