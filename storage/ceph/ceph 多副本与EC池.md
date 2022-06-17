# ceph 存储池

### 1. 存储池介绍

#### 1.1 简介

- Ceph 对集群中所有存储资源进行池化管理，pool 是一个逻辑上的概念，其表达的是一组数据存储和查找的约束条件
- Ceph 提供两种类型的存储池，**多副本存储池（Replicated Pool）** 和 **纠删码存储池(Erasure Code Pool)**。

#### 1.2 存储池功能

- **自恢复力：** 你可以设置在不丢数据的前提下允许多少 OSD 失效，对多副本存储池来说，此值是一对象应达到的副本数。 典型配置存储一个对象和它的一个副本（即 size = 2 ）, 但你可以更改副本数； 对纠删编码的存储池来说，此值是编码块数（即纠删码配置里的 m=2 ）。
- **归置组：** 你可以设置一个存储池的归置组数量。典型配置给每个 OSD 分配大约 100 个归置组， 这样，不用过多计算资源就能得到较优的均衡。配置了多个存储池时，要考虑到这些存储池和整个集群的归置组数量要合理
- **CRUSH 规则：** 当你在存储池里存数据的时候，与此存储池相关联的 CRUSH 规则集可控制 CRUSH 算法， 并以此操纵集群内对象及其副本的复制（或纠删码编码的存储池里的数据块）。你可以自定义存储池的 CRUSH 规则。
- **快照：** 用 ceph osd pool mksnap 创建快照的时候，实际上创建了某一特定存储池的快照。
- **设置所有者：** 你可以设置一个用户 ID 为一个存储池的所有者。

要把数据组织到存储池里，你可以列出、创建、删除存储池，也可以查看每个存储池的利用率。

### 2. 环境说明

| 操作系统 |       Ubuntu 20.04        |
| :------: | :-----------------------: |
| ceph版本 | 15.2.12  octopus (stable) |
| 节点架构 |   3 mon，1 mgr，21 osd    |



### 3. 多副本存储池

所谓多副本存储池，就是把所有的对象都存多个副本，Ceph 默认的副本配置是 size = 3, 也就是说数据存三份，2 个副本。但是一般典型的配置 都会把 size 重置为 2，节省空间。

- 查看存储池列表

```apl
root@node1:~# ceph osd lspools
1 device_health_metrics
2 rabbit
3 tiger
4 turtle
5 .rgw.root
6 default.rgw.log
7 default.rgw.control
8 default.rgw.meta

root@node1:~# rados lspools
device_health_metrics
rabbit
tiger
turtle
.rgw.root
default.rgw.log
default.rgw.control
default.rgw.meta
```

- 查看详细得存储池信息

```apl
root@node1:~# ceph osd pool ls detail

pool 1 'device_health_metrics' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 1 pgp_num 1 autoscale_mode on last_change 127 flags hashpspool stripe_width 0 pg_num_min 1 application mgr_devicehealth
pool 2 'rabbit' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 118 flags hashpspool stripe_width 0 application rgw
pool 3 'tiger' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 119 flags hashpspool stripe_width 0 application rgw
pool 4 'turtle' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 120 flags hashpspool stripe_width 0 application rgw
pool 5 '.rgw.root' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 130 flags hashpspool stripe_width 0 application rgw
pool 6 'default.rgw.log' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 132 flags hashpspool stripe_width 0 application rgw
pool 7 'default.rgw.control' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 134 flags hashpspool stripe_width 0 application rgw
pool 8 'default.rgw.meta' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 136 flags hashpspool stripe_width 0
```

#### 3.1 创建crush

- 查看crush类

```apl
root@node1:~# ceph osd crush class ls
[
    "hdd"
]
```

如果服务器上既有基于SSD的创建的OSD，又有基于HDD创建的OSD，则crush class会显示两种类型：hdd和ssd

- 为SSD 类型和HDD 类型分别创建crush 规则

```apl
# 为HDD类型创建crush规则（规则名称为“rule-hdd”）
root@node1:~# ceph osd crush rule create-replicated rule-hdd default host hdd

# 为SSD类型创建crush规则（规则名称为“rule-ssd”）
ceph osd crush rule create-replicated rule-ssd default host ssd
```

- 查看crush规则是否创建成功

```apl
root@node1:~# ceph osd crush rule ls
replicated_rule
rule-hdd
```

