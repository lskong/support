---
title: Kubernetes
date: 2020/12/25 15:15:26
update: 
---

# Greenplum

[toc]

## 1. Greenplum 介绍



### 1.3 Greenplum 架构

**Greenplum** 主要由Master节点，Segment节点，Interconnect三大部分组成。**Master** 是Greenplum数据库系统的入口，接受客户端连接及提交的SQL语句，将工作负载分发给 **Segment** 数据库实例(Segment实例)，由于他们存储和处理数据。**Interconnect ** 负责不同PostgreSQL实例之间的通信。Greenplum Segment是独立的PostgreSQL数据库，每个Segment存储一部分数据。大部分查询处理都由Segment完成。

**Master** 节点不存放任何用户数据，只是对客户端进行访问控制和存储表分布逻辑的元数据。
**Segment** 节点负责数据的存储，可以对分布键进行优化以充分利用Segment接的io性能来扩展整个集群的性能。





##  2. Greenplum 最佳实践

### 2.1 方案设计

master节点，使用单台物理机。standby master节点，使用单台物理机。



## 3. Greenplum 集群部署

### 3.1 部署环境

- **服务器准备**

| 角色           | 主机名  | IP地址         | 备注                               |
| -------------- | ------- | -------------- | ---------------------------------- |
| master-primary | master  | 172.16.103.201 | master primary                     |
| master-standby | standby | 172.16.103.202 | master standby                     |
| segment        | sgm1    | 172.16.103.203 | 三个primary,三个mirror             |
| segment        | sgm2    | 172.16.103.204 | 三个primary,三个mirror             |
| segment        | sgm3    | 172.16.103.205 | 三个primary,三个mirror             |
| segment        | sgm4    | 172.16.103.206 | 扩容segment,三个primary,三个mirror |
| segment        | sgm5    | 172.16.103.207 | 扩容segment,三个primary,三个mirror |

- **操作系统准备**

  采用Linux CentOS7的版本

  ```bash
  [root@gpmp ~]# cat /etc/redhat-release 
  CentOS Linux release 7.6.1810 (Core) 
  ```

  

- **Greenplum版本**

  采用官方6.13.0版本的RPM包

  下载地址：https://github.com/greenplum-db/gpdb/releases/tag/6.13.0



### 3.2 先决条件

#### 3.2.1 主机名解析

```shell
// 主机名
hostnamectl set-hostname master
hostnamectl set-hostname stanbdy
hostnamectl set-hostname sgm1
hostnamectl set-hostname sgm2
hostnamectl set-hostname sgm3

// 主机解析
cat >/etc/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.16.103.201 master
172.16.103.202 standby
172.16.103.203 sgm1
172.16.103.204 sgm2
172.16.103.205 sgm3
EOF
```

#### 3.2.2 安全设置

```bash
// 关闭selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/seliunx/conf

setenforce 0
getenforce

// 关闭防火墙
systemctl stop firewalld.service
systemctl disable firewalld.service
```

#### 3.2.3 时间同步

```bash
echo "*/5 * * * * /usr/sbin/ntpdate ntp.aliyun.com >/dev/null 2>&1" >/var/spool/cron/root
```

#### 3.2.4 ssh免密

```bash
ssh-keygen
ssh-copy-id master
ssh-copy-id standby
ssh-copy-id sgm1
ssh-copy-id sgm2
ssh-copy-id sgm3
```

#### 3.2.5 磁盘IO优化

文件系统挂在选项，使用xfs文件系统

```bash
rw,noatime,inode64,allocsize=16
```

修改存储数据的磁盘blockdev预读尺寸，应该被设置为65535。

```bash
// 磁盘预读尺寸
/sbin/blockdev --getra /dev/sda
/sbin/blockdev --setra 65536 /dev/sda

# 必要时
echo "/sbin/blockdev --setra 65536 /dev/sda" >>/etc/rc.d/rc.local
```

修改存储数据的IO调度器，SAS磁盘设置为 `deadline` ，SSD/NVMe设置为 `noop`。

```bash
cat /sys/block/sda/queue/scheduler
 noop anticipatory [deadline] cfq 

echo deadline >/sys/block/sda/queue/scheduler

grubby --update-kernel=ALL --args="elevator=deadline"
```

禁用Transparent Huge Pages (THP)

```bash
grubby --update-kernel=ALL --args="transparent_hugepage=never"
```

禁用IPC

```bash
vim /etc/systemd/logind.conf
 RemoveIPC=no
```

禁用NUMA

```bash
# 编辑内核
vim /etc/default/grub
# 在GRUB_CMDLINE_LINUX=，后面加上numa=off

# 编译内核
grub2-mkconfig -o /etc/grub2.cfg

# 重启服务器
shutdown -h now

# 校验状态
yum install numactl -y
numactl --hardware
	available: 1 nodes (0)
```



磁盘资源限制

