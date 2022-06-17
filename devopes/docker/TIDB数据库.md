# TIDB数据库

### 1. 基本概念

#### 1.1 简介

[TiDB](https://github.com/pingcap/tidb) 是 [PingCAP](https://pingcap.com/about-cn/) 公司自主设计、研发的开源分布式关系型数据库，是一款同时支持在线事务处理与在线分析处理 (Hybrid Transactional and Analytical Processing, HTAP) 的融合型分布式数据库产品，具备水平扩容或者缩容、金融级高可用、实时 HTAP、云原生的分布式数据库、兼容 MySQL 5.7 协议和 MySQL 生态等重要特性。目标是为用户提供一站式 OLTP (Online Transactional Processing)、OLAP (Online Analytical Processing)、HTAP 解决方案。TiDB 适合高可用、强一致要求较高、数据规模较大等各种应用场景。



#### 1.2 五大核心特性

- 一键水平扩容或者缩容

  得益于 TiDB 存储计算分离的架构的设计，可按需对计算、存储分别进行在线扩容或者缩容，扩容或者缩容过程中对应用运维人员透明。

- 金融级高可用

  数据采用多副本存储，数据副本通过 Multi-Raft 协议同步事务日志，多数派写入成功事务才能提交，确保数据强一致性且少数副本发生故障时不影响数据的可用性。可按需配置副本地理位置、副本数量等策略满足不同容灾级别的要求。

- 实时 HTAP

  提供行存储引擎 [TiKV](https://docs.pingcap.com/zh/tidb/stable/tikv-overview)、列存储引擎 [TiFlash](https://docs.pingcap.com/zh/tidb/stable/tiflash-overview) 两款存储引擎，TiFlash 通过 Multi-Raft Learner 协议实时从 TiKV 复制数据，确保行存储引擎 TiKV 和列存储引擎 TiFlash 之间的数据强一致。TiKV、TiFlash 可按需部署在不同的机器，解决 HTAP 资源隔离的问题。

- 云原生的分布式数据库

  专为云而设计的分布式数据库，通过 [TiDB Operator](https://docs.pingcap.com/zh/tidb-in-kubernetes/v1.1/tidb-operator-overview) 可在公有云、私有云、混合云中实现部署工具化、自动化。

- 兼容 MySQL 5.7 协议和 MySQL 生态

  兼容 MySQL 5.7 协议、MySQL 常用的功能、MySQL 生态，应用无需或者修改少量代码即可从 MySQL 迁移到 TiDB。提供丰富的[数据迁移工具](https://docs.pingcap.com/zh/tidb/stable/ecosystem-tool-user-guide)帮助应用便捷完成数据迁移。



#### 1.3 四大核心应用场景

- 对数据一致性及高可靠、系统高可用、可扩展性、容灾要求较高的金融行业属性的场景

  众所周知，金融行业对数据一致性及高可靠、系统高可用、可扩展性、容灾要求较高。传统的解决方案是同城两个机房提供服务、异地一个机房提供数据容灾能力但不提供服务，此解决方案存在以下缺点：资源利用率低、维护成本高、RTO (Recovery Time Objective) 及 RPO (Recovery Point Objective) 无法真实达到企业所期望的值。TiDB 采用多副本 + Multi-Raft 协议的方式将数据调度到不同的机房、机架、机器，当部分机器出现故障时系统可自动进行切换，确保系统的 RTO <= 30s 及 RPO = 0。

- 对存储容量、可扩展性、并发要求较高的海量数据及高并发的 OLTP 场景

  随着业务的高速发展，数据呈现爆炸性的增长，传统的单机数据库无法满足因数据爆炸性的增长对数据库的容量要求，可行方案是采用分库分表的中间件产品或者 NewSQL 数据库替代、采用高端的存储设备等，其中性价比最大的是 NewSQL 数据库，例如：TiDB。TiDB 采用计算、存储分离的架构，可对计算、存储分别进行扩容和缩容，计算最大支持 512 节点，每个节点最大支持 1000 并发，集群容量最大支持 PB 级别。

- Real-time HTAP 场景

  随着 5G、物联网、人工智能的高速发展，企业所生产的数据会越来越多，其规模可能达到数百 TB 甚至 PB 级别，传统的解决方案是通过 OLTP 型数据库处理在线联机交易业务，通过 ETL 工具将数据同步到 OLAP 型数据库进行数据分析，这种处理方案存在存储成本高、实时性差等多方面的问题。TiDB 在 4.0 版本中引入列存储引擎 TiFlash 结合行存储引擎 TiKV 构建真正的 HTAP 数据库，在增加少量存储成本的情况下，可以同一个系统中做联机交易处理、实时数据分析，极大地节省企业的成本。

- 数据汇聚、二次加工处理的场景

  当前绝大部分企业的业务数据都分散在不同的系统中，没有一个统一的汇总，随着业务的发展，企业的决策层需要了解整个公司的业务状况以便及时做出决策，故需要将分散在各个系统的数据汇聚在同一个系统并进行二次加工处理生成 T+0 或 T+1 的报表。传统常见的解决方案是采用 ETL + Hadoop 来完成，但 Hadoop 体系太复杂，运维、存储成本太高无法满足用户的需求。与 Hadoop 相比，TiDB 就简单得多，业务通过 ETL 工具或者 TiDB 的同步工具将数据同步到 TiDB，在 TiDB 中可通过 SQL 直接生成报表。



#### 1.4 三大核心组件

- TiDB Server：
  TiDB Server 负责接收 SQL 请求，处理 SQL 相关的逻辑，并通过 PD 找到存储计算所需数
  据的 TiKV 地址，与 TiKV 交互获取数据，最终返回结果。TiDB Server 是无状态的，其本身
  并不存储数据，只负责计算，可以无限水平扩展，可以通过负载均衡组件（如 LVS、HAProxy 或
  F5）对外提供统一的接入地址。
- PD Server：
  Placement Driver(简称 PD) 是整个集群的管理模块，其主要工作有三个：一是存储集群的
  元信息（某个 Key 存储在哪个 TiKV 节点）；二是对 TiKV 集群进行调度和负载均衡（如数据
  的迁移、Raft group leader 的迁移等）；三是分配全局唯一且递增的事务 ID。
  PD 是一个集群，需要部署奇数个节点，一般线上推荐至少部署 3 个节点。
- TiKV Server：
  TiKV Server 负责存储数据，从外部看 TiKV 是一个分布式的提供事务的 Key-Value 存储引
  擎。存储数据的基本单位是 Region，每个 Region 负责存储一个 Key Range（从 StartKey
  到 EndKey 的左闭右开区间）的数据，每个 TiKV 节点会负责多个 Region。TiKV 使用 Raft
  协议做复制，保持数据的一致性和容灾。副本以 Region 为单位进行管理，不同节点上的多个
  Region 构成一个 RaftGroup，互为副本。数据在多个 TiKV 之间的负载均衡由 PD 调度，
  这里也是以 Region 为单位进行调度。

#### 1.5 TiSpark集群

TiSpark 作为 TiDB 中解决用户复杂 OLAP 需求的主要组件，将 Spark SQL 直接运行在
TiDB 存储层上，同时融合 TiKV 分布式集群的优势，并融入大数据社区生态。至此，TiDB 可
以通过一套系统，同时支持 OLTP 与 OLAP，免除用户数据同步的烦恼。

- TiSpark 深度整合了 Spark Catalyst 引擎, 可以对计算提供精确的控制，使 Spark 能够高效的读取 TiKV 中的数据，提供索引支持以实现高速的点查；
- 通过多种计算下推减少 Spark SQL 需要处理的数据大小，以加速查询；利用 TiDB 的内建的统计信息选择更优的查询计划。
- 从数据集群的角度看，TiSpark + TiDB 可以让用户无需进行脆弱和难以维护的 ETL，直接在同一个平台进行事务和分析两种工作，简化了系统架构和运维。
- 除此之外，用户借助 TiSpark 项目可以在 TiDB 上使用 Spark 生态圈提供的多种工具进行数据处理。例如使用 TiSpark 进行数据分析和 ETL；使用 TiKV 作为机器学习的数据源；借助调度系统产生定时报表等等

#### 1.6 水平扩展特性

无限水平扩展是 TiDB 的一大特点，这里说的水平扩展包括两方面：计算能力和存储能力。TiDB
Server 负责处理 SQL 请求，随着业务的增长，可以简单的添加 TiDBServer 节点，提高整
体的处理能力，提供更高的吞吐。TiKV 负责存储数据，随着数据量的增长，可以部署更多的 TiKV
Server 节点解决数据 Scale 的问题。PD 会在 TiKV 节点之间以 Region 为单位做调度，将
部分数据迁移到新加的节点上。所以在业务的早期，可以只部署少量的服务实例（推荐至少部署
3 个 TiKV， 3 个 PD，2 个 TiDB），随着业务量的增长，按照需求添加 TiKV 或者 TiDB 实
例。

#### 1.7 高可用特性

高可用是 TiDB 的另一大特点，TiDB/TiKV/PD 这三个组件都能容忍部分实例失效，不影响整
个集群的可用性。下面分别说明这三个组件的可用性、单个实例失效后的后果以及如何恢复。

- TiDB：
  TiDB 是无状态的，推荐至少部署两个实例，前端通过负载均衡组件对外提供服务。当单个实例
  失效时，会影响正在这个实例上进行的 Session，从应用的角度看，会出现单次请求失败的情
  况，重新连接后即可继续获得服务。单个实例失效后，可以重启这个实例或者部署一个新的实例。
- PD：
  PD 是一个集群，通过 Raft协议保持数据的一致性，单个实例失效时，如果这个实例不是 Raft
  的 leader，那么服务完全不受影响；如果这个实例是 Raft 的 leader，会重新选出新的 Raft
  leader，自动恢复服务。PD 在选举的过程中无法对外提供服务，这个时间大约是 3 秒钟。推
  荐至少部署三个 PD 实例，单个实例失效后，重启这个实例或者添加新的实例。
- TiKV
  TiKV 是一个集群，通过 Raft协议保持数据的一致性（副本数量可配置，默认保存三副本），
  并通过 PD做负载均衡调度。单个节点失效时，会影响这个节点上存储的所有 Region。对于
  Region 中的 Leader 结点，会中断服务，等待重新选举；对于 Region 中的 Follower 节点，
  不会影响服务。当某个 TiKV 节点失效，并且在一段时间内（默认 30 分钟）无法恢复，PD 会
  将其上的数据迁移到其他的 TiKV 节点上。

### 2. 分布式多节点集群部署

#### 2.1 主机清单

| 主机名称 |       IP       |  部署服务  | 数据盘 |
| :------: | :------------: | :--------: | :----: |
|   pd1    | 172.16.105.110 | PD1 & TiDB | /data  |
|   pd2    | 172.16.105.111 |    PD2     | /data  |
|   pd3    | 172.16.105.112 |    PD3     | /data  |
|  tikv1   | 172.16.105.113 |   TiKV1    | /data  |
|  tikv2   | 172.16.105.114 |   TIKV2    | /data  |
|  tikv3   | 172.16.105.115 |   TIKV3    | /data  |

#### 2.2 网络组件

| 组件 | 默认端口 |            说明             |
| :--: | :------: | :-------------------------: |
| TiDB |   4000   | 应用及 DBA 工具访问通信端口 |
| TiDB |  10080   |  TiDB 状态信息上报通信端口  |
| TiKV |  20160   |        TiKV 通信端口        |
| TiKV |  20180   |  TiKV 状态信息上报通信端口  |
|  PD  |   2379   |  提供 TiDB 和 PD 通信端口   |
|  PD  |   2380   |    PD 集群节点间通信端口    |

#### 2.3 环境准备

- 在所有节点安装docker

```apl
# 安装docker
[root@pd1 ~]# yum -y install docker

# 启动docker
[root@pd1 ~]# systemctl start docker

# 查询安装版本，确认安装成功
[root@pd1 ~]# docker -v
Docker version 1.13.1, build 7d71120/1.13.1
```

- 在PD1节点拉取TiDB镜像

```apl
# 拉取镜像
[root@pd1 ~]# docker pull pingcap/tidb:latest

# 查询镜像
[root@pd1 ~]# docker images
```

- 在PD1，PD2，PD3节点拉取PD镜像

```apl
[root@pd1 ~]# docker pull pingcap/pd:latest
```

- 在TiKV1，TiKV2，TiKV3节点拉取TiKV镜像

```apl
[root@pd1 ~]# docker pull pingcap/tikv:latest
```

#### 2.4 启动PD

##### 2.4.1 PD1节点执行

```apl
[root@pd1 ~]# docker run -d --name pd1 \
> -p 2379:2379 \
> -p 2380:2380 \
> -v /etc/localtime:/etc/localtime:ro \
> -v /data:/data \
> pingcap/pd:latest \
> --name="pd1" \
> --data-dir="/data/pd1" \
> --client-urls="http://0.0.0.0:2379" \
> --advertise-client-urls="http://172.16.105.110:2379" \
> --peer-urls="http://0.0.0.0:2380" \
> --advertise-peer-urls="http://172.16.105.110:2380" \
> --initial-cluster="pd1=http://172.16.105.110:2380,pd2=http://172.16.105.111:2380,pd3=http://172.16.105.112:2380"
```

参数说明：

- --name：当前 PD 的名字如果你需要启动多个 PD，一定要给 PD 使用不同的名字
- --data-dir：PD 存储数据路径
- --client-urls：处理客户端请求监听 URL 列表，如果部署一个集群，--client-urls 必须指定当前主机的 IP 地址；如果是运行在 docker 则需要指定为 http://0.0.0.0:2379
- --advertise-client-urls：对外客户端访问URL列表，在某些情况下，譬如 docker，或者 NAT 网络环境，客户端并不能通过 PD 自己监听的 client URLs 来访问到 PD，这时候，你就可以设置 advertise urls 来让客户端访问，例如：docker 内部 IP 地址为 172.17.0.1，而宿主机的 IP 地址为 172.16.105.110 并且设置了端口映射 -p 2379:2379，那么可以设置为 --advertise-client-urls="[http://172.16.105.110:2379"，客户端可以通过](http://172.16.105.110:2379"，客户端可以通过/) [http://172.16.105.110:2379](http://192.168.100.113:2379/) 来找到这个服务
- --peer-urls：处理其他 PD 节点请求监听 URL 列表。如果部署一个集群，--peer-urls 必须指定当前主机的 IP 地址；如果是运行在 docker 则需要指定为 http://0.0.0.0:2380
- --advertise-peer-urls：对外其他 PD 节点访问 URL 列表。功能与--advertise-client-urls相同
- --initial-cluster：初始化 PD 集群配置。如果你需要启动三台 PD，那么 initial-cluster 可能就是 pd1=http://172.16.105.110:2380, pd2=http://172.16.105.111:2380, pd3=172.16.105.112:2380。

##### 2.4.2 PD2节点执行

```apl
[root@pd2 ~]# docker run -d --name pd2 \
> -p 2379:2379 \
> -p 2380:2380 \
> -v /etc/localtime:/etc/localtime:ro \
> -v /data:/data \
> pingcap/pd:latest \
> --name="pd2" \
> --data-dir="/data/pd2" \
> --client-urls="http://0.0.0.0:2379" \
> --advertise-client-urls="http://172.16.105.111:2379" \
> --peer-urls="http://0.0.0.0:2380" \
> --advertise-peer-urls="http://172.16.105.111:2380" \
> --initial-cluster="pd1=http://172.16.105.110:2380,pd2=http://172.16.105.111:2380,pd3=http://172.16.105.112:2380"
```

##### 2.4.3 PD3节点执行

```apl
[root@pd3 ~]# docker run -d --name pd3 \
> -p 2379:2379 \
> -p 2380:2380 \
> -v /etc/localtime:/etc/localtime:ro \
> -v /data:/data \
> pingcap/pd:latest \
> --name="pd3" \
> --data-dir="/data/pd3" \
> --client-urls="http://0.0.0.0:2379" \
> --advertise-client-urls="http://172.16.105.112:2379" \
> --peer-urls="http://0.0.0.0:2380" \
> --advertise-peer-urls="http://172.16.105.112:2380" \
> --initial-cluster="pd1=http://172.16.105.110:2380,pd2=http://172.16.105.111:2380,pd3=http://172.16.105.112:2380"
```

#### 2.5 启动TiKV

##### 2.5.1 TiKV1节点执行

```apl
[root@tikv1 ~]# docker run -d --name tikv1 \
> -p 20160:20160 \
> -v /etc/localtime:/etc/localtime:ro \
> -v /data:/data \
> pingcap/tikv:latest \
> --addr="0.0.0.0:20160" \
> --advertise-addr="172.16.105.113:20160" \
> --data-dir="/data/tikv1" \
> --pd="172.16.105.110:2379,172.16.105.111:2379,172.16.105.112:2379"
```

参数说明：

- --addr：TiKV 监听地址，如果部署一个集群，--addr 必须指定当前主机的 IP 地址；如果运行在docker则需要指定为 "[http://0.0.0.0:20160](http://0.0.0.0:20160/)"
- --advertise-addr：TiKV 对外访问地址，在某些情况下，譬如 docker，或者 NAT 网络环境，客户端并不能通过 TiKV 自己监听的地址来访问到 TiKV，这时候，你就可以设置 advertise addr 来让 客户端访问，例如：docker 内部 IP 地址为 172.17.0.1，而宿主机的 IP 地址为 172.16.105.113 并且设置了端口映射 -p 20160:20160，那么可以设置为 --advertise-addr="172.16.105.113:20160"，客户端可以通过 172.16.105.113:20160 来找到这个服务
- --data-dir：TiKV 数据存储路径
- --pd：PD 地址列表。TiKV 必须使用这个值连接 PD，才能正常工作。使用逗号来分隔多个 PD 地址。

##### 2.5.2 TiKV2节点执行

```apl
[root@tikv2 ~]# docker run -d --name tikv2 \
> -p 20160:20160 \
> -v /etc/localtime:/etc/localtime:ro \
> -v /data:/data \
> pingcap/tikv:latest \
> --addr="0.0.0.0:20160" \
> --advertise-addr="172.16.105.114:20160" \
> --data-dir="/data/tikv2" \
> --pd="172.16.105.110:2379,172.16.105.111:2379,172.16.105.112:2379"
```

##### 2.5.3 TIKV3节点执行

```apl
[root@tikv3 ~]# docker run -d --name tikv3 \
> -p 20160:20160 \
> -v /etc/localtime:/etc/localtime:ro \
> -v /data:/data \
> pingcap/tikv:latest \
> --addr="0.0.0.0:20160" \
> --advertise-addr="172.16.105.115:20160" \
> --data-dir="/data/tikv3" \
> --pd="172.16.105.110:2379,172.16.105.111:2379,172.16.105.112:2379"
```

#### 2.6 启动TiDB

##### 2.6.1 在PD1节点执行

TiDB组件与PD组件安装在同一节点中。可以TiKV和TiDB，PD分开部署；也可以TiDB和PD混合部署，TiKV 作为存储单元独立部署。监控节点可以和某一台TiDB混合部署。

```apl
[root@pd1 ~]# docker run -d --name tidb \
> -p 4000:4000 \
> -p 10080:10080 \
> -v /etc/localtime:/etc/localtime:ro \
> pingcap/tidb:latest \
> --store=tikv \
> --path="172.16.105.110:2379,172.16.105.111:2379,172.16.105.112:2379"
```

参数说明：

- --store：用来指定 TiDB 底层使用的存储引擎，默认为: "goleveldb"，你可以选择 "memory", "goleveldb", "BoltDB" 或者 "TiKV"。（前面三个是本地存储引擎，而 TiKV 是一个分布式存储引擎），例如，如果我们可以通过 tidb-server --store=memory 来启动一个纯内存引擎的 TiDB

- --path：对于本地存储引擎 "goleveldb", "BoltDB" 来说，path 指定的是实际的数据存放路径；对于 "memory" 存储引擎来说，path 不用设置；对于 "TiKV" 存储引擎来说，path 指定的是实际的 PD 地址。

  

**以上需按PD,TiKV,TiDB顺序启动；TiKV需要依赖PD启动，TiDB需要依赖TiKV启动**

#### 2.7 验证

```apl
# 在TiDB节点安装mysql客户端
[root@pd1 ~]# yum -y install mysql

# 使用mysql客户端连接TiDB测试
[root@pd1 ~]# mysql -u root -h 127.0.0.1 -P 4000
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 29
Server version: 5.7.25-TiDB-v5.0.1 TiDB Server (Apache License 2.0) Community Edition, MySQL 5.7 compatible

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]>

# 检查TiDB版本
MySQL [(none)]> select tidb_version()\G
预期结果输出:
*************************** 1. row ***************************
tidb_version(): Release Version: v5.0.1
Edition: Community
Git Commit Hash: 1145e347d3469d8e89f88dce86f6926ca44b3cd8
Git Branch: heads/refs/tags/v5.0.1
UTC Build Time: 2021-04-23 05:51:17
GoVersion: go1.13
Race Enabled: false
TiKV Min Version: v3.0.0-60965b006877ca7234adaced7890d7b029ed1306
Check Table Before Drop: false
1 row in set (0.00 sec)

# 查看TiKV store状态,store_id、存储情况以及启动时间
MySQL [(none)]> select STORE_ID,ADDRESS,STORE_STATE,STORE_STATE_NAME,CAPACITY,AVAILABLE,UPTIME from INFORMATION_SCHEMA.TIKV_STORE_STATUS \G
预期结果输出:
*************************** 1. row ***************************
        STORE_ID: 1001
         ADDRESS: 172.16.105.114:20160
     STORE_STATE: 0
STORE_STATE_NAME: Up
        CAPACITY: 195GiB
       AVAILABLE: 183.1GiB
          UPTIME: 6h6m48.841287353s
*************************** 2. row ***************************
        STORE_ID: 1004
         ADDRESS: 172.16.105.113:20160
     STORE_STATE: 0
STORE_STATE_NAME: Up
        CAPACITY: 195GiB
       AVAILABLE: 183.1GiB
          UPTIME: 6h1m9.878864477s
*************************** 3. row ***************************
        STORE_ID: 1006
         ADDRESS: 172.16.105.115:20160
     STORE_STATE: 0
STORE_STATE_NAME: Up
        CAPACITY: 195GiB
       AVAILABLE: 183.1GiB
          UPTIME: 5h57m24.868356707s
3 rows in set (0.01 sec)

# 查询tikv节点详细信息
MySQL [(none)]> select * from INFORMATION_SCHEMA.TIKV_STORE_STATUS \G

# 查询tidb组件得id及ip：port得具体信息
MySQL [(none)]> admin show ddl \G
预期结果输出:
*************************** 1. row ***************************
   SCHEMA_VER: 25
     OWNER_ID: 53b4a700-6cb8-4b88-81bb-31a9c8b8ff97           
OWNER_ADDRESS: 172.17.0.3:4000
 RUNNING_JOBS:
      SELF_ID: 53b4a700-6cb8-4b88-81bb-31a9c8b8ff97
        QUERY:
1 row in set (0.01 sec)

参数说明：
OWNER_ID：db领导节点ID
SELF_ID：db自身节点ID

# 使用pd组件得api接口查询TiKV存储
[root@pd1 ~]# curl http://172.16.105.110:2379/pd/api/v1/stores
{
  "count": 3,       # TIKV节点数量
  "stores": [		# TiKV节点列表
    {		  #下面列出的是这个集群中单个TiKV节点的信息
      "store": {
        "id": 1001,     # 节点ID
        "address": "172.16.105.114:20160",
        "version": "5.0.1",
        "status_address": "127.0.0.1:20180",
        "git_hash": "e26389a278116b2f61addfa9f15ca25ecf38bc80",
        "start_timestamp": 1622011457,
        "deploy_path": "/",
        "last_heartbeat": 1622033975898059458,
        "state_name": "Up"
      },
      "status": {
        "capacity": "195GiB",     #存储总容量
        "available": "183.1GiB",  #存储剩余容量
        "used_size": "33.11MiB",
        "leader_count": 1,
        "leader_weight": 1,
        "leader_score": 1,
        "leader_size": 1,
        "region_count": 1,
        "region_weight": 1,
        "region_score": 2.5736404329289417,
        "region_size": 1,
        "start_ts": "2021-05-26T06:44:17Z", 
        #启动时间
        "last_heartbeat_ts": "2021-05-26T12:59:35.898059458Z",          
        # 最后一次心跳时间
        "uptime": "6h15m18.898059458s"
      }
    },
    {
      "store": {
        "id": 1004,
        "address": "172.16.105.113:20160",
        "version": "5.0.1",
        "status_address": "127.0.0.1:20180",
        "git_hash": "e26389a278116b2f61addfa9f15ca25ecf38bc80",
        "start_timestamp": 1622011793,
        "deploy_path": "/",
        "last_heartbeat": 1622033982936664467,
        "state_name": "Up"
      },
      "status": {
        "capacity": "195GiB",
        "available": "183.1GiB",
        "used_size": "33.11MiB",
        "leader_count": 0,
        "leader_weight": 1,
        "leader_score": 0,
        "leader_size": 0,
        "region_count": 1,
        "region_weight": 1,
        "region_score": 2.5735965104492897,
        "region_size": 1,
        "start_ts": "2021-05-26T06:49:53Z",
        "last_heartbeat_ts": "2021-05-26T12:59:42.936664467Z",
        "uptime": "6h9m49.936664467s"
      }
    },
    {
      "store": {
        "id": 1006,
        "address": "172.16.105.115:20160",
        "version": "5.0.1",
        "status_address": "127.0.0.1:20180",
        "git_hash": "e26389a278116b2f61addfa9f15ca25ecf38bc80",
        "start_timestamp": 1622012020,
        "deploy_path": "/",
        "last_heartbeat": 1622033974925130451,
        "state_name": "Up"
      },
      "status": {
        "capacity": "195GiB",
        "available": "183.1GiB",
        "used_size": "33.11MiB",
        "leader_count": 0,
        "leader_weight": 1,
        "leader_score": 0,
        "leader_size": 0,
        "region_count": 1,
        "region_weight": 1,
        "region_score": 2.573603105204918,
        "region_size": 1,
        "start_ts": "2021-05-26T06:53:40Z",
        "last_heartbeat_ts": "2021-05-26T12:59:34.925130451Z",
        "uptime": "6h5m54.925130451s"
      }
    }
  ]
}
```



