# Cosbench

## Cosbench 介绍
COSBench是一个测试云对象存储系统的分布式基准测试工具，有Driver和Controller两个关键组件组成，本文简要介绍通过S3接口使用COSBench测试Ceph的RGW。


## Cosbench 测试环境
操作系统：centos7


## Cosbench 部署
```shell
# 安装依赖
yum install java-1.7.0-openjdk nmap-ncat

# 下载Cosbench，请不要使用最新版，这里使用0.4.2.c4版本
wget https://github.com/intel-cloud/cosbench/releases/download/v0.4.2.c4/0.4.2.c4.zip

[root@managr ~]# unzip -q 0.4.2.c4.zip
[root@managr ~]# mv 0.4.2.c4 cosbench
[root@managr ~]# cd /opt/cosbench/

# controller.conf
[root@managr cosbench]# cat conf/controller.conf 
[controller]
drivers = 1
log_level = INFO
log_file = log/system.log
archive_dir = archive

[driver1]
name = driver1
url = http://127.0.0.1:18088/driver

# driver.conf
cat conf/driver.conf 
[driver]
log_level = INFO


# 关闭MD4校验功能
修改所有节点cosbench-start.sh配置文件，在java后添加参数-Dcom.amazonaws.services.s3.disableGetObjectMD5Validation=true
vim cosbench-start.sh

# 启动cosbench
[root@managr cosbench]# sh start-all.sh
Launching osgi framwork ... 
Successfully launched osgi framework!
Booting cosbench driver ... 
.
Starting    cosbench-log_0.4.2    [OK]
Starting    cosbench-tomcat_0.4.2    [OK]
Starting    cosbench-config_0.4.2    [OK]
Starting    cosbench-http_0.4.2    [OK]
Starting    cosbench-cdmi-util_0.4.2    [OK]
Starting    cosbench-core_0.4.2    [OK]
Starting    cosbench-core-web_0.4.2    [OK]
Starting    cosbench-api_0.4.2    [OK]
Starting    cosbench-mock_0.4.2    [OK]
Starting    cosbench-ampli_0.4.2    [OK]
Starting    cosbench-swift_0.4.2    [OK]
Starting    cosbench-keystone_0.4.2    [OK]
Starting    cosbench-httpauth_0.4.2    [OK]
Starting    cosbench-s3_0.4.2    [OK]
Starting    cosbench-librados_0.4.2    [OK]
Starting    cosbench-scality_0.4.2    [OK]
Starting    cosbench-cdmi-swift_0.4.2    [OK]
Starting    cosbench-cdmi-base_0.4.2    [OK]
Starting    cosbench-driver_0.4.2    [OK]
Starting    cosbench-driver-web_0.4.2    [OK]
Successfully started cosbench driver!
Listening on port 0.0.0.0/0.0.0.0:18089 ... 
Persistence bundle starting...
Persistence bundle started.
----------------------------------------------
!!! Service will listen on web port: 18088 !!!
----------------------------------------------

======================================================

Launching osgi framwork ... 
Successfully launched osgi framework!
Booting cosbench controller ... 
Starting    cosbench-log_0.4.2    [OK]
.
Starting    cosbench-tomcat_0.4.2    [OK]
Starting    cosbench-config_0.4.2    [OK]
Starting    cosbench-core_0.4.2    [OK]
Starting    cosbench-core-web_0.4.2    [OK]
Starting    cosbench-controller_0.4.2    [OK]
Starting    cosbench-controller-web_0.4.2    [OK]
Successfully started cosbench controller!
Listening on port 0.0.0.0/0.0.0.0:19089 ... 
Persistence bundle starting...
Persistence bundle started.
----------------------------------------------
!!! Service will listen on web port: 19088 !!!
----------------------------------------------

# 查看进程
[root@managr cosbench]# ps -ef|grep java
root     118467      1 15 14:37 pts/0    00:00:08 java -Dcom.amazonaws.services.s3.disableGetObjectMD5Validation=true -Dcosbench.tomcat.config=conf/driver-tomcat-server.xml -server -cp main/org.eclipse.equinox.launcher_1.2.0.v20110502.jar org.eclipse.equinox.launcher.Main -configuration conf/.driver -console 18089
root     118628      1  8 14:37 pts/0    00:00:04 java -Dcom.amazonaws.services.s3.disableGetObjectMD5Validation=true -Dcosbench.tomcat.config=conf/controller-tomcat-server.xml -server -cp main/org.eclipse.equinox.launcher_1.2.0.v20110502.jar org.eclipse.equinox.launcher.Main -configuration conf/.controller -console 19089
root     118775 108412  0 14:38 pts/0    00:00:00 grep --color=auto java

# 通过web打开
http://172.16.1.21:19088/controller/


# 测试安装
[root@managr cosbench]# sh cli.sh submit conf/workload-config.xml
Accepted with ID: w1

[root@managr cosbench]# sh cli.sh info
Drivers:
driver1	http://127.0.0.1:18088/driver
Total: 1 drivers

Active Workloads:
w1	Tue Jun 08 15:37:36 CST 2021	PROCESSING	s3-main
Total: 1 active workloads


# 容器运行
docker run -it -d  --privileged=true --name=cosbench -p 19088:19088 -p 18088:18088 -e ip=10.0.0.21  -e t=both -e n=1 -e u=true nexenta/cosbench
```

