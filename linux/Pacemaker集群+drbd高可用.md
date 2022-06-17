# Pacemaker集群

[toc]

## Pacemaker集群简介

###  1.基本介绍

pacemaker是一种高可用性集群资源管理器，运行在一组主机上的软件，以保持所需服务（资源）的完整性和最小化停机时间

它可以做乎任何规模的集群，并配备了一个强大的依赖模型，使管理员能够准确地表达群集资源之间的关系（包括顺序和位置）。几乎任何可以编写脚本，可以管理作为pacemaker集群的一部分

pacemaker是个资源管理器，不是提供心跳信息的，因为它似乎是一个普遍的误解，也是值得的。pacemaker是一个延续的CRM（亦称Heartbeat V2资源管理器），最初是为心跳，但已经成为独立的项目。

#### 1.1 主要功能

Pacemaker的主要功能包括：

- 检测节点和服务器故障并从中恢复

- 通过隔离故障节点来确保数据完整性的能力

- 每个集群支持一个或多个节点

- 支持多种资源接口标准（任何可以编写脚本的都可以集群）

- 支持（但不要求）共享存储

- 支持几乎任何冗余配置（主动/被动，N + 1等）

- 可从任何节点更新的自动复制的配置

- 能够指定服务之间的集群范围的关系，例如排序，共置和反共置

- 支持高级服务类型，例如*克隆*（需要在多个节点上处于活动状态的服务），*有状态资源*（可以以两种模式之一运行的克隆）和容器化服务

- 统一的，可编写脚本的集群管理工具

  

#### 1.2 集群架构

在较高的层次上，集群可以被视为具有以下部分（通常一起称为*集群堆栈*）：

