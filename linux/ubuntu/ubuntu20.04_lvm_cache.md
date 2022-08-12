# ubuntu20.04 lvm_cache

## 1. 概念

在RHEL6.7之后，LVM提供对LVM缓存逻辑卷的支持，它是基于dm-cache，LVM缓存逻辑卷使用快速设备（例如SSD驱动器）组成的小型逻辑卷，来提高容量更大但更慢逻辑卷的性能。

> 参考资料：<https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/enabling-caching-to-improve-logical-volume-performance_configuring-and-managing-logical-volumes>

### 1.1 LVM缓存方式

- dm-cache
dm-cache是加快对常用数据的读写缓存操作，也叫读写热点缓存

- dm-writecache
dm-writecache仅缓存写操作，然后再迁移到慢磁盘

### 1.2 LVM缓存组件

- cachevol
该模式的缓存设备会同时存储数据块的缓存副本和用于管理缓存的元数据，即缓存数据和元数据在同一设备中。

- cachepool
该模式的缓存设备是单独存储数据块的缓存副本或用于管理缓存的元数据。即缓存数据和元数据会在不同的设备上。
注意：dm-writecache不兼容cachepool

### 1.3 LVM缓存模式

- Writethrough
直写模式，数据同时写入缓存盘和数据盘。dm-cache的默认模式

- writeback
回写模式，数据先写入缓存盘，在慢慢写入数据盘。dm-writecache唯一模式。dm-cache需要单独设置。

## 2. 环境准备

```shell
lsblk
...
sdb                         8:16   0   50G  0 disk 
sdc                         8:32   0   50G  0 disk 
sdd                         8:48   0   50G  0 disk

# sdb作cache，分两个区10G的，剩余不做用途
# sdc、sdd作data。
```

## 3. 构建dm-cache模式

### 3.1 分区

- cache分区

```shell
# 第一个分区
sgdisk --new 0:0:+10G -c 0:ceph-cache /dev/sdb
sgdisk -p /dev/sdb
Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048        20973567   10.0 GiB    8300  ceph-cache

# 第二个分区
sgdisk --new 0:0:+10G -c 0:ceph-cache /dev/sdb
sgdisk -p /dev/sdb
Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048        20973567   10.0 GiB    8300  ceph-cache
   2        20973568        41945087   10.0 GiB    8300  ceph-cache
```

- data分区

```shell
sgdisk --new 0:0:0 -c 0:ceph-data /dev/sdc
sgdisk --new 0:0:0 -c 0:ceph-data /dev/sdd

lsblk
sdc                         8:32   0   50G  0 disk 
└─sdc1                      8:33   0   50G  0 part 
sdd                         8:48   0   50G  0 disk
└─sdd1                      8:49   0   50G  0 part
```

### 3.2 创建PV

- cache

```shell
pvcreate -f -v -y  /dev/sdb1
pvcreate -f -v -y  /dev/sdb2
```

- data

```shell
pvcreate -f -v -y /dev/sdc1
pvcreate -f -v -y /dev/sdd1
```

### 3.3 构建VG

- VG组1

```shell
vgcreate ps-dmc-vg1 /dev/sdb1 /dev/sdc1
```

- VG组2

```shell
vgcreate ps-dmc-vg2 /dev/sdb2 /dev/sdd1
```

- 查看

```shell
root@ubuntu:~# pvs
  PV         VG         Fmt  Attr PSize    PFree  
  /dev/sdb1  ps-dmc-vg1 lvm2 a--   <10.00g <10.00g
  /dev/sdb2  ps-dmc-vg2 lvm2 a--   <10.00g <10.00g
  /dev/sdc1  ps-dmc-vg1 lvm2 a--   <50.00g <50.00g
  /dev/sdd1  ps-dmc-vg2 lvm2 a--   <50.00g <50.00g
```

### 3.4 构建dm-cache

- vg1-cachevol

