# Ceph CRUSH

[toc]

**Crush**是Ceph最核心的几个设计之一，Crush是一种基于哈希的数据分布算法。
Crush算法基于权重将数据映射到所有存储设备，这个过程受控并高度依赖于集群拓扑描述--**cluster map**，不同数据分布策略通过制定不同的放置规则实现--**placement rule**。

> 文档演示所用环境Ceph版本：15.2.13

## Crush map

上面说到的Cluster map 也就是**Crush map**，是Ceph集群拓扑结构的逻辑描述形式。
在实际应用中通常具有如`数据中心(datacenter)-->机架/机柜(rack)-->主机(host)-->磁盘(device)`这样的树状层级关系。

每个节点都是真实的最小物理存储设备，如磁盘（device）,所有中间节点统称为bucket，每个bucket可以是一些devices的集合，也可以实低一级的集合。

## Crush class

Crush class 称为磁盘智能分组，是根据磁盘类型进行属性关联，最常见如hdd组、ssd组及nvme组。
当然class组不限于磁盘类型关联，可以根据自己定义非磁盘类型的关联，如cg01。

- 查看class分组

```bash
root@qdss-node-01:~# ceph osd tree
ID  CLASS  WEIGHT   TYPE NAME              STATUS  REWEIGHT  PRI-AFF
-1         0.29398  root default                                    
-5         0.09799      host qdss-node-01                           
 2    hdd  0.04900          osd.2              up   1.00000  1.00000
 3    hdd  0.04900          osd.3              up   1.00000  1.00000
-7         0.09799      host qdss-node-02                           
 4    hdd  0.04900          osd.4              up   1.00000  1.00000
 5    hdd  0.04900          osd.5              up   1.00000  1.00000
-3         0.09799      host qdss-node-03                           
 0    hdd  0.04900          osd.0              up   1.00000  1.00000
 1    hdd  0.04900          osd.1              up   1.00000  1.00000

root@qdss-node-01:~# ceph osd crush class ls
[
    "hdd"
]

# 系统会自动根据磁盘类型生成class组名
```

- 创建class分组

```bash
# 创建一个ssd的class分组
root@qdss-node-01:~# ceph osd crush class create ssd
created class ssd with id 1 to crush map
root@qdss-node-01:~# ceph osd crush class ls
[
    "hdd",
    "ssd"
]

# 删除分组
root@qdss-node-01:~# ceph osd crush class rm ssd
removed class SSD with id 1 from crush map
```

- osd绑定class分组

```bash
# 清除当前osd的class分组
root@qdss-node-01:~# ceph osd crush rm-device-class osd.0 osd.1 osd.2 osd.3 osd.4 osd.5
done removing class of osd(s): 0,1,2,3,4,5


# 查看osd的分组
root@qdss-node-01:~# ceph osd tree
ID  CLASS  WEIGHT   TYPE NAME              STATUS  REWEIGHT  PRI-AFF
-1         0.29398  root default                                    
-5         0.09799      host qdss-node-01                           
 2         0.04900          osd.2              up   1.00000  1.00000
 3         0.04900          osd.3              up   1.00000  1.00000
-7         0.09799      host qdss-node-02                           
 4         0.04900          osd.4              up   1.00000  1.00000
 5         0.04900          osd.5              up   1.00000  1.00000
-3         0.09799      host qdss-node-03                           
 0         0.04900          osd.0              up   1.00000  1.00000
 1         0.04900          osd.1              up   1.00000  1.00000


# 重新绑定分组
root@qdss-node-01:~# ceph osd crush set-device-class ssd osd.0 osd.2 osd.4
set osd(s) 0,2,4 to class 'ssd'
root@qdss-node-01:~# ceph osd crush set-device-class hdd osd.1 osd.3 osd.5
set osd(s) 1,3,5 to class 'hdd'

# 再次查看
root@qdss-node-01:~# ceph osd tree
ID  CLASS  WEIGHT   TYPE NAME              STATUS  REWEIGHT  PRI-AFF
-1         0.29398  root default                                    
-5         0.09799      host qdss-node-01                           
 3    hdd  0.04900          osd.3              up   1.00000  1.00000
 2    ssd  0.04900          osd.2              up   1.00000  1.00000
-7         0.09799      host qdss-node-02                           
 5    hdd  0.04900          osd.5              up   1.00000  1.00000
 4    ssd  0.04900          osd.4              up   1.00000  1.00000
-3         0.09799      host qdss-node-03                           
 1    hdd  0.04900          osd.1              up   1.00000  1.00000
 0    ssd  0.04900          osd.0              up   1.00000  1.00000

# 从上面可以看到6个osd分别指定到hdd和ssd两个分组
```

- 重命名class

```bash
# 假设我们要把cg01/cg02分别改为sata7k/sas15k
root@qdss-node-01:~# ceph osd crush class ls
[
    "hdd",
    "cg01",
    "cg02"
]
root@qdss-node-01:~# ceph osd crush class rename cg01 sata7k
rename class 'cg01' to 'sata7k'
root@qdss-node-01:~# ceph osd crush class rename cg02 sas15k
rename class 'cg02' to 'sas15k'
root@qdss-node-01:~# ceph osd crush class ls
[
    "hdd",
    "sata7k",
    "sas15k"
]
```

- 查看osd绑定class

```bash
root@qdss-node-01:~# ceph osd crush class ls-osd sata7k
0
2
4
root@qdss-node-01:~# ceph osd crush class ls-osd sas15k
1
3
5
```