其中replicated_rule是集群默认使用的crush rule，若不指定crush rule则默认使用这个。该rule是三副本模式，存储池的所有数据会按照一定比例存储到所有存储设备上（SSD和HDD上都会有数据存储），rule-ssd和rule-hdd则会分别只把数据存储到SSD上和HDD上。

#### 3.2 创建存储池

- 创建Data Pool和Index Pool

```apl
# 创建数据池（数据池名称为“rgw.data”，归置组总数为512）
root@node1:~# ceph osd pool create rgw.data 512 512

# 创建索引池（索引池名称为“rgw.index”，归置组总数为128）
root@node1:~# ceph osd pool create rgw.index 128 128

# 命令形式：
root@node1:~# ceph osd pool create {pool_name} {pg_num} [{pgp_num}] [replicated] [crush_ruleset_name] [expected_num_objects]
```

归置组（pg）说明：

- 创建存储池命令最后的两个数字，分别代表存储池的pg_num和pgp_num，即存储池对应的pg数量。Ceph官方文档建议整个集群所有存储池的pg数量之和大约为：（OSD数量 * 100)/数据冗余因数，数据冗余因数对副本模式而言是副本数，对EC模式而言是数据块+校验块之和。例如，三副本模式是3，EC4+2模式是6。

- 此处整个集群3台服务器，每台服务器7个OSD，总共21个OSD，按照上述公式计算应为700，一般建议pg数取2的整数次幂。由于数据池存放的数据量远大于其他几个存储池的数据量，因此该存储池也成比例的分配更多的pg。

综上，rgw.data的pg数量取512，rgw.index的pg数量取128。

参数说明：

|         名称         |  类型  | 是否必需 |                           参数说明                           |
| :------------------: | :----: | :------: | :----------------------------------------------------------: |
|      pool_name       | string |   Yes    |                     存储池名称，必须唯一                     |
|        pg_num        |  int   |   Yes    |                      存储池的归置组总数                      |
|       pgp_num        |  int   |    No    |         用于归置的归置组总数。此值应该等于归置组总数         |
|      replicated      | string |    No    |             replicated 表示创建的为多副本存储池              |
|  crush_ruleset_name  | string |    No    |    此存储池所用的 CRUSH 规则集名字。指定的规则集必须存在     |
| expected_num_objects |  int   |    No    | 为这个存储池预估的对象数。设置此值（要同时把 filestore merge threshold 设置为负数）后,在创建存储池时就会拆分 PG 文件夹，以免运行时拆分文件夹导致延时增大。 |

- 修改存储池得crush规则

```apl
# 修改rgw.data池得crush规则为“rule-hdd”，即将数据只存储到hdd磁盘中
root@node1:~# ceph osd pool set rgw.data crush_rule rule-hdd

# 修改rgw.index池得crush规则为“rule-ssd”，即将数据只存储到ssd磁盘中
ceph osd pool set rgw.index crush_rule rule-ssd

# 查看存储池详细信息
root@node1:~# ceph osd pool ls detail

pool 1 'device_health_metrics' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 1 pgp_num 1 autoscale_mode on last_change 127 flags hashpspool stripe_width 0 pg_num_min 1 application mgr_devicehealth
pool 2 'rabbit' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 118 flags hashpspool stripe_width 0 application rgw
pool 3 'tiger' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 119 flags hashpspool stripe_width 0 application rgw
pool 4 'turtle' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 120 flags hashpspool stripe_width 0 application rgw
pool 5 '.rgw.root' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 130 flags hashpspool stripe_width 0 application rgw
pool 6 'default.rgw.log' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 132 flags hashpspool stripe_width 0 application rgw
pool 7 'default.rgw.control' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 134 flags hashpspool stripe_width 0 application rgw
pool 8 'default.rgw.meta' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 136 flags hashpspool stripe_width 0
pool 9 'rgw.data' replicated size 3 min_size 2 crush_rule 1 object_hash rjenkins pg_num 512 pgp_num 512 pg_num_target 32 pgp_num_target 32 autoscale_mode on last_change 473 flags hashpspool stripe_width 0 application rgw
pool 10 'rgw.index' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 pg_num_target 32 pgp_num_target 32 autoscale_mode on last_change 472 flags hashpspool stripe_width 0 application rgw

# 可看到pool 9，crush_rule 1 表示使用的是hhd的crush，可使用ceph osd crush rule ls查看规则集，0为默认规则集
```

