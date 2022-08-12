# OVFTool使用

## Window系统使用

```bat
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

```