- **资源(**Resources**)：**这就是集群存在的原因-需要保持高可用性的服务。
- **资源代理(**Resource agents**)**：这些是在给定一组资源参数的情况下启动，停止和监视资源的脚本或操作系统组件。这些提供了Pacemaker和托管服务之间的统一接口。
- **围栏代理(**Fence agents**)：**这些脚本在给定目标和围栏设备参数的情况下执行节点围栏操作。
- **群集成员资格层(**Cluster membership layer**)：**此组件提供有关群集的可靠消息传递，成员资格和仲裁信息。当前,Pacemaker支持[Corosync](http://www.corosync.org/)作为此层。
- **集群资源管理器(**Cluster resource manager**)：** Pacemaker提供处理和响应集群中发生的事件的大脑。这些事件可能包括节点加入或离开群集。由故障，维护或计划的活动引起的资源事件；和其他行政行为。为了获得所需的可用性，Pacemaker可以启动和停止资源和围栅节点。
- **群集工具(**Cluster tools**)：**这些为用户提供了与群集进行交互的界面。提供了各种命令行和图形（GUI）界面。

集群堆栈示例图：

![示例集群堆栈](https://clusterlabs.org/pacemaker/doc/en-US/Pacemaker/2.0/html/Pacemaker_Explained/images/pcmk-stack.png)



#### 1.3 内部组件

Pacemaker本身由多个协同工作的守护程序组成：

- pacemakerd
- pacemaker-attrd
- pacemaker-based
- pacemaker-controld
- pacemaker-execd
- pacemaker-fenced
- pacemaker-schedulerd

内部组件示例图：

![Pacemaker软件组件](https://clusterlabs.org/pacemaker/doc/en-US/Pacemaker/2.0/html/Pacemaker_Explained/images/pcmk-internals.png)



```ABAP
Pacemaker主进程（pacemakerd）会生成所有其他守护程序，并在它们意外退出时重新生成它们，其中**集群信息库(CIB)**主要负责集群最基本的信息配置与管理，CIB主要使用 XML的格式来显示集群的配置信息和集群所有资源的当前状态信息，CIB所管理的配置信息会自动在集群节点之间进行同步。CIB管理器在整个集群中保持CIB同步，并处理修改CIB的请求。
```

```ABAP
属性管理器(pacemaker-attrd)维护所有节点的属性数据库，使其在集群中保持同步，并处理修改它们的请求。这些属性通常记录在CIB中。
```

```ABAP
CIB的快照作为输入，调度器(pacemaker-schedulerd)确定需要哪些操作才能实现集群的理想状态。
```

```ABAP
本地执行器(pacemaker-execd)处理在本地集群节点上执行资源代理的请求，并返回结果。
```

```ABAP
fencer(pacemaker-fenced)处理对节点的栅栏请求。给定一个目标节点，fencer决定哪个集群节点应该执行哪个fencing设备，并调用必要的fencing代理(直接调用，或通过请求到其他节点上的fencer对等体)，并返回结果。
```

```ABAP
控制器(Pacemaker -control)是Pacemaker的协调器，维护集群成员的一致视图，并协调所有其他组件。
```

```
Pacemaker通过选择一个控制器实例作为指定控制器(DC)来集中集群决策。如果当选的DC进程(或它所在的节点)失败，一个新的DC进程将迅速建立。DC通过获取CIB的当前快照来响应集群事件，将其发送给调度程序，然后请求executor(可以直接在本地节点上，也可以通过请求其他节点上的控制器节点)和fencer执行任何必要的操作。
```



#### 1.4 重要组件角色

**corosync**：集群框架引擎程序，主要收集节点之间的心跳等信息

**pacemaker**：高可用集群资源管理器，提供crm管理资源信息

**crmsh/pcs**：pacemaker集群的命令行工具



#### 1.5 节点冗余设计

Pacemaker实际上支持任何节点冗余配置，包括主/主、主/被动、N+1、N+M、N-to-1和N-to-N。

1.具有两个(或更多)节点的使用Pacemaker和DRBD的主/被动集群对于许多情况都是一种经济有效的高可用性解决方案。其中一个节点提供所需的服务，如果故障，另一个节点接管。

主动/被动冗余示例图：

![主动/被动冗余](https://clusterlabs.org/pacemaker/doc/en-US/Pacemaker/2.0/html/Pacemaker_Explained/images/pcmk-active-passive.png)



2.Pacemaker还支持共享故障转移设计中的多个节点，通过允许多个主动/被动集群组合并共享一个公共备份节点来降低硬件成本。

共享故障转移示例图：

![共享故障转移](https://clusterlabs.org/pacemaker/doc/en-US/Pacemaker/2.0/html/Pacemaker_Explained/images/pcmk-shared-failover.png)



3.当共享存储可用时，每个节点都可能用于故障转移。Pacemaker甚至可以运行多个服务副本来分散工作负载。

N对N冗余示例图：

![N对N冗余](https://clusterlabs.org/pacemaker/doc/en-US/Pacemaker/2.0/html/Pacemaker_Explained/images/pcmk-active-active.png)



## pacemaker+corsosync+pcs+drbd高可用集群搭建

使用pacemaker作为集群管理器

使用corsosync收集各节点的心跳信息

使用pcs作为命令行工具

使用drbd作为分布式块存储

最终目的：

**可以实现一旦主节点发生故障，数据可以基于drbd块存储的方式完整的自动的转移到备用节点，此过程需自动完成，不经过人为干预**

### 1. pacemaker集群搭建

#### 1.1 安装环境

|      主机名称      |  pacemaker-01  |  pacemaker-02  |
| :----------------: | :------------: | :------------: |
|         ip         | 172.16.105.50  | 172.16.105.51  |
|  集群管理用户名称  |   hacluster    |   hacluster    |
|  集群管理用户密码  |     123456     |     123456     |
|        vip         | 172.16.105.200 | 172.16.105.200 |
| 集群粘性设置默认值 |      100       |      100       |

#### 1.2 主端配置

##### 1.2.1 添加主机映射

```shell
[root@pacemaker-01 ~]# vim /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.16.105.50   pacemaker-01
172.16.105.51   pacemaker-02

```

##### 1.2.2 配置免密登陆

```shell
[root@pacemaker-01 ~]# yum -y install rsync

[root@pacemaker-01 ~]# ssh-keygen -t rsa

[root@pacemaker-01 ~]# cd .ssh/

[root@pacemaker-01 .ssh]# cat id_rsa.pub >> authorized_keys

[root@pacemaker-01 .ssh]# ssh-copy-id -i id_rsa.pub 172.16.105.51
```

##### 1.2.3 安装软件及依赖

```shell
[root@pacemaker-01 ~]# yum install -y pacemaker pcs psmisc policycoreutils-python
```

##### 1.2.4 启动pcs守护程序

```shell
[root@pacemaker-01 ~]# systemctl start pcsd.service

[root@pacemaker-01 ~]# systemctl enable pcsd.service
Created symlink from /etc/systemd/system/multi-user.target.wants/pcsd.service to /usr/lib/systemd/system/pcsd.service.
#在配置集群之前，必须启动pcs守护程序并将其启用以在每个节点的引导时启动。该守护程序与pcs命令行界面一起使用，以管理集群中所有节点之间的corosync配置同步。
```

##### 1.2.5 配置corosync及集群管理用户

```shell
[root@pacemaker-01 ~]# passwd hacluster
Changing password for user hacluster.
New password:
BAD PASSWORD: The password is shorter than 8 characters
Retype new password:
passwd: all authentication tokens updated successfully.
#该帐户需要一个登录密码才能执行诸如同步corosync配置或在其他节点上启动和停止集群的任务。

[root@pacemaker-01 ~]# pcs cluster auth pacemaker-01 pacemaker-02
Username: hacluster
Password:
pacemaker-01: Authorized
pacemaker-02: Authorized
#在任意一个节点验证hacluster用户状态

[root@pacemaker-01 ~]# pcs cluster setup --name mycluster pacemaker-01 pacemaker-02
Destroying cluster on nodes: pacemaker-01, pacemaker-02...
pacemaker-01: Stopping Cluster (pacemaker)...
pacemaker-02: Stopping Cluster (pacemaker)...
pacemaker-01: Successfully destroyed cluster
pacemaker-02: Successfully destroyed cluster

Sending 'pacemaker_remote authkey' to 'pacemaker-01', 'pacemaker-02'
pacemaker-01: successful distribution of the file 'pacemaker_remote authkey'
pacemaker-02: successful distribution of the file 'pacemaker_remote authkey'
Sending cluster config files to the nodes...
pacemaker-01: Succeeded
pacemaker-02: Succeeded

Synchronizing pcsd certificates on nodes pacemaker-01, pacemaker-02...
pacemaker-01: Success
pacemaker-02: Success
Restarting pcsd on the nodes in order to reload the certificates...
pacemaker-01: Success
pacemaker-02: Success
#在任意一个节点生成并同步corosync配置，请确保在每个节点上使用相同的密码配置了hacluster用户帐户
```

##### 1.2.6 启动corosync和pacemaker

```shell
[root@pacemaker-01 ~]# pcs cluster start --all
pacemaker-01: Starting Cluster (corosync)...
pacemaker-02: Starting Cluster (corosync)...
pacemaker-02: Starting Cluster (pacemaker)...
pacemaker-01: Starting Cluster (pacemaker)...
#在任意一个节点使用此命令可启动集群中所有节点的corosync和pacemaker

#如果您在pcs cluster auth之前运行该命令在不同的节点发出了start命令，则必须在登录的当前节点上进行身份验证，然后才能启动集群。

#可使用以下命令在单独的节点上启动corosync和pacemaker
#方法一：pcs cluster start
#方法二：systemctl start corosync.service
#      systemctl start pacemaker.service
```

##### 1.2.7 检测集群通信可用性

```shell
[root@pacemaker-01 ~]# corosync-cfgtool -s
Printing ring status.
Local node ID 1
RING ID 0
        id      = 172.16.105.50
        status  = ring 0 active with no faults
#如果您看到不同的内容，则可能首先要检查节点的网络，防火墙和SELinux配置

[root@pacemaker-01 ~]# corosync-cmapctl | grep members
runtime.totem.pg.mrp.srp.members.1.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.1.ip (str) = r(0) ip(172.16.105.50)
runtime.totem.pg.mrp.srp.members.1.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.1.status (str) = joined
runtime.totem.pg.mrp.srp.members.2.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.2.ip (str) = r(0) ip(172.16.105.51)
runtime.totem.pg.mrp.srp.members.2.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.2.status (str) = joined
#检测集群中的节点

[root@pacemaker-01 ~]# pcs status corosync

Membership information
----------------------
    Nodeid      Votes Name
         1          1 pacemaker-01 (local)
         2          1 pacemaker-02
#检测有心跳的节点

[root@pacemaker-01 ~]# pcs status
Cluster name: mycluster

WARNINGS:
No stonith devices and stonith-enabled is not false

Stack: corosync
Current DC: pacemaker-01 (version 1.1.23-1.el7_9.1-9acf116022) - partition with quorum
Last updated: Wed Dec 30 15:47:18 2020
Last change: Wed Dec 30 15:33:42 2020 by hacluster via crmd on pacemaker-01

2 nodes configured
0 resource instances configured

Online: [ pacemaker-01 pacemaker-02 ]

No resources


Daemon Status:
  corosync: active/disabled
  pacemaker: active/disabled
  pcsd: active/enabled
#检测当前pacemaker集群的状态信息
```

##### 1.2.8 关闭Fencing防护

了解Fencing：
Fencing可以保护您的数据免遭损坏，并防止由于恶意节点意外并发访问而导致应用程序不可用。
节点无响应并不意味着它已停止访问您的数据。要确保100％的数据安全，唯一的方法是使用fencing防护来确保该节点真正脱机，然后再允许从另一个节点访问数据。
在无法停止群集服务的情况下，fencing防护也可以发挥作用。在这种情况下，群集使用防护来强制整个节点脱机，从而可以安全地在其他地方启动服务。
Fencing也称为STONITH，是“击杀头部中的另一个节点”的缩写，因为fencing的最流行形式是切断主机的电源。
为了保证数据的安全性，fencing防护已默认启用

```shell
#通过将启用了stonith的群集选项设置为false ，可以告诉群集不要使用防护：
[root@pacemaker-01 ~]# pcs property set stonith-enabled=false

#但是，这对于生产集群是完全不合适的。它告诉集群仅假装故障节点已安全关闭电源。一些供应商将拒绝支持已禁用防护的群集。即使为测试集群禁用它，也意味着您将无法测试实际的故障场景
# 可使用命令启动fencing防护：
# 命令：pcs -f stonith_cfg property set stonith-enabled=true
```

##### 1.2.9 设置浮动IP地址及

无论任何群集服务在何处运行，最终用户都需要一个一致的地址来与他们联系。在这里，我将选择172.16.105.200作为浮动地址，给它起个名称ClusterIP，并告诉集群每30秒检查一次它是否在运行

```shell
[root@pacemaker-01 ~]# pcs resource create ClusterIP ocf:heartbeat:IPaddr2 ip=172.16.105.200 cidr_netmask=24 op monitor interval=30s

#所选地址必须尚未在网络上使用。不要重用已经配置的节点之一的IP地址。
#这里的另一个重要信息是ocf:heartbeat:IPaddr2。这告诉了Pacemaker关于你想添加的资源的三件事:
第一个字段(在本例中是ocf)是资源脚本遵循的标准以及在哪里找到它
第二个字段(本例中是heartbeat)是特定于标准的;对于OCF资源，它告诉集群资源脚本在哪个OCF名称空间中。
第三个字段(在本例中是IPaddr2)是资源脚本的名称。

[root@pacemaker-01 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:50:56:83:a2:9f brd ff:ff:ff:ff:ff:ff
    inet 172.16.105.50/16 brd 172.16.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet 172.16.105.200/24 brd 172.16.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::250:56ff:fe83:a29f/64 scope link
       valid_lft forever preferred_lft forever
#漂移IP已经添加
```

##### 1.2.10 验证现在集群状态

```shell
[root@pacemaker-01 ~]# pcs status
```

![](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20201230165140681.png)

##### 1.2.11 验证该集群可否实现故障转移

我们的最终目标是高可用性，所以我们应该在继续之前测试新资源的故障转移。首先，找到运行浮动IP地址的节点

在1.2.10中可以看到ClusterIP资源的状态已在特定节点上启动（在本示例中为pacemaker-01）。关闭该机器上的Pacemaker和Corosync以触发故障转移

```shell
[root@pacemaker-01 ~]# pcs cluster stop pacemaker-01
pacemaker-01: Stopping Cluster (pacemaker)...
pacemaker-01: Stopping Cluster (corosync)...
#停止pacemaker-01节点上的资源管理器和心跳检测

[root@pacemaker-01 ~]# pcs status
Error: cluster is not currently running on this node
#确认该节点上的pacemaker和corosync不再运行

#在pacemaker-02节点查看集群状态
[root@pacemaker-02 ~]# pcs status
Cluster name: mycluster
Stack: corosync
Current DC: pacemaker-02 (version 1.1.23-1.el7_9.1-9acf116022) - partition with quorum
Last updated: Wed Dec 30 16:48:44 2020
Last change: Wed Dec 30 16:09:39 2020 by root via cibadmin on pacemaker-01

2 nodes configured
1 resource instance configured

Online: [ pacemaker-02 ]
OFFLINE: [ pacemaker-01 ]

Full list of resources:

 ClusterIP      (ocf::heartbeat:IPaddr2):       Started pacemaker-02

Daemon Status:
  corosync: active/disabled
  pacemaker: active/disabled
  pcsd: active/enabled
#pacemaker-01仍是活动的，允许它接收pcs的命令，但它不参与集群,ClusterIP现在正在pacemaker-02上运行 ,故障转移自动发生，并且未报告任何错误

#在pacemaker-01上重新启动群集堆栈来模拟节点恢复，并检查群集的状态
[root@pacemaker-01 ~]# pcs cluster start pacemaker-01
pacemaker-01: Starting Cluster (corosync)...
pacemaker-01: Starting Cluster (pacemaker)...

[root@pacemaker-01 ~]# pcs status
Cluster name: mycluster
Stack: corosync
Current DC: pacemaker-02 (version 1.1.23-1.el7_9.1-9acf116022) - partition with quorum
Last updated: Wed Dec 30 16:52:52 2020
Last change: Wed Dec 30 16:09:39 2020 by root via cibadmin on pacemaker-01

2 nodes configured
1 resource instance configured

Online: [ pacemaker-01 pacemaker-02 ]

Full list of resources:

 ClusterIP      (ocf::heartbeat:IPaddr2):       Started pacemaker-02

Daemon Status:
  corosync: active/disabled
  pacemaker: active/disabled
  pcsd: active/enabled
#可看到2台节点都已经在集群中,至此，可确定该集群可以实现故障转移
```

##### 1.2.12 防止资源在恢复后回切

在大多数情况下，需要防止健康的资源在群集中移动。移动资源几乎总是需要一段时间的停机时间。对于复杂的服务（例如数据库），此时间段可能会很长。

默认情况下pacemaker定义在管理员未明确指定资源和节点列表的情况下，Pacemaker处理资源和节点列表的顺序将创建隐式首选项，使资源处于最优的资源位置。

为了解决这个问题，Pacemaker具有资源*粘性*的概念，该概念控制着服务倾向于保持其原处状态的强烈程度，我们可以为每个资源指定不同的粘性。

```shell
[root@pacemaker-01 ~]# pcs resource defaults resource-stickiness=100
Warning: Defaults do not apply to resources which override them with their own defined values
#更改粘性默认值

[root@pacemaker-01 ~]# pcs resource defaults
resource-stickiness=100
#查看默认值
```



#### 1.3 备端配置

##### 1.3.1 添加主机映射

```shell
[root@pacemaker-02 ~]# vim /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.16.105.50   pacemaker-01
172.16.105.51   pacemaker-02
```

##### 1.3.2 配置免密登陆

```shell
[root@pacemaker-01 ~]# yum -y install rsync

[root@pacemaker-02 ~]# ssh-keygen -t rsa

[root@pacemaker-02 ~]# cd .ssh/

[root@pacemaker-02 .ssh]# cat id_rsa.pub >> authorized_keys

[root@pacemaker-02 .ssh]# ssh-copy-id -i id_rsa.pub 172.16.105.50
```

##### 1.3.3 安装软件及依赖

```shell
[root@pacemaker-02 ~]# yum install -y pacemaker pcs psmisc policycoreutils-python
```

##### 1.3.4 启动pcs守护程序

```shell
[root@pacemaker-02 ~]# systemctl start pcsd.service

[root@pacemaker-02 ~]# systemctl enable pcsd.service
Created symlink from /etc/systemd/system/multi-user.target.wants/pcsd.service to /usr/lib/systemd/system/pcsd.service.
#在配置集群之前，必须启动pcs守护程序并将其启用以在每个节点的引导时启动。该守护程序与pcs命令行界面一起使用，以管理集群中所有节点之间的corosync配置同步。
```

##### 1.3.5 配置corosync及集群管理用户

```shell
[root@pacemaker-02 ~]# passwd hacluster
Changing password for user hacluster.
New password:
BAD PASSWORD: The password is shorter than 8 characters
Retype new password:
passwd: all authentication tokens updated successfully.
#该帐户需要一个登录密码才能执行诸如同步corosync配置或在其他节点上启动和停止集群的任务。
```



### 2. DRBD分布式存储搭建

#### 2.1 安装环境

|   主机名称   | pacemaker-01  | pacemaker-02  |
| :----------: | :-----------: | :-----------: |
|      ip      | 172.16.105.50 | 172.16.105.51 |
| DRDB管理名称 |     data      |     data      |
| DRDB挂载目录 |     /mnt      |     /mnt      |
| DRDB逻辑设备 |  /dev/drdb1   |  /dev/drdb1   |
| DRDB存储设备 |   /dev/sdb    |   /dev/sdb    |

#### 2.2 主端配置

##### 2.2.1 添加主机映射

```shell
[root@pacemaker-01 ~]# vim /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.16.105.50   pacemaker-01
172.16.105.51   pacemaker-02
```

##### 2.2.2 导入elrepo软件包密钥并启用存储库

```shell
[root@pacemaker-01 ~]# rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

[root@pacemaker-01 ~]# rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
Retrieving http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:elrepo-release-7.0-3.el7.elrepo  ################################# [100%]
```

##### 2.2.3 安装DRBD内核模块及相应依赖

```shell
[root@pacemaker-01 ~]# yum install -y kmod-drbd84 drbd84-utils
```

##### 2.2.4 将DRBD进程从selinux控件中排除

```shell
[root@pacemaker-01 ~]# semanage permissive -a drbd_t
```

##### 2.2.5 配置DRBD

```shell
[root@pacemaker-01 ~]# cd /etc/drbd.d/

[root@pacemaker-01 drbd.d]# vi global_common.conf
 net {
                protocol C;
                # protocol timeout max-epoch-size max-buffers
                # connect-int ping-int sndbuf-size rcvbuf-size ko-count
                # allow-two-primaries cram-hmac-alg shared-secret after-sb-0pri
                # after-sb-1pri after-sb-2pri always-asbp rr-conflict
                # ping-timeout data-integrity-alg tcp-cork on-congestion
                # congestion-fill congestion-extents csums-alg verify-alg
                # use-rle
        }
}
#在net段中添加：protocol C；表示使用协议C进行数据同步

[root@pacemaker-01 drbd.d]# pwd
/etc/drbd.d

[root@pacemaker-01 drbd.d]# vi dbdata.res
resource data {
  on pacemaker-01 {
    device    /dev/drbd1;
    disk      /dev/sdb;
    address   172.16.105.50:7789;
    meta-disk internal;
  }
  on pacemaker-02 {
    device    /dev/drbd1;
    disk      /dev/sdb;
    address   172.16.105.51:7789;
    meta-disk internal;
  }
}
#配置DRBD资源池
```

##### 2.2.6 初始化DRBD

```shell
[root@pacemaker-01 ~]# drbdadm create-md data
initializing activity log
initializing bitmap (1280 KB) to all zero
Writing meta data...
New drbd meta data block successfully created.
#创建该drbd模块（如果与回显信息不符，重启再重新创建）

[root@pacemaker-01 ~]# modprobe drbd
#加载drbd模块

[root@pacemaker-01 ~]# drbdadm up data
#启动该资源模块

[root@pacemaker-01 ~]# cat /proc/drbd
version: 8.4.11-1 (api:1/proto:86-101)
GIT-hash: 66145a308421e9c124ec391a7848ac20203bb03c build by mockbuild@, 2020-04-05 02:58:18

 1: cs:Connected ro:Secondary/Secondary ds:Inconsistent/Inconsistent C r-----
    ns:0 nr:0 dw:0 dr:0 al:8 bm:0 lo:0 pe:0 ua:0 ap:0 ep:1 wo:f oos:41941724
#查看DRBD状态，提示为connected表示已连接

[root@pacemaker-01 ~]# drbdadm primary data --force
#在pacemater-01上执行此命令，设置该节点为drbd服务的主节点
```

##### 2.2.7 在主端挂载文件系统

```shell
[root@pacemaker-01 ~]# mkfs.xfs /dev/drbd1
meta-data=/dev/drbd1             isize=512    agcount=4, agsize=2621358 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=10485431, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=5119, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
#将该磁盘格式化为xfs文件系统

[root@pacemaker-01 ~]# mount /dev/drbd1 /mnt/
#挂载磁盘到/mnt目录
```



#### 2.3 备端配置

##### 2.3.1 添加主机映射

```shell
[root@pacemaker-02 ~]# vim /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.16.105.50   pacemaker-01
172.16.105.51   pacemaker-02
```

##### 2.3.2导入elrepo软件包密钥并启用存储库

```shell
[root@pacemaker-02 ~]# rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

[root@pacemaker-02 ~]# rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
Retrieving http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:elrepo-release-7.0-3.el7.elrepo  ################################# [100%]
```

##### 2.3.3 安装DRBD内核模块及相应依赖

```shell
[root@pacemaker-02 ~]# yum install -y kmod-drbd84 drbd84-utils
```

##### 2.3.4 将DRBD进程从selinux控件中排除

```shell
[root@pacemaker-02 ~]# semanage permissive -a drbd_t
```

##### 2.3.5 配置DRBD

```shell
[root@pacemaker-02 ~]# cd /etc/drbd.d/

[root@pacemaker-02 drbd.d]# vi global_common.conf
net {
                protocol C;
                # protocol timeout max-epoch-size max-buffers
                # connect-int ping-int sndbuf-size rcvbuf-size ko-count
                # allow-two-primaries cram-hmac-alg shared-secret after-sb-0pri
                # after-sb-1pri after-sb-2pri always-asbp rr-conflict
                # ping-timeout data-integrity-alg tcp-cork on-congestion
                # congestion-fill congestion-extents csums-alg verify-alg
                # use-rle
        }
}
#在net段中添加：protocol C；表示使用协议C进行数据同步

[root@pacemaker-02 drbd.d]# vi dbdata.res
resource data {
  on pacemaker-01 {
    device    /dev/drbd1;
    disk      /dev/sdb;
    address   172.16.105.50:7789;
    meta-disk internal;
  }
  on pacemaker-02 {
    device    /dev/drbd1;
    disk      /dev/sdb;
    address   172.16.105.51:7789;
    meta-disk internal;
  }
}
#配置DRBD资源池
```

##### 2.3.6 初始化DRBD

```shell
[root@pacemaker-02 ~]# drbdadm create-md data
initializing activity log
initializing bitmap (1280 KB) to all zero
Writing meta data...
New drbd meta data block successfully created.
#创建该drbd模块（如果与回显信息不符，重启再重新创建）

[root@pacemaker-02 ~]# modprobe drbd
#加载drbd模块

[root@pacemaker-02 ~]# drbdadm up data
#启动该资源模块

[root@pacemaker-02 ~]# cat /proc/drbd
version: 8.4.11-1 (api:1/proto:86-101)
GIT-hash: 66145a308421e9c124ec391a7848ac20203bb03c build by mockbuild@, 2020-04-05 02:58:18

 1: cs:Connected ro:Secondary/Secondary ds:Inconsistent/Inconsistent C r-----
    ns:0 nr:0 dw:0 dr:0 al:8 bm:0 lo:0 pe:0 ua:0 ap:0 ep:1 wo:f oos:41941724
#查看DRBD状态，提示为connected表示已连接
```

#### 2.4 验证DRBD服务是否可用

##### 2.4.1 在主端挂载目录中创建文件

```shell
[root@pacemaker-01 ~]# cd /mnt/

[root@pacemaker-01 mnt]# mkdir file{1..5}

[root@pacemaker-01 mnt]# ll
total 0
drwxr-xr-x 2 root root 6 Dec 30 18:52 file1
drwxr-xr-x 2 root root 6 Dec 30 18:52 file2
drwxr-xr-x 2 root root 6 Dec 30 18:52 file3
drwxr-xr-x 2 root root 6 Dec 30 18:52 file4
drwxr-xr-x 2 root root 6 Dec 30 18:52 file5
```

##### 2.4.2 将主端挂载的磁盘卸载

```shell
[root@pacemaker-01 ~]# df -hT
Filesystem              Type      Size  Used Avail Use% Mounted on
devtmpfs                devtmpfs  2.0G     0  2.0G   0% /dev
tmpfs                   tmpfs     2.0G     0  2.0G   0% /dev/shm
tmpfs                   tmpfs     2.0G  8.8M  2.0G   1% /run
tmpfs                   tmpfs     2.0G     0  2.0G   0% /sys/fs/cgroup
/dev/mapper/centos-root xfs       196G  1.8G  194G   1% /
/dev/sda1               xfs      1014M  163M  852M  16% /boot
tmpfs                   tmpfs     396M     0  396M   0% /run/user/0
/dev/drbd1              xfs        40G   33M   40G   1% /mnt

[root@pacemaker-01 ~]# umount /mnt

[root@pacemaker-01 ~]# df -hT
Filesystem              Type      Size  Used Avail Use% Mounted on
devtmpfs                devtmpfs  2.0G     0  2.0G   0% /dev
tmpfs                   tmpfs     2.0G     0  2.0G   0% /dev/shm
tmpfs                   tmpfs     2.0G  8.8M  2.0G   1% /run
tmpfs                   tmpfs     2.0G     0  2.0G   0% /sys/fs/cgroup
/dev/mapper/centos-root xfs       196G  1.8G  194G   1% /
/dev/sda1               xfs      1014M  163M  852M  16% /boot
tmpfs                   tmpfs     396M     0  396M   0% /run/user/0
```

##### 2.4.3 重新设置主备节点

```shell
[root@pacemaker-01 ~]# drbdadm secondary data
#将原来的主端更改为备端

[root@pacemaker-02 ~]# drbdadm primary data
#将原来的备端更改为主端
```

##### 2.4.5在pacemaker-02节点挂载磁盘，并查看是否有数据

```shell
[root@pacemaker-02 ~]# mount /dev/drbd1 /mnt/

[root@pacemaker-02 ~]# df -hT
Filesystem              Type      Size  Used Avail Use% Mounted on
devtmpfs                devtmpfs  2.0G     0  2.0G   0% /dev
tmpfs                   tmpfs     2.0G     0  2.0G   0% /dev/shm
tmpfs                   tmpfs     2.0G  8.8M  2.0G   1% /run
tmpfs                   tmpfs     2.0G     0  2.0G   0% /sys/fs/cgroup
/dev/mapper/centos-root xfs       196G  1.8G  194G   1% /
/dev/sda1               xfs      1014M  163M  852M  16% /boot
tmpfs                   tmpfs     396M     0  396M   0% /run/user/0
/dev/drbd1              xfs        40G   33M   40G   1% /mnt

[root@pacemaker-02 ~]# ll /mnt/
total 0
drwxr-xr-x 2 root root 6 Dec 30 18:52 file1
drwxr-xr-x 2 root root 6 Dec 30 18:52 file2
drwxr-xr-x 2 root root 6 Dec 30 18:52 file3
drwxr-xr-x 2 root root 6 Dec 30 18:52 file4
drwxr-xr-x 2 root root 6 Dec 30 18:52 file5
```



### 3. 配置群集

|   设备名称   |     DRBD     |   文件系统   |
| :----------: | :----------: | :----------: |
|  填充文件名  |   drbd_cfg   |    fs_cfg    |
|   资源名称   |   WebData    |    WebFS     |
|   资源调用   |     data     |  /dev/drbd1  |
|   磁盘挂载   |              |     /mnt     |
| 克隆资源名称 | WebDataClone | WebDataClone |

#### 3.1为DRBD设置群集

##### 3.1.1 填充配置文件

```shell
#pc有一个方便的功能，它可以将多个更改排列到一个文件中，并一次性提交这些更改。为此，首先用来自CIB的当前原始XML配置填充文件。
[root@pacemaker-01 ~]# pcs cluster cib drbd_cfg
```

##### 3.1.2 为DRBD设备创建群集资源以及克隆资源

```shell
[root@pacemaker-01 ~]# pcs -f drbd_cfg resource create WebData ocf:linbit:drbd drbd_resource=data op monitor interval=60s
#配置集群资源

[root@pacemaker-01 ~]# pcs -f drbd_cfg resource master WebDataClone WebData master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
#配置克隆资源

[root@pacemaker-01 ~]# pcs -f drbd_cfg resource show
 ClusterIP      (ocf::heartbeat:IPaddr2):       Started pacemaker-01
 Master/Slave Set: WebDataClone [WebData]
     Stopped: [ pacemaker-01 pacemaker-02 ]
#查看资源运行在哪个节点，在该信息中表示集群和克隆资源运行在2各节点上
```

##### 3.1.3 提交更改

```shell
[root@pacemaker-01 ~]# pcs cluster cib-push drbd_cfg --config
CIB updated
#对所有更改感到完成之后，可以通过将drbd_cfg文件推送到实时CIB中来一次提交所有更改。

[root@pacemaker-01 ~]# pcs status
Cluster name: mycluster
Stack: corosync
Current DC: pacemaker-01 (version 1.1.23-1.el7_9.1-9acf116022) - partition with quorum
Last updated: Wed Dec 30 19:27:56 2020
Last change: Wed Dec 30 19:27:01 2020 by root via cibadmin on pacemaker-01

2 nodes configured
3 resource instances configured

Online: [ pacemaker-01 pacemaker-02 ]

Full list of resources:

 ClusterIP      (ocf::heartbeat:IPaddr2):       Started pacemaker-01
 Master/Slave Set: WebDataClone [WebData]
     Masters: [ pacemaker-01 ]
     Slaves: [ pacemaker-02 ]

Daemon Status:
  corosync: active/disabled
  pacemaker: active/disabled
  pcsd: active/enabled
#查看pacemater集群最新的配置
#可以看到，WebDataClone（我们的DRBD设备）在pacemaker-01上作为主服务器（DRBD的主要角色）运行，在pacemaker-02上作为从属服务器（DRBD的次要角色）运行。
```

#### 3.2 为文件系统配置群集

##### 3.2.1 填充配置文件

有一个工作正常的DRBD设备，我们需要挂载它的文件系统

除了定义文件系统之外，我们还需要告诉群集可以在哪里定位（仅在DRBD主数据库上）以及何时允许启动（在主数据库升级之后）

```shell
[root@pacemaker-01 ~]# pcs cluster cib fs_cfg
#用来自CIB的当前原始XML配置填充文件
```

##### 3.2.2 为文件系统创建群集资源以及克隆资源

```shell
[root@pacemaker-01 ~]# pcs -f fs_cfg resource create WebFS Filesystem device="/dev/drbd1" directory="/mnt" fstype="xfs"
Assumed agent name 'ocf:heartbeat:Filesystem' (deduced from 'Filesystem')
#创建一个名为webfs的资源，该资源的内容为将/dev/drbd1磁盘以xfs的文件系统挂载到/mnt目录中

[root@pacemaker-01 ~]# pcs -f fs_cfg constraint colocation add WebFS with WebDataClone INFINITY with-rsc-role=Master
#配置一个克隆资源

[root@pacemaker-01 ~]#  pcs -f fs_cfg constraint order promote WebDataClone then start WebFS
Adding WebDataClone WebFS (kind: Mandatory) (Options: first-action=promote then-action=start)
#启动该克隆资源

[root@pacemaker-01 ~]# pcs -f fs_cfg constraint
Location Constraints:
Ordering Constraints:
Colocation Constraints:
  WebFS with WebDataClone (score:INFINITY) (with-rsc-role:Master)
Ticket Constraints:
#查看更新的配置

#删除某一个资源：
pcs resource delete WebFS
```

##### 3.2.3 提交更改

```shell
[root@pacemaker-01 ~]# pcs cluster cib-push fs_cfg --config
CIB updated
#对所有更改感到完成之后，可以通过将fs_cfg文件推送到实时CIB中来一次提交所有更改

[root@pacemaker-01 ~]# pcs status
Cluster name: mycluster
Stack: corosync
Current DC: pacemaker-01 (version 1.1.23-1.el7_9.1-9acf116022) - partition with quorum
Last updated: Wed Dec 30 19:40:39 2020
Last change: Wed Dec 30 19:39:41 2020 by root via cibadmin on pacemaker-01

2 nodes configured
4 resource instances configured

Online: [ pacemaker-01 pacemaker-02 ]

Full list of resources:

 ClusterIP      (ocf::heartbeat:IPaddr2):       Started pacemaker-01
 Master/Slave Set: WebDataClone [WebData]
     Masters: [ pacemaker-01 ]
     Slaves: [ pacemaker-02 ]
 WebFS  (ocf::heartbeat:Filesystem):    Started pacemaker-01

Daemon Status:
  corosync: active/disabled
  pacemaker: active/disabled
  pcsd: active/enabled
#查看集群最新的状态信息，可看到新添加的文件系统已经启动
```



### 4. 测试群集故障转移

有2种方法可测试群集故障转移：

第一种方法：

可以使用 pcs cluster stop pacemaker-01命令停止pacemaker-01上的所有集群服务，以对集群资源进行故障转移

第二种方法：

可以将节点置于*待机模式*。处于此状态的节点将继续运行corosync和pacemaker，但不允许运行资源。在该处发现活动的任何资源都将移至其他地方。当执行系统管理任务（例如更新群集资源使用的软件包）时，此功能特别有用

在这里将使用第二种方法进行测试

#### 4.1 将活动节点置于备用模式

```shell
#将活动节点置于备用模式，并观察群集将所有资源移至另一个节点。节点的状态将更改以指示它不再能够托管资源，并且最终所有资源都将移动
[root@pacemaker-01 ~]# pcs cluster standby pacemaker-01
#将pacemaker-01设为备用待机状态

[root@pacemaker-01 ~]# pcs status
Cluster name: mycluster
Stack: corosync
Current DC: pacemaker-02 (version 1.1.23-1.el7_9.1-9acf116022) - partition with quorum
Last updated: Thu Dec 31 11:47:08 2020
Last change: Thu Dec 31 11:46:53 2020 by root via cibadmin on pacemaker-01

2 nodes configured
4 resource instances configured

Node pacemaker-01: standby
Online: [ pacemaker-02 ]

Full list of resources:

 ClusterIP      (ocf::heartbeat:IPaddr2):       Started pacemaker-02
 Master/Slave Set: WebDataClone [WebData]
     Masters: [ pacemaker-02 ]
     Stopped: [ pacemaker-01 ]
 WebFS  (ocf::heartbeat:Filesystem):    Started pacemaker-02

Daemon Status:
  corosync: active/disabled
  pacemaker: active/disabled
  pcsd: active/enabled
# 查看集群状态，可看到pacemaker-01已经被设为备端，主端已更新为pacemaker-02

[root@pacemaker-02 ~]# df -hT
Filesystem              Type      Size  Used Avail Use% Mounted on
devtmpfs                devtmpfs  2.0G     0  2.0G   0% /dev
tmpfs                   tmpfs     2.0G   53M  1.9G   3% /dev/shm
tmpfs                   tmpfs     2.0G  8.9M  2.0G   1% /run
tmpfs                   tmpfs     2.0G     0  2.0G   0% /sys/fs/cgroup
/dev/mapper/centos-root xfs       196G  1.8G  194G   1% /
/dev/sda1               xfs      1014M  163M  852M  16% /boot
tmpfs                   tmpfs     396M     0  396M   0% /run/user/0
/dev/drbd1              xfs        40G   33M   40G   1% /mnt
#在pacemaker-02上可看到文件系统已经自动挂载（没有人为干预进行了自动切换）

[root@pacemaker-02 ~]# ll /mnt/
total 0
drwxr-xr-x 2 root root 6 Dec 31 11:51 file1
drwxr-xr-x 2 root root 6 Dec 31 11:51 file2
drwxr-xr-x 2 root root 6 Dec 31 11:51 file3
drwxr-xr-x 2 root root 6 Dec 31 11:51 file4
drwxr-xr-x 2 root root 6 Dec 31 11:51 file5
#可看到挂载目录中的资源也已经转移到新的节点（pacemaker-02）
```

#### 4.2 重新将节点进行联机

```shell
[root@pacemaker-02 ~]# pcs cluster unstandby pacemaker-01
#可以再次允许该pacemaker-01节点成为完整的集群成员

[root@pacemaker-02 ~]# pcs status
Cluster name: mycluster
Stack: corosync
Current DC: pacemaker-02 (version 1.1.23-1.el7_9.1-9acf116022) - partition with quorum
Last updated: Thu Dec 31 11:53:14 2020
Last change: Thu Dec 31 11:53:08 2020 by root via cibadmin on pacemaker-02

2 nodes configured
4 resource instances configured

Online: [ pacemaker-01 pacemaker-02 ]

Full list of resources:

 ClusterIP      (ocf::heartbeat:IPaddr2):       Started pacemaker-02
 Master/Slave Set: WebDataClone [WebData]
     Masters: [ pacemaker-02 ]
     Slaves: [ pacemaker-01 ]
 WebFS  (ocf::heartbeat:Filesystem):    Started pacemaker-02

Daemon Status:
  corosync: active/disabled
  pacemaker: active/disabled
  pcsd: active/enabled
#可看到现在pacemaker-01和pacemaker-02都已经处于联机状态。但是由于之前配置的资源粘性设置，群集资源仍停留在pacemaker-02，并没有回切到pacemaker-01上
```

