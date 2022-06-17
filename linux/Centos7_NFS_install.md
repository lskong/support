# CentOS7 NFS安装

## 1.环境介绍

​    本实验使用了两台centos7虚拟机，其中

​    服务器：172.16.103.10/16
​    客户端：172.16.103.12/16

## 2.实验步骤

### 2.1 服务端部署

因为centos7自带了rpcbind，所以不用安装rpcbind服务，rpcbind监听在111端口。rpcbind在nfs服务器搭建过程中至关重要，因为rpc能够获得nfs服务器端的端口号等信息，nfs服务器端通过rpc获得这些信息后才能连接nfs服务器端。

```shell
# 安装nfs
yum -y install nfs-utils 

# 检查rpc服务
ss -tnulp | grep 111
 
# 启动rpcbind
systemctl start rpcbind
systemctl enable rpcbind

# 编辑配置文件exports
echo "/data 172.16.0.0/16(rw,async)" >/etc/exports

# 启动nfs
systemctl start nfs
systemctl enable nfs

# 验证nfs
rpcinfo -p 172.16.103.10
showmount -e localhost

# 创建data的目录
mkdir /data

# 添加一个文件用作测试
echo "nfs_server_test" >/data/nfsserver.txt

# 更改目录权限
chown -R nfsnobody.nfsnobody /data
```

### 2.2 客户端部署

客户端上不需要启动nfs服务，只是为了使用showmount工具，所有一般情况也按照nfs-utils软件

```shell
# 安装nfs
yum -y install nfs-utils

# 检查rpc服务
ss -tnulp | grep 111
 
# 启动rpcbind
systemctl start rpcbind
systemctl enable rpcbind

# 验证nfs服务器
showmount -e 172.16.103.10

# 挂载至本地/mnt
mount -t nfs 172.16.103.10:/data /mnt

# 验证挂载
cat /mnt/nfsserver.txt
echo "nfs_client_test" >>/mnt/nfsserver.txt

cat /mnt/nfsserver.txt
## 再次查看你nfserver.txt有两条记录，即标识nfs服务器正常。
```

## 3.结尾

将挂载加入开机自启动

```shell
echo "mount -t nfs 172.16.103.10:/data /mnt" >>/etc/rc.local
```
