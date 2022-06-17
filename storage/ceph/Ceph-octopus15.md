## Contents

[TOC]



## 1. Ceph介绍

Ceph 分布式存储、统一存储；[官方](https://docs.ceph.com/en/latest/)

Ceph 是一个专注于分布式的、弹性可扩展的、高可靠的、性能优异的存储系统平台，可以同时支持块设备、文件系统和对象网关三种类型的存储接口。Ceph架构如[图1](https://support.huaweicloud.com/dpmg-kunpengsdss/kunpengcephblock_04_0001.html#kunpengcephblock_04_0001__zh-cn_topic_0185813847_fig3121152)所示。

![img](Ceph-octopus15.assets/zh-cn_image_0000001129297949.png)



## 2. Ceph模块说明

| 模块名称 | 功能描述                                                     |
| -------- | ------------------------------------------------------------ |
| RADOS    | RADOS（Reliable Autonomic Distributed Object Store，RADOS）是Ceph存储集群的基础。Ceph中的一切都以对象的形式存储，而RADOS就负责存储这些对象，而不考虑它们的数据类型。RADOS层确保数据一致性和可靠性。对于数据一致性，它执行数据复制、故障检测和恢复，还包括数据在集群节点间的recovery。 |
| OSD      | 实际存储数据的进程。通常一个OSD daemon绑定一个物理磁盘。Client write/read数据最终都会走到OSD去执行write/read操作。 |
| MON      | Monitor在Ceph集群中扮演者管理者的角色，维护了整个集群的状态，是Ceph集群中最重要的组件。MON保证集群的相关组件在同一时刻能够达成一致，相当于集群的领导层，负责收集、更新和发布集群信息。为了规避单点故障，在实际的Ceph部署环境中会部署多个MON，同样会引来多个MON之前如何协同工作的问题。 |
| MGR      | MGR目前的主要功能是一个监控系统，包含采集、存储、分析（包含报警）和可视化几部分，用于把集群的一些指标暴露给外界使用。 |
| Librados | 简化访问RADOS的一种方法，目前支持PHP、Ruby、Java、Python、C和C++语言。它提供了Ceph存储集群的一个本地接口RADOS，并且是其他服务（如RBD、RGW）的基础，此外，还为CephFS提供POSIX接口。Librados API支持直接访问RADOS，使开发者能够创建自己的接口来访问Ceph集群存储。 |
| RBD      | Ceph块设备，对外提供块存储。可以像磁盘一样被映射、格式化和挂载到服务器上。 |
| RGW      | Ceph对象网关，提供了一个兼容S3和Swift的RESTful API接口。RGW还支持多租户和OpenStack的Keystone身份验证服务。 |
| MDS      | Ceph元数据服务器，跟踪文件层次结构并存储只供CephFS使用的元数据。Ceph块设备和RADOS网关不需要元数据。MDS不直接给Client提供数据服务。 |
| CephFS   | 提供了一个任意大小且兼容POSlX的分布式文件系统。CephFS依赖Ceph MDS来跟踪文件层次结构，即元数据。 |



## 3. Cephadm (ubuntu20.04)

### 3.1 前置条件

```shell
# 切root用户
sudo su - root

# 设置root用户密码
echo root:123456|chpasswd

# sudoer无密码使用
root    ALL=(ALL:ALL) NOPASSWD:ALL

# 允许root远程登录
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
service sshd reload

# 添加hosts主机解析
vim /etc/hosts
10.0.0.23 node1
10.0.0.24 node2
10.0.0.25 node3

# 设置时区
timedatectl
tzselect
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 

# 安装时间同步工具
apt-get -y install ntpdate
ntpdate ntp.aliyun.com

# 配置时间定时任务
tee /var/spool/cron/crontabs/root <<-'EOF'
*/5 * * * * ntpdate ntp.aliyun.com
EOF

# 添加ceph源
wget -q -O- 'http://mirrors.aliyun.com/ceph/keys/release.asc' | sudo apt-key add -
echo deb http://mirrors.aliyun.com/ceph/debian-octopus/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
apt-get update

wget -q -O- 'http://mirrors.tuna.tsinghua.edu.cn//ceph/keys/release.asc' | sudo apt-key add -
echo deb http://mirrors.tuna.tsinghua.edu.cn//ceph/debian-octopus/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
apt-get update


# 安装docker
```



### 3.2 Install Docker

```shell
# ubuntu20.04 install docker

# Uninstall old versions
sudo apt-get remove docker docker-engine docker.io containerd runc

# Install using the repository
sudo apt-get update

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
    
# Add Docker's official GPG key:
curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

# Set up the stable repository	(No do)
sudo add-apt-repository \
   "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/ \
  $(lsb_release -cs) \
  stable"
  
# Install Docke
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io
 

# To install a specific version
apt-cache madison docker-ce
sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io
sudo docker run hello-world

# Uninstall Docker Engine
sudo apt-get purge docker-ce docker-ce-cli containerd.io
 sudo rm -rf /var/lib/docker
 sudo rm -rf /var/lib/containerd
 
# Mirror to accelerate
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://wc9koj0u.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
```



### 3.3 Deploy Cephadm

```shell
# node1节点执行
apt-get install -y cephadm

root@node1:~# cephadm version
ceph version 15.2.11 (e3523634d9c2227df9af89a4eac33d16738c49cb) octopus (stable)

# cephadm安装之后，会自动下载镜像
```



### 3.4 Ceph Cluster

```shell
# 部署
mkdir -p /etc/ceph
cephadm bootstrap --mon-ip 172.16.103.21

# 结果
.....
	     URL: https://node1:8443/
	    User: admin
	Password: kwp2mjbyul

You can access the Ceph CLI with:

	sudo /usr/sbin/cephadm shell --fsid e3670566-a1ab-11eb-b266-8bfed5f9c18f -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

Please consider enabling telemetry to help improve Ceph:

	ceph telemetry on

For more information see:

	https://docs.ceph.com/docs/master/mgr/telemetry/

Bootstrap complete.
# ======================================================================

# 登录web修改密码：Ceph@123
https://172.16.103.21:8443


# 查看镜像
root@node1:~# docker images
REPOSITORY           TAG       IMAGE ID       CREATED         SIZE
ceph/ceph            <none>    9d01da634b8f   8 hours ago     1.09GB
ceph/ceph            v15       5b724076c58f   4 weeks ago     1.07GB
ceph/ceph-grafana    6.7.4     80728b29ad3f   4 months ago    485MB
prom/prometheus      v2.18.1   de242295e225   11 months ago   140MB
prom/alertmanager    v0.20.0   0881eb8f169f   16 months ago   52.1MB
prom/node-exporter   v0.18.1   e5a616e4b9cf   22 months ago   22.9MB

# 查看运行容器
root@node1:~# docker ps
CONTAINER ID   IMAGE                        COMMAND                  CREATED         STATUS         PORTS     NAMES
06114626b5bb   ceph/ceph-grafana:6.7.4      "/bin/sh -c 'grafana…"   2 minutes ago   Up 2 minutes             ceph-e3670566-a1ab-11eb-b266-8bfed5f9c18f-grafana.node1
cfbc80b9cc1c   prom/alertmanager:v0.20.0    "/bin/alertmanager -…"   3 minutes ago   Up 2 minutes             ceph-e3670566-a1ab-11eb-b266-8bfed5f9c18f-alertmanager.node1
7b98ca5df9c2   prom/prometheus:v2.18.1      "/bin/prometheus --c…"   3 minutes ago   Up 3 minutes             ceph-e3670566-a1ab-11eb-b266-8bfed5f9c18f-prometheus.node1
46433a280a4a   prom/node-exporter:v0.18.1   "/bin/node_exporter …"   3 minutes ago   Up 3 minutes             ceph-e3670566-a1ab-11eb-b266-8bfed5f9c18f-node-exporter.node1
c2b5d8a54732   ceph/ceph:v15                "/usr/bin/ceph-crash…"   4 minutes ago   Up 4 minutes             ceph-e3670566-a1ab-11eb-b266-8bfed5f9c18f-crash.node1
0647b465494c   ceph/ceph:v15                "/usr/bin/ceph-mgr -…"   6 minutes ago   Up 6 minutes             ceph-e3670566-a1ab-11eb-b266-8bfed5f9c18f-mgr.node1.ffzxpd
6c3ab478e525   ceph/ceph:v15                "/usr/bin/ceph-mon -…"   6 minutes ago   Up 6 minutes             ceph-e3670566-a1ab-11eb-b266-8bfed5f9c18f-mon.node1


# 切换到Ceph命令行
cephadm shell

root@node1:~# cephadm shell
Inferring fsid e3670566-a1ab-11eb-b266-8bfed5f9c18f
Inferring config /var/lib/ceph/e3670566-a1ab-11eb-b266-8bfed5f9c18f/mon.node1/config
Using recent ceph image ceph/ceph@sha256:030e84addad8f3a7d26ea49b180660f1a9b33ef06d691759f320a58e892fb535
root@node1:/# ceph -s
  cluster:
    id:     e3670566-a1ab-11eb-b266-8bfed5f9c18f
    health: HEALTH_WARN
            OSD count 0 < osd_pool_default_size 3
 
  services:
    mon: 1 daemons, quorum node1 (age 10m)
    mgr: node1.ffzxpd(active, since 9m)
    osd: 0 osds: 0 up, 0 in
 
  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0 B
    usage:   0 B used, 0 B / 0 B avail
    pgs: 
    
    
# 安装ceph命令
cephadm add-repo --release octopus
cephadm install ceph-common

ceph -v
```



### 3.5  Add node

```shell
# 拷贝密钥文件
ssh-copy-id -f -i /etc/ceph/ceph.pub root@node2
ssh-copy-id -f -i /etc/ceph/ceph.pub root@node3
# 如果ceph.pub没有，自己生成一个。
ssh-keygen
cp .ssh/id_rsa.pub /etc/ceph/ceph.pub
ceph cephadm get-pub-key > ~/ceph.pub
ssh-copy-id -f -i ~/ceph.pub root@node2
ssh-copy-id -f -i ~/ceph.pub root@node3

# 添加节点
ceph orch host add node2
ceph orch host add node3

root@node1:~# ceph orch host add node2
Added host 'node2'
root@node1:~# ceph orch host add node3
Added host 'node3'

# 节点添加成功，会自动下载镜像
# node2自动启动mon和mgr
# node3自动启动mon


# 删除主机
ceph orch host rm node3


# 添加mgr
sudo ceph auth get-or-create mgr.$HOSTNAME mon 'allow profile mgr' osd 'allow *' mds 'allow *'
sudo -u ceph mkdir /var/lib/ceph/mgr/ceph-$HOSTNAME/
sudo ceph auth get mgr.$HOSTNAME -o /var/lib/ceph/mgr/ceph-$HOSTNAME/keyring
sudo chown ceph:ceph /var/lib/ceph/mgr/ceph-$HOSTNAME/keyring
sudo systemctl systemctl daemon-reload
sudo systemctl enable ceph-mgr@$HOSTNAME.service
sudo systemctl restart ceph-mgr@$HOSTNAME.service
sudo ceph auth caps client.admin osd 'allow *' mds 'allow ' mon 'allow *' mgr 'allow *'
```



### 3.6 Deploy Additional (Optinonal)

```shell
# 配置public_network
ceph config set mon public_network 172.16.0.0/16

# 配置cluster_network

# mon节点，默认5个；可以使用命令调整mon节点在那些主机上
ceph orch apply mon node1,node2,node3

# 设置标签来规定节点角色
ceph orch host ls
ceph orch host label add node1 mon
ceph orch host label add node2 mon
ceph orch host label add node3 mon

# 告诉cephadm根据标签部署mon
ceph orch apply mon label:mon

# 指定IP或网段部署mon，要禁用自动部署
ceph orch apply mon --unmanaged
ceph orch daemon add mon newhost1:10.1.2.123
ceph orch daemon add mon newhost1:10.1.2.0/24

# 注意ceph orch apply mon host2命令会取代之前执行过的，列如
ceph orch apply mon host1
ceph orch apply mon host2
ceph orch apply mon host3
# 这样会导致只应了一个mon host3。正常应该是
ceph orch apply mon "host1,host2,host3"
# 或者建议使用yaml文件规范文件
ceph orch apply -i file.yaml

# file.yaml
service_type: mon
placement:
  hosts:
   - host1
   - host2
   - host3
```



### 3.7 Deploy OSD

```shell
# 显示集群磁盘列表
ceph orch device ls

# 可作为osd的磁盘满足的条件：
# - 磁盘没有分区
# - 磁盘没有LVM状态
# - 磁盘不包括文件系统
# - 磁盘不包含ceph blusstore OSD
# - 磁盘必须大于5GB

# 应该所有可以使用的磁盘
ceph orch apply osd --all-available-devices

# 指定节点特定设备创建OSD
ceph orch daemon add osd node1:/dev/sdb

# 或指定规范的yaml文件
ceph orch apply osd -i spec.yml
# 关于yaml书写参考：https://docs.ceph.com/en/octopus/cephadm/drivegroups/#drivegroups
```



### 3.8 Deploy MDS

```shell
ceph orch apply mds *<fs-name>* --placement="*<num-daemons>* [*<host1>* ...]"

ceph orch apply mds mds --placement=node1

# *<num-daemons>*  不指定主机，以数量来自动部署

# 关于yaml规范
https://docs.ceph.com/en/octopus/mgr/orchestrator/#orchestrator-cli-placement-spec
```



### 3.9 Deploy RGWS

```shell
# 格式
ceph orch apply rgw *<realm-name>* *<zone-name>* --placement="*<num-daemons>* [*<host1>* ...]"

# 随机在集群部署2个rgw
ceph orch apply rgw realm-rgw zone-rgw --placement=2
root@node1:/etc/ceph# ceph orch apply rgw realm-rgw zone-rgw --placement=2
Scheduled rgw.realm-rgw.zone-rgw update...


# 指定集群节点部署2个rgw
ceph orch apply rgw realm-rgw zone-rgw --placement=“2 node1 node2"

# 手动部署rgw
radosgw-admin realm create --rgw-realm=<realm-name> --default
radosgw-admin zonegroup create --rgw-zonegroup=<zonegroup-name>  --master --default
radosgw-admin zone create --rgw-zonegroup=<zonegroup-name> --rgw-zone=<zone-name> --master --default
radosgw-admin period update --rgw-realm=<realm-name> --commit
```



### 3.10 Deploy NFS

```shell
# 格式
ceph orch apply nfs *<svc_id>* *<pool>* *<namespace>* --placement="*<num-daemons>* [*<host1>* ...]"

ceph orch apply nfs foo nfs-ganesha nfs-ns
# *<svc_id>* 集群名称ID
# *<pool>*	cephfs池

# 请先创建nfs-ganesha池
ceph osd pool create nfs-ganesha 64
ceph osd pool create nfs-ganesha_metadata 64
ceph fs new nfs-ganesha nfs-ganesha_metadata nfs-ganesha
```



### 3.11 Cephadm logs

```shell
# 查看cephadm日志
ceph -W cephadm

# 开启debug日志信息
ceph config set mgr mgr/cephadm/log_to_cluster_level debug
ceph -W cephadm --watch-debug

# 查看最近日志
ceph log last cephadm

# ceph Daemon日志，守护进程日志
# - 默认cephadm守护进程日志的标准输出是从容器中获取，大多系统这些日志都会发送给journalctl。
# - 比如查看集群osd.0进程日志					
journalctl -u ceph-e3670566-a1ab-11eb-b266-8bfed5f9c18f@osd.0.service
# - 可以禁用标准输出日志
ceph config set global log_to_stderr false
ceph config set global mon_cluster_log_to_stderr false


# 可以将Daemons的日志保存到文件，而不是标准输出。
# - 日志文件路径 /var/log/ceph/<cluster-fsid>
# - 开启日志
ceph config set global log_to_file true
ceph config set global mon_cluster_log_to_file true
# - 开启保存文件，应该禁用标准输出，否正保存两份日志
# - 可以配置cephadm在每台主机上的日志轮询保留计划
/etc/logrotate.d/ceph.<cluster-fsid>.
```



### 3.12 Data Location

```shell
# Cephadm 守护进程数据和日志的位置稍有不同
# - /var/log/ceph/<cluster-fsid> 所有集群日志，默认通过stderr和容器运行时没有这些日志
# - /var/lib/ceph/<cluster-fsid> 所有集群数据日志目录
# - /var/lib/ceph/<cluster-fsid>/<daemon-name> 单个进程的数据
# - /var/lib/ceph/<cluster-fsid>/crash 集群崩溃报告
# - /var/lib/ceph/<cluster-fsid>/removed 被cephadm移除的有状态守护进程的旧数据目录，如monitor，Prometheus

# /var/lib/ceph/ 存放大量数据，特别是monitor和Prometheus，建议移动到非系统磁盘，以免导致系统故障。
```



### 3.13 SSH Configuration

Cephadm 使用SSH key连接远程主机，SSH使用密钥以安全的方式与主机进行身份验证

```shell
# 创建新的密钥
ceph cephadm generate-key

# 查看公钥
ceph cephadm get-pub-key

# 删除密钥
ceph cephadm clear-key

# 可以直接导入密钥
ceph config-key set mgr/cephadm/ssh_identity_key -i <key>
ceph config-key set mgr/cephadm/ssh_identity_pub -i <pub>
```