```bash
cat >>/etc/security/limits.conf <<EOF
* soft  nofile 524288
* hard  nofile 524288
* soft  nproc unlimited
* hard  nproc unlimited
* soft  stack unlimited
* hard  stack unlimited
* soft  memlock unlimited
* hard  memlock unlimited
* soft  core unlimited
EOF

rm -f /etc/security/limits.d/*
```



#### 3.2.6 内核参数

```bash
cat >> /etc/sysctl.conf <<EOF
#// OS内存配置
vm.overcommit_memory = 2  # default 2
vm.overcommit_ratio = 95  # default 50

#// 共享内存设置
kernel.shmmax = 1977094144
kernel.shmmni = 4096
kernel.shmall = 482689
# shmmax == echo $(expr $(getconf _PHYS_PAGES) / 2)
# shmall == echo $(expr $(getconf _PHYS_PAGES) / 2 \* $(getconf PAGE_SIZE))

fs.aio-max-nr = 1048576
fs.file-max = 6815744

kernel.sem = 4096 2147483647 2147483646 512000
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.msgmni = 2048

net.ipv4.ip_local_port_range = 10000 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.arp_filter = 1

net.core.netdev_max_backlog = 10000
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586

vm.swappiness = 10
vm.zone_reclaim_mode = 0
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.dirty_background_ratio = 0  # 64G- set 3, 64+ set 0
vm.dirty_ratio = 0  #64- set 10,64G+ set 0
vm.dirty_background_bytes = 1610612736
vm.dirty_bytes = 4294967296
EOF
sysctl -p
```

#### 3.2.7 用户、用户组

```bash
# 创建组
groupadd -g 599 gpadmin

# 创建用户
useradd -g gpadmin -u 600 gpadmin

# 设置密码：
echo "123456"|passwd gpadmin --stdin
```

#### 3.2.8 准备安装介质

**商业版**：https://network.pivotal.io/products/pivotal-gpdb/

**开源版**：https://github.com/greenplum-db/gpdb/releases

**下载RPM包**：greenplum-db-6.13.0-rhel7-x86_64.rpm

> 本文档使用rpm部署Greenplum



### 3.3 集群部署

Greenplum 4.x/5.x，先安装master二进制包，可以指定安装目录。使用gpseginstall安装seg集群。gp集群参数校验，使用gpinitsystem集群初始化。
Greenplum 6.x，提供rpm包，没有gpseginstall工具，gp集群参数校验，使用gpinitsystem集群初始化。

#### 3.3.1 部署Greenplum

**安装Greenplum**

```bash
// 所有主机
yum -y localinstall greenplum-db-6.13.0-rhel7-x86_64.rpm
```

> 这里编译安装记录暂时保留
>
> ```bash
> // 安装依赖
> yum -y install gcc gcc-c++ perl-devel perl-ExtUtils-Embed krb5-devel readline-devel libzstd-devel libevent-devel apr-devel libyaml-devel libxml2-devel libcurl-devel bzip2-devel xerces-c-devel python-devel bison bison-devel flex flex-devel openssl-devel
> 
> # 编译程序至/usr/local/gpdb
> ./configure --with-perl --with-python --with-libxml --with-gssapi --prefix=/usr/local/gpdb
> 
> # 编译安装
> make -j8
> make -j8 install
> ## 编译报错,先执行make clean
> ```



**配置互信**

```bash
// 使用root权限
# 加载环境变量
source /usr/local/gpdb/greenplum_path.sh

# 创建all_hosts和all_segs主机列表
cd /usr/local/gpdb
sudo cat > all_hosts <<EOF
master
standby
sgm1
sgm2
sgm3
EOF

cat > all_segs <<EOF
sgm1
sgm2
sgm3
EOF

# 使用gpssh-exkeys工具建立互信
gpssh-exkeys -f all_hosts

# 验证,如无密码提示则表示建立完成
gpssh -f all_hosts -e 'ls $GPHOME'
```

**创建数据目录**

```bash
# master和standby master 创建数据目录
mkdir -p /greenplum/gpdata/master
chown gpadmin.gpadmin  -R /greenplum

# 给所有segment主机创建数据目录
gpssh -f all_segs -e 'mkdir -p /greenplum/gpdata/{primary,mirror}' 
gpssh -f all_segs -e 'chown gpadmin.gpadmin  -R /greenplum/gpdata/'

```

**配置环境变量**



**集群性能测试**

**校验Disk I/O性能和内存带宽**

```bash
// 校验Disk I/O性能和内存带宽
gpcheckperf -f all_hosts -r ds -D -d /data/primary -d mirror

// 校验网络性能
gpcheckperf -f /usr/local/greenplum-db/configall_segs -r N -d /tmp >subnet.out
```





#### 3.3.2 初始化集群

**创建初始化文件**

```bash
cp $GPHOME/docs/cli_help/
```

