# vdbench文件系统测试模板

说明：
- 通过启动测试，来调整threads参数的值，测试中resp的值小于保持100左右，则可以继续测试。
- 多台进程同时跑和单台跑，threads参数值不一样，需自行调整，默认1 4 8 16 24 32等。

## 200MB文件纯写MBPS

```shell
hd=default,vdbench=/root/vdbench/,user=root,shell=ssh

hd=hd1,system=172.16.2.21
hd=hd2,system=172.16.2.22
hd=hd3,system=172.16.2.23
hd=hd4,system=172.16.2.24
# hd=hd5,system=172.16.2.25
# hd=hd6,system=172.16.2.26
# hd=hd7,system=172.16.2.27
# hd=hd8,system=172.16.2.28

fsd=fsd1,anchor=/lun1-10T/200MB_4,depth=2,width=5,files=15,size=200m,shared=yes,openflags=o_direct
fwd=format,threads=8,xfersize=1m
fwd=default,operation=write,xfersize=1m,fileio=random,fileselect=random,threads=8

fwd=fwd1,fsd=fsd1,host=hd1
fwd=fwd2,fsd=fsd1,host=hd2
fwd=fwd3,fsd=fsd1,host=hd3
fwd=fwd4,fsd=fsd1,host=hd4
# fwd=fwd5,fsd=fsd1,host=hd5
# fwd=fwd6,fsd=fsd1,host=hd6
# fwd=fwd7,fsd=fsd1,host=hd7
# fwd=fwd8,fsd=fsd1,host=hd8

rd=rd1,fwd=fwd*,fwdrate=max,format=restart,elapsed=600,interval=1
```


## 200MB文件纯读MBPS

```shell
hd=default,vdbench=/root/vdbench/,user=root,shell=ssh

hd=hd1,system=node1
hd=hd2,system=node2
hd=hd3,system=node3
#hd=hd4,system=node4
#hd=hd5,system=node5
#hd=hd6,system=node6
#hd=hd7,system=node7
#hd=hd8,system=node8

fsd=fsd1,anchor=/lun1-10T/200MB_4,depth=2,width=5,files=15,size=200m,shared=yes,openflags=o_direct
fwd=format,threads=8,xfersize=1m
fwd=default,operation=read,xfersize=1m,fileio=random,fileselect=random,threads=8

fwd=fwd1,fsd=fsd1,host=hd1
fwd=fwd2,fsd=fsd1,host=hd2
fwd=fwd3,fsd=fsd1,host=hd3
fwd=fwd4,fsd=fsd1,host=hd4
#fwd=fwd5,fsd=fsd1,host=hd5
#fwd=fwd6,fsd=fsd1,host=hd6
#fwd=fwd7,fsd=fsd1,host=hd7
#fwd=fwd8,fsd=fsd1,host=hd8

rd=rd1,fwd=fwd*,fwdrate=max,format=restart,elapsed=600,interval=1
```


## 200MB文件混合读写6:4 MBPS

```shell
hd=default,vdbench=/root/vdbench/,user=root,shell=ssh

hd=hd1,system=node1
hd=hd2,system=node2
hd=hd3,system=node3
hd=hd4,system=node4
hd=hd5,system=node5
hd=hd6,system=node6
hd=hd7,system=node7
hd=hd8,system=node8

fsd=fsd1,anchor=/mnt/vd/200MB_1,depth=2,width=5,files=15,size=200m,shared=yes,openflags=o_direct
fwd=format,threads=8,xfersize=1m
fwd=default,xfersize=1m,fileio=random,fileselect=random,rdpct=60,threads=8

fwd=fwd1,fsd=fsd1,host=hd1
fwd=fwd2,fsd=fsd1,host=hd2
fwd=fwd3,fsd=fsd1,host=hd3
fwd=fwd4,fsd=fsd1,host=hd4
fwd=fwd5,fsd=fsd1,host=hd5
fwd=fwd6,fsd=fsd1,host=hd6
fwd=fwd7,fsd=fsd1,host=hd7
fwd=fwd8,fsd=fsd1,host=hd8

rd=rd1,fwd=fwd*,fwdrate=max,format=restart,elapsed=600,interval=1
```


## 1MB文件读取时延

```shell
hd=default,vdbench=/root/vdbench/,user=root,shell=ssh

hd=hd1,system=node1
hd=hd2,system=node2
hd=hd3,system=node3
hd=hd4,system=node4
hd=hd5,system=node5
hd=hd6,system=node6
hd=hd7,system=node7
hd=hd8,system=node8

fsd=fsd1,anchor=/mnt/vd/1MB_1,depth=2,width=5,files=50,size=1m,shared=yes,openflags=o_direct
fwd=format,threads=8,xfersize=1m
fwd=default,xfersize=1m,operation=read,fileio=random,fileselect=sequential,threads=8

fwd=fwd1,fsd=fsd1,host=hd1
fwd=fwd2,fsd=fsd1,host=hd2
fwd=fwd3,fsd=fsd1,host=hd3
fwd=fwd4,fsd=fsd1,host=hd4
fwd=fwd5,fsd=fsd1,host=hd5
fwd=fwd6,fsd=fsd1,host=hd6
fwd=fwd7,fsd=fsd1,host=hd7
fwd=fwd8,fsd=fsd1,host=hd8

rd=rd1,fwd=fwd*,fwdrate=max,format=restart,elapsed=300,interval=1
```


## 64KB小文件写入IOPS

```shell
hd=default,vdbench=/root/vdbench/,user=root,shell=ssh

hd=hd1,system=node1
hd=hd2,system=node2
hd=hd3,system=node3
hd=hd4,system=node4
#hd=hd5,system=node5
#hd=hd6,system=node6
#hd=hd7,system=node7
#hd=hd8,system=node8

fsd=fsd1,anchor=/mnt/vd/1MB_1,depth=2,width=50,files=100,size=64k,shared=yes,openflags=o_direct
fwd=format,threads=8,xfersize=32k
fwd=default,xfersize=32k,operation=read,fileio=random,fileselect=sequential,threads=8

fwd=fwd1,fsd=fsd1,host=hd1
fwd=fwd2,fsd=fsd1,host=hd2
fwd=fwd3,fsd=fsd1,host=hd3
fwd=fwd4,fsd=fsd1,host=hd4
#fwd=fwd5,fsd=fsd1,host=hd5
#fwd=fwd6,fsd=fsd1,host=hd6
#fwd=fwd7,fsd=fsd1,host=hd7
#fwd=fwd8,fsd=fsd1,host=hd8

rd=rd1,fwd=fwd*,fwdrate=max,format=restart,elapsed=300,interval=1
```


## 128KB小文件块存储读写7:3IOPS

```shell
hd=default,vdbench=/root/vdbench/,user=root,shell=ssh,jvms=8

hd=hd1,system=172.16.2.21
hd=hd2,system=172.16.2.22
hd=hd3,system=172.16.2.23
hd=hd4,system=172.16.2.24
#hd=hd5,system=node5
#hd=hd6,system=node6
#hd=hd7,system=node7
#hd=hd8,system=node8

sd=sd1,host=hd*,lun=/dev/sdb,openflags=o_direct

wd=wdpre,sd=sd*,xfersize=(128k,100),rdpct=70,seekpct=100,streams=16

rd=runpre,wd=wdpre,iorate=max,elapsed=300,interval=1,warmup=5,threads=512
```