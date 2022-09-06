# mysql

## centos7

```bash
# yum部署
$ sudo cat >> /etc/yum.repos.d/mysql-community.repo <<EOF
[mysql-connectors-community]
name=MySQL Connectors Community
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql-connectors-community-el7-$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.mysql.com/RPM-GPG-KEY-mysql

[mysql-tools-community]
name=MySQL Tools Community
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql-tools-community-el7-$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.mysql.com/RPM-GPG-KEY-mysql

[mysql-5.6-community]
name=MySQL 5.6 Community Server
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql-5.6-community-el7-$basearch/
enabled=0
gpgcheck=1
gpgkey=https://repo.mysql.com/RPM-GPG-KEY-mysql

[mysql-5.7-community]
name=MySQL 5.7 Community Server
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql-5.7-community-el7-$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.mysql.com/RPM-GPG-KEY-mysql

[mysql-8.0-community]
name=MySQL 8.0 Community Server
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql-8.0-community-el7-$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.mysql.com/RPM-GPG-KEY-mysql
EOF

$ sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022      # 如果安装failing,请执行命令
$ sudo yum install mysql-community-server

# 获取初始化密码
$ sudo cat /var/log/mysqld.log
...root@localhost: y,g:Myabt5:>      # 密码

# 首次修改密码
alter user 'root'@'localhost' identified by 'Cgls@123';

# 再次修改密码
use mysql
#update user set authentication_string='' where user='root';             # 密码置空
update user set plugin='mysql_native_password' where user='root';       # 修改密码认证方式
flush privileges;
select user,host from mysql.user;
update user set Host='%' where User='root';
flush privileges;
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'Cgsl@123';

# 设置密码强度
SHOW VARIABLES LIKE 'validate_password%';
set global validate_password.policy=LOW;
set global validate_password.length=6;
flush privileges;
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '123456';
```