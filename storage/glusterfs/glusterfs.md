# GlusterFS

[toc]

## 1.GlusterFS 介绍

## 2. GlusterFS 环境准备

### 2.1 环境列表

| 节点  | IP地址      | 数据盘            | 操作系统  |
| ----- | ----------- | ----------------- | --------- |
| node1 | 172.16.1.31 | sdb/100G,sdc/100G | Centos7.6 |
| node2 | 172.16.1.32 | sdb/100G,sdc/100G | Centos7.6 |
| node3 | 172.16.1.33 | sdb/100G,sdc/100G | Centos7.6 |

### 2.2 NTP

### 2.3 关闭防火墙

### 2.4 SSH免密

### 2.5 数据盘准备

```shell
# 每个节点处理
for i in b c
do
mkfs.xfs -i size=512 /dev/sd${i}
mkdir -p /data/sd${i}
echo "/dev/sd${i} /data/sd${i} xfs defaults 1 2" >> /etc/fstab
done && mount -a && mount
```

## 3. GlusterFS Quick Start Guide

### 3.1 Install GlusterFS

```shell
# 安装gluster源
yum install -y centos-release-gluster

yum install -y glusterfs-server

systemctl start glusterd.service
systemctl enable glusterd.service 
systemctl status glusterd
```

```shell
[root@node1 ~]# gluster --help
peer help                - display help for peer commands
volume help              - display help for volume commands
volume bitrot help       - display help for volume bitrot commands
volume quota help        - display help for volume quota commands
snapshot help            - display help for snapshot commands
global help              - list global commands


gluster peer probe     - Add node
gluster peer detach     - delete node
gluster volume create    - create volume
gluster volume start    - start volume
gluster volume stop     - stop volume
gluster volume delete   - delete volume
gluster volume quota enable   - enable volume quota
gluster volume quota disable   - disable volume quota
gluster volume quota limit-usage  - set volume quota (eg:100G)

```

### 3.2 Add pool from node

```shell
# From "node1"
gluster peer probe node2
gluster peer probe node3

# check status
[root@node1 ~]# gluster peer status
Number of Peers: 2

Hostname: node2
Uuid: 4ed31f82-6513-4bd6-8baa-a82f40384fdb
State: Peer in Cluster (Connected)

Hostname: node3
Uuid: 96bf659a-8db4-4159-b51c-0db9cafc7c13
State: Peer in Cluster (Connected)

[root@node1 ~]# gluster pool list
UUID      Hostname    State
4ed31f82-6513-4bd6-8baa-a82f40384fdb	node2    	Connected 
96bf659a-8db4-4159-b51c-0db9cafc7c13	node3    	Connected 
47e077ae-37cd-4f1f-bfe0-09f29e54b052	localhost	Connected 

```

### 3.3  Create volume

```shell
# On all node
gluster volume create gv0 replica 3 \
  172.16.1.31:/data/sdb 172.16.1.31:/data/sdc \
  172.16.1.32:/data/sdb 172.16.1.32:/data/sdc \
  172.16.1.33:/data/sdb 172.16.1.33:/data/sdc \
  force
# gv0	    volume name
# replica   replica number,1~3
# force		Ignore data volumes partitioned as root

# start volume gv0
gluster volume start gv0

# check volume status
gluster volume status

# list all volume
gluster volume list

# list volume info gv0
gluster volume info gv0 
 
Volume Name: gv0
Type: Distributed-Replicate
Volume ID: b953b7ef-8f77-4da0-aadf-23ec46e11689
Status: Started
Snapshot Count: 0
Number of Bricks: 3 x 2 = 6
Transport-type: tcp
Bricks:
Brick1: node1:/data/sdb
Brick2: node1:/data/sdc
Brick3: node2:/data/sdb
Brick4: node2:/data/sdc
Brick5: node3:/data/sdb
Brick6: node3:/data/sdc
Options Reconfigured:
transport.address-family: inet
storage.fips-mode-rchecksum: on
nfs.disable: on
performance.client-io-threads: off
```

### 设置ipv6挂载方式
```shell
gluster vol set gv0 transport.address-family inet6
gluster volume restart gv0

```

### 3.4 Mount volume

