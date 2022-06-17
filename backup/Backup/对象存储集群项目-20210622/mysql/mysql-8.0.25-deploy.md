# MySQL-deploy

## MySQL deploy for ubuntu20.04

- 安装mysql

```shell
apt install mysql-server mysql-client mysql-common
```

- 配置data路径

```shell
vim /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
 datadir        = /nvmedata/mysql

cp -r /var/lib/mysql /nvmedata/
chown -R mysql.mysql /nvmedata/mysql


vim /etc/apparmor.d/usr.sbin.mysqld
# Allow data dir access
  /nvmedata/mysql/ r,
  /nvmedata/mysql/** rwk,

systemctl restart apparmor.service 
systemctl daemon-reload 
systemctl restart mysql.service
```

- 修改远程登录
```shelll
# 修改监听地址
vim /etc/mysql/mysql.conf.d/mysqld.cnf
 bind-address            = 0.0.0.0

# 登录MySQL修改
use mysql
select host,user from user;
update user set host='%' where user='root';
alter user 'root'@'%' identified with mysql_native_password by '123456';
flush privileges;
```

## performance_schema

> 参考文档：https://blog.csdn.net/n88Lpo/article/details/80331752


- 检查当前数据库版本是否支持
```sql
# 命令一
SELECT * FROM INFORMATION_SCHEMA.ENGINES WHERE ENGINE ='PERFORMANCE_SCHEMA';

# 命令二
show engines;

# support显示yes，标识支持
mysql> SELECT * FROM INFORMATION_SCHEMA.ENGINES WHERE ENGINE ='PERFORMANCE_SCHEMA';
+--------------------+---------+--------------------+--------------+------+------------+
| ENGINE             | SUPPORT | COMMENT            | TRANSACTIONS | XA   | SAVEPOINTS |
+--------------------+---------+--------------------+--------------+------+------------+
| PERFORMANCE_SCHEMA | YES     | Performance Schema | NO           | NO   | NO         |
+--------------------+---------+--------------------+--------------+------+------------+

mysql> show engines;
+--------------------+---------+----------------------------------------------------------------+--------------+------+------------+
| Engine             | Support | Comment                                                        | Transactions | XA   | Savepoints |
+--------------------+---------+----------------------------------------------------------------+--------------+------+------------+
| ARCHIVE            | YES     | Archive storage engine                                         | NO           | NO   | NO         |
| BLACKHOLE          | YES     | /dev/null storage engine (anything you write to it disappears) | NO           | NO   | NO         |
| MRG_MYISAM         | YES     | Collection of identical MyISAM tables                          | NO           | NO   | NO         |
| FEDERATED          | NO      | Federated MySQL storage engine                                 | NULL         | NULL | NULL       |
| MyISAM             | YES     | MyISAM storage engine                                          | NO           | NO   | NO         |
| PERFORMANCE_SCHEMA | YES     | Performance Schema                                             | NO           | NO   | NO         |
| InnoDB             | DEFAULT | Supports transactions, row-level locking, and foreign keys     | YES          | YES  | YES        |
| MEMORY             | YES     | Hash based, stored in memory, useful for temporary tables      | NO           | NO   | NO         |
| CSV                | YES     | CSV storage engine                                             | NO           | NO   | NO         |
+--------------------+---------+----------------------------------------------------------------+--------------+------+------------+
```

- 启用performance_schema
```shell
# 配置参数
performance_schema = ON


# 配置文件目录
vim /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
performance_schema = ON

# 重启MySQL
systemctl restart mysql.service

# 验证
mysql> SHOW VARIABLES LIKE 'performance_schema';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| performance_schema | ON    |
+--------------------+-------+
```

SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES \
WHERE TABLE_SCHEMA ='performance_schema' and engine='performance_schema';