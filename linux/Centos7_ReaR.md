# Linux ReaR



[toc]

## 1. ReaR介绍

Relax-and-Recover（简称ReaR）是一个简单但功能强大，易于设置，功能齐全且领先的开源裸机灾难恢复和系统迁移解决方案，用Bash编写。它是一个模块化且可配置的框架，具有用于常见情况的大量现成的工作流。

ReaR创建各种格式的可启动救援系统和/或系统备份。您可以使用应急系统映像启动裸机服务器，并从备份启动系统还原。它可以在必要时还原到不同的硬件，因此也可以用作系统迁移工具。



## 2. ReaR特性

支持热备份，可不停机进行备份恢复。
它具有用Bash编写的模块化设计，可以使用自定义功能进行扩展。
支持绝大多少磁盘格式，如：ext2、ext3、ext4、xfs、reiserfs、jfs、btrfs。
支持各种引导媒体，包括ISO，PXE，OBDR磁带，USB或eSATA存储。
支持多种网络协议，包括用于存储和备份的 FTP，SFTP，HTTP，NFS和CIFS 。
支持磁盘布局实施，例如Raid，LVM，DRBD，iSCSI，HWRAID（HP SmartArray），SWRAID，多路径和LUKS（加密分区和文件系统）。支持第三方和内部备份工具，包括IBM TSM，HP DataProtector，Symantec NetBackup，Bacula；tar和rsync。
支持通过PXE，DVD/CD，可启动磁带或虚拟资源调配启动。
支持一个仿真模型，该模型显示运行什么脚本而不执行它们。
支持一致的日志记录和高级调试选项，以进行故障排除。
它可以与Nagios和Opsview 等监视工具集成。
它还可以与诸如cron的作业调度程序集成。
它还支持受支持的各种虚拟化技术（KVM，Xen，VMware）。



## 3. ReaR支持

### 3.1 系统支持

Fedora 29、30、31、32
RHEL 6、7、8
CentOS 6、7、8
Scientific Linux 6、7
SLES 12、15
openSUSE Leap 15.x
Debian 8、9
Ubuntu 16、17、18



### 3.2 架构支持

Intel x86类型的处理器
AMD x86类型的处理器
PPC64处理器
PPC64LE处理器



## 4. Rear安装部署

### 4.1 部署环境

实验背景：这里的测试是针对物理机操作Linux系统的备份。

| 项目         | 说明                                                         |
| ------------ | ------------------------------------------------------------ |
| 操作系统     | CentOS7.6_x86_64                                             |
| 备份存储方式 | nfs共享存储  /backup_rear                                    |
| nfs服务地址  | 172.16.103.10                                                |
| ReaR主机     | 172.16.103.12                                                |
| ReaR版本     | rear-2.6-1.el7.x86_64.rpm                                    |
| ReaR官方     | http://download.opensuse.org/repositories/Archiving:/Backup:/Rear/CentOS_7/x86_64/ |

### 4.2 nfs服务部署

nfs服务器部署

```shell
# 安装nfs
yum -y install nfs-utils 

# 检查rpc服务
ss -tnulp | grep 111
 
# 启动rpcbind
systemctl start rpcbind
systemctl enable rpcbind

# 编辑配置文件exports
echo "/backup 172.16.0.0/16(rw,async)" >/etc/exports

# 启动nfs
systemctl start nfs
systemctl enable nfs

# 验证nfs
rpcinfo -p 172.16.103.10
showmount -e localhost

# 创建data的目录
mkdir /backup

# 更改目录权限
chown -R nfsnobody.nfsnobody /data
```



### 4.3 ReaR安装

#### 4.3.1 安装依赖

```shell
yum -y install syslinux attr bc genisoimage 
```

#### 4.3.2 安装ReaR

```shell
rpm -ivh rear-2.6-1.el7.x86_64.rpm
```

#### 4.3.3 检查安装

```shell
rpm -qa |grep rear
rpm -ql rear
```



### 4.4 ReaR配置

因使用nfs共享模式备份，所有配置文件指定备份输出格式为iso。

配置文件：/etc/rear/local.conf

```sh
vim /etc/rear/local.conf
OUTPUT=ISO
OUTPUT_URL="nfs://172.16.103.10/backup"

BACKUP=NETFS
BACKUP_URL="nfs://172.16.103.10/backup"

BACKUP_PROG_EXCLUDE=("${BACKUP_PROG_EXCLUDE[@]}",'/media,'/tmp')
```



### 4.5 执行ReaR备份

```shell
rear -d -v mkbackup
```

执行备份过程查看6.5章节

### 4.6 查看备份数据

由于是指定NFS存储，所以在nfs服务器上查看。备份的结果是以客户端的主机名来命名的