## Cosbench 多driver部署
本次部署模拟在一台主机上模拟三个driver
- 规划
```shell
# 拷贝cosbench目录
cp -r cosbench cosbench-d1
cp -r cosbench cosbench-d2
cp -r cosbench cosbench-d3

# cosbench-d1 作为控制节点和driver1
# cosbench-d2和d3，作为driver2和driver3

# 端口规划
d1  18078  19078
d2  18068
d3  18058
```


- 修改配置
```shell
# cosbench-d1
cd /opt/cosbench-d1

[root@managr cosbench-d1]# cat ./conf/controller.conf 
[controller]
drivers = 3
log_level = INFO
log_file = log/system.log
archive_dir = archive

[driver1]
name = driver1
url = http://127.0.0.1:18078/driver

[driver2]
name = driver2
url = http://127.0.0.1:18068/driver

[driver3]
name = driver3
url = http://127.0.0.1:18058/driver

[root@managr cosbench-d1]# cat ./conf/driver.conf 
[driver]
name=127.0.0.1:18078
url=http://127.0.0.1:18078/driver

[root@managr cosbench-d1]# vim ./start-controller.sh
OSGI_CONSOLE_PORT=19079

[root@managr cosbench-d1]# vim ./start-driver.sh
base_port=18078

[root@managr cosbench-d1]# vim ./conf/controller-tomcat-server.xml
<Connector port="19078" protocol="HTTP/1.1" />

# csobench-d2
cd /opt/cosbench-d2

[root@managr cosbench-d2]# cat ./conf/driver.conf
[driver]
name=127.0.0.1:18068
url=http://127.0.0.1:18068/driver

[root@managr cosbench-d2]# vim ./start-driver.sh
base_port=18068


# csobench-d3
cd /opt/cosbench-d2

[root@managr cosbench-d3]# cat ./conf/driver.conf 
[driver]
name=127.0.0.1:18058
url=http://127.0.0.1:18058/driver

[root@managr cosbench-d3]# vim ./start-driver.sh
base_port=18058
```

- 启动服务
```shell
# 先启动driver
sh /opt/cosbench-d3/start-driver.sh
sh /opt/cosbench-d2/start-driver.sh
sh /opt/cosbench-d1/start-driver.sh
sh /opt/cosbench-d1/start-controller.sh
```

- web访问
```shell
http://172.16.1.21:19078/controller
```



## Cosbench 测试步骤
```shell
# cosbench执行有5个过程分别为：
// init，初始化，一般指创建bucket
// init put，初始化对象数，一般指写入对象数据
// put，写入对象，与init put是一个功能。put是为测试随机写，如果顺序写，则可以省略put。
// get,读对象，可以测试随机读，顺序读。提前是对象已存在。所有在get之前一定要init put。
// cleanup，清理对象
// dispose，删除bucket
```

## Cosbench xml文件
- 配置文件结构
```shell
workload
    auth
    storage
    workflow
        workstage
            auth
            storage
            work
                auth
                storage
                operation

# 一个workload可以定义多个workstage
# 执行多个workstages是顺序的，执行同一个workstage里面的work是可以并行的
# 每个work里面，worker是来调整负载的
# 认证可以多个级别定义，低级别的认证会覆盖高级别的配置

# 可以通过配置多个work的方式来实现并发，而在work内通过增加worker的方式增加并发，从而实现多对多的访问，worker的分摊是分到了driver上面，注意多work的时候的containers不要重名，划分好bucker的空间
```

- workload
```shell
<workload name="create-bucket" description="create s3 bucket" config="">

# name值会显示web页面上，尽量有意义
```

- storage
```shell
<storage type="s3" config="accesskey=SXTUKNM2MCBBQB4Q0BZW;secretkey=5cbxDBmvNgOBk9VG5Bs5iw5Q9BrSFNGXKOp9xVV9;endpoint=http://10.0.0.23:7480;path_style_access=true"/>

# 存储类型，一般都是s3
# storage可以在每层定义：workload、workstage、work
```

- workflow\workstage
```shell
<workflow config="">
        <workstage name="create bucket" closuredelay="0" config="">

# 一个workflow可以包含多个workstage（建议一个就好）
# 一个workstage可以包含多个work（建议一个就好。多客户端测试除外）
# 一个work可以包含多个operation（建议一个就会。混合测试除外）
```

- work
```shell
...
            <work name="rgw1" type="init" workers="2" interval="5"
                division="container" runtime="0" rampup="0" rampdown="0"
                afr="0" totalOps="1" totalBytes="0" config="containers=r(1,32)">
                <auth type="none" config=""/>
                <storage type="s3" config="accesskey=test1;secretkey=test1;endpoint=http://192.168.19.101:7481;path_style_access=true"/>
                <operation type="init" ratio="100" division="container"
                    config="containers=r(1,32);containers=r(1,32);objects=r(0,0);sizes=c(0)B;containers=r(1,32)" id="none"/>
            </work>
...

# 可以通过写入时间，写入容量，写入iops来控制什么时候结束
# interval默认是5s是用户对性能快照的间隔，可以理解为采样点
# divsion控制workers直接的分配工作的方式是bucket还是对象还是none
# 默认全备的diriver参与工作，也可以通过参数控制部分driver参与
# 时间会控制执行，如果时间没到，但是指定的对象已经写完了的话就会去进行复写操作，这里要注意是进行对象的控制还是时间的控制进行的测试
# 如果读取测试的时候，如果没有哪个对象，会中断的提示，所以测试读之前需要把测试的对象都填充完毕。
```