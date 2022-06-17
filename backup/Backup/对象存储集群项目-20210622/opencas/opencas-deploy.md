# open CAS

## open CAS 介绍
- 官方入口：https://open-cas.github.io/
- github：https://github.com/Open-CAS/ocf


## open CAS 语术
- cache：一般指高速缓存设备，比如Nvme SSD或更高的设备。
- core：一般指数据存储设备，普通HDD磁盘
- 关系：一个cache可以挂载N个core，也可以是一个cache对应一个core。但一个core不能对应多个cache。


## open CAS 部署

- 部署环境
```shell
# 单台设备配置（共3台）
操作系统：ubuntu20.02 TLS
cache盘：SAMSUNG 1.5TB NVMe  *1
core盘：Toshiba 2.0TB SATA HDD  *7

# 1个cache对应7个core
```

- 安装依赖
```shell
apt install debhelper devscripts dkms libelf-dev
```

- 部署步骤
```shell
# 下载最新版本源码
git clone https://github.com/Open-CAS/open-cas-linux

# 更新子模块
cd open-cas-linux
git submodule update --init

# 编译
./configure

# 安装
make  && make install

# 验证
root@node1:~/open-cas-linux# casadm -V
╔═════════════════════════╤═════════════════════╗
║ Name                    │       Version       ║
╠═════════════════════════╪═════════════════════╣
║ CAS Cache Kernel Module │ 21.06.0.0500.master ║
║ CAS Disk Kernel Module  │ 21.06.0.0500.master ║
║ CAS CLI Utility         │ 21.06.0.0500.master ║
╚═════════════════════════╧═════════════════════╝

# 查看内核模块
root@node1:~/open-cas-linux# lsmod |grep cas
cas_cache             380928  0
cas_disk               24576  1 cas_cache
```

- open CAS 命令
```shell
# casadm 命令
root@node1:~/open-cas-linux# casadm -H
Cache Acceleration Software Linux

Usage: casadm <command> [option...]

Available commands:
   -S  --start-cache              Start new cache instance or load using metadata
   -T  --stop-cache               Stop cache instance
   -X  --set-param                Set various runtime parameters
   -G  --get-param                Get various runtime parameters
   -Q  --set-cache-mode           Set cache mode
   -A  --add-core                 Add core device to cache instance
   -R  --remove-core              Remove active core device from cache instance
       --remove-inactive          Remove inactive core device from cache instance
       --remove-detached          Remove core device from core pool
   -L  --list-caches              List all cache instances and core devices
   -P  --stats                    Print statistics for cache instance
   -Z  --reset-counters           Reset cache statistics for core device within cache instance
   -F  --flush-cache              Flush all dirty data from the caching device to core devices
   -E  --flush-core               Flush dirty data of a given core from the caching device to this core device
   -C  --io-class                 Manage IO classes
   -V  --version                  Print CAS version
   -H  --help                     Print help
       --zero-metadata            Clear metadata from caching device

For detailed help on the above commands use --help after the command.
e.g.
   casadm --start-cache --help
For more information, please refer to manual, Admin Guide (man casadm)
or go to support page <https://open-cas.github.io>.


# casctl 命令
root@node1:~/open-cas-linux# casctl -h
usage: casctl [-h] {init,start,settle,stop} ...

optional arguments:
  -h, --help            show this help message and exit

actions:
  {init,start,settle,stop}
    init                Setup initial configuration
    start               Start cache configuration
    settle              Wait for startup of devices
    stop                Stop cache configuration
```

## open CAS 缓存模式
- write-back
```shell
# write-back（wb），回写模式，数据先写入缓存，然后定期写到磁盘，加速读和写,本案中使用。
# 示例
casadm -S -i 1 -d /dev/nvme0n1 -c wb
```
- Write-through
```shell
# write-back（wt）,默认模式，数据写入缓存同时写入磁盘，加速读。
# 示例
casadm -S -i 1 -d /dev/nvme0n1
casadm -S -i 1 -d /dev/nvme0n1 -c wt
```
- Write-around
```shell
# Write-around(wo)，类似于wt，但只会加速读密集型的数据。
# 示例
casadm -S -i 1 -d /dev/nvme0n1 -c wa
```
- Pass-through
```shell
# Write-around(pt)，所有操作绕过缓存。常用先关联core设备，然后使用模式切换在使用。
# 示例
casadm -S -i 1 -d /dev/nvme0n1 -c pt
```
- Write-only
```shell
# Write-only(wo)，只写缓存，读直接绕过缓存。只写主要时改善写密集型操作。
# 示例
casadm -S -i 1 -d /dev/nvme0n1 -c wo
```