#### 3.3 储存池设置

- 获取pool副本数

```apl
# 获取rgw.data池的副本数（该池副本数为3）
root@node1:~# ceph osd pool get rgw.data size
size: 3
```

- 设置存储池副本

```apl
# 设置rgw.data池的副本数为2
root@node1:~# ceph osd pool set rgw.data size 2
set pool 9 size to 2

# 查看
root@node1:~# ceph osd pool get rgw.data size
size: 2
```

- 调整存储池选项值

```apl
# 命令形式：
ceph osd pool set {pool_name} {key} {value}

# 获取rgw.data存储池的 pg_num / pgp_num
root@node1:~# ceph osd pool get rgw.data  pg_num
pg_num: 512

root@node1:~# ceph osd pool get rgw.data  pgp_num
pgp_num: 512

# 设置 pg_num 和 pgp_num
root@node1:~# ceph osd pool set rgw.data pg_num 1024
root@node1:~# ceph osd pool set rgw.data pgp_num 1024
```

**Pool 的 pg_num 只能增大，不能减小。并且如果修改了 pg_num 最好同时修改 pgp_num，保持 pg_num = pgp_num。**

- 删除存储池

  删除存储是非常危险测操作，会销毁存储池中的全部数据，所以如果要删除存储池，你首先要在配置文档 `ceph.conf` 加入一条配置， 设置允许删除存储池，然后重启 MON 服务生效。

```apl
vim /etc/ceph/ceph.conf
mon_allow_pool_delete = true
```

其次为了防止删错，你需要连续输入两次 `{pool_name}`， 并且命令后面跟上 `--yes-i-really-really-mean-it` 参数。

```apl
root@node1:~# ceph osd pool rm  rgw.data rgw.data --yes-i-really-really-mean-it
```

- 重命名存储池

```apl
# 命令格式：
ceph osd pool rename {current_pool_name} {new_pool_name}
```

- 查看存储池统计信息

```apl
root@node1:~# rados df
```

#### 3.4 存储池快照

- 创建存储池快照

```apl
# 将rgw.data存储池拍摄快照，快照名称为snap.rgw.data
root@node1:~# ceph osd pool mksnap rgw.data snap.rgw.data
created pool rgw.data snap snap.rgw.data
```

- 删除存储池快照

```apl
root@node1:~# ceph osd pool rmsnap rgw.data snap.rgw.data
removed pool rgw.data snap snap.rgw.data 
```



### 4. 创建EC存储池

Ceph 在没有特别指定参数的情况下，默认创建的是多副本存储池。纠删码存储池可以在提供与副本相同的冗余水平的同时节省空间。

最简单的纠删码存储池等效于RAID5，它相当于 `size = 2` 的副本池，却能节省 25% 的磁盘空间。

#### 4.1 创建EC配置

- 为SSD 类型和HDD 类型分别创建crush 规则，参考：3.1
- 创建EC profile

```apl
root@node1:~# ceph osd erasure-code-profile set myprofile k=4 m=2 crush-failure-domain=osd crush-device-class=hdd

#在此配置中 k=4 和 m=2，其含义为数据分布于 6 个 OSD （ k+m==6 ）且允许二个失效。
一个 k=4 且 m=2 的配置可容忍 2 个 OSD 失效，它会把一对象分布到 6 个（ k+m=6 ） OSD 上。 此对象先被分割为 6 块（若对象为 10MB ，那每块就是 1MB ）、并计算出 2 个用于恢复的编码块（各编码块尺寸等于数据块，即 1MB ）； 这样，原始空间仅多占用 10% 就可容忍 2 个 OSD 同时失效、且不丢失数据。
```

参数说明：

以EC 4+2为例，以上命令创建了一个名为myprofile的EC profile，k为数据块数量，m为校验块数量，crush-failure-domain=host表示最小故障域为host，crush-device-class=hdd表示crush rule建立在hdd上。

一般情况下，最小故障域设置为host，若host数量小于k+m，则需要将故障域改为osd，否则会因无法找到足够多的host而报错。

#### 4.2 创建EC存储池

- 创建Data Pool和Index Pool