```shell
[root@zyp-c76-nfs zyp-c76-nsdl]# pwd
/backup/zyp-c76-nsdl

[root@zyp-c76-nfs zyp-c76-nsdl]# ls -lh
total 950M
-rw------- 1 nfsnobody nfsnobody 4.6M Sep  9 23:35 backup.log
-rw------- 1 nfsnobody nfsnobody 734M Sep  9 23:35 backup.tar.gz
-rw------- 1 nfsnobody nfsnobody  202 Sep  9 23:32 README
-rw------- 1 nfsnobody nfsnobody 213M Sep  9 23:32 rear-zyp-c76-nsdl.iso
-rw------- 1 nfsnobody nfsnobody 126K Sep  9 23:32 rear-zyp-c76-nsdl.log
-rw------- 1 nfsnobody nfsnobody  276 Sep  9 23:32 VERSION
```



## 5. ReaR恢复

### 5.1 挂载启动文件

在备份目录下有一个ISO文件，将这个文件刻录光盘和U盘，制作启动引导盘，然后加载引导启动系统。

这里测试使用VMware虚机机来恢复，新建一台新的虚机机，挂载ISO文件，使用CD光驱启动，选择第一项Recover <hostname>。如下图，最下方显示数据来源。也就是说恢复时将从URL拉取数据用于恢复。

![image-20200910001109212](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200910001109212.png)

### 5.2 进入恢复命令行

回车进入恢复命令行，输入root账户，这里不需要输入密码

![image-20200910001703077](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200910001703077.png)

### 5.3 执行恢复命令

```shell
rear -d -v recover
```

输入命令回车后执行恢复过程。执行过程中会提示几次确定，默认回车即可。

![image-20200910002339993](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200910002339993.png)



恢复完成后，会提醒你可以通过rm -Rf删除临时文件，然后reboot重启。

验证是否系统能正常启动。

![image-20200910003849768](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200910003849768.png)





## 6. 附录

### 6.1 命令

ReaR只有一个命令：rear，下面介绍rear命令参数。

```comm
# 选项参数
-h --help		# 查看帮助信息
-c  DIR		# 指定配置目录，默认/etc/rear
-C  CONFIG		# 指定额外的配置文件
-d 				# 调试模式，将信息记录到log文件，配合-v使用
-D				# 调试脚本模式
-r KERNEL		# 使用内核版本，一般使用默认
-s				# 模拟模式，显示执行过程，但本身正真执行
-S				# 分别确定每个脚本
-v				# 显示详细执行过程
-V				# 显示rear版本

# 命令参数
checklayout 	# 检查自上次运行备份以来分区是否改动
dump			# 验证设置是否正确
format			# 
help			# 帮助
mkbackup		# 创建急救盘并备份系统
mkbackuponly	# 仅备份系统文件
mkrescue		# 仅创建急救盘
mountonly		# 使用急救盘修复系统
recover			# 恢复系统，只能在急救模式下使用
restoreonly		# 只恢复备份文件，只能在急救模式下使用
mkopalpba		# 创建预启动身份验证，符号TCGopal加密
opaladmin		# 管理TCGopal自加密磁盘
validate		# 提交验证信息

# 可以使用rear -v help 获得更多命令

# 命令例子
## 备份时使用
rear -d -v mkbackup

## 恢复时使用
rear -d -v recover
```





### 6.2 配置

#### 6.2.1 OUTPUT

OUTPUT变量指定引导分区表以哪种格式生成，即恢复时的引导启动。

```conf
OUTPUT=RAMDISK
# 指定引导镜像为initramfs格式

OUTPUT=ISO
# 指定引导镜像为ISO格式

OUTPUT=PXE
# 创建的引导镜像为PEX/NFS格式

OUTPUT=OBDR
# 创建的引导镜像为OBDR格式，可以使用TAPE_DEVICE指定设备

OUTPUT=USB
# 创建的引导镜像为U盘启动格式。

OUTPUT=RAWDISK
# 创建一个名为rear-$(hostname).raw.gz镜像文件
# 可以支持UEFI引导
```

#### 6.2.2 OUTPUT_URL

```conf
OUTPUT_URL=file://
Write the image to disk. The default is in /var/lib/rear/output/.
写入镜像到磁盘上，默认路径/var/lib/rear/output/

OUTPUT_URL=nfs://
Write the image by mounting the target filesystem via NFS.
写入镜像到NFS文件系统上

OUTPUT_URL=cifs://
Write the image by mounting the target filesystem via CIFS.
写入镜像到CIFS文件系统上

OUTPUT_URL=fish://
Write the image using lftp and the FISH protocol.
使用lftp和FISH协议，写入镜像

OUTPUT_URL=ftp://
Write the image using lftp and the FTP protocol.
使用lftp和FTP协议，写入镜像

OUTPUT_URL=ftps://
Write the image using lftp and the FTPS protocol.
使用lftp和FTPS协议，写入镜像

OUTPUT_URL=hftp://
Write the image using lftp and the HFTP protocol.
使用lftp和HFTP协议，写入镜像

OUTPUT_URL=http://
Write the image using lftp and the HTTP (PUT) procotol.
使用lftp和HTTP协议，写入镜像

OUTPUT_URL=https://
Write the image using lftp and the HTTPS (PUT) protocol.
使用lftp和HTTPS协议，写入镜像

OUTPUT_URL=sftp://
Write the image using lftp and the secure FTP (SFTP) protocol.
使用lftp和SFTP协议，写入镜像

OUTPUT_URL=rsync://
Write the image using rsync and the RSYNC protocol.
使用rsync协议，写入镜像

OUTPUT_URL=sshfs://
Write the image using sshfs and the SSH protocol.
使用sshfs和SSH协议，写入镜像

OUTPUT_URL=null
```



