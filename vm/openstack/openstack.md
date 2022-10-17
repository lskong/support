---
id: openstack
title: openstack
---

- [1.OpenStack概述](#1openstack概述)
  - [1.1 OpenStack由来](#11-openstack由来)
  - [1.2 OpenStack是什么](#12-openstack是什么)
- [2.OpenStack项目和服务](#2openstack项目和服务)
  - [2.1 核心项目三个](#21-核心项目三个)
  - [2.2 共享服务项目三个](#22-共享服务项目三个)
  - [2.3 存储项目两个](#23-存储项目两个)
  - [2.4 其他项目服务](#24-其他项目服务)
- [3.OpenStack架构解析](#3openstack架构解析)
- [4.环境-CentOS7操作系统](#4环境-centos7操作系统)
  - [4.1 安全](#41-安全)
  - [4.2 主机网络](#42-主机网络)
    - [4.2.1 配置网络接口](#421-配置网络接口)
    - [4.2.2 配置域名解析](#422-配置域名解析)
    - [4.2.3 网络时间协议(NTP)](#423-网络时间协议ntp)
    - [4.2.4 OpenStack包](#424-openstack包)
    - [4.2.5 SQL数据库](#425-sql数据库)
    - [4.2.6 消息队列](#426-消息队列)
    - [4.2.7 Memcached](#427-memcached)
    - [4.2.8 Etcd](#428-etcd)
- [5.安装OpenStack Service](#5安装openstack-service)
  - [5.1 安装配置keystone](#51-安装配置keystone)
  - [5.2 创建域、项目、用户和角色](#52-创建域项目用户和角色)
  - [5.3 验证认证服务](#53-验证认证服务)
  - [5.4 创建 OpenStack 客户端环境脚本](#54-创建-openstack-客户端环境脚本)
- [6.镜像服务](#6镜像服务)
  - [6.1 安装glane先决条件](#61-安装glane先决条件)
  - [6.2 安装配置glance](#62-安装配置glance)
  - [6.3 验证](#63-验证)
- [7.Placement服务](#7placement服务)
  - [7.1 先决条件](#71-先决条件)
  - [7.2 安装placement](#72-安装placement)
  - [7.3 验证](#73-验证)
- [8.计算服务](#8计算服务)
  - [8.1 安装配置控制节点-先决条件](#81-安装配置控制节点-先决条件)
  - [8.2 安装配置控制节点](#82-安装配置控制节点)
  - [8.3 安装配置计算节点](#83-安装配置计算节点)
  - [8.3 验证操作](#83-验证操作)
- [9.Networking服务](#9networking服务)
  - [9.1 neutron概念](#91-neutron概念)
  - [9.2 安装配置控制节点](#92-安装配置控制节点)
  - [9.3 安装配置计算节点](#93-安装配置计算节点)
  - [9.4 验证](#94-验证)
- [10.dashboard](#10dashboard)



# 1.OpenStack概述

> 官方文档：https://docs.openstack.org/zh_CN/

## 1.1 OpenStack由来

**OpenStack**最早由美国国家航空航天局NASA研发的Nova和Rackspace研发的swift组成。后来以apache许可证授权,旨在为公共及私有云平台建设。OpenStack主要用来为企业内部实现类似于Amazon EC2和S3的云基础架构服务（Iaas）.每6个月更新一次，基本与ubuntu同步，命名是以A-Z作为首字母来的。

**OpenStack**系统由几个关键服务组成，它们可以单独安装。这些服务根据你的云需求工作在一起。这些服务包括计算服务、认证服务、网络服务、镜像服务、块存储服务、对象存储服务、计量服务、编排服务和数据库服务。您可以独立安装这些服务、独自配置它们或者连接成一个整体。


## 1.2 OpenStack是什么

**OpenStack**，既是一个社区，也是一个项目和一个开源软件，它提供了一个部署云的操作平台或工具集。其宗旨在于，帮助组织运行为虚拟计算或存储服务的云，为公有云、私有云，也为大云、小云提供可扩展的、灵活的云计算。
OpenStack旗下包含了一组由社区维护的开源项目，他们分别是OpenStackCompute(Nova)，OpenStackObjectStorage(Swift)，以及OpenStackImageService(Glance）

**OpenStackCompute**，为云组织的控制器，它提供一个工具来部署云，包括运行实例、管理网络以及控制用户和其他项目对云的访问 (thecloudthroughusersandprojects)。它底层的开源项目名称是Nova，其提供的软件能控制IaaS云计算平台，类似于 AmazonEC2和RackspaceCloudServers。实际上它定义的是，与运行在主机操作系统上潜在的虚拟化机制交互的驱动，暴露基于 WebAPI的功能。

**OpenStackObjectStorage**，是一个可扩展的对象存储系统。对象存储支持多种应用，比如复制和存档数据，图像或视频服务，存储次级静态数据，开发数据存储整合的新应用，存储容量难以估计的数据，为Web应用创建基于云的弹性存储。

**OpenStackImageService**，是一个虚拟机镜像的存储、查询和检索系统，服务包括的RESTfulAPI允许用户通过 HTTP请求查询VM镜像元数据，以及检索实际的镜像。VM镜像有四种配置方式：简单的文件系统，类似OpenStackObjectStorage的对 象存储系统，直接用Amazon’sSimpleStorageSolution(S3)存储，用带有ObjectStore的S3间接访问S3。


# 2.OpenStack项目和服务

服务名是项目的别名

## 2.1 核心项目三个

- 控制台

服务名：Dashboard
项目名：Horizon
功能：web方式管理云平台，建云主机，分配网络，配安全组，加云盘。

- 计算

服务名：计算
项目名：Nova（可以支持各种各样的虚拟化技术，vmware\kvm等）
功能：负责响应虚拟机创建请求、调度、销毁云主机。

- 网络

服务名：网络
项目名：Neutron（实现网络虚拟化）
功能：实现SDN（软件定义网络），提供一整套API，用户可以基于该API实现自己定义专属网络，不同厂商可以基于此API提供自己的产品实现。

## 2.2 共享服务项目三个

- 认证服务

服务名：认证服务
项目名：Keystone
功能：为访问openstack各组件提供认证和授权功能，认证通过后，提供一个服务列表（存放你有权访问的服务），可以通过该列表访问各个组件。

- 镜像服务

服务名：镜像服务
项目名：Glance
功能：为云主机安操作系统提供不同的镜像选择

- 计费服务

服务名：计费服务
项目名：Ceilometer（监控）
功能：收集云平台资源使用数据，用来计费或者性能监控

## 2.3 存储项目两个

现在主流的存储主要是三种：文件存储、块存储、对象存储

**文件存储**相当于一个大的文件夹，典型是FTP\NFS服务器，以文件作为传输协议。Ext3、Ext4、NTFS是本地文件存储，NFS、CIFS是网络文件存储（NAS存储）；最明显的特征是支持POSIX的文件访问接口：open、read、write、seek、close等；优点：便于扩展&共享；缺点：读写速度慢。

**块存储**在物理级别的最小读写单位是扇区。块存储可以认为是裸盘，最多包一层逻辑卷（LVM）；常见的DAS、FC-SAN、IP-SAN都是块存储，块存储最明显的特征就是不能被操作系统直接读写，需要格式化为指定的文件系统（Ext3、Ext4、NTFS）后才可以访问。优点：读写快（带宽&IOPS）；缺点：因为太底层了，不利于扩展。

**对象存储**将元数据独立了出来，控制节点叫元数据服务器（服务器+对象存储管理软件），里面主要负责存储对象的属性（主要是对象的数据被打散存放到了那几台分布式服务器中的信息），而其他负责存储数据的分布式服务器叫做OSD，主要负责存储文件的数据部分。当用户访问对象，会先访问元数据服务器，元数据服务器只负责反馈对象存储在哪些OSD，假设反馈文件A存储在B、C、D三台OSD，那么用户就会再次直接访问3台OSD服务器去读取数据。

基于rest api的方式访问，说穿了就是url地址。对象存储和分布式文件系统的表面区别：对象存储支持的访问接口基本都是restful接口、而分布式文件系统提供的POSIX兼容的文件操作接口；

- 对象存储

服务名：对象存储
项目名：Swift
功能：REST风格的接口和扁平的数据组织结构。RESTFUL HTTP API来保存和访问任意非结构化数据，ring环的方式实现数据自动复制和高度可以扩展架构，保证数据的高度容错和可靠性

- 块存储

服务名：块存储
项目名：Cinder
功能：提供持久化块存储，即为云主机提供附加云盘。


## 2.4 其他项目服务

- 数据库服务

服务名：数据库服务
项目名：Trove
功能：提供管理数据库即服务配置关系和非关系数据库引擎节点的Trove相关，同时提供Trove在Horizon中的管理面板

- 编排服务

服务名：编排服务
项目名：Heat
功能：自动化部署应用，自动化管理应用的整个生命周期.主要用于Paas

- Bare Metal

服务名：Bare Metal
项目名：Ironic
功能：提供裸金属管理服务，Nova Baremetal驱动程序

- Data Processing

服务名：Data Processing
项目名：Sahara
功能：使用用户能够在Openstack平台上便于创建和管理Hadoop以及其他计算框架集群

- Placement

服务名：Placement
项目名：Placement
功能：是从【nova】服务中拆分出来的组件，作用是收集各个【node】节点的可用资源，把【node】节点的资源统计写入到【MySQL】

# 3.OpenStack架构解析

整个OpenStack是由控制节点，计算节点，网络节点，存储节点四大部分组成。（这四个节点也可以安装在一台机器上，单机部署）

- 控制节点

控制节点上运行身份认证服务，镜像服务，计算服务的管理部分，网络服务的管理部分，多种网络代理以及仪表板。也需要包含一些支持服务，例如：SQL数据库，term:消息队列, and NTP。

可选的，可以在计算节点上运行部分块存储，对象存储，Orchestration 和 Telemetry 服务。

计算节点上需要至少两块网卡。

- 计算节点

计算节点上运行计算服务中管理实例的管理程序部分。默认情况下，计算服务使用 KVM。

你可以部署超过一个计算节点。每个结算节点至少需要两块网卡。

- 块存储

可选的块存储节点上包含了磁盘，块存储服务和共享文件系统会向实例提供这些磁盘。

为了简单起见，计算节点和本节点之间的服务流量使用管理网络。生产环境中应该部署一个单独的存储网络以增强性能和安全。

你可以部署超过一个块存储节点。每个块存储节点要求至少一块网卡

- 对象存储

可选的对象存储节点包含了磁盘。对象存储服务用这些磁盘来存储账号，容器和对象。

为了简单起见，计算节点和本节点之间的服务流量使用管理网络。生产环境中应该部署一个单独的存储网络以增强性能和安全。

这个服务要求两个节点。每个节点要求最少一块网卡。你可以部署超过两个对象存储节点。

- 网络-公共网络

公有网络选项使用尽可能简单的方式主要通过layer-2（网桥/交换机）服务以及VLAN网络的分割来部署OpenStack网络服务。本质上，它建立虚拟网络到物理网络的桥，依靠物理网络基础设施提供layer-3服务(路由)。额外地 ，DHCP为实例提供IP地址信息

- 网络-私有网络

私有网络选项扩展了公有网络选项，增加了启用self-service覆盖分段方法的layer-3（路由）服务，比如 `VXLAN。本质上，它使用NAT路由虚拟网络到物理网络。另外，这个选项也提供高级服务的基础，比如LBaas和FWaaS。

# 4.环境-CentOS7操作系统

以下最小需求支持概念验证环境，使用核心服务和几个CirrOS实例:
控制节点: 1 处理器, 4 GB 内存, 及5 GB 存储
计算节点: 1 处理器, 2 GB 内存, 及10 GB 存储

对于第一次安装和测试目的，很多用户选择使用virtual machine (VM)作为主机。使用虚拟机的主要好处有一下几点：
- 一台物理服务器可以支持多个节点，每个节点几乎可以使用任意数目的网络接口。
- 在安装过程中定期进行“快照”并且在遇到问题时可以“回滚”到上一个可工作配置的能力。

但是，虚拟机会降低您实例的性能，特别是如果您的 hypervisor 和/或 进程缺少硬件加速的嵌套虚拟机支持时。


## 4.1 安全

OpenStack 服务支持各种各样的安全方式，包括密码 password、policy 和 encryption，支持的服务包括数据库服务器，且消息 broker 至少支持 password 的安全方式。

可以使用如下命令来生成密码
```
$ openssl rand -hex 10
```

对 OpenStack 服务而言，本指南使用``SERVICE_PASS`` 表示服务帐号密码，使用``SERVICE_DBPASS`` 表示数据库密码。

下面的给出了需要密码的服务列表以及它们在指南中关联关系：
- 数据库密码(不能使用变量)：数据库root密码
- ADMIN_PASS：admin用户密码
- CEILOMETER_DBPASS：Telemetry 服务的数据库密码
- CEILOMETER_PASS：Telemetry 服务的 ceilometer 用户密码
- CINDER_DBPASS：块设备存储服务的数据库密码
- CINDER_PASS：块设备存储服务的 cinder 密码
- DASH_DBPASS：Database password for the dashboard
- DEMO_PASS：demo 用户的密码
- GLANCE_DBPASS：镜像服务的数据库密码
- GLANCE_PASS：镜像服务的 glance 用户密码
- HEAT_DBPASS：Orchestration服务的数据库密码
- HEAT_DOMAIN_PASS：Orchestration 域的密码
- HEAT_PASS：Orchestration 服务中``heat``用户的密码
- KEYSTONE_DBPASS：认证服务的数据库密码
- NEUTRON_DBPASS：网络服务的数据库密码
- NEUTRON_PASS：网络服务的 neutron 用户密码
- NOVA_DBPASS：计算服务的数据库密码
- NOVA_PASS：计算服务中``nova``用户的密码
- RABBIT_PASS：RabbitMQ的guest用户密码
- SWIFT_PASS：对象存储服务用户``swift``的密码


## 4.2 主机网络

- 管理网络（management network）
这个网络需要一个网关以为所有节点提供内部的管理目的的访问，例如包的安装、安全更新、 DNS，和 NTP。

- 提供者网络（provider network）
这个网络需要一个网关来提供在环境中内部实例的访问。


### 4.2.1 配置网络接口

编辑``/etc/sysconfig/network-scripts/ifcfg-INTERFACE_NAME``文件包含以下内容：
不要改变 键``HWADDR`` 和 UUID 。

```bash
DEVICE=INTERFACE_NAME
TYPE=Ethernet
ONBOOT="yes"
BOOTPROTO="none"
```

### 4.2.2 配置域名解析

设置节点主机名为 controller。
编辑/etc/hosts文件包含一下内容：

```bash
# controller
10.0.0.11       controller

# compute1
10.0.0.31       compute1

# block1
10.0.0.41       block1

# object1
10.0.0.51       object1

# object2
10.0.0.52       object2
```
一些发行版本在``/etc/hosts``文件中添加了附加条目解析实际主机名到另一个IP地址如 127.0.1.1。为了防止域名解析问题，你必须注释或者删除这些条目。不要删除127.0.0.1条目。


### 4.2.3 网络时间协议(NTP)

1.安装并配置chrony

```bash
sudo yum install chrony
```

2.编辑 ``/etc/chrony.conf`` 文件，按照你环境的要求，对下面的键进行添加，修改或者删除

```bash
server NTP_SERVER iburst
```

3.为了允许其他节点可以连接到控制节点的 chrony 后台进程，在``/etc/chrony.conf`` 文件添加下面的键：

```bash
allow 10.0.0.0/24
```

4.启动 NTP 服务并将其配置为随系统启动：

```bash
sudo systemctl enable chronyd.service
sudo systemctl start chronyd.service
sudo systemctl status chronyd.service
```

5.验证操作

```bash
sudo chronyc sources
210 Number of sources = 1
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^* 172.16.254.1                  3   6    37    19    -15us[-6103us] +/-   86ms
```

### 4.2.4 OpenStack包

版本:openstack-train

1.在CentOS中， ``extras``仓库提供用于启用 OpenStack 仓库的RPM包。 CentOS 默认启用``extras``仓库，因此你可以直接安装用于启用OpenStack仓库的包

```bash
sudo yum install centos-release-openstack-train
```

2.更新包

```bash
sudo yum upgrade
```

3.安装 OpenStack 客户端

```bash
yum install python-openstackclient
```


### 4.2.5 SQL数据库

大多数 OpenStack 服务使用 SQL 数据库来存储信息。 典型地，数据库运行在控制节点上。指南中的步骤依据不同的发行版使用MariaDB或 MySQL。OpenStack 服务也支持其他 SQL 数据库，包括PostgreSQL

1.安装数据库包
```bash
sudo yum install mariadb mariadb-server python2-PyMySQL
```

2.创建并编辑 /etc/my.cnf.d/openstack.cnf

```bash
[mysqld]
bind-address = 10.0.0.11 
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8

# 可以通过10.0.0.11网卡访问数据库
# 127.0.0.1 只允许本地访问数据库
# 0.0.0.0 允许所以网卡接口访问数据库
```

3.重启SQL

```bash
sudo systemctl enable mariadb.service
sudo systemctl start mariadb.service
```

4.为了保证数据库服务的安全性，运行``mysql_secure_installation``脚本。特别需要说明的是，为数据库的root用户设置一个适当的密码。

```bash
sudo mysql_secure_installation
```

### 4.2.6 消息队列

OpenStack 使用 message queue 协调操作和各服务的状态信息。消息队列服务一般运行在控制节点上。OpenStack支持好几种消息队列服务包括 RabbitMQ, Qpid, 和 ZeroMQ。不过，大多数发行版本的OpenStack包支持特定的消息队列服务。本指南安装 RabbitMQ 消息队列服务，因为大部分发行版本都支持它。

1.安装包

```bash
sudo yum install rabbitmq-server
```

2.启动mq

```bash
sudo systemctl enable rabbitmq-server.service
sudo systemctl start rabbitmq-server.service
```

3.添加``openstack``用户

```bash
sudo rabbitmqctl add_user openstack 123456
```

4.给``openstack``用户配置写和读权限

```bash
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"
```

### 4.2.7 Memcached

认证服务认证缓存使用Memcached缓存令牌。缓存服务memecached运行在控制节点。在生产部署中，我们推荐联合启用防火墙、认证和加密保证它的安全。

1.安装包

```bash
sudo yum install memcached python-memcached
```

2.编辑/etc/sysconfig/memcached，配置服务可以通过控制节点管理网访问

```bash
OPTIONS="-l 127.0.0.1,::1,controller"
```

3.启动服务

```bash
sudo systemctl enable memcached.service
sudo systemctl start memcached.service
```

### 4.2.8 Etcd

OpenStack Services可以使用ETCD，这是一个可靠的可靠键值商店，用于分布式键锁定，存储配置，跟踪服务现场性和其他方案。ETCD服务在控制器节点上运行。

1.安装包

```bash
sudo yum install etcd
```

2.编辑/etc/etcd/etcd.conf，配置可以通过控制节点管理网访问

```bash
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://10.0.0.11:2380"
ETCD_LISTEN_CLIENT_URLS="http://10.0.0.11:2379"
ETCD_NAME="controller"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.0.0.11:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://10.0.0.11:2379"
ETCD_INITIAL_CLUSTER="controller=http://10.0.0.11:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"
```

3.启动服务

```bash
sudo systemctl enable etcd
sudo systemctl start etcd
```

# 5.安装OpenStack Service

OpenStack `Identity service`为认证管理，授权管理和服务目录服务管理提供单点整合。其它OpenStack服务将身份认证服务当做通用统一API来使用。此外，提供用户信息但是不在OpenStack项目中的服务（如LDAP服务）可被整合进先前存在的基础设施中。

为了从identity服务中获益，其他的OpenStack服务需要与它合作。当某个OpenStack服务收到来自用户的请求时，该服务询问Identity服务，验证该用户是否有权限进行此次请求。

身份服务包含这些组件：

- 服务器
一个中心化的服务器使用RESTful 接口来提供认证和授权服务

- 驱动
驱动或服务后端被整合进集中式服务器中。它们被用来访问OpenStack外部仓库的身份信息, 并且它们可能已经存在于OpenStack被部署在的基础设施（例如，SQL数据库或LDAP服务器）中。

- 模块
中间件模块运行于使用身份认证服务的OpenStack组件的地址空间中。这些模块拦截服务请求，取出用户凭据，并将它们送入中央是服务器寻求授权。中间件模块和OpenStack组件间的整合使用Python Web服务器网关接口。

当安装OpenStack身份服务，用户必须将之注册到其OpenStack安装环境的每个服务。身份服务才可以追踪那些OpenStack服务已经安装，以及在网络中定位它们。

## 5.1 安装配置keystone

1.创建数据库，并授权

```bash
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'keystone';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'keystone';
```

2.安装包

```bash
sudo yum install openstack-keystone httpd mod_wsgi
```

3.编辑/etc/keystone/keystone.conf

```bash
[database]
# ...
connection = mysql+pymysql://keystone:keystone@controller/keystone

[token]
# ...
provider = fernet
```

4.初始化身份认证服务的数据库

```bash
su -s /bin/sh -c "keystone-manage db_sync" keystone
```

5.初始化Fernet keys

```bash
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
```

6.引导 Identity 服务

```bash
sudo keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

sudo keystone-manage bootstrap --bootstrap-password 123456 \
  --bootstrap-admin-url http://172.16.103.31:5000/v3/ \
  --bootstrap-internal-url http://172.16.103.31:5000/v3/ \
  --bootstrap-public-url http://172.16.103.31:5000/v3/ \
  --bootstrap-region-id RegionOne
```

7.配置apache服务，编辑/etc/httpd/conf/httpd.conf

```bash
ServerName controller
```

8.创建http服务的软连接文件

```bash
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
```

9.启动服务

```bash
sudo systemctl enable httpd.service
sudo systemctl start httpd.service
```

10.设置环境变量，编辑/etc/profile

```bash
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
```

## 5.2 创建域、项目、用户和角色

在初始化时，系统已经生产了默认的域，这里只是介绍创建方法。

1.创建域

```bash
$ openstack domain create --description "An Example Domain" example

+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | An Example Domain                |
| enabled     | True                             |
| id          | 2f4f80574fd84fe6ba9067228ae0a50c |
| name        | example                          |
| tags        | []                               |
+-------------+----------------------------------+
```

2.创建项目

```bash
$ openstack project create --domain default \
  --description "Service Project" service

+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Service Project                  |
| domain_id   | default                          |
| enabled     | True                             |
| id          | 9629192ce6fe4542934508b1e959467e |
| is_domain   | False                            |
| name        | service                          |
| options     | {}                               |
| parent_id   | default                          |
| tags        | []                               |
+-------------+----------------------------------+
```


3.创建用户

```bash
$ openstack user create --domain default \
  --password-prompt myuser

+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | 6f7d32c3b2d84d1ea41a213731a6dff7 |
| name                | myuser                           |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+
```

4.创建角色

```bash
$ openstack role create myrole

+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | None                             |
| domain_id   | None                             |
| id          | 8e85569ec51246fc9b1de0645acf7532 |
| name        | myrole                           |
| options     | {}                               |
+-------------+----------------------------------+
```

5.管理项目、用户和角色

```bash
$ openstack role add --project service --user myuser myrole
```

## 5.3 验证认证服务


1.管理员用户，请求认证令牌

```bash
$ openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name admin --os-username admin token issue

$ openstack --os-auth-url http://172.16.103.31:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name admin --os-username admin token issue
```

2.myuser用户，请求认证令牌

```
$ openstack --os-auth-url http://172.16.103.31:5000/v3 \
  --os-project-domain-name Default --os-user-domain-name Default \
  --os-project-name service --os-username myuser token issue
```

## 5.4 创建 OpenStack 客户端环境脚本

1.admin用户，环境脚本

编辑``.admin-openrc``文件

```bash
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=123456
export OS_AUTH_URL=http://172.16.103.31:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```

2.myuser用户，环境脚本

编辑``.myuser-openrc``文件

```bash
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=service
export OS_USERNAME=myuser
export OS_PASSWORD=123456
export OS_AUTH_URL=http://172.16.103.31:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```

3.使用脚本

```bash
source .admin-openrc
openstack token issue
```



# 6.镜像服务

镜像服务 (glance) 允许用户发现、注册和获取虚拟机镜像。它提供了一个 REST API，允许您查询虚拟机镜像的 metadata 并获取一个现存的镜像。您可以将虚拟机镜像存储到各种位置，从简单的文件系统到对象存储系统—-例如 OpenStack 对象存储, 并通过镜像服务使用。

OpenStack镜像服务包括以下组件：

- glance-api
接收镜像API的调用，诸如镜像发现、恢复、存储

- glance-registry
存储、处理和恢复镜像的元数据，元数据包括项诸如大小和类型

- 数据库
存放镜像元数据，用户是可以依据个人喜好选择数据库的，多数的部署使用MySQL或SQLite。

- 镜像文件的存储仓库
支持多种类型的仓库，它们有普通文件系统、对象存储、RADOS块设备、HTTP、以及亚马逊S3。记住，其中一些仓库仅支持只读方式使用。

- 元数据定义服务
通用的API，是用于为厂商，管理员，服务，以及用户自定义元数据。这种元数据可用于不同的资源，例如镜像，工件，卷，配额以及集合。一个定义包括了新属性的键，描述，约束以及可以与之关联的资源的类型。

## 6.1 安装glane先决条件

1.创建数据库

```bash
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
  IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
  IDENTIFIED BY '123456';
```

2.使用admin脚本

```bash
source .admin-openrc
```

3.创建服务证书glane用户

```bash
$ openstack user create --domain default --password-prompt glance

+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | c8261ed480c941fc9032cd463151fc2d |
| name                | glance                           |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+
```

4.添加 admin 角色到 glance 用户和 service 项目上

```bash
$ openstack role add --project service --user glance admin
```

5.创建``glance``服务实体

```bash
$ openstack service create --name glance \
  --description "OpenStack Image" image

+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Image                  |
| enabled     | True                             |
| id          | 62f8231112e34635b6d1f696901dbb7e |
| name        | glance                           |
| type        | image                            |
+-------------+----------------------------------+
```

6.创建镜像服务的 API 端点

```bash
$ openstack endpoint create --region RegionOne \
  image public http://172.16.103.31:9292

+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 22a0d3dca74648c489ed8267567a2ab1 |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 62f8231112e34635b6d1f696901dbb7e |
| service_name | glance                           |
| service_type | image                            |
| url          | http://172.16.103.31:9292        |
+--------------+----------------------------------+
```

## 6.2 安装配置glance

1.安装包

```bash
sudo yum install openstack-glance
```

2.编辑/etc/glance/glance-api.conf

```bash
[database]
# ...
connection = mysql+pymysql://glance:123456@172.16.103.31/glance

[keystone_authtoken]
# ...
www_authenticate_uri  = http://172.16.103.31:5000
auth_url = http://172.16.103.31:5000
memcached_servers = 172.16.103.31:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = 123456

[paste_deploy]
# ...
flavor = keystone

[glance_store]
# ...
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/
```

3.写入镜像服务数据库

```bash
sudo su -s /bin/sh -c "glance-manage db_sync" glance
```

4.启动服务

```bash
sudo systemctl enable openstack-glance-api.service
sudo systemctl start openstack-glance-api.service
```

## 6.3 验证

1.使用admin用户

```bash
source .admin-openrc
```

2.下载镜像

```bash
$ wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
```

3.使用 QCOW2 磁盘格式， bare 容器格式上传镜像到镜像服务并设置公共可见，这样所有的项目都可以访问它

```bash
$ openstack image create "cirros" \
  --file cirros-0.3.4-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --public

$ glance image-list
+--------------------------------------+--------+
| ID                                   | Name   |
+--------------------------------------+--------+
| bc41077c-3ccd-4925-9df0-de27fb582627 | cirros |
+--------------------------------------+--------+
```


# 7.Placement服务

placement提供了一个 WSGI 脚本，用于使用 Apache、nginx 或其他支持 WSGI 的 Web 服务器运行服务。根据部署 OpenStack 的打包解决方案，WSGI 脚本可能位于 或 中。placement-api /usr/bin /usr/local/bin

## 7.1 先决条件

1.创建数据库

```bash
CREATE DATABASE placement;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' \
  IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' \
  IDENTIFIED BY '123456';
```

2.使用admin

```bash
source .admin-openrc
```

3.创建服务用户

```bash
$ openstack user create --domain default --password-prompt placement

+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | d2710ae0143e426ca6bd43d0911ed2b1 |
| name                | placement                        |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+
```

4.添加用户服务角色

```bash
$ openstack role add --project service --user placement admin
```

5.在服务目录中创建位置API条目

```bash
$ openstack service create --name placement \
  --description "Placement API" placement

+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Placement API                    |
| enabled     | True                             |
| id          | 6f9ea3f095db4adfafe4b53a405ef8d8 |
| name        | placement                        |
| type        | placement                        |
+-------------+----------------------------------+
```

6.创建位置API服务挂载点

```bash
$ openstack endpoint create --region RegionOne \
  placement public http://172.16.103.31:8778

+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 6a8a25ca6e4640289a813f8b775b449e |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 6f9ea3f095db4adfafe4b53a405ef8d8 |
| service_name | placement                        |
| service_type | placement                        |
| url          | http://172.16.103.31:8778        |
+--------------+----------------------------------+
```

## 7.2 安装placement

1.安装包

```bash
yum install openstack-placement-api
```

2.编辑/etc/placement/placement.conf文件

```bash
[placement_database]
# ...
connection = mysql+pymysql://placement:123456@172.16.103.31/placement

[api]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
auth_url = http://172.16.103.31:5000/v3
memcached_servers = 172.16.103.31:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = 123456
```

3.初始化数据库

```bash
su -s /bin/sh -c "placement-manage db sync" placement
```

4.重启http服务

```bash
systemctl restart httpd
```

## 7.3 验证

1.使用admin用户，查看placement状态

```bash
$ source .admin-openrc

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

2.采用工具来验证

```bash
$ yum -y install python3-pip
$ pip3 install mock
$ pip3 install rust
$ pip3 install osc-placement

$ openstack --os-placement-api-version 1.2 resource class list --sort-column name
```


# 8.计算服务

使用OpenStack计算服务来托管和管理云计算系统。OpenStack计算服务是基础设施即服务(IaaS)系统的主要部分，模块主要由Python实现。

OpenStack计算服务由下列组件所构成：

- nova-api 服务
接收和响应来自最终用户的计算API请求。此服务支持OpenStack计算服务API，Amazon EC2 API，以及特殊的管理API用于赋予用户做一些管理的操作。它会强制实施一些规则，发起多数的编排活动，例如运行一个实例。

- nova-api-metadata 服务
接受来自虚拟机发送的元数据请求。``nova-api-metadata``服务一般在安装``nova-network``服务的多主机模式下使用。

- nova-compute 服务
一个持续工作的守护进程，通过Hypervior的API来创建和销毁虚拟机实例。

- nova-scheduler 服务
拿到一个来自队列请求虚拟机实例，然后决定那台计算服务器主机来运行它。

- nova-conductor 模块
媒介作用于``nova-compute``服务与数据库之间。它排除了由``nova-compute``服务对云数据库的直接访问。nova-conductor模块可以水平扩展。但是，不要将它部署在运行``nova-compute``服务的主机节点上。

- nova-cert 模块
服务器守护进程向Nova Cert服务提供X509证书。用来为``euca-bundle-image``生成证书。仅仅是在EC2 API的请求中使用

- nova-network worker 守护进程
与``nova-compute``服务类似，从队列中接受网络任务，并且操作网络。执行任务例如创建桥接的接口或者改变IPtables的规则。

- nova-consoleauth 守护进程
授权控制台代理所提供的用户令牌。详情可查看``nova-novncproxy``和 ``nova-xvpvncproxy``。该服务必须为控制台代理运行才可奏效。在集群配置中你可以运行二者中任一代理服务而非仅运行一个``nova-consoleauth``服务。

- nova-novncproxy 守护进程
提供一个代理，用于访问正在运行的实例，通过VNC协议，支持基于浏览器的novnc客户端。

- nova-spicehtml5proxy 守护进程
提供一个代理，用于访问正在运行的实例，通过 SPICE 协议，支持基于浏览器的 HTML5 客户端。

- nova-xvpvncproxy 守护进程
提供一个代理，用于访问正在运行的实例，通过VNC协议，支持OpenStack特定的Java客户端。

- nova-cert 守护进程
X509 证书。

- nova 客户端
用于用户作为租户管理员或最终用户来提交命令。

- 队列
一个在守护进程间传递消息的中央集线器。

- SQL数据库
存储构建时和运行时的状态，为云基础设施

## 8.1 安装配置控制节点-先决条件

1.创建数据库

```sql
CREATE DATABASE nova_api;
CREATE DATABASE nova;
CREATE DATABASE nova_cell0;

GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
  IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
  IDENTIFIED BY '123456';

GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
  IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
  IDENTIFIED BY '123456';

GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' \
  IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' \
  IDENTIFIED BY '123456';
```

2.使用admin，创建Compute服务证书

```bash
$ openstack user create --domain default --password-prompt nova

+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | fb9e8a8bb0904423bac69e70bb903485 |
| name                | nova                             |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+
```

3.添加role和user

```bash
$ openstack role add --project service --user nova admin
```

4.创建NOVA服务实体

```bash
$ openstack service create --name nova \
  --description "OpenStack Compute" compute

+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Compute                |
| enabled     | True                             |
| id          | cad96e7a3757412d9e5bac7df892392b |
| name        | nova                             |
| type        | compute                          |
+-------------+----------------------------------+
```

5.创建计算API服务端点

```bash
$ openstack endpoint create --region RegionOne \
  compute public http://172.16.103.31:8774/v2.1

+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 47ca69c45c57415fa2d054d80cfdd765 |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | cad96e7a3757412d9e5bac7df892392b |
| service_name | nova                             |
| service_type | compute                          |
| url          | http://172.16.103.31:8774/v2.1   |
+--------------+----------------------------------+
```

## 8.2 安装配置控制节点

1.安装包

```bash
yum install openstack-nova-api openstack-nova-conductor \
  openstack-nova-novncproxy openstack-nova-scheduler
```

2.编辑/etc/nova/nova.conf文件，修改配置

```conf
[DEFAULT]
# ...
enabled_apis = osapi_compute,metadata   # 启用计算和元数据AP

[api_database]
# ...
connection = mysql+pymysql://nova:123456@172.16.103.31/nova_api     # api配置数据库的连接

[database]
# ...
connection = mysql+pymysql://nova:123456@172.16.103.31/nova     # 配置数据库的连接

[DEFAULT]
# ...
transport_url = rabbit://openstack:123456@172.16.103.31:5672/     # 配置 RabbitMQ 消息队列访问

[api]
# ...
auth_strategy = keystone        # 配置认证服务访问

[keystone_authtoken]
# ...
www_authenticate_uri = http://172.16.103.31:5000/
auth_url = http://172.16.103.31:5000/
memcached_servers = 172.16.103.31:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = 123456

[DEFAULT]
# ...
my_ip = 0.0.0.0   # 配置接口IP

[DEFAULT]
# ...
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver   # 使能 Networking 服务

[vnc]
enabled = true
# ...
server_listen = $my_ip
server_proxyclient_address = $my_ip       # 配置vnc访问接口

[glance]
# ...
api_servers = http://172.16.103.31:9292     # 配置认证服务api

[oslo_concurrency]
# ...
lock_path = /var/lib/nova/tmp     # 配置锁路径

[placement]     # 配置连接placement
# ...
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://172.16.103.31:5000/v3
username = placement
password = 123456
```

3.初始化nova_api数据库

```bash
$ su -s /bin/sh -c "nova-manage api_db sync" nova
```

4.初始化map_cell0数据库

```bash
$ su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
```

5.创建cell1

```bash
$ su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
```

6.初始化nova数据库

```bash
$ su -s /bin/sh -c "nova-manage db sync" nova
```

7.验证Nova Cell0和Cell1已正确注册

```bash
$ su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

+-------+--------------------------------------+---------------------------------------------+----------------------------------------------------+----------+
|  Name |                 UUID                 |                Transport URL                |                Database Connection                 | Disabled |
+-------+--------------------------------------+---------------------------------------------+----------------------------------------------------+----------+
| cell0 | 00000000-0000-0000-0000-000000000000 |                    none:/                   | mysql+pymysql://nova:****@172.16.103.31/nova_cell0 |  False   |
| cell1 | 0014a133-75f5-46f6-9120-d35fa8507f8e | rabbit://openstack:****@172.16.103.31:5672/ |    mysql+pymysql://nova:****@172.16.103.31/nova    |  False   |
+-------+--------------------------------------+---------------------------------------------+----------------------------------------------------+----------+
```

8.启动服务

```bash
$ systemctl enable \
    openstack-nova-api.service \
    openstack-nova-scheduler.service \
    openstack-nova-conductor.service \
    openstack-nova-novncproxy.service
$ systemctl start \
    openstack-nova-api.service \
    openstack-nova-scheduler.service \
    openstack-nova-conductor.service \
    openstack-nova-novncproxy.service
```


## 8.3 安装配置计算节点

1.安装包

```bash
$ yum install openstack-nova-compute
```

2.编辑/etc/nova/nova.conf

```conf
[DEFAULT]
# ...
enabled_apis = osapi_compute,metadata

[DEFAULT]
# ...
transport_url = rabbit://openstack:RABBIT_PASS@controller

[api]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
www_authenticate_uri = http://controller:5000/
auth_url = http://controller:5000/
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS

[DEFAULT]
# ...
my_ip = MANAGEMENT_INTERFACE_IP_ADDRESS

[DEFAULT]
# ...
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver

[vnc]
# ...
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = $my_ip
novncproxy_base_url = http://controller:6080/vnc_auto.html

[glance]
# ...
api_servers = http://controller:9292

[oslo_concurrency]
# ...
lock_path = /var/lib/nova/tmp

[placement]
# ...
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = PLACEMENT_PASS
```

3.确定计算节点是否支持虚拟机的硬件加速

```bash
$ egrep -c '(vmx|svm)' /proc/cpuinfo

# 如果这个命令返回了 大于1，那么计算节点支持硬件加速且不需要额外的配置。
# 如果这个命令返回了 等于0，那么计算节点不支持硬件加速。必须配置 libvirt 来使用 QEMU 去代替 KVM。

vi /etc/nova/nova.conf
[libvirt]
...
virt_type = qemu
```

4.启动服务

```bash
$ systemctl enable libvirtd.service openstack-nova-compute.service
$ systemctl start libvirtd.service openstack-nova-compute.service
```

5.添加计算节点到cell数据库

```bash
$ source admin-openrc

$ openstack compute service list --service nova-compute
+----+--------------+----------------------+------+---------+-------+----------------------------+
| ID | Binary       | Host                 | Zone | Status  | State | Updated At                 |
+----+--------------+----------------------+------+---------+-------+----------------------------+
|  6 | nova-compute | openstack-controller | nova | enabled | up    | 2022-09-07T03:06:59.000000 |
+----+--------------+----------------------+------+---------+-------+----------------------------+
```

6.发现计算节点

```bash
$ su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

Found 2 cell mappings.
Skipping cell0 since it does not contain hosts.
Getting computes from cell 'cell1': 0014a133-75f5-46f6-9120-d35fa8507f8e
Checking host mapping for compute host 'openstack-controller': 15654f16-c9c5-4acf-86be-57d2117ff406
Creating host mapping for compute host 'openstack-controller': 15654f16-c9c5-4acf-86be-57d2117ff406
Found 1 unmapped computes in cell: 0014a133-75f5-46f6-9120-d35fa8507f8e


# 添加新的计算节点时，必须在控制器节点上运行Nova-Manage Cell_V2 Discover_host才能注册这些新的计算节点。另外，您可以在/etc/nova/nova.conf中设置适当的间隔：
[scheduler]
discover_hosts_in_cells_interval = 300
```

## 8.3 验证操作

1.列出服务组件以验证每个过程的成功启动和注册

```bash
$ openstack compute service list
+----+----------------+----------------------+----------+---------+-------+----------------------------+
| ID | Binary         | Host                 | Zone     | Status  | State | Updated At                 |
+----+----------------+----------------------+----------+---------+-------+----------------------------+
|  3 | nova-conductor | openstack-controller | internal | enabled | up    | 2022-09-07T03:14:11.000000 |
|  5 | nova-scheduler | openstack-controller | internal | enabled | up    | 2022-09-07T03:14:15.000000 |
|  6 | nova-compute   | openstack-controller | nova     | enabled | up    | 2022-09-07T03:14:19.000000 |
+----+----------------+----------------------+----------+---------+-------+----------------------------+
```

2.列出身份服务中的API端点，以验证与身份服务的连接

```bash
$ openstack catalog list
+-----------+-----------+-------------------------------------------+
| Name      | Type      | Endpoints                                 |
+-----------+-----------+-------------------------------------------+
| glance    | image     | RegionOne                                 |
|           |           |   public: http://172.16.103.31:9292       |
|           |           |                                           |
| placement | placement | RegionOne                                 |
|           |           |   public: http://172.16.103.31:8778       |
|           |           |                                           |
| keystone  | identity  | RegionOne                                 |
|           |           |   public: http://172.16.103.31:5000/v3/   |
|           |           | RegionOne                                 |
|           |           |   internal: http://172.16.103.31:5000/v3/ |
|           |           | RegionOne                                 |
|           |           |   admin: http://172.16.103.31:5000/v3/    |
|           |           |                                           |
| nova      | compute   | RegionOne                                 |
|           |           |   public: http://172.16.103.31:8774/v2.1  |
|           |           | RegionOne                                 |
|           |           |   public: http://controller:8774/v2.1     |
|           |           |                                           |
+-----------+-----------+-------------------------------------------+
```

3.列出镜像列表

```bash
$ openstack image list
+--------------------------------------+--------+--------+
| ID                                   | Name   | Status |
+--------------------------------------+--------+--------+
| bc41077c-3ccd-4925-9df0-de27fb582627 | cirros | active |
+--------------------------------------+--------+--------+
```

4.检查单元格和放置API正在成功工作，并且还有其他必要的先决条件

```bash
$ nova-status upgrade check

+--------------------------------------------------------------------+
| Upgrade Check Results                                              |
+--------------------------------------------------------------------+
| Check: Cells v2                                                    |
| Result: Success                                                    |
| Details: None                                                      |
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



# 9.Networking服务

OpenStack Networking（neutron），允许创建、插入接口设备，这些设备由其他的OpenStack服务管理。插件式的实现可以容纳不同的网络设备和软件，为OpenStack架构与部署提供了灵活性。

它包含下列组件：

- neutron-server
接收和路由API请求到合适的OpenStack网络插件，以达到预想的目的。

- OpenStack网络插件和代理
插拔端口，创建网络和子网，以及提供IP地址，这些插件和代理依赖于供应商和技术而不同，OpenStack网络基于插件和代理为Cisco 虚拟和物理交换机、NEC OpenFlow产品，Open vSwitch,Linux bridging以及VMware NSX 产品穿线搭桥。

常见的代理L3(3层)，DHCP(动态主机IP地址)，以及插件代理。

- 消息队列
大多数的OpenStack Networking安装都会用到，用于在neutron-server和各种各样的代理进程间路由信息。也为某些特定的插件扮演数据库的角色，以存储网络状态



## 9.1 neutron概念

OpenStack网络（neutron）管理OpenStack环境中所有虚拟网络基础设施（VNI），物理网络基础设施（PNI）的接入层。OpenStack网络允许租户创建包括像 firewall，`load balancer`和`virtual private network (VPN)`等这样的高级虚拟网络拓扑。

网络服务提供网络，子网以及路由这些对象的抽象概念。每个抽象概念都有自己的功能，可以模拟对应的物理设备：网络包括子网，路由在不同的子网和网络间进行路由转发。

对于任意一个给定的网络都必须包含至少一个外部网络。不像其他的网络那样，外部网络不仅仅是一个定义的虚拟网络。相反，它代表了一种OpenStack安装之外的能从物理的，外部的网络访问的视图。外部网络上的IP地址可供外部网络上的任意的物理设备所访问。

外部网络之外，任何 Networking 设置拥有一个或多个内部网络。这些软件定义的网络直接连接到虚拟机。仅仅在给定网络上的虚拟机，或那些在通过接口连接到相近路由的子网上的虚拟机，能直接访问连接到那个网络上的虚拟机。

如果外部网络想要访问实例或者相反实例想要访问外部网络，那么网络之间的路由就是必要的了。每一个路由都配有一个网关用于连接到外部网络，以及一个或多个连接到内部网络的接口。就像一个物理路由一样，子网可以访问同一个路由上其他子网中的机器，并且机器也可以访问路由的网关访问外部网络。

另外，你可以将外部网络的IP地址分配给内部网络的端口。不管什么时候一旦有连接连接到子网，那个连接被称作端口。你可以给实例的端口分配外部网络的IP地址。通过这种方式，外部网络上的实体可以访问实例.

网络服务同样支持安全组。安全组允许管理员在安全组中定义防火墙规则。一个实例可以属于一个或多个安全组，网络为这个实例配置这些安全组中的规则，阻止或者开启端口，端口范围或者通信类型。

每一个Networking使用的插件都有其自有的概念。虽然对操作VNI和OpenStack环境不是至关重要的，但理解这些概念能帮助你设置Networking。所有的Networking安装使用了一个核心插件和一个安全组插件(或仅是空操作安全组插件)。另外，防火墙即服务(FWaaS)和负载均衡即服务(LBaaS)插件是可用的。


## 9.2 安装配置控制节点

1.创建neutron数据库

```sql
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY '123456';
```

2.创建neutron用户

```bash
$ source /root/.admin-openrc

$ openstack user create --domain default --password-prompt neutron
User Password:
Repeat User Password:
+---------------------+----------------------------------+
| Field               | Value                            |
+---------------------+----------------------------------+
| domain_id           | default                          |
| enabled             | True                             |
| id                  | bf94d55865d84896b5f7df1766b9babf |
| name                | neutron                          |
| options             | {}                               |
| password_expires_at | None                             |
+---------------------+----------------------------------+
```

3.添加admin用户角色

```bash
$ openstack role add --project service --user neutron admin
```

4.创建neutron服务实体

```bash
$ openstack service create --name neutron \
  --description "OpenStack Networking" network

+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Networking             |
| enabled     | True                             |
| id          | e7d6c3dba3504ea5becfa59d9223f6db |
| name        | neutron                          |
| type        | network                          |
+-------------+----------------------------------+
```

5.创建网络服务api

```bash
$ openstack endpoint create --region RegionOne \
  network public http://172.16.103.31:9696

+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 4fd4c0dd35184b3d808bb3846d5b5865 |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | e7d6c3dba3504ea5becfa59d9223f6db |
| service_name | neutron                          |
| service_type | network                          |
| url          | http://172.16.103.31:9696        |
+--------------+----------------------------------+


$ openstack endpoint create --region RegionOne \
  network internal http://172.16.103.31:9696

+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 514902fb1c8e461490e4eec0a708b7fe |
| interface    | internal                         |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | e7d6c3dba3504ea5becfa59d9223f6db |
| service_name | neutron                          |
| service_type | network                          |
| url          | http://172.16.103.31:9696        |
+--------------+----------------------------------+

$ openstack endpoint create --region RegionOne \
  network admin http://172.16.103.31:9696

+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 0066e79f783b454fbb92b6660d82c221 |
| interface    | admin                            |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | e7d6c3dba3504ea5becfa59d9223f6db |
| service_name | neutron                          |
| service_type | network                          |
| url          | http://172.16.103.31:9696        |
+--------------+----------------------------------+
```

6.配置网络选项
您可以部署网络服务使用选项1和选项2两种架构中的一种来部署网络服务。

选项1采用尽可能简单的架构进行部署，只支持实例连接到公有网络（外部网络）。没有私有网络（个人网络），路由器以及浮动IP地址。只有``admin``或者其他特权用户才可以管理公有网络

选项2在选项1的基础上多了layer－3服务，支持实例连接到私有网络。``demo``或者其他没有特权的用户可以管理自己的私有网络，包含连接公网和私网的路由器。另外，浮动IP地址可以让实例使用私有网络连接到外部网络，例如互联网

典型的私有网络一般使用覆盖网络。覆盖网络，例如VXLAN包含了额外的数据头，这些数据头增加了开销，减少了有效内容和用户数据的可用空间。在不了解虚拟网络架构的情况下，实例尝试用以太网 最大传输单元 (MTU) 1500字节发送数据包。网络服务会自动给实例提供正确的MTU的值通过DHCP的方式。但是，一些云镜像并没有使用DHCP或者忽视了DHCP MTU选项，要求使用元数据或者脚本来进行配置

6.1.选项1：公网网络

```conf
# 1.安装包
$ yum install openstack-neutron \
  openstack-neutron-server openstack-neutron-linuxbridge-agent \
  openstack-neutron-dhcp-agent openstack-neutron-metadata-agent \
  bridge-utils

# 2.编辑/etc/neutron/neutron.conf
[database]  # 连接数据库
# ...
connection = mysql+pymysql://neutron:123456@172.16.103.31/neutron

[DEFAULT]   # 在[默认]部分中，启用模块化层2（ML2）插件，并禁用其他插件
# ...
core_plugin = ml2
service_plugins =

[DEFAULT]   # 连接mq
# ...
transport_url = rabbit://openstack:123456@172.16.103.31

[DEFAULT]
# ...
auth_strategy = keystone

[keystone_authtoken]    # 连接keystone
# ...
www_authenticate_uri = http://172.16.103.31:5000
auth_url = http://172.16.103.31:5000
memcached_servers = 172.16.103.31:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = 123456

[DEFAULT]
# ...
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true

[nova]    # 连接nova
# ...
auth_url = http://172.16.103.31:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = 123456

[oslo_concurrency]
# ...
lock_path = /var/lib/neutron/tmp


# 3.配置 Modular Layer 2 (ML2) 插件
# 编辑/etc/neutron/plugins/ml2/ml2_conf.ini
[ml2]
type_drivers = flat,vlan      # 启动ml2插件
tenant_network_types =        # 禁用私有网络
mechanism_drivers = linuxbridge   # 启动Linuxbridge机制
extension_drivers = port_security   # 启用端口安全扩展驱动

[ml2_type_flat]
flat_networks = provider      # 配置公共虚拟网络为flat网络

[securitygroup]
enable_ipset = true   # 启用 ipset 增加安全组规则的高效性


# 4.配置Linuxbridge代理
# 编辑/etc/neutron/plugins/ml2/linuxbridge_agent.ini
[linux_bridge]      # 将公共虚拟网络和公共物理网络接口对应起来
physical_interface_mappings = provider:eth0

[vxlan]     # 禁止VXLAN覆盖网络
enable_vxlan = False

[securitygroup]       # 启用安全组并配置 Linuxbridge iptables firewall driver
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

# 5.内核添加配置，启动内核网络桥接支持
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1

# 7.配置dhcp
# 编辑/etc/neutron/dhcp_agent.ini
[DEFAULT]
interface_driver = linuxbridge
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
```

6.2.选项2：私有网络

```conf
# 1.安装包
$ yum install openstack-neutron openstack-neutron-ml2 \
  openstack-neutron-linuxbridge ebtables

# 2.编辑/etc/neutron/neutron.conf
[database]
# 配置访问数据库
connection = mysql+pymysql://neutron:123456@172.16.103.31/neutron

[DEFAULT]
# 启用Modular Layer 2 (ML2)插件，路由服务和重叠的IP地址
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = true

[DEFAULT]
# 配置MQ
transport_url = rabbit://openstack:123456@172.16.103.31

[DEFAULT]
# 配置认证服务
auth_strategy = keystone

[keystone_authtoken]
# ...
www_authenticate_uri = http://172.16.103.31:5000
auth_url = http://172.16.103.31:5000
memcached_servers = 172.16.103.31:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = 123456

[DEFAULT]
# 配置网络服务来通知计算节点的网络拓扑变化
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true

[nova]
# ...
auth_url = http://172.16.103.31:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = 123456

[oslo_concurrency]
# 配置锁路径
lock_path = /var/lib/neutron/tmp


# 3.配置 Modular Layer 2 (ML2) 插件
# 编辑/etc/neutron/plugins/ml2/ml2_conf.ini

[ml2]
# ...
type_drivers = flat,vlan,vxlan      # 启用flat，VLAN以及VXLAN网络
tenant_network_types = vxlan        # 启用VXLAN私有网络
mechanism_drivers = linuxbridge,l2population      # 启用Linuxbridge和layer－2机制
extension_drivers = port_security   # 启用端口安全扩展驱动

[ml2_type_flat]
# 配置公共虚拟网络为flat网络
flat_networks = provider

[ml2_type_vxlan]
# 为私有网络配置VXLAN网络识别的网络范围
vni_ranges = 1:1000

[securitygroup]
# 启用 ipset 增加安全组规则的高效性
enable_ipset = true


# 4.配置Linuxbridge代理
# 编辑/etc/neutron/plugins/ml2/linuxbridge_agent.ini

[linux_bridge]      # 将公共虚拟网络和公共物理网络接口对应起来
physical_interface_mappings = provider:eth0

[vxlan]   # 启用VXLAN覆盖网络，配置覆盖网络的物理网络接口的IP地址，启用layer－2 population
enable_vxlan = True
local_ip = 172.16.103.31
l2_population = True

[securitygroup]   # 启用安全组并配置 Linuxbridge iptables firewall driver:
# ...
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver


# 5.内核添加配置，启动内核网络桥接支持
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1

# 6.配置layer-3代理
# 编辑/etc/neutron/l3_agent.ini
[DEFAULT]
# ...
interface_driver = linuxbridge

# 7.配置DHCP代理
# 编辑/etc/neutron/dhcp_agent.ini
[DEFAULT]
# ...
interface_driver = linuxbridge
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
```


7.配置元数据代理，编辑/etc/neutron/metadata_agent.ini

```conf
[DEFAULT]
nova_metadata_ip = 172.16.103.31
metadata_proxy_shared_secret = 123456
```

8.编辑/etc/nova/nova.conf配置文件

```conf
[neutron]
# ...
auth_url = http://172.16.103.31:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = 123456
service_metadata_proxy = true
metadata_proxy_shared_secret = 123456

```


9.完成配置

```bash
# 1.创建软连接
$ ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

# 2.生成数据库
$ su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

# 3.重启nova_api
$ systemctl restart openstack-nova-api.service

# 4.选项1
$ systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
$ systemctl start neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service

# 5.选项2
$ systemctl enable neutron-l3-agent.service
$ systemctl start neutron-l3-agent.service
```


## 9.3 安装配置计算节点

1.安装组件

```bash
$ yum install openstack-neutron-linuxbridge ebtables ipset
```

2.配置通用组件，编辑/etc/neutron/neutron.conf

```conf
[DEFAULT]
# 配置连接MQ
transport_url = rabbit://openstack:RABBIT_PASS@controller

[DEFAULT]
# ...
auth_strategy = keystone

[keystone_authtoken]
# 配置认证服务
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_PASS

[oslo_concurrency]
# 配置锁路径
lock_path = /var/lib/neutron/tmp
```

3.配置网络

选项1：公网网络

编辑/etc/neutron/plugins/ml2/linuxbridge_agent.ini

```conf
[linux_bridge]
physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME

[vxlan]
enable_vxlan = false

[securitygroup]
# ...
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

# 添加内核参数
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
```


选项2：私有网络

编辑/etc/neutron/plugins/ml2/linuxbridge_agent.ini

```conf
[linux_bridge]
physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME

[vxlan]
enable_vxlan = true
local_ip = OVERLAY_INTERFACE_IP_ADDRESS
l2_population = true

[securitygroup]
# ...
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

# 添加内核参数
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
```


4.配置计算节点网络服务
编辑/etc/nova/nova.conf

```conf
[neutron]
# ...
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS
```

5.启动服务

```bash
$ systemctl restart openstack-nova-compute.service

$ systemctl enable neutron-linuxbridge-agent.service
$ systemctl start neutron-linuxbridge-agent.service
```

## 9.4 验证

```bash
$ source .admin-openrc

$ openstack extension list --network

$ openstack network agent list
```


# 10.dashboard

1.安装包

```bash
$ yum python-django-1.8.14-1.el7.noarch

$ yum install openstack-dashboard

```