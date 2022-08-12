# ceph osd 时延过高实现自动隔离命令


- 获取osd时延

```bash
root@node01:~# ceph osd perf 
osd  commit_latency(ms)  apply_latency(ms)
  5                   0                  0
  4                   0                  0
  3                   0                  0
  2                   0                  0
  0                   0                  0
  1                   0                  0

# 说明：
osd列：             代表osd号，ceph中表示为osd.0  osd.1
commit_latency：    提交时延，数据提交保存
apply_latency：     申请时延，应该统计这个
```

- 获取osd所在节点

```bash
root@node01:~# ceph osd tree
ID  CLASS  WEIGHT   TYPE_NAME        STATUS  REWEIGHT  PRI-AFF
-1         0.29279  root default                              
-5         0.09760      host node01                           
 2    hdd  0.04880          osd.2        up   1.00000  1.00000
 3    hdd  0.04880          osd.3        up   1.00000  1.00000
-7         0.09760      host node02                           
 4    hdd  0.04880          osd.4        up   1.00000  1.00000
 5    hdd  0.04880          osd.5        up   1.00000  1.00000
-3         0.09760      host node03                           
 0    hdd  0.04880          osd.0        up   1.00000  1.00000
 1    hdd  0.04880          osd.1        up   1.00000  1.00000

# STATUS栏位有四种状态
up      #osd正常可以读写
in      #osd在线，但有可能不是up状态
down    #osd离线
out     #osd不仅离线，而且不在集群

# 查看osd应用的节点
root@node04:~# ceph osd status 
ID  HOST     USED  AVAIL  WR OPS  WR DATA  RD OPS  RD DATA  STATE      
 0  node03  2219G  9176G     68     16.7M      0        0   exists,up  
 1  node03  2052G  9343G     65     16.0M      0        0   exists,up  
 2  node03  2084G  9311G     51     12.6M      0        0   exists,up  


root@node02:~# ceph osd stat 
45 osds: 45 up (since 102s), 45 in (since 2m); epoch: e557; 268 remapped pgs

```

- 获取pg状态

```bash
ceph pg dump_stuck inactive|unclean|stale|undersized|degraded [--format <format>]

degraded   # pg存在降级

```

- 查看osd最大个数

```bash
root@node04:~# ceph osd getmaxosd
max_osd = 45 in epoch 509
```


- osd 提出集群

```bash
systemctl stop ceph-osd@0      # 这条命令必须在osd对应节点上执行
#ceph osd down 0                # 集群所有节点皆可
ceph osd out 0                 # 集群所有节点皆可
# osd.0 先down，然后再out

```

- osd 加入集群

```bash
ceph osd in 0
#ceph osd up 0
systemctl start ceph-osd@0 
```


- 集群管理日志

```bash
cat /opt/petasan/log/zxcloudAuth.log
```

- 模拟注入磁盘时延100ms

```bash
fio -name=test01 -filename=/dev/sda -ioengine=libaio -direct=1 -bs=1024k -iodepth=128 -rw=randread -runtime=604800 -time_based -group_reporting

```