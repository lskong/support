#！/bin/sh
. /etc/init.d/functions

#custom variable
cp_name=$(whoami)_$(date +%F)
ip_lan=`ifconfig eth1|awk -F '[ :]+' 'NR==2 {print $4}'`

#host name
hostname mysql01
sed -i 's/HOSTNAME=CentOS610/HOSTNAME=mysql01/g' /etc/sysconfig/network

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
/bin/tar -zcf $path/conf_$date.tar.gz /etc/rc.d/rc.local /var/spool/cron/root /server/scripts

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

#install mysql 
##user add
useradd -s /sbin/nologin -M mysql

##mysql download Binary package
cd /application/tools
wget http://mirrors.ustc.edu.cn/mysql-ftp/Downloads/MySQL-5.5/mysql-5.5.62-linux-glibc2.12-x86_64.tar.gz

##tar mysql
tar xf mysql-5.5.62-linux-glibc2.12-x86_64.tar.gz

##install mysql
mv mysql-5.5.62-linux-glibc2.12-x86_64 /application/mysql-5.5.62
ln -s /application/mysql-5.5.62 /application/mysql

##initialize mysql
/application/mysql/scripts/mysql_install_db --basedir=/application/mysql --datadir=/application/mysql/data --user=mysql
chown -R mysql:mysql /application/mysql/
cp /application/mysql/support-files/my-small.cnf /etc/my.cnf
sed -i 's#usr/local/mysql#/application/mysql#g' /application/mysql/bin/mysqld_safe
cp /application/mysql/support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
sed -i 's#/usr/local/mysql#/application/mysql#g' /etc/init.d/mysqld

##mysql commond
export PATH="/application/mysql/bin:$PATH"
echo 'PATH="/application/mysql/bin:$PATH"' >>/etc/profile
source /etc/profile

##start mysql
/etc/init.d/mysqld start
echo -e '\n' >>/etc/rc.local
echo "mysql start by $cp_name" >>/etc/rc.local
echo "/etc/init.d/mysqld start" >>/etc/rc.local

##set mysql password
mysqladmin -uroot password "123456"

##initialize mysql
mysql -uroot -p123456 <<EOF
drop database test;
drop user ''@'mysql01';
drop user 'root'@'mysql01';
drop user ''@'localhost';
drop user 'root'@'::1';
create database wordpress;
create database www;
create database bbs;
grant all on wordpress.* to 'wordpress'@'172.16.1.%' identified by '123456';
grant all on www.* to 'www'@'172.16.1.%' identified by '123456';
grant all on bbs.* to 'bbs'@'172.16.1.%' identified by '123456';
grant all on *.* to 'admin'@'172.16.1.%' identified by '123456' with grant option;
flush privileges;
exit
EOF

##backup mysql
cat >>/server/scripts/backup_mysql.sh<<"EOF"
#!/bin/sh
path="/backup/mysql"
date=$(date +%F)
flag="flag_md5_$date"
[ ! -d $path ] && mkdir $path -p

mysqldump -uroot -p123456 -B -x mysql|gzip>$path/back_mysql_$date.sql.gz
mysqldump -uroot -p123456 -B -x www|gzip>$path/back_www_$date.sql.gz
mysqldump -uroot -p123456 -B -x bbs|gzip>$path/back_bbs_$date.sql.gz
mysqldump -uroot -p123456 -B -x wordpress|gzip>$path/back_wordpress_$date.sql.gz

/bin/find $path -type f -name "*$date.sql.gz"|/usr/bin/xargs /usr/bin/md5sum >$path/$flag
rsync -az /backup/mysql rsync_backup@172.16.1.2::backup/ --password-file=/etc/rsync.password
/bin/find /backup/mysql -type f -name "*.sql.gz" -mtime +7|/usr/bin/xargs /bin/rm -f
/bin/find /backup/mysql -type f -name "flag_md5_*" -mtime +7|/usr/bin/xargs /bin/rm -f
EOF
sh /server/scripts/backup_mysql.sh

##add cron
echo -e '\n' >>/var/spool/cron/root
echo "####add mysql_backup by $cp_name" >>/var/spool/cron/root
echo "00 04 * * * /bin/sh /server/scripts/backup_mysql.sh >/dev/null 2>1&" >>/var/spool/cron/root

#conf end