```shell
# node1 mount
mount -t glusterfs node1:/gv0 /mnt

# check mount
df -h|grep gv0
node1:/gv0               300G  3.2G  297G   2% /mnt

# Auto mount at boot
echo "node1:/gv0 /mnt glusterfs defaults,_netdev 0 0" >>/etc/fstab

# test volume
for i in `seq -w 1 100`; do cp -rp /var/log/messages /mnt/copy-test-$i; done

# check the client mount point
ls -lA /mnt/copy* | wc -l

# check the node pool
ls -lA /data/sdb/copy*
```

### 3.5 Docker Mount

```shell
docker run -it --privileged=true glusterfs_client:v1.0
mount -t glusterfs 172.16.1.31:gv0  -o backup-volfile-servers=172.16.1.32:172.16.1.33 /mnt/test

docker run -it --privileged=true -v /mnt/test:/mnt/test gfs_nfs_c8:v1.0 
mount -t nfs 172.16.103.8:/nas_data /mnt/test
```

## 4. GlusterFS ubuntu20.04

GlusterFS Release: 8.2

### 4.1 Prerequisite

```shell
# set root password
echo root:123456|chpasswd

# PermitRootLogin
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
service sshd reload

# ssh Avoid close login
ssh-keygen
ssh-copy-id node1
ssh-copy-id node2
ssh-copy-id node3

# Add sources
wget -O - https://download.gluster.org/pub/gluster/glusterfs/8/rsa.pub | apt-key add -
echo deb [arch=amd64] https://download.gluster.org/pub/gluster/glusterfs/8/8.2/Debian/bullseye/amd64/apt bullseye main > /etc/apt/sources.list.d/gluster.list
apt update
```

### 4.2 Install

```shell
apt-get install glusterfs-server

glusterfs --version
```

### 4.3 Configure Glusterfs

```shell
# Add cluster pool From "node1"
gluster peer probe node2
gluster peer probe node3

# check status
[root@node1 ~]# gluster peer status
Number of Peers: 2

Hostname: node2
Uuid: 4ed31f82-6513-4bd6-8baa-a82f40384fdb
State: Peer in Cluster (Connected)

Hostname: node3
Uuid: 96bf659a-8db4-4159-b51c-0db9cafc7c13
State: Peer in Cluster (Connected)

[root@node1 ~]# gluster pool list
UUID					Hostname 	State
4ed31f82-6513-4bd6-8baa-a82f40384fdb	node2    	Connected 
96bf659a-8db4-4159-b51c-0db9cafc7c13	node3    	Connected 
47e077ae-37cd-4f1f-bfe0-09f29e54b052	localhost	Connected


# Create volume
gluster volume create gv0 replica 3 \
node1:/data/sdb node2:/data/sdb node3:/data/sdb \
force
# gv0	    volume name
# replica   replica number,1~3
# force		Ignore data volumes partitioned as root

# start volume gv0
gluster volume start gv0

# check volume status
gluster volume status

# list all volume
gluster volume list

# list volume info gv0
gluster volume info gv0
 
Volume Name: gv0
Type: Distributed-Replicate
Volume ID: b953b7ef-8f77-4da0-aadf-23ec46e11689
Status: Started
Snapshot Count: 0
Number of Bricks: 3 x 2 = 6
Transport-type: tcp
Bricks:
Brick1: node1:/data/sdb
Brick2: node1:/data/sdc
Brick3: node2:/data/sdb
Brick4: node2:/data/sdc
Brick5: node3:/data/sdb
Brick6: node3:/data/sdc
Options Reconfigured:
transport.address-family: inet
storage.fips-mode-rchecksum: on
nfs.disable: on
performance.client-io-threads: off


# create gv1
gluster volume create gv1 replica 3 \
node1:/data/sdc node2:/data/sdc node3:/data/sdc \
force
```

### 4.4 Mount volume

```shell
# node1 mount
mount -t glusterfs node1:/gv0 /mnt

# check mount
df -h|grep gv0
node1:/gv0               300G  3.2G  297G   2% /mnt

# Auto mount at boot
echo "node1:/gv0 /mnt glusterfs defaults,_netdev 0 0" >>/etc/fstab

# test volume
for i in `seq -w 1 100`; do cp -rp /var/log/messages /mnt/copy-test-$i; done

# check the client mount point
ls -lA /mnt/copy* | wc -l

# check the node pool
ls -lA /data/sdb/copy*
```