## open CAS 配置
- 配置文件
```shell
root@node1:~/open-cas-linux# cat /etc/opencas/opencas.conf 
version=19.3.0
# Version tag has to be first line in this file
#
# Open CAS configuration file - for reference on syntax
# of this file please refer to appropriate documentation

# NOTES:
# 1) It is required to specify cache/core device using links in
# /dev/disk/by-id/, preferably those using device WWN if available:
#   /dev/disk/by-id/wwn-0x123456789abcdef0
# Referencing devices via /dev/sd* is prohibited because
# may result in cache misconfiguration after system reboot
# due to change(s) in drive order. It is allowed to use /dev/cas*-*
# as a device path.

## Caches configuration section
[caches]
## Cache ID	Cache device				Cache mode	Extra fields (optional)
## Uncomment and edit the below line for cache configuration
#1		/dev/disk/by-id/nvme-INTEL_SSDP..	WT

## Core devices configuration
[cores]
## Cache ID	Core ID		Core device	Extra fields (optional)
## Uncomment and edit the below line for core configuration
#1		1		/dev/disk/by-id/wwn-0x123456789abcdef0

## To specify use of the IO Classification file, place content of the following line in the
## Caches configuration section under Extra fields (optional)
## ioclass_file=/etc/opencas/ioclass-config.csv

## If given cache/core pair is especially slow to start up, often doesn't come back
## up after reboot or you simply don't care if it does and don't want it to have
## an effect on your boot you can mark cores as lazy to prevent Open CAS from
## dropping boot to emergency shell because of this core failure. To do this
## put following line under in Extra fields (optional) section of core config:
## lazy_startup=true
## NOTE: This will cause open-cas.service to not wait for marked core while
## starting up - this option should be used with care to prevent races with
## other services for devices (e.g. mounts based on FS labels)
```
- 配置文件关键内容
```shell
version=19.3.0
[caches]
1		/dev/disk/by-id/nvme-INTEL_SSDP..	WT
[cores]
1		1		/dev/disk/by-id/wwn-0x123456789abcdef0

# 请注意，使用open cas的盘一定只要在/dev/disk/by-id/路径下，一般为软链接文件
```

- 获取磁盘wwn
```shell
# 获取cache盘信息
root@node1:~/open-cas-linux# ls -l /dev/disk/by-id/nvme-*
lrwxrwxrwx 1 root root 13 Jun  7 11:32 /dev/disk/by-id/nvme-eui.334d30304d4003470025384100000004 -> ../../nvme0n1
lrwxrwxrwx 1 root root 13 Jun  7 11:32 /dev/disk/by-id/nvme-MT001600KWHAC_S3M0NA0M400347 -> ../../nvme0n1
# 显示两个链接文件，都是指向nvme0n1,在使用时可以选择其中一个即可

# 获取core盘信息
root@node1:~/open-cas-linux# ls -l /dev/disk/by-id/wwn-*
lrwxrwxrwx 1 root root  9 Jun  7 11:32 /dev/disk/by-id/wwn-0x670b5e80db7e760027eaf96e0ef7dbd8 -> ../../sda
lrwxrwxrwx 1 root root 10 Jun  7 11:32 /dev/disk/by-id/wwn-0x670b5e80db7e760027eaf96e0ef7dbd8-part1 -> ../../sda1
lrwxrwxrwx 1 root root 10 Jun  7 11:32 /dev/disk/by-id/wwn-0x670b5e80db7e760027eaf96e0ef7dbd8-part2 -> ../../sda2
lrwxrwxrwx 1 root root 10 Jun  7 11:32 /dev/disk/by-id/wwn-0x670b5e80db7e760027eaf96e0ef7dbd8-part3 -> ../../sda3
lrwxrwxrwx 1 root root  9 Jun  7 11:32 /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58c20b7c4dce -> ../../sdb
lrwxrwxrwx 1 root root  9 Jun  7 11:32 /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58d50c97053e -> ../../sdc
lrwxrwxrwx 1 root root  9 Jun  7 11:32 /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58de0d274e82 -> ../../sdd
lrwxrwxrwx 1 root root  9 Jun  7 11:32 /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58e70db2f3ed -> ../../sde
lrwxrwxrwx 1 root root  9 Jun  7 11:32 /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58f20e51e38d -> ../../sdf
lrwxrwxrwx 1 root root  9 Jun  7 11:32 /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58fe0f0ce8a2 -> ../../sdg
lrwxrwxrwx 1 root root  9 Jun  7 11:32 /dev/disk/by-id/wwn-0x670b5e80db7e7600282b59070f8e4ab1 -> ../../sdh

# 这里需要甄别可用的盘用于core
```

