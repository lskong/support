# vmware转pve虚拟机方法


## vmware导出

- vmware workstation导出ovf虚拟机

```windows
1、选择需要导出的虚拟机-关机
2、单击菜单“文件”--“导出为OVF”
3、选择导出目录，开始导出。

4、导出后的文件有三中类型：.mf/.ovf/.vmdk

```

- exsi导出ovf虚拟机

```windows
// 使用OVFtool导出虚拟机
1、打开cmd
cmd

2、切换目录
cd C:\app\OVFTool

3、导出命令
ovftool.exe vi://root:"Vaddsoft@123"@192.168.3.28/"nessus扫描-172.16.104.16" D:\Vmware\ovf

// 解释
root:"Vaddsoft@123"  	#Exsi账号密码
192.168.3.8      		#Exsi服务器IP
nessus扫描-172.16.104.16	#虚拟机名
D:\Vmware\ovf		#导出路径

4、导出后的文件有四种类型：.mf/.ovf/.vmdk/.nvram
```


## pve导入

- VOF格式导入

```bash
1、将VMware导出的ovf的所有文件类型，上传到pve服务器上
2、使用pve命令行导入虚拟机
qm importovf 999 WinDev1709Eval.ovf local-lvm

# 解释
qm importovf    #导入命令
999             #pve虚拟机ID号
WinDev1709Eval.ovf      #ovf文件
local-lvm               #导入到pve存储

3、导入结束，在pve控制页面为虚拟机添加网卡、或修改其他配置：如内存、cpu等

```



## 导出过程问题处理

- 关于centos7导入开机dracut-initqueue timeout

经过查询得知，可能是initramfs文件是依据旧平台硬件创建的，而不支持新平台的硬件。尝试从系统的救援内核进行启动。
注：救援内核是由原始安装程序安装的，并且支持大多数硬件

```bash
# 打开虚拟机电源该虚拟机未正确引导提示:
dracut-initqueue[259]: Warning: dracut-initqueue timeout
Warning: /dev/centos/root does not exist
Warning: /dev/centos/swap does not exist
Warning: /dev/mapper/centos-root does not exist

# 处理过错
1、进入系统救援模式
重新引导虚拟机，在boot页面选择CentOS Linx(0-rescue-xxx) 7 (Core)

2、重建initramfs文件
cd /boot/
dracut -f initramfs-3.10.0-957.el7.x86_64.img
reboot

```