```shell
lvcreate -n cache -l 100%FREE ps-dmc-vg1 /dev/sdb1
lvcreate -n main -l 100%FREE ps-dmc-vg1 /dev/sdc1

root@ubuntu:~# lvs -a
  LV        VG         Attr       LSize    Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  cache     ps-dmc-vg1 -wi-a-----  <10.00g                                                    
  main      ps-dmc-vg1 -wi-a-----  <50.00g                                                    

# 构建命令
lvconvert --yes --type cache --cachevol cache ps-dmc-vg1/main

# 查询1
root@ubuntu:~# lsblk
sdb                                   8:16   0   50G  0 disk 
├─sdb1                                8:17   0   10G  0 part 
│ └─ps--dmc--vg1-cache_cvol         253:0    0   10G  0 lvm  
│   ├─ps--dmc--vg1-cache_cvol-cdata 253:2    0   10G  0 lvm  
│   │ └─ps--dmc--vg1-main           253:1    0   50G  0 lvm  
│   └─ps--dmc--vg1-cache_cvol-cmeta 253:3    0   12M  0 lvm  
│     └─ps--dmc--vg1-main           253:1    0   50G  0 lvm  
sdc                                   8:32   0   50G  0 disk 
└─sdc1                                8:33   0   50G  0 part 
  └─ps--dmc--vg1-main_corig         253:4    0   50G  0 lvm  
    └─ps--dmc--vg1-main             253:1    0   50G  0 lvm  

# 查询2
root@ubuntu:~# lvs -a
  LV           VG         Attr       LSize    Pool         Origin       Data%  Meta%  Move Log Cpy%Sync Convert
  [cache_cvol] ps-dmc-vg1 Cwi-aoC---  <10.00g                                                                  
  main         ps-dmc-vg1 Cwi-a-C---  <50.00g [cache_cvol] [main_corig] 0.01   11.07           0.00            
  [main_corig] ps-dmc-vg1 owi-aoC---  <50.00g  
```

- vg2-cachepool

```shell
lvcreate -n cache -l 90%FREE ps-dmc-vg2 /dev/sdb2
lvcreate -n main -l 100%FREE ps-dmc-vg2 /dev/sdd1
# 注意这里cache需要预留空间给meta。

# 构建命令
lvconvert --yes --type cache --cachepool cache ps-dmc-vg2/main


# 查询1
lsblk
sdb
└─sdb2                                8:18   0   10G  0 part 
  ├─ps--dmc--vg2-cache_cpool_cdata  253:6    0    9G  0 lvm  
  │ └─ps--dmc--vg2-main             253:7    0   50G  0 lvm  
  └─ps--dmc--vg2-cache_cpool_cmeta  253:8    0   12M  0 lvm  
    └─ps--dmc--vg2-main             253:7    0   50G  0 lvm  
sdd                                   8:48   0   50G  0 disk 
└─sdd1                                8:49   0   50G  0 part 
  └─ps--dmc--vg2-main_corig         253:9    0   50G  0 lvm  
    └─ps--dmc--vg2-main             253:7    0   50G  0 lvm

# 查询2
root@ubuntu:~# lvs
  LV        VG         Attr       LSize    Pool          Origin       Data%  Meta%  Move Log Cpy%Sync Convert
  main      ps-dmc-vg1 Cwi-a-C---  <50.00g [cache_cvol]  [main_corig] 0.01   11.07           0.00            
  main      ps-dmc-vg2 Cwi-a-C---  <50.00g [cache_cpool] [main_corig] 0.01   9.99            0.00  
```

### 3.5 取消构建

```shell
lvconvert --yes --uncache ps-dmc-vg1/main ps-dmc-vg2/main
lvremove -f /dev/ps-dmc-vg1/main /dev/ps-dmc-vg2/main
```



## 4. 构建dm-writecache模式

接3章PV之后操作，目前ubuntu20.04.2中lvm2的版本2.03.07，writecache模式有bug，需要更新lvm2

```shell
vgcreate ps-wc-vg1 /dev/sdb1 /dev/sdc1

lvcreate -n cache -l 100%FREE ps-wc-vg1 /dev/sdb1
lvcreate -n main -l 100%FREE ps-wc-vg1 /dev/sdc1

lvchange -an /dev/ps-wc-vg2/cache

lvconvert --yes --type writecache --cachevol cache --cachesettings writeback_jobs=15369 ps-dmc-vg2/main

lvconvert --splitcache osd-vg1/data
```