- 标准配置文件
- node1
```conf
version=19.3.0
[caches]
1		/dev/disk/by-id/nvme-MT001600KWHAC_S3M0NA0M400347	WB

[cores]
1		1		/dev/disk/by-id/wwn-0x670b5e80db7e7600282b58c20b7c4dce
1		2		/dev/disk/by-id/wwn-0x670b5e80db7e7600282b58d50c97053e
1		3		/dev/disk/by-id/wwn-0x670b5e80db7e7600282b58de0d274e82
1		4		/dev/disk/by-id/wwn-0x670b5e80db7e7600282b58e70db2f3ed
1		5		/dev/disk/by-id/wwn-0x670b5e80db7e7600282b58f20e51e38d
1		6		/dev/disk/by-id/wwn-0x670b5e80db7e7600282b58fe0f0ce8a2
1		7		/dev/disk/by-id/wwn-0x670b5e80db7e7600282b59070f8e4ab1
```

- node2
```conf
version=19.3.0
[caches]
1		/dev/disk/by-id/nvme-MT001600KWHAC_S3M0NA0M400259	WB

[cores]
1		1		/dev/disk/by-id/wwn-0x670b5e80db7d3e0028607e810de35264
1		2		/dev/disk/by-id/wwn-0x670b5e80db7d3e0028607e970f3302f9
1		3		/dev/disk/by-id/wwn-0x670b5e80db7d3e0028607ea10fcf825b
1		4		/dev/disk/by-id/wwn-0x670b5e80db7d3e0028607eab1065a6d9
1		5		/dev/disk/by-id/wwn-0x670b5e80db7d3e0028607eb611110b20
1		6		/dev/disk/by-id/wwn-0x670b5e80db7d3e0028607ebf1196941d
1		7		/dev/disk/by-id/wwn-0x670b5e80db7d3e0028607ecd1272cb89
```


- node3
```conf
version=19.3.0
[caches]
1		/dev/disk/by-id/nvme-MT001600KWHAC_S3M0NA0M400319	WB

[cores]
1		1		/dev/disk/by-id/wwn-0x670b5e80db7d2f00282b6269082804c1
1		2		/dev/disk/by-id/wwn-0x670b5e80db7d2f00282b627308bb3d6d
1		3		/dev/disk/by-id/wwn-0x670b5e80db7d2f00282b627c093d1e85
1		4		/dev/disk/by-id/wwn-0x670b5e80db7d2f00282b628409bf0038
1		5		/dev/disk/by-id/wwn-0x670b5e80db7d2f00282b628c0a3c7d16
1		6		/dev/disk/by-id/wwn-0x670b5e80db7d2f00282b62940ab0748d
1		7		/dev/disk/by-id/wwn-0x670b5e80db7d2f00282b629c0b242d6e
```

- 操作命令
```shell
mv /etc/opencas/opencas.conf /etc/opencas/opencas.conf.bak
nano /etc/opencas/opencas.conf
```