## Crush rule

placement rule即Crush rule，rule相当于crush的行为准则，crush做的每一步都是按照rule规则来执行。

- 配置模板

```conf
rule <rulename> {
    ruleset <ruleset>
    type [ replicated | erasure ]
    min_size <min-size>
    max_size <max-size>
    step take <bucket-type> [ class <class-name> ]
    step select [choose|chooseleaf] [firstn|indep] <num> type <bucket-type>
    step emit
}
```

- 配置解释

```conf
ruleset         相当于rule的id
type            存储池pool的类型，是副本还是纠删码
min_size        如果副本数小于这个数值，就不会应用这条rule
max_size        如果副本数大于这个数值，就不会应用这条rule
step take       crush规则的入口，一般时类型为root的bucket
step select     分别为choose和chooseleaf两种，num代表选择的数量，type是预期的bucket类型
step emit       代表从take开始到这个操作结束
```

- 重点介绍

```conf
# step select [choose|chooseleaf] [firstn|indep] <num> type <bucket-type>
select:           select开始的起点，就是上一个step的输出
-- choose            在选择到预期类型的bucket后就到此结束，进行下一个select操作
-- chooselesf        在选择到预期的bucket后会继续递归选择到osd
-- firstn            深度优先遍历算法，对应多副本
-- indep             深度优先遍历算法，对应纠删码
-- num               预期选择的数量，0代表选择repnum(副本数)个，负数代表选择repnum-num个，例如repnum=3，num=-1，代表选择为：3-1=2个

-- firstn/indep的区别：
假如选择的num为4，而被选择的osd无法选够4个结果的时候firstn会返回[1,2,4]的结果
而indep会返回[1,2,CRUSH_ITEM_NONE,4]，即indeph会使用空穴来进行填充
```

- num该怎么用

num在什么时候该用0、正数、负数呢？ 举例（假设3副本模式下）：

```conf
# 第一种规则
id 0
type replicated
min_size 1
max_size 10
step take ssd_host
step choose firstn 1 type room       # num=1，从ssd_host入口，选择1个room
step chooseleaf firstn 0 type host   # num=0，从room开始，选择3个host，并找各到一个osd作为存放数据的osd
step emit

# 第二种规则
id 0
type replicated
min_size 1
max_size 10
step take rep_ssd
step chooseleaf firstn 1 type host    # num=1，从rep_ssd入口，选择1个host并找到一个osd作为主osd
step emit
step take rep_hdd
step chooseleaf firstn -1 type host   # num=-1，从rep_hdd入口，选择2个host，并找各到一个osd作为2个副本osd
step emit
```

## 亚节点纠删

首先，正常的纠删码规则是到host级别（表现形式为N+M），也就是当配置就删码规则为4+2时，需要最少6个节点。
但，当集群小于6节点，若依然要配置4+2的EC规则，此时引出亚节点纠删的概念（表现形式为N+M:B），
N+M:B，N和M都好理解，B表示是可以接受故障的节点数量；比如4+2:1，表示有6个数据分片，允许随机两个磁盘故障或一个节点故障。
这样的好处在于，在保持磁盘空间利用率的情况下，还可以兼顾允许范围的故障域。

以下以三个节点为例，如何配置4+2:1

```shell
# Crush规则
id 0
type erasure
min_size 3
max_size 20
step set_chooseleaf_tries 5
step set_choose_tries 50
step take default
step choose indep 3 type host       //num=3，从default入口，选择3个host故障域
step choose indep 2 type osd        //num=2，从每个host的故障域开始，各选择2个osd，共选择6个osd
step emit

# EC规则为4+2
$ ceph osd erasure-code-profile ls
$ ceph osd erasure-code-profile get ec-42-profile
crush-device-class=
crush-failure-domain=host
crush-root=default
jerasure-per-chunk-alignment=false
k=4
m=2
plugin=jerasure
technique=reed_sol_van
w=8

## 上传一个文件到tiger存储池
$ s3cmd put release/qdss-deploy.deb s3://test1/

## 查看文件的crush map
$ ceph osd map tiger qdss-deploy.deb
osdmap e1169 pool 'tiger' (37) object 'qdss-deploy.deb' -> pg 37.5c0e4a19 (37.19) -> up ([12,14,0,1,6,5], p12) acting ([12,14,0,1,6,5], p12)

## 核对osd
root@node1:~# ceph osd crush tree --show-shadow
ID  CLASS  WEIGHT     TYPE NAME           
-1         168.82484  root default      
-5          56.27495      host node1    
 5    hdd   11.25499          osd.5     
 6    hdd   11.25499          osd.6     
 7    hdd   11.25499          osd.7     
 8    hdd   11.25499          osd.8     
 9    hdd   11.25499          osd.9     
-7          56.27495      host node2    
10    hdd   11.25499          osd.10    
11    hdd   11.25499          osd.11    
12    hdd   11.25499          osd.12    
13    hdd   11.25499          osd.13    
14    hdd   11.25499          osd.14    
-3          56.27495      host node3    
 0    hdd   11.25499          osd.0     
 1    hdd   11.25499          osd.1     
 2    hdd   11.25499          osd.2     
 3    hdd   11.25499          osd.3     
 4    hdd   11.25499          osd.4 
```

## 磁盘分组配置示例

利用Crush class磁盘分组和Crush rule之间的配合，将数据存放至指定的分组中

- 环境说明

```bash
存储三节点
```
