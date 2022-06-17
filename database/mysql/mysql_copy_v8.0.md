```shell
# 主库配置
docker create network mysql_copy
docker run -d --network=mysql_copy --name=mysql-master -e MYSQL_ROOT_PASSWORD=123456 -e TZ=Asia/Shanghai -p 3306:3306 -v /data/mysql_data/mysql:/var/lib/mysql/ -v /data/mysql_conf/mysql:/etc/mysql/ mysql:latest

mysql -uroot -h 172.16.105.160 -p

# 创建用于主从复制得用户
mysql> create user 'rep'@'172.16.105.%' identified with mysql_native_password by '123456';

# 授权
mysql> grant replication slave on *.* to 'rep'@'172.16.105.%';

# 确认使用mysql_native_password加密
mysql> select user,host,plugin,authentication_string from mysql.user \G

mysql> flush privileges;

# 查看主库当前数据记录
mysql> show master status;
```

```shell
# 从库配置
docker run -d --network=mysql_copy --name=mysql-slave -e MYSQL_ROOT_PASSWORD=123456 -e TZ=Asia/Shanghai -p 3306:3306 -v /data/mysql_data/mysql:/var/lib/mysql/ -v /data/mysql_conf/mysql:/etc/mysql/ mysql:latest

vi /data/mysql_data/mysql/auto.cnf
## 修改uuid号，与主库不同即可

vi /data/mysql_conf/mysql/my.cnf
## 修改server_id = 2

mysql -uroot -h 172.16.105.161 -p

# 导入主库信息
mysql> change master to  master_host='172.16.105.160',master_user='rep',master_password='123456',master_log_file='mysql-bin.000001',master_log_pos=838;

# 开启主从复制
mysql> start slave;

# 查看复制状态
mysql> show slave status \G
```