```apl
# 创建一个名为ec.rgw.data的EC模式数据存储池，并使用刚创建的EC 配置（myprofile）
root@node1:~# ceph osd pool create ec.rgw.data 256 256 erasure myprofile
pool 'ec.rgw.data' created

# 索引池并没有使用EC模式存储池
root@node1:~# ceph osd pool create ec.rgw.index 64 64
pool 'ec.rgw.index' created

# 应用该池
root@node1:~# ceph osd pool application enable ec.rgw.data rgw
enabled application 'rgw' on pool 'ec.rgw.data'

root@node1:~# ceph osd pool application enable ec.rgw.index rgw
enabled application 'rgw' on pool 'ec.rgw.index'
```

- 查看存储池详细信息

```apl
root@node1:~# ceph osd pool ls detail

pool 1 'device_health_metrics' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 1 pgp_num 1 autoscale_mode on last_change 127 flags hashpspool stripe_width 0 pg_num_min 1 application mgr_devicehealth
pool 2 'rabbit' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 118 flags hashpspool stripe_width 0 application rgw
pool 3 'tiger' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 119 flags hashpspool stripe_width 0 application rgw
pool 4 'turtle' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 120 flags hashpspool stripe_width 0 application rgw
pool 5 '.rgw.root' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 130 flags hashpspool stripe_width 0 application rgw
pool 6 'default.rgw.log' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 132 flags hashpspool stripe_width 0 application rgw
pool 7 'default.rgw.control' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 134 flags hashpspool stripe_width 0 application rgw
pool 8 'default.rgw.meta' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 136 flags hashpspool stripe_width 0
pool 9 'rgw.data' replicated size 2 min_size 1 crush_rule 1 object_hash rjenkins pg_num 512 pgp_num 512 pg_num_target 32 pgp_num_target 32 autoscale_mode on last_change 478 flags hashpspool,pool_snaps stripe_width 0 application rgw
pool 10 'rgw.index' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 128 pgp_num 128 pg_num_target 32 pgp_num_target 32 autoscale_mode on last_change 472 flags hashpspool stripe_width 0 application rgw
pool 11 'ec.rgw.data' erasure profile myprofile size 6 min_size 5 crush_rule 2 object_hash rjenkins pg_num 256 pgp_num 256 pg_num_target 32 pgp_num_target 32 autoscale_mode on last_change 488 flags hashpspool stripe_width 16384 application rgw
pool 12 'ec.rgw.index' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 64 pgp_num 64 autoscale_mode on last_change 489 flags hashpspool stripe_width 0 application rgw
```

数据冗余因数对副本模式而言是副本数，对EC模式而言是数据块+校验块之和。例如，三副本模式是3，EC4+2模式是6。

- 修改crush规则

```apl
root@node1:~# ceph osd pool set {pool_name} crush_rule {crush_name}
```

#### 4.3 缓存层配置

- 纠删码存储池与缓存分级

纠删码存储池比复制池需要更多的资源，并且缺少某些功能，例如部分写入。为了弥补这些缺陷，建议在纠删码存储池前面设置一个缓存层。

例如：如果 `hot-storage` 是由快速存储组成，我们可以使用下面的方式设置缓存层：

```
ceph osd tier add ecpool hot-storage
ceph osd tier cache-mode hot-storage writeback
ceph osd tier set-overlay ecpool hot-storage
```

此时会将 `hot-storage` 池作为 `ecpool` 池的回写模式，这样一来 `ecpool` 的每次写入和读取实际上都在使用 `hot-storage` 缓存池，并从其灵活性和速度中受益。

 ### 5. 存储池，归置组，crush配置参考