## open CAS 启动运行
```shell
# 确保配置文件正常，先初始化
casctl init

# 在启动
casctl start
# 目前测试下来这步不需执行

# 检查
root@node1:~# casadm -L
type    id   disk           status    write policy   device
cache   1    /dev/nvme0n1   Running   wb             -
├core   1    /dev/sdb       Active    -              /dev/cas1-1
├core   2    /dev/sdc       Active    -              /dev/cas1-2
├core   3    /dev/sdd       Active    -              /dev/cas1-3
├core   4    /dev/sde       Active    -              /dev/cas1-4
├core   5    /dev/sdf       Active    -              /dev/cas1-5
├core   6    /dev/sdg       Active    -              /dev/cas1-6
└core   7    /dev/sdh       Active    -              /dev/cas1-7


# 停止
casctl stop
```

- OCF驱动的盘需要给开通LVM类型识别，在下默174行文件添加类型

```shell
vim /etc/lvm/lvm.conf
types = [ "cas", 16 ]
```



## 报错处理
- 启动错误处理
```shell
root@node3:~/open-cas-linux# casctl init
Unable to start cache 1 (/dev/disk/by-id/nvme-MT001600KWHAC_S3M0NA0M400319). Reason:
Error inserting cache 1
Old metadata found on device.
Please load cache metadata using --load option or use --force to
 discard on-disk metadata and start fresh cache instance.
# 用于cache盘已有旧的元数据，加--force参数执行

# 如果使用cache是旧的数据盘，cache会有元数据残留，请先对cache盘做数据清理
dd if=/dev/zero of=/dev/nvme0n1 count=10000K

Unable to add core /dev/disk/by-id/wwn-0x670b5e80db7d2f00282b6269082804c1 to cache 1. Reason:
Error while adding core device to cache instance 1
Failed to open '/dev/disk/by-id/wwn-0x670b5e80db7d2f00282b6269082804c1' device exclusively. Please close all applications accessing it or unmount the device.
# 用于core的盘已被占用。
```

- cache与core不能正常关联
```shell
root@node3:~# casadm -L
type        id   disk           status     write policy   device
core pool   -    -              -          -              -
├core       -    /dev/sdb       Detached   -              -
├core       -    /dev/sdg       Detached   -              -
├core       -    /dev/sde       Detached   -              -
├core       -    /dev/sdd       Detached   -              -
├core       -    /dev/sdh       Detached   -              -
├core       -    /dev/sdc       Detached   -              -
└core       -    /dev/sdf       Detached   -              -
cache       1    /dev/nvme0n1   Running    wb             -

root@node3:~# casctl stop

# 清理cache
casadm --zero-metadata -d /dev/disk/by-id/nvme-MT001600KWHAC_S3M0NA0M400319 

# 删除core（Detached状态）
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d2f00282b6269082804c1
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d2f00282b627308bb3d6d
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d2f00282b627c093d1e85
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d2f00282b628409bf0038
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d2f00282b628c0a3c7d16
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d2f00282b62940ab0748d
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d2f00282b629c0b242d6e


## node2
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d3e00282b5f0806ae6066
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d3e00282b5f11073deff9
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d3e00282b5f1a07c9185f
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d3e00282b5f23084c3460
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d3e00282b5f2b08c162f4
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d3e00282b5f3309457703
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7d3e00282b5f3b09b8f1e1

## node1
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58c20b7c4dce
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58d50c97053e
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58de0d274e82
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58e70db2f3ed
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58f20e51e38d
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7e7600282b58fe0f0ce8a2
casadm --remove-detached -d /dev/disk/by-id/wwn-0x670b5e80db7e7600282b59070f8e4ab1

# 在重新执初始化修复
casctl init
```

- core的Inactive状态处理
```shell
root@node2:~# casadm -L
type    id   disk           status       write policy   device
cache   1    /dev/nvme1n1   Incomplete   wb             -
├core   1    /dev/sdb       Inactive     -              /dev/cas1-1
├core   2    /dev/sdc       Inactive     -              /dev/cas1-2
├core   3    /dev/sdd       Inactive     -              /dev/cas1-3
├core   4    /dev/sde       Inactive     -              /dev/cas1-4
├core   5    /dev/sdf       Inactive     -              /dev/cas1-5
├core   6    /dev/sdg       Inactive     -              /dev/cas1-6
└core   7    /dev/sdh       Inactive     -              /dev/cas1-7

# 停止ceph osd
systemctl stop ceph-osd.target

```
