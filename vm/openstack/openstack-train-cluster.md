---
id: openstack
title: OpenStack高可用集群部署方案(train版)
---

- [1.架构环境](#1架构环境)
  - [1.1节点信息](#11节点信息)
  - [1.2操作系统](#12操作系统)
  - [1.3节点规划](#13节点规划)
- [2.集群高可用](#2集群高可用)
  - [2.1参考文档](#21参考文档)
  - [2.2无状态服务](#22无状态服务)
  - [2.3有状态服务](#23有状态服务)
  - [2.4高可用方案](#24高可用方案)
    - [2.4.1控制节点方案](#241控制节点方案)
    - [2.4.2数据库方案](#242数据库方案)
    - [2.4.3RabbitMQ集群](#243rabbitmq集群)
- [3.基础配置](#3基础配置)
  - [3.1Host主机配置](#31host主机配置)
  - [3.2SSH免密配置](#32ssh免密配置)
  - [3.3时间同步](#33时间同步)
  - [3.4内核、selinux、iptables](#34内核selinuxiptables)
  - [3.5下载软件包](#35下载软件包)
- [4.Mariadb集群(控制节点)](#4mariadb集群控制节点)
  - [4.1安装与配置](#41安装与配置)
  - [4.2构建集群](#42构建集群)
  - [4.3设置心跳检测clustercheck](#43设置心跳检测clustercheck)
  - [4.4异常关机或异常断电后的修复](#44异常关机或异常断电后的修复)
- [5.RabbitMQ集群(控制节点)](#5rabbitmq集群控制节点)
  - [5.1下载相关软件包(所有节点)](#51下载相关软件包所有节点)
  - [5.2构建rabbitmq集群](#52构建rabbitmq集群)
- [6.Memcached和Etcd集群(控制节点)](#6memcached和etcd集群控制节点)
  - [6.1安装memcache的软件包](#61安装memcache的软件包)
  - [6.2安装etcd的软件包](#62安装etcd的软件包)
- [7.配置Pacemaker高可用集群](#7配置pacemaker高可用集群)
  - [7.1安装相关软件](#71安装相关软件)
  - [7.2构建集群](#72构建集群)
  - [7.3配置VIP](#73配置vip)
  - [7.4高可用性管理](#74高可用性管理)
- [8.部署Haproxy](#8部署haproxy)
  - [8.1安装haproxy(控制节点)](#81安装haproxy控制节点)
  - [8.2 配置haproxy.cfg](#82-配置haproxycfg)
  - [8.3配置内核参数](#83配置内核参数)
  - [8.4启动服务](#84启动服务)
  - [8.5访问haproxy web](#85访问haproxy-web)
  - [8.6设置pcs资源](#86设置pcs资源)
- [9.Keystone集群部署](#9keystone集群部署)
  - [9.1配置keystone数据库](#91配置keystone数据库)
  - [9.2安装keystone](#92安装keystone)
  - [9.3配置Keystone配置文件](#93配置keystone配置文件)
  - [9.4同步keystone数据库](#94同步keystone数据库)
  - [9.5认证引导](#95认证引导)
  - [9.6设置pcs资源](#96设置pcs资源)
- [10.Glance集群部署](#10glance集群部署)
  - [10.1创建glance数据库](#101创建glance数据库)
  - [10.2创建glance-api相关服务凭证](#102创建glance-api相关服务凭证)
  - [10.3部署与配置glance](#103部署与配置glance)
- [11.Placement放置服务部署](#11placement放置服务部署)
  - [11.1配置Placement数据库](#111配置placement数据库)
  - [11.2创建placement-api](#112创建placement-api)
  - [11.3安装placement软件包](#113安装placement软件包)
  - [11.4配置00-placement-api.conf](#114配置00-placement-apiconf)
  - [11.5验证检查Placement健康状态](#115验证检查placement健康状态)
  - [11.6设置pcs资源](#116设置pcs资源)
- [12.Nova控制节点集群部署](#12nova控制节点集群部署)
  - [12.1创建nova相关数据库](#121创建nova相关数据库)
  - [12.2创建nova相关服务凭证](#122创建nova相关服务凭证)
  - [12.3安装nova软件包](#123安装nova软件包)
  - [12.4部署与配置](#124部署与配置)
  - [12.5同步nova相关数据库并验证](#125同步nova相关数据库并验证)
  - [12.6启动nova服务，并配置开机启动](#126启动nova服务并配置开机启动)
  - [12.7验证](#127验证)
  - [12.8设置pcs资源](#128设置pcs资源)
- [13.Nova计算节点集群部署](#13nova计算节点集群部署)
  - [13.1安装nova-compute](#131安装nova-compute)
  - [13.2部署与配置](#132部署与配置)
  - [13.3启动计算节点的nova服务](#133启动计算节点的nova服务)
  - [13.4向cell数据库添加计算节点](#134向cell数据库添加计算节点)
  - [13.5控制节点上发现计算主机](#135控制节点上发现计算主机)
  - [13.6验证](#136验证)
- [14.Neutron控制节点集群部署](#14neutron控制节点集群部署)
  - [14.1创建nova相关数据库（控制节点）](#141创建nova相关数据库控制节点)
  - [14.2创建neutron相关服务凭证(控制节点)](#142创建neutron相关服务凭证控制节点)
  - [14.3安装Neutron server（控制节点)](#143安装neutron-server控制节点)
  - [14.4部署与配置（控制节点)](#144部署与配置控制节点)
- [15.Neutron计算节点集群部署](#15neutron计算节点集群部署)
  - [15.1安装Neutron agent（计算节点=网络节点)](#151安装neutron-agent计算节点网络节点)
  - [15.2部署与配置(计算节点)](#152部署与配置计算节点)
  - [15.3neutron服务验证（控制节点）](#153neutron服务验证控制节点)
  - [15.4添加pcs资源](#154添加pcs资源)
- [16.Horazion仪表盘集群部署](#16horazion仪表盘集群部署)
  - [16.1安装dashboard](#161安装dashboard)
  - [16.2配置local_settings](#162配置local_settings)
  - [16.3配置openstack-dashboard.conf](#163配置openstack-dashboardconf)
  - [16.4重启apache和memcache](#164重启apache和memcache)
  - [16.5验证访问](#165验证访问)
  - [16.6创建虚拟网络并启动实例操作](#166创建虚拟网络并启动实例操作)
- [17.OpenStack高可用集群部署方案(train版)—Cinder](#17openstack高可用集群部署方案train版cinder)



# 1.架构环境

参考资源：https://www.jianshu.com/p/f61deadfab4d


## 1.1节点信息

```conf
management ip   hostname       device        external network
--------------- -------------- ------------- --------------------
172.16.181.31   controller01   c8m8h220      10.181.0.31
172.16.181.32   controller02   c8m8h220      10.181.0.32
172.16.181.33   controller02   c8m8h220      10.181.0.33
172.16.181.34   compute01      c8m8h220      10.181.0.34
172.16.181.35   compute02      c8m8h220      10.181.0.35
172.16.181.36   compute03      c8m8h220      10.181.0.36
172.16.181.21   storage01      c8m8h220      10.181.0.21
172.16.181.22   storage02      c8m8h220      10.181.0.22
172.16.181.23   storage03      c8m8h220      10.181.0.23

VIP:172.16.181.30
```

## 1.2操作系统

```bash
[root@controller01 ~]# cat /etc/redhat-release 
CentOS Linux release 7.6.1810 (Core) 
[root@controller01 ~]# uname -r
3.10.0-957.el7.x86_64

[root@compute01 ~]# cat /etc/redhat-release 
CentOS Linux release 7.6.1810 (Core) 
[root@compute01 ~]# uname -r
3.10.0-957.el7.x86_64
```

## 1.3节点规划

openstack高可用环境测试需要9台虚拟机，控制、计算、网络、存储、ceph共享存储集群共9台，后续资源充足可以将网络节点和存储节点进行分离，单独准备节点部署。

因控制节点需要运行服务较多，所以选择内存较大的虚拟机，生产中，建议将大磁盘挂载到ceph存储上

```conf
controller：
1. keystone
2. glance-api , glance-registry
3. nova-api, nova-conductor, nova-consoleauth, nova-scheduler, nova-novncproxy
4. neutron-api, neutron-linuxbridge-agent, neutron-dhcp-agent, neutron-metadata-agent, neutron-l3-agent
5. cinder-api, cinder-schedulera
6. dashboard
7. mariadb, rabbitmq, memcached,Haproxy
# 1.控制节点: keystone, glance, horizon, nova&neutron管理组件；
# 2.网络节点：虚机网络，L2/L3，dhcp，route，nat等；2核 32线程1.2T硬盘
# 3.存储节点：调度，监控(ceph)等组件；2核 32线程1.2T硬盘
# 4.openstack基础服务


compute:
1. nova-compute
2. neutron-linuxbridge-agent
3. cinder-volume(如果后端使用共享存储，建议部署在controller节点)
# 1.计算节点：hypervisor(kvm)；
# 2.网络节点：虚机网络等；
# 3.存储节点：卷服务等组件

storage:
ceph-mon, ceph-mgr, ceph-osd
ceph-mon, ceph-mgr, ceph-osd
ceph-mon, ceph-mgr, ceph-osd

HA vip:
172.16.181.30
```

# 2.集群高可用

## 2.1参考文档

1.高可用：https://docs.openstack.org/ha-guide/
2.控制平台设计架构：https://docs.openstack.org/arch-design/design-control-plane.html
3.OpenStack体系结构设计指南: https://docs.openstack.org/arch-design/
4.OpenStack存储:https://docs.openstack.org/ha-guide/storage-ha.html

## 2.2无状态服务

可在提出请求后提供响应，然后无需进一步关注。为了使无状态服务高度可用，需要提供冗余节点并对其进行负载。

包括nova-api， nova-conductor，glance-api，keystone-api，neutron-api，nova-scheduler。

## 2.3有状态服务

对服务的后续请求取决于第一个请求的结果。有状态服务更难管理，因为单个动作通常涉及多个请求。使状态服务高度可用可能取决于您选择主动/被动配置还是主动/主动配置。包括OpenStack的数据库和消息队列。

## 2.4高可用方案

### 2.4.1控制节点方案
1.三台 Controller 节点分别部署OpenStack服务，共享数据库和消息队列，由haproxy负载均衡请求到后端处理。
2.前端代理可以采用Haproxy + KeepAlived或者Haproxy + pacemaker方式，OpenStack控制节点各服务，对外暴露VIP提供API访问。建议将Haproxy单独部署
3.Openstack官网使用开源的pacemaker cluster stack做为集群高可用资源管理软件

### 2.4.2数据库方案
1.采用MariaDB + Galera组成三个Active节点，外部访问通过Haproxy的active + backend方式代理。平时主库为A，当A出现故障，则切换到B或C节点。目前测试将MariaDB三个节点部署到了控制节点上。
2.三个节点的MariaDB和Galera集群，建议每个集群具有4个vCPU和8 GB RAM

### 2.4.3RabbitMQ集群

RabbitMQ采用原生Cluster集群，所有节点同步镜像队列。三台物理机，其中2个Mem节点主要提供服务，1个Disk节点用于持久化消息，客户端根据需求分别配置主从策略。



# 3.基础配置

## 3.1Host主机配置

```bash
cat >>/etc/hosts <<EOF
172.16.181.31  controller01
172.16.181.32  controller02
172.16.181.33  controller03
172.16.181.34  compute01
172.16.181.35  compute02
172.16.181.36  compute03
172.16.181.21  storage01
172.16.181.22  storage02
172.16.181.23  storage03
EOF
```

## 3.2SSH免密配置

```bash
$ ssh-keygen
$ ssh-copy-id controller02
$ ssh controller02 hostname
```

## 3.3时间同步

```bash
# 所有节点安装，controller01可作为server
$ yum install chrony -y

$ vim /etc/chrony.conf 
server 172.16.254.1 iburst

$ systemctl restart chronyd.service 
$ systemctl enable chronyd.service 
$ chronyc sources
```


## 3.4内核、selinux、iptables

```bash
#内核参数优化
echo 'net.ipv4.ip_forward = 1' >>/etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-iptables=1' >>/etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables=1'  >>/etc/sysctl.conf

#在控制节点上添加，允许非本地IP绑定，允许运行中的HAProxy实例绑定到VIP
echo 'net.ipv4.ip_nonlocal_bind = 1' >>/etc/sysctl.conf

sysctl -p

#关闭selinux
setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config

#关闭firewalld
systemctl disable firewalld.service
systemctl stop firewalld.service 
```

## 3.5下载软件包

```bash
yum install centos-release-openstack-train -y
yum install yum-utils -y 

# 安装客户端
yum install python-openstackclient -y

# openstack-utils能够让openstack安装更加简单
yum install -y openstack-utils

# 添加epel源
yum install epel-release
sed -e 's!^metalink=!#metalink=!g' \
    -e 's!^#baseurl=!baseurl=!g' \
    -e 's!//download\.fedoraproject\.org/pub!//mirrors.tuna.tsinghua.edu.cn!g' \
    -e 's!//download\.example/pub!//mirrors.tuna.tsinghua.edu.cn!g' \
    -e 's!http://mirrors!https://mirrors!g' \
    -i /etc/yum.repos.d/epel*.repo
    
```


# 4.Mariadb集群(控制节点)

## 4.1安装与配置

1.所有controller节点安装

```bash
yum install mariadb mariadb-server python2-PyMySQL -y
```

2.安装galera相关插件，利用galera搭建集群

```bash
yum install mariadb-server-galera mariadb-galera-common galera xinetd rsync -y
systemctl restart mariadb.service
systemctl enable mariadb.service
```

3.初始化mariadb，在全部控制节点初始化数据库密码

```bash
[root@controller01 ~]# mysql_secure_installation
#输入root用户的当前密码（不输入密码）
Enter current password for root (enter for none): 
#设置root密码？
Set root password? [Y/n] y
#新密码：
New password: 
#重新输入新的密码：
Re-enter new password: 
#删除匿名用户？
Remove anonymous users? [Y/n] y
#禁止远程root登录？
Disallow root login remotely? [Y/n] n
#删除测试数据库并访问它？
Remove test database and access to it? [Y/n] y
#现在重新加载特权表？
Reload privilege tables now? [Y/n] y 
```

3.修改mariadb配置文件

在全部控制节点/etc/my.cnf.d/目录下新增openstack.cnf配置文件，主要设置集群同步相关参数，以controller01节点为例，个别涉及ip地址/host名等参数根据当前节点实际情况修改

创建和编辑/etc/my.cnf.d/openstack.cnf文件

```conf
[server]

[mysqld]
bind-address = 172.16.181.31
max_connections = 1000
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-error=/var/log/mariadb/mariadb.log
pid-file=/run/mariadb/mariadb.pid


[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_name="mariadb_galera_cluster"

wsrep_cluster_address="gcomm://controller01,controller02,controller03"
wsrep_node_name="controller01"
wsrep_node_address="172.16.181.31"

binlog_format=ROW
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
wsrep_slave_threads=4
innodb_flush_log_at_trx_commit=2
innodb_buffer_pool_size=1024M
wsrep_sst_method=rsync

[embedded]

[mariadb]

[mariadb-10.3]
```

> wsrep_sync_wait：默认值是0，如果需要保证读写一致性可以设置为1。但是需要注意的是，该设置会带来相应的延迟性


## 4.2构建集群

1.停止所有controller节点mariadb服务

```bash
systemctl stop mariadb
```

2.在controller01节点通过如下方式启动mariadb服务

```bash
/usr/libexec/mysqld --wsrep-new-cluster --user=root &

[1] 20660
[root@controller01 ~]# 2022-09-21 20:48:36 0 [Note] /usr/libexec/mysqld (mysqld 10.3.20-MariaDB) starting as process 20660 ...

```

3.其他控制节点加入mariadb集群

以controller02节点为例；启动后加入集群，controller02节点从controller01节点同步数据，也可同步查看mariadb日志/var/log/mariadb/mariadb.log

```bash
# controller02 and controller03 启动mariadb自动加入集群
systemctl start mariadb.service
```

4.回到controller01节点重新配置mariadb

```bash
#重启controller01节点；并在启动前删除contrller01节点之前的数据 
pkill -9 mysqld
rm -rf /var/lib/mysql/*

#注意以system unit方式启动mariadb服务时的权限
chown mysql:mysql /var/run/mariadb/mariadb.pid

## 启动后查看节点所在服务状态，controller01节点从controller02节点同步数据
systemctl start mariadb.service
systemctl status mariadb.service
```

5.查看集群状态

```sql
MariaDB [(none)]> show status like "wsrep_cluster_size";
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+

MariaDB [(none)]> show status LIKE 'wsrep_ready';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| wsrep_ready   | ON    |
+---------------+-------+
```

6.在controller01创建数据库，到另外两台节点上查看是否可以同步

```sql
# controller01
MariaDB [(none)]> create database cluster_test charset utf8mb4;
Query OK, 1 row affected (0.150 sec)

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| cluster_test       |
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
4 rows in set (0.001 sec)


[root@controller02 ~]# mysql -uroot -p123456 -e 'show databases'
+--------------------+
| Database           |
+--------------------+
| cluster_test       |
| information_schema |
| mysql              |
| performance_schema |
+--------------------+


[root@controller03 ~]# mysql -uroot -p123456 -e 'show databases'
+--------------------+
| Database           |
+--------------------+
| cluster_test       |
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
```

## 4.3设置心跳检测clustercheck

1.下载clustercheck脚本

```bash
# 在全部控制节点下载修改此脚本
$ mkdir -p /opt/clustercheck/
$ wget -P /opt/clustercheck/ https://raw.githubusercontent.com/olafz/percona-clustercheck/master/clustercheck

# 注意账号/密码与脚本中的账号/密码对应，这里用的是脚本默认的账号/密码，否则需要修改clustercheck脚本
$ vim /opt/clustercheck/clustercheck
MYSQL_USERNAME="${MYSQL_USERNAME:=clustercheckuser}"
MYSQL_PASSWORD="${MYSQL_PASSWORD-clustercheckpassword!}"
...

#添加执行权限并复制到/usr/bin/下
$ chmod +x /opt/clustercheck/clustercheck
$ ln -s /opt/clustercheck/clustercheck /usr/local/bin/clustercheck
```

2.创建心跳检测用户(创建一次即可)

```sql
GRANT PROCESS ON *.* TO 'clustercheckuser'@'localhost' IDENTIFIED BY 'clustercheckpassword!';
flush privileges;
```

3.创建心跳检测文件

在全部控制节点新增心跳检测服务配置文件/etc/xinetd.d/mysqlchk

```bash
$ cat > /etc/xinetd.d/mysqlchk <<EOF
# default: on
# description: mysqlchk
service mysqlchk
{
        disable = no
        flags = REUSE
        socket_type = stream
        port = 9200
        wait = no
        user = nobody
        server = /usr/local/bin/clustercheck
        log_on_failure += USERID
        only_from = 0.0.0.0/0
        per_source = UNLIMITED
}
EOF
```

4.启动心跳检测服务

在全部控制 节点修改/etc/services，变更tcp9200端口用途

```bash
$ vim /etc/services
...
#wap-wsp         9200/tcp                # WAP connectionless session service
#wap-wsp         9200/udp                # WAP connectionless session service
mysqlchk        9200/tcp                # mysql check
```

5.启动服务

```bash
mkdir -p /opt/clustercheck/systemd/

cat > /opt/clustercheck/systemd/mysqlchk.socket << EOF
[Unit]
Description=Percona XtraDB Cluster node check socket

[Socket]
ListenStream=9200
Accept=yes

[Install]
WantedBy=sockets.target
EOF

cat > /opt/clustercheck/systemd/mysqlchk@.service << EOF
[Unit]
Description=Percona XtraDB Cluster node check service

[Service]
ExecStart=-/usr/local/bin/clustercheck
StandardInput=socket
EOF

ln -s /opt/clustercheck/systemd/mysqlchk.socket /usr/lib/systemd/system/
ln -s /opt/clustercheck/systemd/mysqlchk@.service /usr/lib/systemd/system/

systemctl enable mysqlchk.socket
systemctl start mysqlchk.socket
```

6.验证

```bash
$ /usr/local/bin/clustercheck
HTTP/1.1 200 OK
Content-Type: text/plain
Connection: close
Content-Length: 40

Percona XtraDB Cluster Node is synced.
```

## 4.4异常关机或异常断电后的修复

```bash
第1步：开启galera集群的群主主机的mariadb服务。
第2步：开启galera集群的成员主机的mariadb服务。

异常处理：galera集群的群主主机和成员主机的mysql服务无法启动，如何处理？

#解决方法一：
第1步、删除garlera群主主机的/var/lib/mysql/grastate.dat状态文件
/bin/galera_new_cluster启动服务。启动正常。登录并查看wsrep状态。

第2步：删除galera成员主机中的/var/lib/mysql/grastate.dat状态文件
systemctl restart mariadb重启服务。启动正常。登录并查看wsrep状态。

#解决方法二：
第1步、修改garlera群主主机的/var/lib/mysql/grastate.dat状态文件中的0为1
/bin/galera_new_cluster启动服务。启动正常。登录并查看wsrep状态。

第2步：修改galera成员主机中的/var/lib/mysql/grastate.dat状态文件中的0为1
systemctl restart mariadb重启服务。启动正常。登录并查看wsrep状态。
```




# 5.RabbitMQ集群(控制节点)

## 5.1下载相关软件包(所有节点)

以controller01节点为例，RabbbitMQ基与erlang开发，首先安装erlang，采用yum方式

```bash
$ yum install erlang rabbitmq-server -y
$ systemctl enable rabbitmq-server.service
```

## 5.2构建rabbitmq集群

1.任选1个控制节点首先启动rabbitmq服务

```bash
$ systemctl start rabbitmq-server.service

$ rabbitmqctl cluster_status
Cluster status of node rabbit@controller01
[{nodes,[{disc,[rabbit@controller01]}]},
 {running_nodes,[rabbit@controller01]},
 {cluster_name,<<"rabbit@controller01">>},
 {partitions,[]}, 
 {alarms,[{rabbit@controller01,[]}]}]

$ cat /var/lib/rabbitmq/.erlang.cookie
RLYWYOQDNFINUBXPUOSA
```

2.分发.erlang.cookie到其他控制节点

注意：修改全部控制节点.erlang.cookie文件的权限，默认为400权限，可用不修改

```bash
$ scp /var/lib/rabbitmq/.erlang.cookie  controller02:/var/lib/rabbitmq/
$ scp /var/lib/rabbitmq/.erlang.cookie  controller03:/var/lib/rabbitmq/
```

3.修改controller02和03节点.erlang.cookie文件的用户/组

```bash
$ chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
```

4.启动controller02和03节点的rabbitmq服务

```bash
$ systemctl start rabbitmq-server
```


5.构建集群，controller02和03节点以ram节点的形式加入集群

```bash
$ rabbitmqctl stop_app
Stopping rabbit application on node rabbit@controller02

$ rabbitmqctl join_cluster --ram rabbit@controller01
Clustering node rabbit@controller02 with rabbit@controller01

$ rabbitmqctl start_app
Starting node rabbit@controller02
```

6.任意控制节点查看RabbitMQ集群状态

```bash
$ rabbitmqctl cluster_status
Cluster status of node rabbit@controller01
[{nodes,[{disc,[rabbit@controller01]},
         {ram,[rabbit@controller03,rabbit@controller02]}]},
 {running_nodes,[rabbit@controller03,rabbit@controller02,rabbit@controller01]},
 {cluster_name,<<"rabbit@controller01">>},
 {partitions,[]},
 {alarms,[{rabbit@controller03,[]},
          {rabbit@controller02,[]},
          {rabbit@controller01,[]}]}]

```

7.创建rabbitmq管理员账号

```bash
# 在任意节点新建账号并设置密码，以controller01节点为例
$ rabbitmqctl add_user openstack 123456
Creating user "openstack"

# 设置新建账号的状态
$ rabbitmqctl set_user_tags openstack administrator
Setting tags for user "openstack" to [administrator]

# 设置新建账号的权限
$ rabbitmqctl set_permissions -p "/" openstack ".*" ".*" ".*"
Setting permissions for user "openstack" in vhost "/"

# 查看账号
$ rabbitmqctl list_users 
Listing users
openstack	[administrator]
guest	[administrator]

```

8.镜像队列的HA

```bash
#设置镜像队列高可用
$ rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}'
Setting policy "ha-all" for pattern "^" to "{\"ha-mode\":\"all\"}" with priority "0"

#任意控制节点查看镜像队列策略
$ rabbitmqctl list_policies
Listing policies
/	ha-all	all	^	{"ha-mode":"all"}	0
```

9.安装web管理插件

在全部控制节点安装web管理插件，以controller01节点为例

```bash
$ rabbitmq-plugins enable rabbitmq_management
The following plugins have been enabled:
  amqp_client
  cowlib
  cowboy
  rabbitmq_web_dispatch
  rabbitmq_management_agent
  rabbitmq_management

Applying plugin configuration to rabbit@controller01... started 6 plugins.

$ ss -lntup|grep 5672
tcp    LISTEN     0      128       *:25672                 *:*                   users:(("beam.smp",pid=24725,fd=46))
tcp    LISTEN     0      128       *:15672                 *:*                   users:(("beam.smp",pid=24725,fd=59))
tcp    LISTEN     0      128      :::5672                 :::*                   users:(("beam.smp",pid=24725,fd=55))

# 访问任意节点，如：http://172.16.181.31:15672
# 账号：openstack
# 密码：123456
```



# 6.Memcached和Etcd集群(控制节点)

- Memcached是一款开源、高性能、分布式内存对象缓存系统，可应用各种需要缓存的场景，其主要目的是通过降低对Database的访问来加速web应用程序。
- Memcached一般的使用场景是：通过缓存数据库查询的结果，减少数据库访问次数，以提高动态Web应用的速度、提高可扩展性。
- 本质上，memcached是一个基于内存的key-value存储，用于存储数据库调用、API调用或页面引用结果的直接数据，如字符串、对象等小块任意数据。
- Memcached是无状态的，各控制节点独立部署，openstack各服务模块统一调用多个控制节点的memcached服务即可。


## 6.1安装memcache的软件包

1.在全部控制节点安装

```bash
$ yum install memcached -y
```

2.设置memcached

在全部安装memcached服务的节点设置服务监听本地地址

```bash
$ sed -i 's|127.0.0.1,::1|0.0.0.0|g' /etc/sysconfig/memcached
```

3.设置开机启动

```bash
$ systemctl enable memcached.service
$ systemctl start memcached.service
$ systemctl status memcached.service

$ netstat -lntup|grep memcached
tcp        0      0 0.0.0.0:11211           0.0.0.0:*               LISTEN      28995/memcached
```

## 6.2安装etcd的软件包

> OpenStack服务可以使用Etcd，这是一种分布式可靠的键值存储，用于分布式密钥锁定、存储配置、跟踪服务生存周期和其他场景；用于共享配置和服务发现特点是，安全，具有可选客户端证书身份验证的自动TLS；快速，基准测试10,000次/秒；可靠，使用Raft正确分发。

1.在全部控制节点安装

```bash
yum install -y etcd
```

2.设置etcd文件

修改配置文件为控制节点的管理IP地址，使其他节点能够通过管理网络进行访问: ETCD_NAME根据当前实例主机名进行修改

```bash
$ cp -a /etc/etcd/etcd.conf{,.bak}

# controller01
$ cat > /etc/etcd/etcd.conf <<EOF 
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://172.16.181.31:2379,http://127.0.0.1:2379"
ETCD_NAME="controller01"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://172.16.181.31:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://172.16.181.31:2379"
ETCD_INITIAL_CLUSTER="controller01=http://172.16.181.31:2380,controller02=http://172.16.181.32:2380,controller03=http://172.16.181.33:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

# controller02
$ cat > /etc/etcd/etcd.conf <<EOF 
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://172.16.181.32:2379,http://127.0.0.1:2379"
ETCD_NAME="controller02"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://172.16.181.32:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://172.16.181.32:2379"
ETCD_INITIAL_CLUSTER="controller01=http://172.16.181.31:2380,controller02=http://172.16.181.32:2380,controller03=http://172.16.181.33:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF


# controller03
$ cat > /etc/etcd/etcd.conf <<EOF 
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://172.16.181.33:2379,http://127.0.0.1:2379"
ETCD_NAME="controller03"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://172.16.181.33:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://172.16.181.33:2379"
ETCD_INITIAL_CLUSTER="controller01=http://172.16.181.31:2380,controller02=http://172.16.181.32:2380,controller03=http://172.16.181.33:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF
```

3.修改etcd.service

```bash
$ vim /usr/lib/systemd/system/etcd.service
[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
User=etcd
# set GOMAXPROCS to number of processors
ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/bin/etcd \
--name=\"${ETCD_NAME}\" \
--data-dir=\"${ETCD_DATA_DIR}\" \
--listen-peer-urls=\"${ETCD_LISTEN_PEER_URLS}\" \
--listen-client-urls=\"${ETCD_LISTEN_CLIENT_URLS}\" \
--initial-advertise-peer-urls=\"${ETCD_INITIAL_ADVERTISE_PEER_URLS}\" \
--advertise-client-urls=\"${ETCD_ADVERTISE_CLIENT_URLS}\" \
--initial-cluster=\"${ETCD_INITIAL_CLUSTER}\"  \
--initial-cluster-token=\"${ETCD_INITIAL_CLUSTER_TOKEN}\" \
--initial-cluster-state=\"${ETCD_INITIAL_CLUSTER_STATE}\""
Restart=on-failure
LimitNOFILE=65536

# 拷贝其他节点
scp -rp /usr/lib/systemd/system/etcd.service controller02:/usr/lib/systemd/system/
scp -rp /usr/lib/systemd/system/etcd.service controller03:/usr/lib/systemd/system/
```

4.启动、验证

全部控制节点同时执行

```bash
systemctl enable etcd
systemctl restart etcd
systemctl status etcd


$ etcdctl cluster-health
member c774df0c1fcbf86 is healthy: got healthy result from http://172.16.181.31:2379
member 34d670a094ccde30 is healthy: got healthy result from http://172.16.181.33:2379
member d27c95959e2e8c90 is healthy: got healthy result from http://172.16.181.32:2379
cluster is healthy

$ etcdctl member list
c774df0c1fcbf86: name=controller01 peerURLs=http://172.16.181.31:2380 clientURLs=http://172.16.181.31:2379 isLeader=false
34d670a094ccde30: name=controller03 peerURLs=http://172.16.181.33:2380 clientURLs=http://172.16.181.33:2379 isLeader=false
d27c95959e2e8c90: name=controller02 peerURLs=http://172.16.181.32:2380 clientURLs=http://172.16.181.32:2379 isLeader=true
```



# 7.配置Pacemaker高可用集群

Openstack官网使用开源的pacemaker cluster stack做为集群高可用资源管理软件。

Pacemaker 承担集群资源管理者（CRM - Cluster Resource Manager）的角色，它是一款开源的高可用资源管理软件，适合各种大小集群。Pacemaker 由 Novell 支持，SLES HAE 就是用 Pacemaker 来管理集群，并且 Pacemaker 得到了来自Redhat，Linbit等公司的支持。它用资源级别的监测和恢复来保证集群服务(aka. 资源)的最大可用性。它可以用基础组件(Corosync 或者是Heartbeat)来实现集群中各成员之间的通信和关系管理。它包含以下的关键特性:

- 监测并恢复节点和服务级别的故障
- 存储无关，并不需要共享存储
- 资源无关，任何能用脚本控制的资源都可以作为服务
- 支持使用 STONITH 来保证数据一致性
- 支持大型或者小型的集群
- 支持 quorum (仲裁) 或 resource(资源) 驱动的集群
- 支持任何的冗余配置
- 自动同步各个节点的配置文件
- 可以设定集群范围内的 ordering, colocation and anti-colocation
- 支持高级的服务模式

Pacemaker 软件架构

- Pacemaker - 资源管理器(CRM)，负责启动和停止服务，而且保证它们是一直运行着的以及某个时刻某服务只在一个节点上运行（避免多服务同时操作数据造成的混乱）。
- Corosync - 消息层组件（Messaging Layer），管理成员关系、消息与仲裁，为高可用环境中提供通讯服务，位于高可用集群架构的底层，为各节点（node）之间提供心跳信息。
- Resource Agents - 资源代理，实现在节点上接收 CRM 的调度对某一个资源进行管理的工具，这个管理的工具通常是脚本，所以我们通常称为资源代理。任何资源代理都要使用同一种风格，接收四个参数：{start|stop|restart|status}，包括配置IP地址的也是。每个种资源的代理都要完成这四个参数据的输出。Pacemaker 的 RA 可以分为三种：（1）Pacemaker 自己实现的 （2）第三方实现的，比如 RabbitMQ 的 RA （3）自己实现的，比如 OpenStack 实现的它的各种服务的RA，这是 mysql 的 RA。
- pcs - 命令行工具集
- fence agents - 在一个节点不稳定或无答复时将其关闭，使其不会损坏集群的其它资源，其主要作用是消除脑裂。

## 7.1安装相关软件

在全部控制节点安装相关服务；以controller01节点为例

```bash
$ yum install pacemaker pcs corosync fence-agents resource-agents -y
```

## 7.2构建集群

1.启动pcs服务

在全部控制节点执行，以controller01节点为例

```bash
systemctl enable pcsd
systemctl start pcsd
systemctl status pcsd
```

2.修改集群管理员hacluster（默认生成）密码

在全部控制节点执行，以controller01节点为例

```bash
echo 123456 | passwd --stdin hacluster
```

3.认证操作

认证配置在任意节点操作，以controller01节点为例；

节点认证，组建集群，需要采用上一步设置的password

```bash
#centos7的命令
$ pcs cluster auth controller01 controller02 controller03 -u hacluster -p 123456 --force
controller01: Authorized
controller02: Authorized
controller03: Authorized

#centos8(仅作为记录)
pcs host auth controller01 controller02 controller03 -u hacluster -p 123456
```

4.创建并命名集群

在任意节点操作；以controller01节点为例

```bash
#centos7的命令
$ pcs cluster setup --force --name openstack-cluster-01 controller01 controller02 controller03
Destroying cluster on nodes: controller01, controller02, controller03...
controller01: Stopping Cluster (pacemaker)...
controller02: Stopping Cluster (pacemaker)...
controller03: Stopping Cluster (pacemaker)...
controller01: Successfully destroyed cluster
controller02: Successfully destroyed cluster
controller03: Successfully destroyed cluster

Sending 'pacemaker_remote authkey' to 'controller01', 'controller02', 'controller03'
controller02: successful distribution of the file 'pacemaker_remote authkey'
controller01: successful distribution of the file 'pacemaker_remote authkey'
controller03: successful distribution of the file 'pacemaker_remote authkey'
Sending cluster config files to the nodes...
controller01: Succeeded
controller02: Succeeded
controller03: Succeeded

Synchronizing pcsd certificates on nodes controller01, controller02, controller03...
controller01: Success
controller02: Success
controller03: Success
Restarting pcsd on the nodes in order to reload the certificates...
controller01: Success
controller02: Success
controller03: Success


#centos8(仅作为记录)
pcs cluster setup openstack-cluster-01 --start controller01 controller02 controller03
```

5.pcemaker集群启动

```bash
$ pcs cluster start  --all
controller01: Starting Cluster (corosync)...
controller02: Starting Cluster (corosync)...
controller03: Starting Cluster (corosync)...
controller02: Starting Cluster (pacemaker)...
controller03: Starting Cluster (pacemaker)...
controller01: Starting Cluster (pacemaker)...

$ pcs cluster enable  --all
controller01: Cluster Enabled
controller02: Cluster Enabled
controller03: Cluster Enabled
```

6.查看pacemaker集群状态

```bash
$ pcs cluster status
Cluster Status:
 Stack: corosync
 Current DC: controller02 (version 1.1.23-1.el7_9.1-9acf116022) - partition with quorum
 Last updated: Fri Sep 23 17:42:02 2022
 Last change: Fri Sep 23 14:41:26 2022 by hacluster via crmd on controller02
 3 nodes configured
 0 resource instances configured

PCSD Status:
  controller01: Online
  controller02: Online
  controller03: Online

# 查看集群状态，也可使用crm_mon -1命令
$ crm_mon -1
Stack: corosync
Current DC: controller02 (version 1.1.23-1.el7_9.1-9acf116022) - partition with quorum
Last updated: Fri Sep 23 17:43:45 2022
Last change: Fri Sep 23 14:41:26 2022 by hacluster via crmd on controller02

3 nodes configured
0 resource instances configured

Online: [ controller01 controller02 controller03 ]

No active resources

# 通过cibadmin --query --scope nodes可查看节点配置
$ cibadmin --query --scope nodes
<nodes>
  <node id="1" uname="controller01"/>
  <node id="2" uname="controller02"/>
  <node id="3" uname="controller03"/>
</nodes>
```

7.查看corosync状态

corosync表示一种底层状态等信息的同步方式

```bash
$ pcs status corosync

Membership information
----------------------
    Nodeid      Votes Name
         1          1 controller01 (local)
         2          1 controller02
         3          1 controller03
```

8.查看节点和资源

```bash
$ corosync-cmapctl | grep members
runtime.totem.pg.mrp.srp.members.1.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.1.ip (str) = r(0) ip(172.16.181.31) 
runtime.totem.pg.mrp.srp.members.1.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.1.status (str) = joined
runtime.totem.pg.mrp.srp.members.2.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.2.ip (str) = r(0) ip(172.16.181.32) 
runtime.totem.pg.mrp.srp.members.2.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.2.status (str) = joined
runtime.totem.pg.mrp.srp.members.3.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.3.ip (str) = r(0) ip(172.16.181.33) 
runtime.totem.pg.mrp.srp.members.3.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.3.status (str) = joined
```

9.通过web界面访问pacemaker

访问任意控制节点：https://172.16.181.31:2224

账号/密码（即构建集群时生成的密码）：hacluster/123456


10.设置高可用属性

在任意控制节点设置属性即可，以controller01节点为例；

```bash
# 设置合适的输入处理历史记录及策略引擎生成的错误与警告，在trouble shooting故障排查时有用
$ pcs property set pe-warn-series-max=1000 \
  pe-input-series-max=1000 \
  pe-error-series-max=1000 

# pacemaker基于时间驱动的方式进行状态处理，cluster-recheck-interval默认定义某些pacemaker操作发生的事件间隔为15min，建议设置为5min或3min
$ pcs property set cluster-recheck-interval=5

# corosync默认启用stonith，但stonith机制（通过ipmi或ssh关闭节点）并没有配置相应的stonith设备（通过crm_verify -L -V验证配置是否正确，没有输出即正确），此时pacemaker将拒绝启动任何资源；在生产环境可根据情况灵活调整，测试环境下可关闭
$ pcs property set stonith-enabled=false

# 默认当有半数以上节点在线时，集群认为自己拥有法定人数，是“合法”的，满足公式：total_nodes < 2 * active_nodes；
# 以3个节点的集群计算，当故障2个节点时，集群状态不满足上述公式，此时集群即非法；当集群只有2个节点时，故障1个节点集群即非法，所谓的”双节点集群”就没有意义；
# 在实际生产环境中，做2节点集群，无法仲裁时，可选择忽略；做3节点集群，可根据对集群节点的高可用阀值灵活设置
$ pcs property set no-quorum-policy=ignore

# v2的heartbeat为了支持多节点集群，提供了一种积分策略来控制各个资源在集群中各节点之间的切换策略；通过计算出各节点的的总分数，得分最高者将成为active状态来管理某个（或某组）资源；
# 默认每一个资源的初始分数（取全局参数default-resource-stickiness，通过"pcs property list --all"查看）是0，同时每一个资源在每次失败之后减掉的分数（取全局参数default-resource-failure-stickiness）也是0，此时一个资源不论失败多少次，heartbeat都只是执行restart操作，不会进行节点切换；
# 如果针对某一个资源设置初始分数”resource-stickiness“或"resource-failure-stickiness"，则取单独设置的资源分数；
# 一般来说，resource-stickiness的值都是正数，resource-failure-stickiness的值都是负数；有一个特殊值是正无穷大（INFINITY）和负无穷大（-INFINITY），即"永远不切换"与"只要失败必须切换"，是用来满足极端规则的简单配置项；
# 如果节点的分数为负，该节点在任何情况下都不会接管资源（冷备节点）；如果某节点的分数大于当前运行该资源的节点的分数，heartbeat会做出切换动作，现在运行该资源的节点将释 放资源，分数高出的节点将接管该资源

# pcs property list 只可查看修改后的属性值，参数”--all”可查看含默认值的全部属性值；
# 也可查看/var/lib/pacemaker/cib/cib.xml文件，或”pcs cluster cib”，或“cibadmin --query --scope crm_config”查看属性设置，” cibadmin --query --scope resources”查看资源配置
$ pcs property list
Cluster Properties:
 cluster-infrastructure: corosync
 cluster-name: openstack-cluster-01
 cluster-recheck-interval: 5
 dc-version: 1.1.23-1.el7_9.1-9acf116022
 have-watchdog: false
 no-quorum-policy: ignore
 pe-error-series-max: 1000
 pe-input-series-max: 1000
 pe-warn-series-max: 1000
 stonith-enabled: false
```

## 7.3配置VIP

1.设置vip

- 在任意控制节点设置vip（resource_id属性）即可，命名即为vip；
- ocf（standard属性）：资源代理（resource agent）的一种，另有systemd，lsb，service等；
- heartbeat：资源脚本的提供者（provider属性），ocf规范允许多个供应商提供同一资源代理，大多数ocf规范提供的资源代理都使用heartbeat作为provider；
- IPaddr2：资源代理的名称（type属性），IPaddr2便是资源的type；
- cidr_netmask: 子网掩码位数
- 通过定义资源属性（standard:provider:type），定位vip资源对应的ra脚本位置；
- centos系统中，符合ocf规范的ra脚本位于/usr/lib/ocf/resource.d/目录，目录下存放了全部的provider，每个provider目录下有多个type；
- op：表示Operations（运作方式 监控间隔= 30s）

```bash
$ pcs resource create vip ocf:heartbeat:IPaddr2 ip=172.16.181.30 cidr_netmask=16 op monitor interval=30s
```

2.查看集群资源

- 通过pcs resouce查询，vip资源在controller01节点；
- 通过ip a show可查看vip

```bash
$ pcs resource
 vip	(ocf::heartbeat:IPaddr2):	Started controller01

$ ip a show eth0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 5e:95:86:7e:53:d8 brd ff:ff:ff:ff:ff:ff
    inet 172.16.181.31/16 brd 172.16.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet 172.16.181.30/16 brd 172.16.255.255 scope global secondary eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::5c95:86ff:fe7e:53d8/64 scope link 
       valid_lft forever preferred_lft forever
```

3.可选(根据业务需求是否区分来决定)：

如果api区分管理员/内部/公共的接口，对客户端只开放公共接口，通常设置两个vip，如在命名时设置为：
建议是将vip_management与vip_public约束在1个节点上

```bash
$ pcs constraint colocation add vip_management with vip_public
```

## 7.4高可用性管理

通过web访问任意控制节点：https://172.16.181.31:2224

账号/密码（即构建集群时生成的密码）：hacluster/123456

虽然以命令行的方式设置了集群，但web界面默认并不显示，手动添加集群，实际操作只需要添加已组建集群的任意节点即可，如下

```windows

登录 --> + Add Existing --> Node Name/IP: 172.16.181.31 --> Add Existing --> 输入hacluter账号密码：123456 --> Authenticate

```


# 8.部署Haproxy


## 8.1安装haproxy(控制节点)

在全部控制节点安装haproxy，以controller01节点为例；

```bash
$ yum install haproxy -y
```

## 8.2 配置haproxy.cfg

在全部控制节点配置，以controller01节点为例；

1.创建HAProxy记录日志文件并授权

建议开启haproxy的日志功能，便于后续的问题排查

```bash
$ mkdir /var/log/haproxy
$ chmod a+w /var/log/haproxy
```

2.在rsyslog文件下修改以下字段

```bash

$ vim /etc/rsyslog.conf
#取消注释
$ModLoad imudp
$UDPServerRun 514
...
$ModLoad imtcp
$InputTCPServerRun 514

*.info;mail.none;authpriv.none;cron.none;local0.none                /var/log/messages

#在文件最后添加haproxy配置日志
local0.=info    -/var/log/haproxy/haproxy-info.log
local0.=err     -/var/log/haproxy/haproxy-err.log
local0.notice;local0.!=err      -/var/log/haproxy/haproxy-notice.log

#重启rsyslog
$ systemctl restart rsyslog
```

3.集群的haproxy文件，涉及服务较多，这里针对涉及到的openstack服务，一次性设置完成：

> VIP: 172.16.181.30

```bash
$ mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
$ vim /etc/haproxy/haproxy.cfg

```

```conf
global
  log      127.0.0.1     local0
  chroot   /var/lib/haproxy
  daemon
  group    haproxy
  user     haproxy
  maxconn  4000
  pidfile  /var/run/haproxy.pid
  stats    socket /var/lib/haproxy/stats

defaults
    mode                    http
    log                     global
    maxconn                 4000    #最大连接数
    option                  httplog
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout check           10s


# haproxy监控页
listen stats
  bind 0.0.0.0:1080
  mode http
  stats enable
  stats uri /
  stats realm OpenStack\ Haproxy
  stats auth admin:admin
  stats  refresh 30s
  stats  show-node
  stats  show-legends
  stats  hide-version

# horizon服务
 listen dashboard_cluster
  bind  172.16.181.30:80
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 172.16.181.31:80 check inter 2000 rise 2 fall 5
  server controller02 172.16.181.32:80 check inter 2000 rise 2 fall 5
  server controller03 172.16.181.33:80 check inter 2000 rise 2 fall 5

# mariadb服务；
#设置controller01节点为master，controller02/03节点为backup，一主多备的架构可规避数据不一致性；
#另外官方示例为检测9200（心跳）端口，测试在mariadb服务宕机的情况下，虽然”/usr/bin/clustercheck”脚本已探测不到服务，但受xinetd控制的9200端口依然正常，导致haproxy始终将请求转发到mariadb服务宕机的节点，暂时修改为监听3306端口
listen galera_cluster
  bind 172.16.181.30:3306
  balance  source
  mode    tcp
  server controller01 172.16.181.31:3306 check inter 2000 rise 2 fall 5
  server controller02 172.16.181.32:3306 backup check inter 2000 rise 2 fall 5
  server controller03 172.16.181.33:3306 backup check inter 2000 rise 2 fall 5

#为rabbirmq提供ha集群访问端口，供openstack各服务访问；
#如果openstack各服务直接连接rabbitmq集群，这里可不设置rabbitmq的负载均衡
 listen rabbitmq_cluster
   bind 172.16.181.30:5673
   mode tcp
   option tcpka
   balance roundrobin
   timeout client  3h
   timeout server  3h
   option  clitcpka
   server controller01 172.16.181.31:5672 check inter 10s rise 2 fall 5
   server controller02 172.16.181.32:5672 check inter 10s rise 2 fall 5
   server controller03 172.16.181.33:5672 check inter 10s rise 2 fall 5

# glance_api服务
 listen glance_api_cluster
  bind  172.16.181.30:9292
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  timeout client 3h 
  timeout server 3h
  server controller01 172.16.181.31:9292 check inter 2000 rise 2 fall 5
  server controller02 172.16.181.32:9292 check inter 2000 rise 2 fall 5
  server controller03 172.16.181.33:9292 check inter 2000 rise 2 fall 5

# keystone_public _api服务
 listen keystone_public_cluster
  bind 172.16.181.30:5000
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 172.16.181.31:5000 check inter 2000 rise 2 fall 5
  server controller02 172.16.181.32:5000 check inter 2000 rise 2 fall 5
  server controller03 172.16.181.33:5000 check inter 2000 rise 2 fall 5

 listen nova_compute_api_cluster
  bind 172.16.181.30:8774
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 172.16.181.31:8774 check inter 2000 rise 2 fall 5
  server controller02 172.16.181.32:8774 check inter 2000 rise 2 fall 5
  server controller03 172.16.181.33:8774 check inter 2000 rise 2 fall 5

 listen nova_placement_cluster
  bind 172.16.181.30:8778
  balance  source
  option  tcpka
  option  tcplog
  server controller01 172.16.181.31:8778 check inter 2000 rise 2 fall 5
  server controller02 172.16.181.32:8778 check inter 2000 rise 2 fall 5
  server controller03 172.16.181.33:8778 check inter 2000 rise 2 fall 5

 listen nova_metadata_api_cluster
  bind 172.16.181.30:8775
  balance  source
  option  tcpka
  option  tcplog
  server controller01 172.16.181.31:8775 check inter 2000 rise 2 fall 5
  server controller02 172.16.181.32:8775 check inter 2000 rise 2 fall 5
  server controller03 172.16.181.33:8775 check inter 2000 rise 2 fall 5

 listen nova_vncproxy_cluster
  bind 172.16.181.30:6080
  balance  source
  option  tcpka
  option  tcplog
  server controller01 172.16.181.31:6080 check inter 2000 rise 2 fall 5
  server controller02 172.16.181.32:6080 check inter 2000 rise 2 fall 5
  server controller03 172.16.181.33:6080 check inter 2000 rise 2 fall 5

 listen neutron_api_cluster
  bind 172.16.181.30:9696
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 172.16.181.31:9696 check inter 2000 rise 2 fall 5
  server controller02 172.16.181.32:9696 check inter 2000 rise 2 fall 5
  server controller03 172.16.181.33:9696 check inter 2000 rise 2 fall 5

 listen cinder_api_cluster
  bind 172.16.181.30:8776
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 172.16.181.31:8776 check inter 2000 rise 2 fall 5
  server controller02 172.16.181.32:8776 check inter 2000 rise 2 fall 5
  server controller03 172.16.181.33:8776 check inter 2000 rise 2 fall 5
```

4.将配置文件拷贝到其他节点中

```bash
$ scp /etc/haproxy/haproxy.cfg controller02:/etc/haproxy/haproxy.cfg
$ scp /etc/haproxy/haproxy.cfg controller03:/etc/haproxy/haproxy.cfg
```

## 8.3配置内核参数

在基础环境准备中已经配置，这里再做一次记录，以controller01节点为例；

- net.ipv4.ip_nonlocal_bind：是否允许no-local ip绑定，关系到haproxy实例与vip能否绑定并切换
- net.ipv4.ip_forward：是否允许转发

```bash
echo 'net.ipv4.ip_nonlocal_bind = 1' >>/etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.conf
sysctl -p
```

## 8.4启动服务

在全部控制节点启动，以controller01节点为例；
开机启动是否设置可自行选择，利用pacemaker设置haproxy相关资源后，pacemaker可控制各节点haproxy服务是否启动

```bash
systemctl enable haproxy
systemctl restart haproxy
systemctl status haproxy
```

## 8.5访问haproxy web

访问：http://172.16.181.30:1080 用户名/密码：admin/admin


## 8.6设置pcs资源

1.添加资源 lb-haproxy-clone

任意控制节点操作即可，以controller01节点为例；

```bash
$ pcs resource create lb-haproxy systemd:haproxy clone
$ pcs resource
 vip	(ocf::heartbeat:IPaddr2):	Started controller01
 Clone Set: lb-haproxy-clone [lb-haproxy]
     Started: [ controller01 controller02 controller03 ]
```

2.设置资源启动顺序，先vip再lb-haproxy-clone

通过cibadmin --query --scope constraints可查看资源约束配置

```bash
$ pcs constraint order start vip then lb-haproxy-clone kind=Optional
Adding vip lb-haproxy-clone (kind: Optional) (Options: first-action=start then-action=start)

$ cibadmin --query --scope constraints
<constraints>
  <rsc_order first="vip" first-action="start" id="order-vip-lb-haproxy-clone-Optional" kind="Optional" then="lb-haproxy-clone" then-action="start"/>
</constraints>
```

3.将两种资源约束在1个节点

官方建议设置vip运行在haproxy active的节点，通过绑定lb-haproxy-clone与vip服务，所以将两种资源约束在1个节点；约束后，从资源角度看，其余暂时没有获得vip的节点的haproxy会被pcs关闭

```bash
$ pcs constraint colocation add lb-haproxy-clone with vip
$ pcs resource
 vip	(ocf::heartbeat:IPaddr2):	Started controller01
 Clone Set: lb-haproxy-clone [lb-haproxy]
     Started: [ controller01 ]
     Stopped: [ controller02 controller03 ]
```



# 9.Keystone集群部署

> https://docs.openstack.org/keystone/train/install/index-rdo.html

Keystone 的主要功能：

- 管理用户及其权限；
- 维护 OpenStack 服务的 Endpoint；
- Authentication（认证）和 Authorization（鉴权）。

## 9.1配置keystone数据库

在任意控制节点创建数据库，数据库自动同步，以controller01节点为例；

```bash
mysql -u root -p
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '123456';
flush privileges;
exit
```

## 9.2安装keystone

在全部控制节点安装keystone，以controller01节点为例；

如果要使用https访问，需要安装mod_ssl

```bash
# 个别依赖指定安装版本
$ yum install qpid-proton-c-0.26.0-2.el7.x86_64

$ yum install openstack-keystone httpd mod_wsgi mod_ssl -y

#备份Keystone配置文件
cp /etc/keystone/keystone.conf{,.bak}
egrep -v '^$|^#' /etc/keystone/keystone.conf.bak >/etc/keystone/keystone.conf
```

## 9.3配置Keystone配置文件

> 要对接有状态服务时都修改为解析过的vip(myvip)

```bash
openstack-config --set /etc/keystone/keystone.conf cache backend oslo_cache.memcache_pool
openstack-config --set /etc/keystone/keystone.conf cache enabled true
openstack-config --set /etc/keystone/keystone.conf cache memcache_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:123456@172.16.181.30/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet
```

将配置文件拷贝到另外两个节点：

```bash
scp -rp /etc/keystone/keystone.conf controller02:/etc/keystone/keystone.conf
scp -rp /etc/keystone/keystone.conf controller03:/etc/keystone/keystone.conf
```


## 9.4同步keystone数据库

1.在任意控制节点操作；填充Keystone数据库

```bash
su -s /bin/sh -c "keystone-manage db_sync" keystone

mysql -uroot -p123456  keystone  -e "show  tables";
```

2.初始化Fernet密钥存储库，无报错即为成功;

```bash
#在/etc/keystone/生成相关秘钥及目录
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

#并将初始化的密钥拷贝到其他的控制节点
scp -rp /etc/keystone/fernet-keys /etc/keystone/credential-keys controller02:/etc/keystone/
scp -rp /etc/keystone/fernet-keys /etc/keystone/credential-keys controller03:/etc/keystone/

#同步后修改另外两台控制节点fernet的权限
chown -R keystone:keystone /etc/keystone/credential-keys/
chown -R keystone:keystone /etc/keystone/fernet-keys/ 
```

## 9.5认证引导

1.任意控制节点操作；初始化admin用户（管理用户）与密码，3种api端点，服务实体可用区等

注意：这里使用的是VIP

```bash
$ keystone-manage bootstrap --bootstrap-password 123456 \
    --bootstrap-admin-url http://172.16.181.30:5000/v3/ \
    --bootstrap-internal-url http://172.16.181.30:5000/v3/ \
    --bootstrap-public-url http://172.16.181.30:5000/v3/ \
    --bootstrap-region-id RegionOne
```

2.配置httpd.conf

在全部控制节点设置，以controller01节点为例；

```bash
#修改域名为主机名
cp /etc/httpd/conf/httpd.conf{,.bak}
sed -i "s/#ServerName www.example.com:80/ServerName ${HOSTNAME}/" /etc/httpd/conf/httpd.conf

#不同的节点替换不同的ip地址
##controller01
sed -i "s/Listen\ 80/Listen\ 172.16.181.31:80/g" /etc/httpd/conf/httpd.conf
##controller02
sed -i "s/Listen\ 80/Listen\ 172.16.181.32:80/g" /etc/httpd/conf/httpd.conf
##controller03
sed -i "s/Listen\ 80/Listen\ 172.16.181.33:80/g" /etc/httpd/conf/httpd.conf
```

3.配置wsgi-keystone.conf

在全部控制节点操作，以controller01节点为例；

```bash
#创建软连接wsgi-keystone.conf文件
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

#不同的节点替换不同的ip地址
##controller01
sed -i "s/Listen\ 5000/Listen\ 172.16.181.31:5000/g" /etc/httpd/conf.d/wsgi-keystone.conf
sed -i "s#*:5000#172.16.181.31:5000#g" /etc/httpd/conf.d/wsgi-keystone.conf

##controller02
sed -i "s/Listen\ 5000/Listen\ 172.16.181.32:5000/g" /etc/httpd/conf.d/wsgi-keystone.conf
sed -i "s#*:5000#172.16.181.32:5000#g" /etc/httpd/conf.d/wsgi-keystone.conf

##controller03
sed -i "s/Listen\ 5000/Listen\ 172.16.181.33:5000/g" /etc/httpd/conf.d/wsgi-keystone.conf
sed -i "s#*:5000#172.16.181.33:5000#g" /etc/httpd/conf.d/wsgi-keystone.conf
```

4.启动服务

```bash
systemctl restart httpd.service
systemctl enable httpd.service
systemctl status httpd.service
```

5.配置用户变量脚本

在任意控制节点操作；

- openstack client环境脚本定义client调用openstack api环境变量，以方便api的调用（不必在命令行中携带环境变量）;
- 官方文档将admin用户和demo租户的变量写入到了家目录下,根据不同的用户角色，需要定义不同的脚本；
- 一般将脚本创建在用户主目录

```bash
$ cat >> ~/.admin-openrc << EOF
#admin-openrc
export OS_USERNAME=admin
export OS_PASSWORD=123456
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://172.16.181.30:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
$ source  ~/.admin-openrc

#拷贝到其他的控制节点
scp -rp ~/.admin-openrc controller02:~/
scp -rp ~/.admin-openrc controller03:~/

#验证
$ openstack domain list
+---------+---------+---------+--------------------+
| ID      | Name    | Enabled | Description        |
+---------+---------+---------+--------------------+
| default | Default | True    | The default domain |
+---------+---------+---------+--------------------+

#也可以使用下面的命令
openstack token issue 

```

6.创建新域、项目、用户和角色

在任意控制节点操作；

身份服务为每个OpenStack服务提供身份验证服务，其中包括服务使用域、项目、用户和角色的组合。

```bash
#创建域 
#keystone-manage引导步骤中，默认Default域已经存在，创建新域的方法是:
$ openstack domain create --description "An Example Domain" example
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | An Example Domain                |
| enabled     | True                             |
| id          | 5ce8364c37d342b2966e5de91a1b6c0b |
| name        | example                          |
| options     | {}                               |
| tags        | []                               |
+-------------+----------------------------------+

$ openstack domain list
+----------------------------------+---------+---------+--------------------+
| ID                               | Name    | Enabled | Description        |
+----------------------------------+---------+---------+--------------------+
| 5ce8364c37d342b2966e5de91a1b6c0b | example | True    | An Example Domain  |
| default                          | Default | True    | The default domain |
+----------------------------------+---------+---------+--------------------+

#创建demo项目
#由于admin的项目角色用户都已经存在了；重新创建一个新的项目角色demo
#以创建demo项目为例，demo项目属于”default”域
$ openstack project create --domain default --description "demo Project" demo
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | demo Project                     |
| domain_id   | default                          |
| enabled     | True                             |
| id          | 8519019f16e14fe3a1c0cdc0d3d703b8 |
| is_domain   | False                            |
| name        | demo                             |
| options     | {}                               |
| parent_id   | default                          |
| tags        | []                               |
+-------------+----------------------------------+

$ openstack project list
+----------------------------------+-------+
| ID                               | Name  |
+----------------------------------+-------+
| 58587b22289f469f9923d154dfacbb76 | admin |
| 8519019f16e14fe3a1c0cdc0d3d703b8 | demo  |
+----------------------------------+-------+

#创建demo用户
#需要输入新用户的密码
#--password-prompt为交互式；--password+密码为非交互式
$ openstack user create --domain default   --password 123456 demo
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | afa2a848e2ec440f955d9175b2a6e391 |
| name                | demo                             |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+

$ openstack user list
+----------------------------------+-------+
| ID                               | Name  |
+----------------------------------+-------+
| ad73806f4ed349b3bdd6de122e63b8ce | admin |
| afa2a848e2ec440f955d9175b2a6e391 | demo  |
+----------------------------------+-------+

#创建user角色
$ openstack role create user
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | None                             |
| domain_id   | None                             |
| id          | 24ee9b6479c0432db71c1c37448ea445 |
| name        | user                             |
| options     | {}                               |
+-------------+----------------------------------+

$ openstack role list
+----------------------------------+--------+
| ID                               | Name   |
+----------------------------------+--------+
| 24ee9b6479c0432db71c1c37448ea445 | user   |
| 3aa6ead34fee486d912381a5fff0eaed | member |
| bafeb2c93b2d44f88277176f5b86b7c0 | reader |
| c995077a77e548f2bccb7e71efc26605 | admin  |
+----------------------------------+--------+

#将user角色添加到demo项目和demo用户
$ openstack role add --project demo --user  demo user

#为demo用户也添加一个环境变量文件
#密码为demo用户的密码,需要用到此用户变量的时候source一下
$ cat >> ~/.demo-openrc << EOF
#demo-openrc
export OS_USERNAME=demo
export OS_PASSWORD=123456
export OS_PROJECT_NAME=demo
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://172.16.181.30:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
$ source  ~/.demo-openrc

$ scp -rp ~/.demo-openrc controller02:~/
$ scp -rp ~/.demo-openrc controller03:~/

$ openstack token issue 
```

6.验证keystone

任意一台控制节点；以admin用户身份，请求身份验证令牌, 使用admin用户变量

```bash
$ source ~/.admin-openrc
$ openstack --os-auth-url http://172.16.181.30:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name admin --os-username admin token issue
```

任意一台控制节点；以demo用户身份，请请求认证令牌, 使用demo用户变量

```bash
$ source ~/.demo-openrc
$ openstack --os-auth-url http://172.16.181.30:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name demo --os-username demo token issue
```

## 9.6设置pcs资源

在任意控制节点操作；添加资源openstack-keystone-clone；
pcs实际控制的是各节点system unit(系统单位) 控制的httpd服务

```bash
$ pcs resource create openstack-keystone systemd:httpd clone interleave=true
$ pcs resource
 vip	(ocf::heartbeat:IPaddr2):	Started controller01
 Clone Set: lb-haproxy-clone [lb-haproxy]
     Started: [ controller01 ]
     Stopped: [ controller02 controller03 ]
 Clone Set: openstack-keystone-clone [openstack-keystone]
     Started: [ controller01 controller02 controller03 ]

```


---

# 10.Glance集群部署

https://docs.openstack.org/glance/train/install/install-rdo.html

Glance 具体功能如下：
- 提供 RESTful API 让用户能够查询和获取镜像的元数据和镜像本身；
- 支持多种方式存储镜像，包括普通的文件系统、Swift、Ceph 等；
- 对实例执行快照创建新的镜像。


## 10.1创建glance数据库

在任意控制节点创建数据库，数据库自动同步，以controller01节点为例；

```bash
mysql -u root -p
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '123456';
flush privileges;
```

## 10.2创建glance-api相关服务凭证

在任意控制节点创建数据库，以controller01节点为例；

```bash
source ~/.admin-openrc
#创建service项目
openstack project create --domain default --description "Service Project" service

#创建glance用户
openstack user create --domain default --password 123456 glance

#将管理员admin用户添加到glance用户和项目中
openstack role add --project service --user glance admin

#创建glance服务实体
openstack service create --name glance --description "OpenStack Image" image

#创建glance-api;
openstack endpoint create --region RegionOne image public http://172.16.181.30:9292
openstack endpoint create --region RegionOne image internal http://172.16.181.30:9292
openstack endpoint create --region RegionOne image admin http://172.16.181.30:9292

#查看创建之后的api;
$ openstack endpoint list
+----------------------------------+-----------+--------------+--------------+---------+-----------+-------------------------------+
| ID                               | Region    | Service Name | Service Type | Enabled | Interface | URL                           |
+----------------------------------+-----------+--------------+--------------+---------+-----------+-------------------------------+
| 05acce575e2d48e88d0b4b1682ac78b5 | RegionOne | glance       | image        | True    | internal  | http://172.16.181.30:9292     |
| 0b5249da688044c6a93860d850a506ad | RegionOne | glance       | image        | True    | public    | http://172.16.181.30:9292     |
| 26987deaf6e44066826127b9c6f9bddf | RegionOne | keystone     | identity     | True    | internal  | http://172.16.181.30:5000/v3/ |
| 7994062ddb4e45a19937a2a316a7b4f1 | RegionOne | keystone     | identity     | True    | public    | http://172.16.181.30:5000/v3/ |
| 81ef31c9948947428844667f203612ec | RegionOne | keystone     | identity     | True    | admin     | http://172.16.181.30:5000/v3/ |
| d80b188615ab4dd1af43c4f953e55c86 | RegionOne | glance       | image        | True    | admin     | http://172.16.181.30:9292     |
+----------------------------------+-----------+--------------+--------------+---------+-----------+-------------------------------+
```

## 10.3部署与配置glance

1.安装glance

在全部控制节点安装glance，以controller01节点为例

```bash
yum install openstack-glance -y

#备份Keystone配置文件
cp /etc/glance/glance-api.conf{,.bak}
egrep -v '^$|^#' /etc/glance/glance-api.conf.bak >/etc/glance/glance-api.conf
```

2.配置glance-api.conf

注意bind_host参数，根据不同节点修改;以controller01节点为例；

```bash
openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_host 172.16.181.31
openstack-config --set /etc/glance/glance-api.conf database connection  mysql+pymysql://glance:123456@172.16.181.30/glance
openstack-config --set /etc/glance/glance-api.conf glance_store stores file,http
openstack-config --set /etc/glance/glance-api.conf glance_store default_store file
openstack-config --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken www_authenticate_uri   http://172.16.181.30:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url  http://172.16.181.30:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name Default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name Default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_name  service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken password 123456
openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone
```

将配置文件拷贝到另外两个节点：

```bash
scp -rp /etc/glance/glance-api.conf controller02:/etc/glance/glance-api.conf
scp -rp /etc/glance/glance-api.conf controller03:/etc/glance/glance-api.conf

#在controller02
openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_host 172.16.181.32
#在controller03
openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_host 172.16.181.33
```

创建镜像存储目录并赋权限；在全部控制节点创建

/var/lib/glance/images是默认的存储目录

```bash
mkdir /var/lib/glance/images/
chown glance:nobody /var/lib/glance/images
```


3.同步glance数据库

任意控制节点操作；同步写入镜像数据库;忽略输出内容

```bash
su -s /bin/sh -c "glance-manage db_sync" glance
```

验证glance数据库是否正常写入

```bash
mysql -uglance -p123456 -e "use glance;show tables;"
```

4.启动服务

全部控制节点；

```bash
systemctl enable openstack-glance-api.service
systemctl restart openstack-glance-api.service
systemctl status openstack-glance-api.service

$ lsof -i:9292 
COMMAND      PID    USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
glance-ap 933834  glance   3u  IPv4  8918196   0t0  TCP controller01:armtechdaemon ..
glance-ap 933896  glance   3u  IPv4  8918196   0t0  TCP controller01:armtechdaemon ..
glance-ap 933897  glance   3u  IPv4  8918196   0t0  TCP controller01:armtechdaemon ..
haproxy   934346  haproxy  12u  IPv4 8921712   0t0  TCP myvip:armtechdaemon  ..
```

5.下载cirros镜像验证glance服务

在任意控制节点上;下载cirros镜像；格式指定为qcow2，bare；设置public权限；

镜像生成后，在指定的存储目录下生成以镜像id命名的镜像文件

```bash
source ~/.admin-openrc
wget -c http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img

openstack image create --file ~/cirros-0.5.1-x86_64-disk.img --disk-format qcow2 --container-format bare --public cirros-qcow2

$ openstack image list
+--------------------------------------+--------------+--------+
| ID                                   | Name         | Status |
+--------------------------------------+--------------+--------+
| b22a040d-bffd-4527-9f10-f9ac937a8df2 | cirros-qcow2 | active |
+--------------------------------------+--------------+--------+
```

6.添加pcs资源

在任意控制节点操作；添加资源openstack-glance-api；

```bash
$ pcs resource create openstack-glance-api systemd:openstack-glance-api clone interleave=true
$ pcs resource
 vip	(ocf::heartbeat:IPaddr2):	Started controller01
 Clone Set: lb-haproxy-clone [lb-haproxy]
     Started: [ controller01 ]
     Stopped: [ controller02 controller03 ]
 Clone Set: openstack-keystone-clone [openstack-keystone]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: openstack-glance-api-clone [openstack-glance-api]
     Started: [ controller01 controller02 controller03 ]
```



# 11.Placement放置服务部署

https://docs.openstack.org/placement/train/install/

Placement具体功能：
- 通过HTTP请求来跟踪和过滤资源
- 数据保存在本地数据库中
- 具备丰富的资源管理和筛选策略

## 11.1配置Placement数据库

在任意控制节点创建数据库，数据库自动同步，以controller01节点为例；

```bash
mysql -u root -p
CREATE DATABASE placement;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '123456';
flush privileges;
```

## 11.2创建placement-api

在任意控制节点操作，以controller01节点为例;

1.创建Placement服务用户

```bash
openstack user create --domain default --password=123456 placement
```

2.将Placement用户添加到服务项目并赋予admin权限

```bash
openstack role add --project service --user placement admin
```

3.创建placement API服务实体

```bash
openstack service create --name placement --description "Placement API" placement
```

4.创建placement API服务访问端点

```bash
openstack endpoint create --region RegionOne placement public http://172.16.181.30:8778
openstack endpoint create --region RegionOne placement internal http://172.16.181.30:8778
openstack endpoint create --region RegionOne placement admin http://172.16.181.30:8778
```

## 11.3安装placement软件包

在全部控制节点操作，以controller01节点为例；

```bash
yum install openstack-placement-api -y
```

1.修改配置文件

```bash
#备份Placement配置
cp /etc/placement/placement.conf /etc/placement/placement.conf.bak
grep -Ev '^$|#' /etc/placement/placement.conf.bak > /etc/placement/placement.conf

openstack-config --set /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:123456@172.16.181.30/placement
openstack-config --set /etc/placement/placement.conf api auth_strategy keystone
openstack-config --set /etc/placement/placement.conf keystone_authtoken auth_url  http://172.16.181.30:5000/v3
openstack-config --set /etc/placement/placement.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/placement/placement.conf keystone_authtoken auth_type password
openstack-config --set /etc/placement/placement.conf keystone_authtoken project_domain_name Default
openstack-config --set /etc/placement/placement.conf keystone_authtoken user_domain_name Default
openstack-config --set /etc/placement/placement.conf keystone_authtoken project_name service
openstack-config --set /etc/placement/placement.conf keystone_authtoken username placement
openstack-config --set /etc/placement/placement.conf keystone_authtoken password 123456

scp /etc/placement/placement.conf controller02:/etc/placement/
scp /etc/placement/placement.conf controller03:/etc/placement/
```

2.同步placement数据库

任意控制节点操作；同步写入镜像数据库;忽略输出内容

```bash
su -s /bin/sh -c "placement-manage db sync" placement
mysql -uroot -p123456 placement -e " show tables;"
```

## 11.4配置00-placement-api.conf

1.修改placement的apache配置文件

在全部控制节点操作，以controller01节点为例；注意根据不同节点修改监听地址；官方文档没有提到，如果不修改，计算服务检查时将会报错；

```bash
#备份00-Placement-api配置
##controller01上
cp /etc/httpd/conf.d/00-placement-api.conf{,.bak}
sed -i "s/Listen\ 8778/Listen\ 172.16.181.31:8778/g" /etc/httpd/conf.d/00-placement-api.conf
sed -i "s/*:8778/172.16.181.31:8778/g" /etc/httpd/conf.d/00-placement-api.conf

##controller02上
cp /etc/httpd/conf.d/00-placement-api.conf{,.bak}
sed -i "s/Listen\ 8778/Listen\ 172.16.181.32:8778/g" /etc/httpd/conf.d/00-placement-api.conf
sed -i "s/*:8778/172.16.181.32:8778/g" /etc/httpd/conf.d/00-placement-api.conf

##controller03上
cp /etc/httpd/conf.d/00-placement-api.conf{,.bak}
sed -i "s/Listen\ 8778/Listen\ 172.16.181.33:8778/g" /etc/httpd/conf.d/00-placement-api.conf
sed -i "s/*:8778/172.16.181.33:8778/g" /etc/httpd/conf.d/00-placement-api.conf
```

2.启用placement API访问

在全部控制节点操作;

```bash
...
  #SSLCertificateKeyFile ...
  <Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
  </Directory>
</VirtualHost>
...
```

3.重启apache服务

在全部控制节点操作；启动placement-api监听端口

```bash
$ systemctl restart httpd.service

$ netstat -lntup|grep 8778
$ lsof -i:8778

$ curl http://172.16.181.30:8778
{"versions": [{"status": "CURRENT", "min_version": "1.0", "max_version": "1.36", "id": "v1.0", "links": [{"href": "", "rel": "self"}]}]}
```

## 11.5验证检查Placement健康状态

```bash
$ placement-status upgrade check
+----------------------------------+
| Upgrade Check Results            |
+----------------------------------+
| Check: Missing Root Provider IDs |
| Result: Success                  |
| Details: None                    |
+----------------------------------+
| Check: Incomplete Consumers      |
| Result: Success                  |
| Details: None                    |
+----------------------------------+
```

## 11.6设置pcs资源

前面keystone已经设置过httpd的服务，因为placement也是使用httpd服务，因此不需要再重复设置

登陆haproxy的web界面查看已经添加成功




# 12.Nova控制节点集群部署

https://docs.openstack.org/nova/stein/install/

Nova具体功能如下：
1 实例生命周期管理
2 管理计算资源
3 网络和认证管理
4 REST风格的API
5 异步的一致性通信
6 Hypervisor透明：支持Xen,XenServer/XCP, KVM, UML, VMware vSphere and Hyper-V

## 12.1创建nova相关数据库

在任意控制节点创建数据库，数据库自动同步，以controller01节点为例；

```bash
#创建nova_api，nova和nova_cell0数据库并授权
mysql -uroot -p

CREATE DATABASE nova_api;
CREATE DATABASE nova;
CREATE DATABASE nova_cell0;

GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '123456';

GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '123456';

GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '123456';
flush privileges;
```

## 12.2创建nova相关服务凭证

在任意控制节点操作，以controller01节点为例；

1.创建nova用户

```bash
source ~/.admin-openrc
openstack user create --domain default --password 123456 nova
```

2.向nova用户赋予admin权限

```bash
openstack role add --project service --user nova admin
```

3.创建nova服务实体

```bash
openstack service create --name nova --description "OpenStack Compute" compute
```

4.创建Compute API服务端点

api地址统一采用vip，如果public/internal/admin分别设计使用不同的vip，请注意区分；

--region与初始化admin用户时生成的region一致；

```bash
openstack endpoint create --region RegionOne compute public http://172.16.181.30:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://172.16.181.30:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://172.16.181.30:8774/v2.1
```

## 12.3安装nova软件包

在全部控制节点安装nova相关服务，以controller01节点为例；

- nova-api（nova主服务）
- nova-scheduler（nova调度服务）
- nova-conductor（nova数据库服务，提供数据库访问）
- nova-novncproxy（nova的vnc服务，提供实例的控制台）

```bash
yum install openstack-nova-api openstack-nova-conductor openstack-nova-novncproxy openstack-nova-scheduler -y
```

## 12.4部署与配置

> https://docs.openstack.org/nova/stein/install/controller-install-rdo.html

在全部控制节点配置nova相关服务，以controller01节点为例；

注意my_ip参数，根据节点修改；注意nova.conf文件的权限：root:nova

```bash
#备份配置文件/etc/nova/nova.conf
cp -a /etc/nova/nova.conf{,.bak}
grep -Ev '^$|#' /etc/nova/nova.conf.bak > /etc/nova/nova.conf


openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis  osapi_compute,metadata
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip  172.16.181.31
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron  true
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver  nova.virt.firewall.NoopFirewallDriver

#rabbitmq的vip端口在haproxy中设置的为5673;暂不使用haproxy配置的rabbitmq；直接连接rabbitmq集群
#openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:123456@172.16.181.30:5673
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:123456@controller01:5672,openstack:123456@controller02:5672,openstack:123456@controller03:5672

openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_listen_port 8774
openstack-config --set /etc/nova/nova.conf DEFAULT metadata_listen_port 8775
openstack-config --set /etc/nova/nova.conf DEFAULT metadata_listen '$my_ip'
openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_listen '$my_ip'

openstack-config --set /etc/nova/nova.conf api auth_strategy  keystone
openstack-config --set /etc/nova/nova.conf api_database  connection  mysql+pymysql://nova:123456@172.16.181.30/nova_api

openstack-config --set /etc/nova/nova.conf cache backend oslo_cache.memcache_pool
openstack-config --set /etc/nova/nova.conf cache enabled True
openstack-config --set /etc/nova/nova.conf cache memcache_servers controller01:11211,controller02:11211,controller03:11211

openstack-config --set /etc/nova/nova.conf database connection  mysql+pymysql://nova:123456@172.16.181.30/nova

openstack-config --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri  http://172.16.181.30:5000/v3
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url  http://172.16.181.30:5000/v3
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers  controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type  password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name  Default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name  Default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name  service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username  nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password  123456

openstack-config --set /etc/nova/nova.conf vnc enabled  true
openstack-config --set /etc/nova/nova.conf vnc server_listen  '$my_ip'
openstack-config --set /etc/nova/nova.conf vnc server_proxyclient_address  '$my_ip'
openstack-config --set /etc/nova/nova.conf vnc novncproxy_host '$my_ip'
openstack-config --set /etc/nova/nova.conf vnc novncproxy_port  6080

openstack-config --set /etc/nova/nova.conf glance  api_servers  http://172.16.181.30:9292

openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path  /var/lib/nova/tmp

openstack-config --set /etc/nova/nova.conf placement region_name  RegionOne
openstack-config --set /etc/nova/nova.conf placement project_domain_name  Default
openstack-config --set /etc/nova/nova.conf placement project_name  service
openstack-config --set /etc/nova/nova.conf placement auth_type  password
openstack-config --set /etc/nova/nova.conf placement user_domain_name  Default
openstack-config --set /etc/nova/nova.conf placement auth_url  http://172.16.181.30:5000/v3
openstack-config --set /etc/nova/nova.conf placement username  placement
openstack-config --set /etc/nova/nova.conf placement password  123456
```

注意！！！

```bash
# 前端采用haproxy时，服务连接rabbitmq会出现连接超时重连的情况，可通过各服务与rabbitmq的日志查看；
# transport_url=rabbit://openstack:123456*@172.16.181.30:5672
# rabbitmq本身具备集群机制，官方文档建议直接连接rabbitmq集群；但采用此方式时服务启动有时会报错，原因不明；如果没有此现象，建议连接rabbitmq直接对接集群而非通过前端haproxy的vip+端口
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:123456@controller01:5672,openstack:123456@controller02:5672,openstack:123456@controller03:5672
```

将nova的配置文件拷贝到另外的控制节点上：

```bash
scp -rp /etc/nova/nova.conf controller02:/etc/nova/
scp -rp /etc/nova/nova.conf controller03:/etc/nova/

##controller02上
sed -i "s#172.16.181.31#172.16.181.32#g" /etc/nova/nova.conf

##controller03上
sed -i "s#172.16.181.31#172.16.181.33#g" /etc/nova/nova.conf
```

## 12.5同步nova相关数据库并验证

任意控制节点操作；填充nova-api数据库

```bash
#填充nova-api数据库,无输出
#填充cell0数据库,无输出
#创建cell1表
#同步nova数据库
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
```

验证nova cell0和cell1是否正确注册

```bash
$ su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
+-------+--------------------------------------+-------------------------------------------+----------------------------------------------------+----------+
|  Name |                 UUID                 |               Transport URL               |                Database Connection                 | Disabled |
+-------+--------------------------------------+-------------------------------------------+----------------------------------------------------+----------+
| cell0 | 00000000-0000-0000-0000-000000000000 |                   none:/                  | mysql+pymysql://nova:****@172.16.181.30/nova_cell0 |  False   |
| cell1 | 2c3f1c9b-b2fd-47bd-8ec5-ea5ae355ac28 | rabbit://openstack:****@controller03:5672 |    mysql+pymysql://nova:****@172.16.181.30/nova    |  False   |
+-------+--------------------------------------+-------------------------------------------+----------------------------------------------------+----------+
```

验证nova数据库是否正常写入

```bash
mysql -h controller01 -u nova -p123456 -e "use nova_api;show tables;"
mysql -h controller01 -u nova -p123456 -e "use nova;show tables;"
mysql -h controller01 -u nova -p123456 -e "use nova_cell0;show tables;"
```

## 12.6启动nova服务，并配置开机启动

在全部控制节点操作，以controller01节点为例；

```bash
systemctl enable openstack-nova-api.service 
systemctl enable openstack-nova-scheduler.service 
systemctl enable openstack-nova-conductor.service 
systemctl enable openstack-nova-novncproxy.service

systemctl restart openstack-nova-api.service 
systemctl restart openstack-nova-scheduler.service 
systemctl restart openstack-nova-conductor.service 
systemctl restart openstack-nova-novncproxy.service

systemctl status openstack-nova-api.service 
systemctl status openstack-nova-scheduler.service 
systemctl status openstack-nova-conductor.service 
systemctl status openstack-nova-novncproxy.service


netstat -tunlp | egrep '8774|8775|8778|6080'
$ curl http://172.16.181.30:8774
{"versions": [{"status": "SUPPORTED", "updated": "2011-01-21T11:33:21Z", "links": [{"href": "http://172.16.181.30:8774/v2/", "rel": "self"}], "min_version": "", "version": "", "id": "v2.0"}, {"status": "CURRENT", "updated": "2013-07-23T11:33:21Z", "links": [{"href": "http://172.16.181.30:8774/v2.1/", "rel": "self"}], "min_version": "2.1", "version": "2.79", "id": "v2.1"}]}
```

## 12.7验证

列出各服务控制组件，查看状态；

```bash
$ openstack compute service list
+-----+----------------+--------------+----------+---------+-------+----------------------------+
|  ID | Binary         | Host         | Zone     | Status  | State | Updated At                 |
+-----+----------------+--------------+----------+---------+-------+----------------------------+
| 109 | nova-scheduler | controller01 | internal | enabled | up    | 2022-10-11T04:10:18.000000 |
| 133 | nova-conductor | controller01 | internal | enabled | up    | 2022-10-11T04:10:21.000000 |
| 151 | nova-scheduler | controller03 | internal | enabled | up    | 2022-10-11T04:10:12.000000 |
| 175 | nova-scheduler | controller02 | internal | enabled | up    | 2022-10-11T04:10:14.000000 |
| 199 | nova-conductor | controller03 | internal | enabled | up    | 2022-10-11T04:10:16.000000 |
| 211 | nova-conductor | controller02 | internal | enabled | up    | 2022-10-11T04:10:19.000000 |
+-----+----------------+--------------+----------+---------+-------+----------------------------+
```

展示api端点;

```bash
$ openstack catalog list
+-----------+-----------+--------------------------------------------+
| Name      | Type      | Endpoints                                  |
+-----------+-----------+--------------------------------------------+
| keystone  | identity  | RegionOne                                  |
|           |           |   internal: http://172.16.181.30:5000/v3/  |
|           |           | RegionOne                                  |
|           |           |   public: http://172.16.181.30:5000/v3/    |
|           |           | RegionOne                                  |
|           |           |   admin: http://172.16.181.30:5000/v3/     |
|           |           |                                            |
| placement | placement | RegionOne                                  |
|           |           |   admin: http://172.16.181.30:8778         |
|           |           | RegionOne                                  |
|           |           |   public: http://172.16.181.30:8778        |
|           |           | RegionOne                                  |
|           |           |   internal: http://172.16.181.30:8778      |
|           |           |                                            |
| nova      | compute   | RegionOne                                  |
|           |           |   admin: http://172.16.181.30:8774/v2.1    |
|           |           | RegionOne                                  |
|           |           |   public: http://172.16.181.30:8774/v2.1   |
|           |           | RegionOne                                  |
|           |           |   internal: http://172.16.181.30:8774/v2.1 |
|           |           |                                            |
| glance    | image     | RegionOne                                  |
|           |           |   internal: http://172.16.181.30:9292      |
|           |           | RegionOne                                  |
|           |           |   public: http://172.16.181.30:9292        |
|           |           | RegionOne                                  |
|           |           |   admin: http://172.16.181.30:9292         |
|           |           |                                            |
+-----------+-----------+--------------------------------------------+
```

检查cell与placement api；都为success为正常

```bash
$ nova-status upgrade check
+--------------------------------------------------------------------+
| Upgrade Check Results                                              |
+--------------------------------------------------------------------+
| Check: Cells v2                                                    |
| Result: Success                                                    |
| Details: No host mappings or compute nodes were found. Remember to |
|   run command 'nova-manage cell_v2 discover_hosts' when new        |
|   compute hosts are deployed.                                      |
+--------------------------------------------------------------------+
| Check: Placement API                                               |
| Result: Success                                                    |
| Details: None                                                      |
+--------------------------------------------------------------------+
| Check: Ironic Flavor Migration                                     |
| Result: Success                                                    |
| Details: None                                                      |
+--------------------------------------------------------------------+
| Check: Cinder API                                                  |
| Result: Success                                                    |
| Details: None                                                      |
+--------------------------------------------------------------------+
```


## 12.8设置pcs资源

在任意控制节点操作；添加资源openstack-nova-api，openstack-nova-consoleauth，openstack-nova-scheduler，openstack-nova-conductor与openstack-nova-novncproxy

```bash
pcs resource create openstack-nova-api systemd:openstack-nova-api clone interleave=true
pcs resource create openstack-nova-scheduler systemd:openstack-nova-scheduler clone interleave=true
pcs resource create openstack-nova-conductor systemd:openstack-nova-conductor clone interleave=true
pcs resource create openstack-nova-novncproxy systemd:openstack-nova-novncproxy clone interleave=true

#建议openstack-nova-api，openstack-nova-conductor与openstack-nova-novncproxy 等无状态服务以active/active模式运行；
#openstack-nova-scheduler等服务以active/passive模式运行
```

查看pcs资源

```bash
$ pcs resource
 vip	(ocf::heartbeat:IPaddr2):	Started controller01
 Clone Set: lb-haproxy-clone [lb-haproxy]
     Started: [ controller01 ]
     Stopped: [ controller02 controller03 ]
 Clone Set: openstack-keystone-clone [openstack-keystone]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: openstack-glance-api-clone [openstack-glance-api]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: openstack-nova-api-clone [openstack-nova-api]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: openstack-nova-scheduler-clone [openstack-nova-scheduler]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: openstack-nova-conductor-clone [openstack-nova-conductor]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: openstack-nova-novncproxy-clone [openstack-nova-novncproxy]
     Started: [ controller01 controller02 controller03 ]
```


---

# 13.Nova计算节点集群部署

172.16.181.34 compute01
172.16.181.35 compute02
172.16.181.36 compute03


## 13.1安装nova-compute

在全部计算节点安装nova-compute服务，以compute01节点为例；

```bash
#在基础配置时已经下载好了openstack的源和需要的依赖，所以直接下载需要的服务组件即可
yum install qpid-proton-c-0.26.0-2.el7.x86_64
yum install -y openstack-utils -y

yum install openstack-nova-compute -y
```

## 13.2部署与配置

在全部计算节点安装nova-compute服务，以compute01节点为例；

注意my_ip参数，根据节点修改；注意nova.conf文件的权限：root:nova

```bash
#备份配置文件/etc/nova/nova.confcp /etc/nova/nova.conf{,.bak}
cp /etc/nova/nova.conf{,.bak}
grep -Ev '^$|#' /etc/nova/nova.conf.bak > /etc/nova/nova.conf
```

1.确定计算节点是否支持虚拟机硬件加速

```bash
$ egrep -c '(vmx|svm)' /proc/cpuinfo
0
# 如果此命令返回值不是0，则计算节点支持硬件加速，不需要加入下面的配置。
# 如果此命令返回值是0，则计算节点不支持硬件加速，并且必须配置libvirt为使用QEMU而不是KVM
# 需要编辑/etc/nova/nova.conf 配置中的[libvirt]部分：因测试使用为虚拟机，所以修改为qemu
```

2.编辑配置文件nova.conf

```bash
openstack-config --set  /etc/nova/nova.conf DEFAULT enabled_apis  osapi_compute,metadata
openstack-config --set  /etc/nova/nova.conf DEFAULT transport_url  rabbit://openstack:123456@172.16.181.30
openstack-config --set  /etc/nova/nova.conf DEFAULT my_ip 172.16.181.34
openstack-config --set  /etc/nova/nova.conf DEFAULT use_neutron  true
openstack-config --set  /etc/nova/nova.conf DEFAULT firewall_driver  nova.virt.firewall.NoopFirewallDriver

openstack-config --set  /etc/nova/nova.conf api auth_strategy  keystone

openstack-config --set /etc/nova/nova.conf  keystone_authtoken www_authenticate_uri  http://172.16.181.30:5000
openstack-config --set  /etc/nova/nova.conf keystone_authtoken auth_url  http://172.16.181.30:5000
openstack-config --set  /etc/nova/nova.conf keystone_authtoken memcached_servers  controller01:11211,controller02:11211,controller03:11211
openstack-config --set  /etc/nova/nova.conf keystone_authtoken auth_type  password
openstack-config --set  /etc/nova/nova.conf keystone_authtoken project_domain_name  Default
openstack-config --set  /etc/nova/nova.conf keystone_authtoken user_domain_name  Default
openstack-config --set  /etc/nova/nova.conf keystone_authtoken project_name  service
openstack-config --set  /etc/nova/nova.conf keystone_authtoken username  nova
openstack-config --set  /etc/nova/nova.conf keystone_authtoken password  123456

openstack-config --set /etc/nova/nova.conf libvirt virt_type  qemu

openstack-config --set  /etc/nova/nova.conf vnc enabled  true
openstack-config --set  /etc/nova/nova.conf vnc server_listen  0.0.0.0
openstack-config --set  /etc/nova/nova.conf vnc server_proxyclient_address  '$my_ip'
openstack-config --set  /etc/nova/nova.conf vnc novncproxy_base_url http://172.16.181.30:6080/vnc_auto.html

openstack-config --set  /etc/nova/nova.conf glance api_servers  http://172.16.181.30:9292

openstack-config --set  /etc/nova/nova.conf oslo_concurrency lock_path  /var/lib/nova/tmp

openstack-config --set  /etc/nova/nova.conf placement region_name  RegionOne
openstack-config --set  /etc/nova/nova.conf placement project_domain_name  Default
openstack-config --set  /etc/nova/nova.conf placement project_name  service
openstack-config --set  /etc/nova/nova.conf placement auth_type  password
openstack-config --set  /etc/nova/nova.conf placement user_domain_name  Default
openstack-config --set  /etc/nova/nova.conf placement auth_url  http://172.16.181.30:5000/v3
openstack-config --set  /etc/nova/nova.conf placement username  placement
openstack-config --set  /etc/nova/nova.conf placement password  123456
```

3.将nova的配置文件拷贝到另外的计算节点上：

```bash
scp -rp /etc/nova/nova.conf compute02:/etc/nova/
scp -rp /etc/nova/nova.conf compute03:/etc/nova/

##compute02上
sed -i "s#172.16.181.34#172.16.181.35#g" /etc/nova/nova.conf

##compute03上
sed -i "s#172.16.181.34#172.16.181.36#g" /etc/nova/nova.conf
```


## 13.3启动计算节点的nova服务

全部计算节点操作；

```bash
systemctl restart libvirtd.service openstack-nova-compute.service
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl status libvirtd.service openstack-nova-compute.service
```

## 13.4向cell数据库添加计算节点

任意控制节点执行；查看计算节点列表

```bash
$ openstack compute service list --service nova-compute
+-----+--------------+-----------+------+---------+-------+----------------------------+
|  ID | Binary       | Host      | Zone | Status  | State | Updated At                 |
+-----+--------------+-----------+------+---------+-------+----------------------------+
| 220 | nova-compute | compute01 | nova | enabled | up    | 2022-10-11T09:12:10.000000 |
| 223 | nova-compute | compute02 | nova | enabled | up    | 2022-10-11T09:12:10.000000 |
| 226 | nova-compute | compute03 | nova | enabled | up    | 2022-10-11T09:12:10.000000 |
+-----+--------------+-----------+------+---------+-------+----------------------------+
```

## 13.5控制节点上发现计算主机

添加每台新的计算节点时，必须在控制器节点上运行

1.手动发现计算节点

```bash
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
```

2.自动发现计算节点

为避免新加入计算节点时，手动执行注册操作nova-manage cell_v2 discover_hosts，可设置控制节点定时自动发现主机；涉及控制节点nova.conf文件的[scheduler]字段；
在全部控制节点操作；设置自动发现时间为10min，可根据实际环境调节

```bash
openstack-config --set  /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 600
systemctl restart openstack-nova-api.service
```

## 13.6验证

列出服务组件以验证每个进程的成功启动和注册情况

```bash
$ openstack compute service list
+-----+----------------+--------------+----------+---------+-------+----------------------------+
|  ID | Binary         | Host         | Zone     | Status  | State | Updated At                 |
+-----+----------------+--------------+----------+---------+-------+----------------------------+
| 109 | nova-scheduler | controller01 | internal | enabled | up    | 2022-10-11T09:12:55.000000 |
| 133 | nova-conductor | controller01 | internal | enabled | up    | 2022-10-11T09:12:47.000000 |
| 151 | nova-scheduler | controller03 | internal | enabled | up    | 2022-10-11T09:12:50.000000 |
| 175 | nova-scheduler | controller02 | internal | enabled | up    | 2022-10-11T09:12:52.000000 |
| 199 | nova-conductor | controller03 | internal | enabled | up    | 2022-10-11T09:12:55.000000 |
| 211 | nova-conductor | controller02 | internal | enabled | up    | 2022-10-11T09:12:48.000000 |
| 220 | nova-compute   | compute01    | nova     | enabled | up    | 2022-10-11T09:12:50.000000 |
| 223 | nova-compute   | compute02    | nova     | enabled | up    | 2022-10-11T09:12:50.000000 |
| 226 | nova-compute   | compute03    | nova     | enabled | up    | 2022-10-11T09:12:50.000000 |
+-----+----------------+--------------+----------+---------+-------+----------------------------+
```

列出身份服务中的API端点以验证与身份服务的连接

```bash
$ openstack catalog list
+-----------+-----------+--------------------------------------------+
| Name      | Type      | Endpoints                                  |
+-----------+-----------+--------------------------------------------+
| keystone  | identity  | RegionOne                                  |
|           |           |   internal: http://172.16.181.30:5000/v3/  |
|           |           | RegionOne                                  |
|           |           |   public: http://172.16.181.30:5000/v3/    |
|           |           | RegionOne                                  |
|           |           |   admin: http://172.16.181.30:5000/v3/     |
|           |           |                                            |
| placement | placement | RegionOne                                  |
|           |           |   admin: http://172.16.181.30:8778         |
|           |           | RegionOne                                  |
|           |           |   public: http://172.16.181.30:8778        |
|           |           | RegionOne                                  |
|           |           |   internal: http://172.16.181.30:8778      |
|           |           |                                            |
| nova      | compute   | RegionOne                                  |
|           |           |   admin: http://172.16.181.30:8774/v2.1    |
|           |           | RegionOne                                  |
|           |           |   public: http://172.16.181.30:8774/v2.1   |
|           |           | RegionOne                                  |
|           |           |   internal: http://172.16.181.30:8774/v2.1 |
|           |           |                                            |
| glance    | image     | RegionOne                                  |
|           |           |   internal: http://172.16.181.30:9292      |
|           |           | RegionOne                                  |
|           |           |   public: http://172.16.181.30:9292        |
|           |           | RegionOne                                  |
|           |           |   admin: http://172.16.181.30:9292         |
|           |           |                                            |
+-----------+-----------+--------------------------------------------+
```

列出图像服务中的图像以验证与图像服务的连接性

```bash
$ openstack image list
+--------------------------------------+--------------+--------+
| ID                                   | Name         | Status |
+--------------------------------------+--------------+--------+
| eb05b5b5-ffff-4db5-a6dc-42b3668484d1 | cirros-qcow2 | active |
+--------------------------------------+--------------+--------+
```

检查Cells和placement API是否正常运行

```bash
$ nova-status upgrade check
+------------------------------------------------------------------+
| Upgrade Check Results                                            |
+------------------------------------------------------------------+
| Check: Cells v2                                                  |
| Result: Failure                                                  |
| Details: No host mappings found but there are compute nodes. Run |
|   command 'nova-manage cell_v2 simple_cell_setup' and then       |
|   retry.                                                         |
+------------------------------------------------------------------+
| Check: Placement API                                             |
| Result: Success                                                  |
| Details: None                                                    |
+------------------------------------------------------------------+
| Check: Ironic Flavor Migration                                   |
| Result: Success                                                  |
| Details: None                                                    |
+------------------------------------------------------------------+
| Check: Cinder API                                                |
| Result: Success                                                  |
| Details: None                                                    |
+------------------------------------------------------------------+
```


---

# 14.Neutron控制节点集群部署

https://docs.openstack.org/neutron/train/install/install-rdo.html

Neutron网络的博客:https://blog.51cto.com/u_11555417/2438097

Nova具体功能如下：
- Neutron 为整个 OpenStack 环境提供网络支持，包括二层交换，三层路由，负载均衡，防火墙和 VPN 等。
- Neutron 提供了一个灵活的框架，通过配置，无论是开源还是商业软件都可以被用来实现这些功能。


## 14.1创建nova相关数据库（控制节点）

在任意控制节点创建数据库，数据库自动同步，以controller01节点为例；

```bash
mysql -u root -p123456
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '123456';
flush privileges;
```

## 14.2创建neutron相关服务凭证(控制节点)

在任意控制节点操作，以controller01节点为例；

1.创建neutron用户

```bash
source ~/.admin-openrc
openstack user create --domain default --password 123456 neutron
```

2.向neutron用户赋予admin权限

```bash
openstack role add --project service --user neutron admin
```

3.创建neutron服务实体

```bash
openstack service create --name neutron --description "OpenStack Networking" network
```

4.创建neutron API服务端点

api地址统一采用vip，如果public/internal/admin分别设计使用不同的vip，请注意区分；

--region与初始化admin用户时生成的region一致；neutron-api 服务类型为network；

```bash
openstack endpoint create --region RegionOne network public http://172.16.181.30:9696
openstack endpoint create --region RegionOne network internal http://172.16.181.30:9696
openstack endpoint create --region RegionOne network admin http://172.16.181.30:9696
```


## 14.3安装Neutron server（控制节点)

提供商网络：https://docs.openstack.org/neutron/train/install/controller-install-option1-rdo.html
租户服务网络：https://docs.openstack.org/neutron/train/install/controller-install-option2-rdo.html

- openstack-neutron：neutron-server的包
- openstack-neutron-ml2：ML2 plugin的包
- openstack-neutron-linuxbridge：linux bridge network provider相关的包
- ebtables：防火墙相关的包
- conntrack-tools： 该模块可以对iptables进行状态数据包检查

这里将neutron server与neutron agent分离，所以采取这样的部署方式，常规的控制节点部署所有neutron的应用包括agent，计算节点部署只部署以下的neutron server、linuxbridge和nova配置即可；三台计算节点现在相当于neutron节点

在全部控制节点安装neutron相关服务，以controller01节点为例；

```bash
#yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables -y

yum install openstack-neutron openstack-neutron-ml2 ebtables -y
yum install conntrack-tools -y
yum install -y libibverbs
```


## 14.4部署与配置（控制节点)

https://docs.openstack.org/neutron/train/install/controller-install-rdo.html

在全部控制节点配置neutron相关服务，以controller01节点为例；

1.配置neutron.conf

注意my_ip参数，根据节点修改；注意neutron.conf文件的权限：root:neutron

注意bind_host参数，根据节点修改；

```bash
#备份配置文件/etc/nova/nova.conf
cp -a /etc/neutron/neutron.conf{,.bak}
grep -Ev '^$|#' /etc/neutron/neutron.conf.bak > /etc/neutron/neutron.conf


openstack-config --set  /etc/neutron/neutron.conf DEFAULT bind_host 172.16.181.31
openstack-config --set  /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set  /etc/neutron/neutron.conf DEFAULT service_plugins router
openstack-config --set  /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true

#直接连接rabbitmq集群
openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:123456@controller01:5672,openstack:123456@controller02:5672,openstack:123456@controller03:5672
openstack-config --set  /etc/neutron/neutron.conf DEFAULT auth_strategy  keystone
openstack-config --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes  true
openstack-config --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes  true

#启用l3 ha功能
openstack-config --set  /etc/neutron/neutron.conf DEFAULT l3_ha True

#最多在几个l3 agent上创建ha router
openstack-config --set  /etc/neutron/neutron.conf DEFAULT max_l3_agents_per_router 3

#可创建ha router的最少正常运行的l3 agnet数量
openstack-config --set  /etc/neutron/neutron.conf DEFAULT min_l3_agents_per_router 2

#dhcp高可用，在3个网络节点各生成1个dhcp服务器
openstack-config --set  /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network 3

openstack-config --set  /etc/neutron/neutron.conf database connection  mysql+pymysql://neutron:123456@172.16.181.30/neutron

openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri  http://172.16.181.30:5000
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken auth_url  http://172.16.181.30:5000
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken memcached_servers  controller01:11211,controller02:11211,controller03:11211
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken auth_type  password
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken project_domain_name  default
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken user_domain_name  default
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken project_name  service
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken username  neutron
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken password  123456

openstack-config --set  /etc/neutron/neutron.conf nova  auth_url http://172.16.181.30:5000
openstack-config --set  /etc/neutron/neutron.conf nova  auth_type password
openstack-config --set  /etc/neutron/neutron.conf nova  project_domain_name default
openstack-config --set  /etc/neutron/neutron.conf nova  user_domain_name default
openstack-config --set  /etc/neutron/neutron.conf nova  region_name RegionOne
openstack-config --set  /etc/neutron/neutron.conf nova  project_name service
openstack-config --set  /etc/neutron/neutron.conf nova  username nova
openstack-config --set  /etc/neutron/neutron.conf nova  password 123456

openstack-config --set  /etc/neutron/neutron.conf oslo_concurrency lock_path  /var/lib/neutron/tmp
```

将neutron.conf配置文件拷贝到另外的控制节点上：

```bash
scp -rp /etc/neutron/neutron.conf controller02:/etc/neutron/
scp -rp /etc/neutron/neutron.conf controller03:/etc/neutron/

##controller02上
sed -i "s#172.16.181.31#172.16.181.32#g" /etc/neutron/neutron.conf

##controller03上
sed -i "s#172.16.181.31#172.16.181.33#g" /etc/neutron/neutron.conf
```

2.配置 ml2_conf.ini

在全部控制节点操作，以controller01节点为例；

```bash
#备份配置文件
cp -a /etc/neutron/plugins/ml2/ml2_conf.ini{,.bak}
grep -Ev '^$|#' /etc/neutron/plugins/ml2/ml2_conf.ini.bak > /etc/neutron/plugins/ml2/ml2_conf.ini

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers  flat,vlan,vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers  linuxbridge,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers  port_security
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks  provider
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset  true
```

将ml2_conf.ini配置文件拷贝到另外的控制节点上：

```bash
scp -rp /etc/neutron/plugins/ml2/ml2_conf.ini controller02:/etc/neutron/plugins/ml2/ml2_conf.ini
scp -rp /etc/neutron/plugins/ml2/ml2_conf.ini controller03:/etc/neutron/plugins/ml2/ml2_conf.ini
```

3.配置nova服务与neutron服务进行交互

全部控制节点执行；

```bash
#修改配置文件/etc/nova/nova.conf
#在全部控制节点上配置nova服务与网络节点服务进行交互
openstack-config --set  /etc/nova/nova.conf neutron url  http://172.16.181.30:9696
openstack-config --set  /etc/nova/nova.conf neutron auth_url  http://172.16.181.30:5000
openstack-config --set  /etc/nova/nova.conf neutron auth_type  password
openstack-config --set  /etc/nova/nova.conf neutron project_domain_name  default
openstack-config --set  /etc/nova/nova.conf neutron user_domain_name  default
openstack-config --set  /etc/nova/nova.conf neutron region_name  RegionOne
openstack-config --set  /etc/nova/nova.conf neutron project_name  service
openstack-config --set  /etc/nova/nova.conf neutron username  neutron
openstack-config --set  /etc/nova/nova.conf neutron password  123456
openstack-config --set  /etc/nova/nova.conf neutron service_metadata_proxy  true
openstack-config --set  /etc/nova/nova.conf neutron metadata_proxy_shared_secret  123456
```

4.同步nova相关数据库并验证

任意控制节点操作；填充neutron数据库

```bash
$ su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
```

验证neutron数据库是否正常写入

```bash
mysql -h controller01 -u neutron -p123456 -e "use neutron;show tables;"
```


5.创建ml2的软连接 文件指向ML2插件配置的软链接

全部控制节点执行；

```bash
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
```

6.重启nova-api和neutron-server服务

全部控制节点执行；

```bash
systemctl restart openstack-nova-api.service
systemctl status openstack-nova-api.service

systemctl enable neutron-server.service
systemctl restart neutron-server.service
systemctl status neutron-server.service
```


---
# 15.Neutron计算节点集群部署

## 15.1安装Neutron agent（计算节点=网络节点)

由于这里部署为neutron server与neutron agent分离，所以采取这样的部署方式，常规的控制节点部署所有neutron的应用包括server和agent；

计算节点部署neutron agent、linuxbridge和nova配置即可；也可以单独准备网络节点进行neutron agent的部署；

在全部计算节点安装，以compute01节点为例；

```bash
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables -y
yum install -y libibverbs

#备份配置文件/etc/nova/nova.conf
cp -a /etc/neutron/neutron.conf{,.bak}
grep -Ev '^$|#' /etc/neutron/neutron.conf.bak > /etc/neutron/neutron.conf


openstack-config --set  /etc/neutron/neutron.conf DEFAULT bind_host 172.16.181.34
openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:123456@controller01:5672,openstack:123456@controller02:5672,openstack:123456@controller03:5672
openstack-config --set  /etc/neutron/neutron.conf DEFAULT auth_strategy keystone 
#配置RPC的超时时间，默认为60s,可能导致超时异常.设置为180s
openstack-config --set  /etc/neutron/neutron.conf DEFAULT rpc_response_timeout 180

openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://172.16.181.30:5000
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken auth_url http://172.16.181.30:5000
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set  /etc/neutron/neutron.conf keystone_authtoken password 123456

openstack-config --set  /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp
```

将neutron.conf配置文件拷贝到另外的计算节点上：

```bash
scp -rp /etc/neutron/neutron.conf compute02:/etc/neutron/
scp -rp /etc/neutron/neutron.conf compute03:/etc/neutron/

##compute02上
sed -i "s#172.16.181.34#172.16.181.35#g" /etc/neutron/neutron.conf

##compute03上
sed -i "s#172.16.181.34#172.16.181.36#g" /etc/neutron/neutron.conf
```


## 15.2部署与配置(计算节点)

1.配置nova.conf

在全部计算节点操作；配置只涉及nova.conf的[neutron]字段

```bash
openstack-config --set  /etc/nova/nova.conf neutron url http://172.16.181.30:9696
openstack-config --set  /etc/nova/nova.conf neutron auth_url http://172.16.181.30:5000
openstack-config --set  /etc/nova/nova.conf neutron auth_type password
openstack-config --set  /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set  /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set  /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set  /etc/nova/nova.conf neutron project_name service
openstack-config --set  /etc/nova/nova.conf neutron username neutron
openstack-config --set  /etc/nova/nova.conf neutron password 123456
```

2.配置ml2_conf.ini

在全部计算节点操作，以compute01节点为例；

```bash
#备份配置文件
cp -a /etc/neutron/plugins/ml2/ml2_conf.ini{,.bak}
grep -Ev '^$|#' /etc/neutron/plugins/ml2/ml2_conf.ini.bak > /etc/neutron/plugins/ml2/ml2_conf.ini

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers  flat,vlan,vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers  linuxbridge,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers  port_security
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks  provider
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset  true
```

3.配置linuxbridge_agent.ini

- Linux网桥代理
- Linux网桥代理为实例构建第2层（桥接和交换）虚拟网络基础结构并处理安全组
- 网络类型名称与物理网卡对应，这里提供商网络provider对应规划的ens192网卡，vlan租户网络对应规划的ens224网卡，在创建相应网络时采用的是网络名称而非网卡名称；
- 需要明确的是物理网卡是本地有效，根据主机实际使用的网卡名确定；

在全部计算节点操作，以compute01节点为例；

```bash
#备份配置文件
cp -a /etc/neutron/plugins/ml2/linuxbridge_agent.ini{,.bak}
grep -Ev '^$|#' /etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak >/etc/neutron/plugins/ml2/linuxbridge_agent.ini

#环境无法提供四张网卡；建议生产环境上将每种网络分开配置
#provider网络对应规划的eth0
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings  provider:eth0

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true

#tunnel租户网络（vxlan）vtep端点，这里对应规划的eth0地址，根据节点做相应修改
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip 172.16.181.34

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population true
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group  true
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver  neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
```

将 linuxbridge_agent.ini 配置文件拷贝到另外的计算节点上：

```bash
scp -rp /etc/neutron/plugins/ml2/linuxbridge_agent.ini  compute02:/etc/neutron/plugins/ml2/
scp -rp /etc/neutron/plugins/ml2/linuxbridge_agent.ini  compute03:/etc/neutron/plugins/ml2/

##compute02上
sed -i "s#10.15.253.162#10.15.253.194#g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini 

##compute03上
sed -i "s#10.15.253.162#10.15.253.226#g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
```

4.配置 l3_agent.ini

l3代理为租户虚拟网络提供路由和NAT服务

在全部计算节点操作，以compute01节点为例；

```bash
#备份配置文件
cp -a /etc/neutron/l3_agent.ini{,.bak}
grep -Ev '^$|#' /etc/neutron/l3_agent.ini.bak > /etc/neutron/l3_agent.ini

openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver linuxbridge
```

5.配置dhcp_agent.ini

DHCP代理，DHCP代理为虚拟网络提供DHCP服务;
使用dnsmasp提供dhcp服务；

在全部计算节点操作，以compute01节点为例；

```bash
#备份配置文件
cp -a /etc/neutron/dhcp_agent.ini{,.bak}
grep -Ev '^$|#' /etc/neutron/dhcp_agent.ini.bak > /etc/neutron/dhcp_agent.ini

openstack-config --set  /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
openstack-config --set  /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set  /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true

```

6.配置metadata_agent.ini

元数据代理提供配置信息，例如实例的凭据
metadata_proxy_shared_secret 的密码与控制节点上/etc/nova/nova.conf文件中密码一致；

在全部计算节点操作，以compute01节点为例；

```bash
#备份配置文件
cp -a /etc/neutron/metadata_agent.ini{,.bak}
grep -Ev '^$|#' /etc/neutron/metadata_agent.ini.bak > /etc/neutron/metadata_agent.ini

openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host 172.16.181.30
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret 123456
openstack-config --set /etc/neutron/metadata_agent.ini cache memcache_servers controller01:11211,controller02:11211,controller03:11211

```

7.添加linux内核参数设置

确保Linux操作系统内核支持网桥过滤器，通过验证所有下列sysctl值设置为1；

全部控制节点和计算节点配置；

```bash
echo 'net.ipv4.ip_nonlocal_bind = 1' >>/etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-iptables=1' >>/etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables=1'  >>/etc/sysctl.conf

#启用网络桥接器支持，需要加载 br_netfilter 内核模块；否则会提示没有目录
modprobe br_netfilter
sysctl -p
```


8.重启nova-api和neutron-gaent服务

全部计算节点；重启nova-compute服务

```bash
systemctl restart openstack-nova-compute.service
```

全部计算节点；启动neutron-agent服务和l3网络服务

```bash
systemctl enable neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent neutron-l3-agent
systemctl restart neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent neutron-l3-agent
systemctl status neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent neutron-l3-agent
```

## 15.3neutron服务验证（控制节点）

```bash
#列出已加载的扩展，以验证该neutron-server过程是否成功启动
$ openstack extension list --network

#列出代理商以验证成功
$ openstack network agent list
+--------------------------------------+--------------------+-----------+-------------------+-------+-------+---------------------------+
| ID                                   | Agent Type         | Host      | Availability Zone | Alive | State | Binary                    |
+--------------------------------------+--------------------+-----------+-------------------+-------+-------+---------------------------+
| 00cf2a53-7bb4-4430-afe6-b61b03714714 | Linux bridge agent | compute02 | None              | :-)   | UP    | neutron-linuxbridge-agent |
| 057a1280-f407-4104-92d9-b94076dde560 | Metadata agent     | compute01 | None              | :-)   | UP    | neutron-metadata-agent    |
| 0d0ad03b-91eb-4a31-97ae-ea444bf63799 | DHCP agent         | compute03 | nova              | :-)   | UP    | neutron-dhcp-agent        |
| 4f962e3c-3a01-471a-9a2b-ebea1945440e | Linux bridge agent | compute01 | None              | :-)   | UP    | neutron-linuxbridge-agent |
| 52a77cdc-f16b-46ef-8d99-40f92b6cdfda | Metadata agent     | compute03 | None              | :-)   | UP    | neutron-metadata-agent    |
| 64b90391-c29c-4932-a8b0-9ec3caa0522b | DHCP agent         | compute02 | nova              | :-)   | UP    | neutron-dhcp-agent        |
| 728f9251-e47c-4b3e-91f5-3a0ba6ad2b2c | Linux bridge agent | compute03 | None              | :-)   | UP    | neutron-linuxbridge-agent |
| 9ff23bc2-7345-481d-9b1c-25d64947ccbd | L3 agent           | compute03 | nova              | :-)   | UP    | neutron-l3-agent          |
| c0ec2ad2-fc6b-4a04-886e-0308af1eeac8 | L3 agent           | compute01 | nova              | :-)   | UP    | neutron-l3-agent          |
| c761f609-9b1c-4106-89f0-22dd49e25323 | Metadata agent     | compute02 | None              | :-)   | UP    | neutron-metadata-agent    |
| d1f2f9aa-ef0d-49ce-9e0f-a9e7c2bc62fa | DHCP agent         | compute01 | nova              | :-)   | UP    | neutron-dhcp-agent        |
| f26fb996-96f5-44c2-b3a4-e3c6a74bc5eb | L3 agent           | compute02 | nova              | :-)   | UP    | neutron-l3-agent          |
+--------------------------------------+--------------------+-----------+-------------------+-------+-------+---------------------------+

```

## 15.4添加pcs资源

只需要添加neutron-server，其他的neutron-agent服务：neutron-linuxbridge-agent，neutron-l3-agent，neutron-dhcp-agent与neutron-metadata-agent 不需要添加了；因为部署在了计算节点上


在任意控制节点操作；添加资源neutron-server

```bash
#pcs resource create neutron-linuxbridge-agent systemd:neutron-linuxbridge-agent clone interleave=true
#pcs resource create neutron-l3-agent systemd:neutron-l3-agent clone interleave=true
#pcs resource create neutron-dhcp-agent systemd:neutron-dhcp-agent clone interleave=true
#pcs resource create neutron-metadata-agent systemd:neutron-metadata-agent clone interleave=true

$ pcs resource create neutron-server systemd:neutron-server clone interleave=true
$ pcs resource 
 vip	(ocf::heartbeat:IPaddr2):	Started controller01
 Clone Set: lb-haproxy-clone [lb-haproxy]
     Started: [ controller01 ]
     Stopped: [ controller02 controller03 ]
 Clone Set: openstack-keystone-clone [openstack-keystone]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: openstack-glance-api-clone [openstack-glance-api]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: openstack-nova-api-clone [openstack-nova-api]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: openstack-nova-scheduler-clone [openstack-nova-scheduler]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: openstack-nova-conductor-clone [openstack-nova-conductor]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: openstack-nova-novncproxy-clone [openstack-nova-novncproxy]
     Started: [ controller01 controller02 controller03 ]
 Clone Set: neutron-server-clone [neutron-server]
     Started: [ controller01 controller02 controller03 ]
```


---

# 16.Horazion仪表盘集群部署


https://docs.openstack.org/horizon/train/install/

- OpenStack仪表板Dashboard服务的项目名称是Horizon，它所需的唯一服务是身份服务keystone，开发语言是python的web框架Django。
- 仪表盘使得通过OpenStack API与OpenStack计算云控制器进行基于web的交互成为可能。 
- Horizon 允许自定义仪表板的商标；并提供了一套内核类和可重复使用的模板及工具。

安装Train版本的Horizon有以下要求：

Python 2.7、3.6或3.7
Django 1.11、2.0和2.2
Django 2.0和2.2支持在Train版本中处于试验阶段
Ussuri发行版（Train发行版之后的下一个发行版）将使用Django 2.2作为主要的Django版本。Django 2.0支持将被删除。


## 16.1安装dashboard

在全部控制节点安装dashboard服务，以controller01节点为例

```bash
yum install openstack-dashboard memcached python-memcached -y
```


## 16.2配置local_settings

OpenStack Horizon 参数设置说明: https://blog.csdn.net/u011521019/article/details/51237068

```bash
#备份配置文件/etc/nova/nova.conf
cp -a /etc/openstack-dashboard/local_settings{,.bak}
grep -Ev '^$|#' /etc/openstack-dashboard/local_settings.bak >/etc/openstack-dashboard/local_settings
```

```conf
#配置文件中要将所有注释取消

#指定在网络服务器中配置仪表板的访问位置;默认值: "/"
WEBROOT = '/dashboard/'
#配置仪表盘在controller节点上使用OpenStack服务
OPENSTACK_HOST = "172.16.181.30"

#允许主机访问仪表板,接受所有主机,不安全不应在生产中使用
ALLOWED_HOSTS = ['*', 'localhost']
#ALLOWED_HOSTS = ['one.example.com', 'two.example.com']

#配置memcached会话存储服务
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller01:11211,controller02:11211,controller03:11211',
    }
}

#启用身份API版本3
OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST

#启用对域的支持
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True

#配置API版本
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 3,
}

#配置Default为通过仪表板创建的用户的默认域
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"

#配置user为通过仪表板创建的用户的默认角色
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"

#如果选择网络选项1，请禁用对第3层网络服务的支持,如果选择网络选项2,则可以打开
OPENSTACK_NEUTRON_NETWORK = {
    #自动分配的网络
    'enable_auto_allocated_network': False,
    #Neutron分布式虚拟路由器（DVR）
    'enable_distributed_router': False,
    #FIP拓扑检查
    'enable_fip_topology_check': False,
    #高可用路由器模式
    'enable_ha_router': True,
    #下面三个已过时,不用过多了解,官方文档配置中是关闭的
    'enable_lb': False,
    'enable_firewall': False,
    'enable_vpn': False,
    #ipv6网络
    'enable_ipv6': True,
    #Neutron配额功能
    'enable_quotas': True,
    #rbac政策
    'enable_rbac_policy': True,
    #路由器的菜单和浮动IP功能,Neutron部署中有三层功能的支持;可以打开
    'enable_router': True,
    #默认的DNS名称服务器
    'default_dns_nameservers': [],
    #网络支持的提供者类型,在创建网络时，该列表中的网络类型可供选择
    'supported_provider_types': ['*'],
    #使用与提供网络ID范围,仅涉及到VLAN，GRE，和VXLAN网络类型
    'segmentation_id_range': {},
    #使用与提供网络类型
    'extra_provider_types': {},
    #支持的vnic类型,用于与端口绑定扩展
    'supported_vnic_types': ['*'],
    #物理网络
    'physical_networks': [],
}

#配置时区为亚洲上海
TIME_ZONE = "Asia/Shanghai"
....
```

将dashboard配置文件拷贝到另外的控制节点上：

```bash
scp -rp /etc/openstack-dashboard/local_settings  controller02:/etc/openstack-dashboard/
scp -rp /etc/openstack-dashboard/local_settings  controller03:/etc/openstack-dashboard/
```


## 16.3配置openstack-dashboard.conf

在全部控制节点操作；

```bash
cp /etc/httpd/conf.d/openstack-dashboard.conf{,.bak}

#建立策略文件（policy.json）的软链接，否则登录到dashboard将出现权限错误和显示混乱
ln -s /etc/openstack-dashboard /usr/share/openstack-dashboard/openstack_dashboard/conf

#赋权，在第3行后新增 WSGIApplicationGroup %{GLOBAL}
sed -i '3a WSGIApplicationGroup\ %{GLOBAL}' /etc/httpd/conf.d/openstack-dashboard.conf
```

将dashboard配置文件拷贝到另外的控制节点上：

```bash
scp -rp /etc/httpd/conf.d/openstack-dashboard.conf  controller02:/etc/httpd/conf.d/
scp -rp /etc/httpd/conf.d/openstack-dashboard.conf  controller03:/etc/httpd/conf.d/
```

文件配置记录

```bash
[root@controller01 ~]# cat /etc/httpd/conf.d/openstack-dashboard.conf
WSGIDaemonProcess dashboard
WSGIProcessGroup dashboard
WSGISocketPrefix run/wsgi
WSGIApplicationGroup %{GLOBAL}

WSGIScriptAlias /dashboard /usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi
Alias /dashboard/static /usr/share/openstack-dashboard/static

<Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>
  Options All
  AllowOverride All
  Require all granted
</Directory>

<Directory /usr/share/openstack-dashboard/static>
  Options All
  AllowOverride All
  Require all granted
</Directory>

```

## 16.4重启apache和memcache

```bash
systemctl restart httpd.service memcached.service
systemctl enable httpd.service memcached.service
systemctl status httpd.service memcached.service
```


## 16.5验证访问

在浏览器访问仪表板，网址为 http://172.16.181.30/dashboard  或 https://172.16.181.30/dashboard

注意配置文件中添加了url，需要加dashboard
使用admin或demo用户和default域凭据进行身份验证。


## 16.6创建虚拟网络并启动实例操作

参考博客:

https://www.cnblogs.com/gleaners/p/5632708.html

https://docs.openstack.org/install-guide/launch-instance.html#block-storage

创建虚拟网络的两种方式:
https://www.cnblogs.com/linhaifeng/p/6577199.html




# 17.OpenStack高可用集群部署方案(train版)—Cinder

Cinder的核心功能是对卷的管理，允许对卷、卷的类型、卷的快照、卷备份进行处理。它为后端不同的存储设备提供给了统一的接口，不同的块设备服务厂商在Cinder中实现其驱动，可以被Openstack整合管理，nova与cinder的工作原理类似。支持多种 back-end（后端）存储方式，包括 LVM，NFS，Ceph 和其他诸如 EMC、IBM 等商业存储产品和方案。


Cinder各组件功能

Cinder-api 是 cinder 服务的 endpoint，提供 rest 接口，负责处理 client 请求，并将 RPC 请求发送至 cinder-scheduler 组件。

Cinder-scheduler 负责 cinder 请求调度，其核心部分就是 scheduler_driver, 作为 scheduler manager 的 driver，负责 cinder-volume 具体的调度处理，发送 cinder RPC 请求到选择的 cinder-volume。

Cinder-volume 负责具体的 volume 请求处理，由不同后端存储提供 volume 存储空间。目前各大存储厂商已经积极地将存储产品的 driver 贡献到 cinder 社区