当你创建存储池并给它设置归置组数量时，建议更改某些默认值，特别是存储池的副本数和默认归置组数量，可以在运行 [pool](http://docs.ceph.org.cn/rados/operations/pools) 命令的时候设置这些值。你也可以把配置写入 Ceph 配置文件的 `[global]` 段来覆盖默认值。

- ```
  mon max pool pg num
  ```

  | 描述:   | 每个存储的最大归置组数量。 |
  | :------ | -------------------------- |
  | 类型:   | Integer                    |
  | 默认值: | `65536`                    |

- ```
  mon pg create interval
  ```

  | 描述:   | 在同一个 OSD 里创建 PG 的间隔秒数。 |
  | :------ | ----------------------------------- |
  | 类型:   | Float                               |
  | 默认值: | `30.0`                              |

- ```
  mon pg stuck threshold
  ```

  | 描述:   | 多长时间无响应的 PG 才认为它卡住了。 |
  | :------ | ------------------------------------ |
  | 类型:   | 32-bit Integer                       |
  | 默认值: | `300`                                |

- ```
  osd pg bits
  ```

  | 描述:   | 每个 OSD 的归置组位数。 |
  | :------ | ----------------------- |
  | 类型:   | 32-bit Integer          |
  | 默认值: | `6`                     |

- ```
  osd pgp bits
  ```

  | 描述:   | 每个 OSD 为 PGP 留的位数。 |
  | :------ | -------------------------- |
  | 类型:   | 32-bit Integer             |
  | 默认值: | `6`                        |

- ```
  osd crush chooseleaf type
  ```

  | 描述:   | 在一个 CRUSH 规则内用于 `chooseleaf` 的桶类型。用序列号而不是名字。 |
  | :------ | ------------------------------------------------------------ |
  | 类型:   | 32-bit Integer                                               |
  | 默认值: | `1` ，通常一台主机包含一或多个 OSD 。                        |

- ```
  osd pool default crush replicated ruleset
  ```

  | 描述:   | 创建多副本存储池时用哪个默认 CRUSH 规则集。                  |
  | :------ | ------------------------------------------------------------ |
  | 类型:   | 8-bit Integer                                                |
  | 默认值: | `CEPH_DEFAULT_CRUSH_REPLICATED_RULESET` ，也就是说，“挑选数字 ID 最小的规则集”。这样，没有规则集 0 时也能成功创建存储池。 |

- ```
  osd pool erasure code stripe width
  ```

  | 描述:   | 设置每个已编码池内的对象条带尺寸（单位为字节）。尺寸为 S 的各对象将存储为 N 个条带，且各条带将分别编码/解码。 |
  | :------ | ------------------------------------------------------------ |
  | 类型:   | Unsigned 32-bit Integer                                      |
  | 默认值: | `4096`                                                       |

- ```
  osd pool default size
  ```

  | 描述:   | 设置一存储池的对象副本数，默认值等同于 `ceph osd pool set {pool-name} size {size}` 。 |
  | :------ | ------------------------------------------------------------ |
  | 类型:   | 32-bit Integer                                               |
  | 默认值: | `3`                                                          |

- ```
  osd pool default min size
  ```

  | 描述:   | 设置存储池中已写副本的最小数量，以向客户端确认写操作。如果未达到最小值， Ceph 就不会向客户端回复已写确认。此选项可确保降级（ `degraded` ）模式下的最小副本数。 |
  | :------ | ------------------------------------------------------------ |
  | 类型:   | 32-bit Integer                                               |
  | 默认值: | `0` ，意思是没有最小值。如果为 `0` ，最小值是 `size - (size / 2)` 。 |

- ```
  osd pool default pg num
  ```

  | 描述:   | 一个存储池的默认归置组数量，默认值即是 `mkpool` 的 `pg_num` 参数。 |
  | :------ | ------------------------------------------------------------ |
  | 类型:   | 32-bit Integer                                               |
  | 默认值: | `8`                                                          |

- ```
  osd pool default pgp num
  ```

  | 描述:   | 一个存储池里，为归置使用的归置组数量，默认值等同于 `mkpool` 的 `pgp_num` 参数。当前 PG 和 PGP 应该相同。 |
  | :------ | ------------------------------------------------------------ |
  | 类型:   | 32-bit Integer                                               |
  | 默认值: | `8`                                                          |

- ```
  osd pool default flags
  ```

  | 描述:   | 新存储池的默认标志。 |
  | :------ | -------------------- |
  | 类型:   | 32-bit Integer       |
  | 默认值: | `0`                  |

- ```
  osd max pgls
  ```

  | 描述:   | 将列出的最大归置组数量，一客户端请求量大时会影响 OSD 。 |
  | :------ | ------------------------------------------------------- |
  | 类型:   | Unsigned 64-bit Integer                                 |
  | 默认值: | `1024`                                                  |
  | Note:   | 默认值应该没问题。                                      |

- ```
  osd min pg log entries
  ```

  | 描述:   | 清理日志文件的时候保留的归置组日志量。 |
  | :------ | -------------------------------------- |
  | 类型:   | 32-bit Int Unsigned                    |
  | 默认值: | `1000`                                 |

- ```
  osd default data pool replay window
  ```

  | 描述:   | 一 OSD 等待客户端重播请求的时间，秒。 |
  | :------ | ------------------------------------- |
  | 类型:   | 32-bit Integer                        |
  | 默认值: | `45`                                  |

