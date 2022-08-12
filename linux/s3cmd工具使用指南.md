# s3cmd工具使用指南

[toc]

s3cmd是一个简单开源的Amazon s3命令行工具，兼容标准的第三方s3对象接口。
众所周知s3协议是采用access_key和secret_key来访问授权的，所有的s3协议都需遵守此规则。

官方入口：https://s3tools.org/s3cmd
github：https://github.com/s3tools/s3cmd

> 所内实验室环境4台服务器均已安装


## 安装s3cmd

- 查看s3cmd是否安装

```shell
which s3cmd     ##无返回表示未安装
```

- ubuntu/debian

```shell
apt install s3cmd
```

- 源码安装

```shell
git clone https://github.com/s3tools/s3cmd
cd s3cmd
python setup.py install
```


- deb安装
```shell
root@qdisk:~# ll
-rw-r--r-- 1 root root  63272 Jan  6  2020 python3-dateutil_2.7.3-3ubuntu1_all.deb
-rw-r--r-- 1 root root   9376 Dec 27  2019 python3-magic_2%3a0.4.15-3_all.deb
-rw-r--r-- 1 root root 111144 Sep  1  2020 s3cmd_2.0.2-1ubuntu1_all.deb

# 安装s3cmd
root@qdisk:~# apt install ./s3cmd/*.deb
root@qdisk:~# which s3cmd
/usr/bin/s3cmd
```

- 首次初始化
```shell
# 使用命令初始化，按照步骤设置
s3cmd --configure

# 初始化之后生成配置文件/root/.s3cfg
# 使用s3cmd命令时，可以使用-c参数指定配置文件，不使用-c默认读取/root/.s3cfg
```

## s3cmd配置文件


- 配置文件路径：/root/.s3cfg

```conf
[default]
access_key = hehehehe
secret_key = hehehehe
default_mime_type = binary/octet-stream
enable_multipart = True
encoding = UTF-8
encrypt = False
host_base = s3.qcos.com:8080
host_bucket = s3.qcos.com:8080
use_https = False
multipart_chunk_size_mb = 5
```

- 配置说明

```conf
access_key      # 标准s3协议的访问密钥AK，由s3服务端生成
secret_key      # 标准s3协议的证书密钥SK，由s3服务端生成
host_base       # s3的url地址和端口
host_bucket     # s3的url地址和端口

# 其他配置有兴趣访问官方了解。

# 不同用户有不通的AK/SK。
# 如果用户的AK和SK修改，对应配置文件也需要修改
```

- 启动https
```shell

```


## s3cmd使用

- 列举bucket

```shell
$ s3cmd ls
```


- 创建bucket

```shell
$ s3cmd mb s3://ceshi
Bucket 's3://ceshi/' created
```


- 删除空bucket
```shell
$ s3cmd rb s3://ceshi
Bucket 's3://ceshi/' removed
```


- 上传文件
```shell
$ s3cmd put file.txt s3://ceshi/file.txt
```


- 删除文件
```shell
$ s3cmd del s3://ceshi/file.txt
```


- 列举对象
```shell
$ s3cmd ls s3://ceshi/
```


## s3cmd工具与量子网盘

量子网盘(qdisk)底层存储使用的基于Ceph集群，威道思自研的s3网关，是标准的s3协议接口，系统简称(qcos)。

s3cmd操作qcos与操作亚马逊的S3一样，首先修改好配置文件.s3cfg，文件中的主要参数上面都用提及。

s3.qcos.com:8080：qcos的s3对外访问url，必须使用域名，不能使用IP地址。
AK/SK：在qcos中，一个s3用户即有一对AK/SK，在用户的Ui中可以获取，且是唯一。使用s3cmd管理不同用户的对象即要修改.s3cfg中的AK/SK

量子网盘UI：http://<ip>:<port>  admin/123456
量子网盘存储UI：http://<ip>:8088   admin/qdss@123   user/User12345

```