### 6.3 常见报错

报错1：

ERORR，no nameserver no nameserver or only loopback addresses

解决：添加一条DNS记录，在/etc/resolv.conf配置文件下添加`nameserver 114.114.114.114`



### 6.5 备份执行日志

```log
Relax-and-Recover 2.6 / 2020-06-17
Running rear mkbackup (PID 7003)
Using log file: /var/log/rear/rear-zyp-c76-nsdl.log
Running workflow mkbackup on the normal/original system
Using backup archive '/tmp/rear.58zpAPWmeboP6Cu/outputfs/zyp-c76-nsdl/backup.tar.gz'
Using autodetected kernel '/boot/vmlinuz-3.10.0-957.el7.x86_64' as kernel in the recovery system
Creating disk layout
Using guessed bootloader 'GRUB' (found in first bytes on /dev/sda)
Verifying that the entries in /var/lib/rear/layout/disklayout.conf are correct ...
Creating recovery system root filesystem skeleton layout
Adding biosdevname=0 to KERNEL_CMDLINE
Adding net.ifnames=0 to KERNEL_CMDLINE
Handling network interface 'eth0'
eth0 is a physical device
Handled network interface 'eth0'
Copying logfile /var/log/rear/rear-zyp-c76-nsdl.log into initramfs as '/tmp/rear-zyp-c76-nsdl-partial-2020-09-09T23:30:12+0800.log'
Copying files and directories
Copying binaries and libraries
Copying all kernel modules in /lib/modules/3.10.0-957.el7.x86_64 (MODULES contains 'all_modules')
Copying all files in /lib*/firmware/
Skip copying broken symlink '/etc/mtab' target '/proc/16716/mounts' on /proc/ /sys/ /dev/ or /run/
Symlink '/usr/lib/modules/3.10.0-957.el7.x86_64/build' -> '/usr/src/kernels/3.10.0-957.el7.x86_64' refers to a non-existing directory on the recovery system.
It will not be copied by default. You can include '/usr/src/kernels/3.10.0-957.el7.x86_64' via the 'COPY_AS_IS' configuration variable.
Symlink '/usr/lib/modules/3.10.0-957.el7.x86_64/source' -> '/usr/src/kernels/3.10.0-957.el7.x86_64' refers to a non-existing directory on the recovery system.
It will not be copied by default. You can include '/usr/src/kernels/3.10.0-957.el7.x86_64' via the 'COPY_AS_IS' configuration variable.
Testing that the recovery system in /tmp/rear.58zpAPWmeboP6Cu/rootfs contains a usable system
Creating recovery/rescue system initramfs/initrd initrd.cgz with gzip default compression
Created initrd.cgz with gzip default compression (213095750 bytes) in 30 seconds
Making ISO image
Wrote ISO image: /var/lib/rear/output/rear-zyp-c76-nsdl.iso (213M)
Copying resulting files to nfs location
Saving /var/log/rear/rear-zyp-c76-nsdl.log as rear-zyp-c76-nsdl.log to nfs location
Copying result files '/var/lib/rear/output/rear-zyp-c76-nsdl.iso /tmp/rear.58zpAPWmeboP6Cu/tmp/VERSION /tmp/rear.58zpAPWmeboP6Cu/tmp/README /tmp/rear.58zpAPWmeboP6Cu/tmp/rear-zyp-c76-nsdl.log' to /tmp/rear.58zpAPWmeboP6Cu/outputfs/zyp-c76-nsdl at nfs location
Making backup (using backup method NETFS)
Creating tar archive '/tmp/rear.58zpAPWmeboP6Cu/outputfs/zyp-c76-nsdl/backup.tar.gz'
Archived 732 MiB [avg 3622 KiB/sec] OK
WARNING: tar ended with return code 1 and below output:
  ---snip---
  tar: /var/spool/postfix/public/flush: socket ignored
  tar: /var/spool/postfix/public/showq: socket ignored
  tar: /mnt: Warning: Cannot stat: Stale file handle
  ----------
This means that files have been modified during the archiving
process. As a result the backup may not be completely consistent
or may not be a perfect copy of the system. Relax-and-Recover
will continue, however it is highly advisable to verify the
backup in order to be sure to safely recover this system.

Archived 732 MiB in 208 seconds [avg 3604 KiB/sec]
Exiting rear mkbackup (PID 7003) and its descendant processes ...
Running exit tasks
You should also rm -Rf /tmp/rear.58zpAPWmeboP6Cu
```



[ReaR备份压缩类型测试](http://www.it3.be/2013/09/16/NETFS-compression-tests/)



