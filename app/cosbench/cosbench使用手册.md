# Cosbench

## Cosbench 介绍

COSBench是一个测试云对象存储系统的分布式基准测试工具，有Driver和Controller两个关键组件组成，本文简要介绍通过S3接口使用COSBench测试Ceph的RGW。



## Cosbench 部署

- 版本准备

这里使用0.4.2.c4版本，最新版本存在bug，暂不使用

```shell
wget https://github.com/intel-cloud/cosbench/releases/download/v0.4.2.c4/0.4.2.c4.zip
```


- 部署依赖

```shell
yum install java-1.7.0-openjdk nmap-ncat
```


- 配置文件

```shell
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
```

- 启动cosbench

```shell
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

for i in {1..15}
do
cd /opt/cosbench-d${i}/
sh start-driver.sh
done
```

- web访问

```shell
http://172.16.1.21:19078/controller
```



## Cosbench 概述

cosbench执行有5个阶段，每一个阶段也可以单独执行。分别为：
- init：初始化，一般指创建bucket
- input：初始化对象数，一般指写入对象数据
- put：写入对象与input是一个功能，put是为测试随机写，如果顺序写，则可以省略put
- get：读对象，可以测试随机读，顺序读，提前是对象已存在。所有在get之前一定要input
- cleanup：清理对象
- dispose：删除bucket




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


- 常规work

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
有一种常规work（normal）和四种特殊work（init、prepare、cleanup、dispose），不同工作类型会有不同的参数组合，一般规则如下：
1.通常使用workers控制负载情况
2.通常使用runtime（包括rampup和rampdown）、totalOps、totalBytes控制负载什么时候结束，一般一个work定义只能设置其中一种，特殊work不需要定义此项参数

参数列表

| 属性       | 类型   | 默认值                                   | 注释                                                         |
| :--------- | :----- | :--------------------------------------- | :----------------------------------------------------------- |
| name       | 字符串 |                                          | work的一个名称                                               |
| type       | 字符串 | normal                                   | work的类型，可选参数为normal、init、prepare、cleanup、dispose、delay |
| workers    | 整型   |                                          | 并行进行work的workers数量，即同时起多少个线程运行负载        |
| interval   | 整型   | 5                                        | 性能快照之间的间隔，即多久统计一次性能数据                   |
| division   | 字符串 | none                                     | 控制workers之间的work分配方式，可选参数为none、container、object |
| runtime    | 整型   | 0                                        | 结束选项，work将执行多少秒                                   |
| rampup     | 整型   | 0                                        | 结束选项，加速工作负载的秒数（需要多少秒来增加工作负载）；此时间不包括在runtime中 |
| rampdown   | 整型   | 0                                        | 结束选项，减速工作负载的秒数（需要多少秒来减少工作负载）；此时间不包括在runtime中 |
| totalOps   | 整型   | 0                                        | 结束选项，将执行多少个操作；应该是workers的倍数              |
| totalBytes | 整型   | 0                                        | 结束选项，要传输多少字节，应该是workers和size的乘积的倍数。  |
| driver     | 字符串 |                                          | 将执行此work的driver，默认情况下，所有driver都将参与执行，可手动指定该work由哪个driver执行负载测试 |
| afr        | 整型   | 200000（常规work类型） 0（特殊work类型） | 可接受的失败率，是百万分之一。                               |

参数解释

division（划分策略）
1.1. division用于将一个work划分为多个不重叠区域，这些区域有着较小的容器或者对象范围，支持的策略有none、container、object
1.2. 不同阶段有不同的默认划分策略
对于init/dispose，默认的划分策略为container
对于prepare/cleanup，默认的划分策略为object
对于常规work，默认划分策略为none

```xml
#示例参数如下：
<work name="main" workers="4" runtime="300" division="?">
  <operation type="read" ratio="100" config="containers=u(1,8);objects=u(1,1000)" />
</work>
```
若division="container"，则表示在当前work中，worker通过container划分负载区域范围，访问模式示例如下：
注：workers数量不允许超过container

| Worker | Container Range | Object Range |
| :----- | :-------------- | :----------- |
| #1     | 1-2             | 1-1000       |
| #2     | 3-4             | 1-1000       |
| #3     | 5-6             | 1-1000       |
| #4     | 7-8             | 1-1000       |


若division="object"，则表示在当前work中，worker通过object划分负载区域范围，访问模式示例如下：
注：wrokers数量不允许超过objects

| Worker | Container Range | Object Range |
| :----- | :-------------- | :----------- |
| #1     | 1-8             | 1-250        |
| #2     | 1-8             | 251-500      |
| #3     | 1-8             | 501-750      |
| #4     | 1-8             | 751-1000     |


- 特殊work

特殊work与常规work有以下不同的地方：
1.它内部采用totalOps并计算具体数值来控制负载运行时长，因此不需要额外去定义结束选项
2.它有隐形定义的操作，因此不需要额外再定义具体操作内容（operation）
3."delay"与其他不同，这会导致work只休眠指定的秒数



init(批量创建特定桶)

```xml
<work type="init" workers="4" config="containers=r(1,100)" />
```

| 参数       | 类型   | 默认值        | 注释                                  |
| :--------- | :----- | :------------ | :------------------------------------ |
| containers | 字符串 |               | 容器选择表达式；例如： c(1), r(1,100) |
| cprefix    | 字符串 | mycontainers_ | 容器前缀                              |
| csuffix    | 字符串 |               | 容器后缀                              |



prepare（批量创建特定对象）

```xml
<work type="prepare" workers="4" config="containers=r(1,10);objects=r(1,100);sizes=c(64)KB" />
```

| 参数            | 类型   | 默认值        | 注释                                                         |
| :-------------- | :----- | :------------ | :----------------------------------------------------------- |
| containers      | 字符串 |               | 容器选择表达式；例如： c(1), u(1,100)                        |
| cprefix         | 字符串 | mycontainers_ | 容器前缀                                                     |
| csuffix         | 字符串 |               | 容器后缀                                                     |
| objects         | 字符串 |               | 对象选择表达式；例如 c(1), u(1,100)                          |
| oprefix         | 字符串 | myobjects_    | 对象前缀                                                     |
| osuffix         | 字符串 |               | 对象后缀                                                     |
| sizes           | 字符串 |               | 带单位(B/KB/MB/GB)的大小选择表达式；例如: c(128)KB, u(2,10)MB |
| chunked         | 布尔型 | False         | 是否以chunked模式上传数据                                    |
| content         | 字符串 | random        | 使用随机数据或全零填充对象内容，可选参数为random、zero       |
| createContainer | 布尔型 | False         | 创建相关容器(如果不存在)                                     |
| hashCheck       | 布尔型 | False         | 做与对象完整性检查相关的工作                                 |


cleanup（批量删除特定对象）
dispose（批量删除特定桶）
delay（插入几秒的延迟）

```xml
<workstage name=”delay” closuredelay=”60” >
  <work type="delay" workers="1" />
</workstage>
```
注：closuredelay即延迟时间（单位为秒）



- operation
ratio为当前操作数占总操作数的比例，单个work定义中，所有operation的ratio之和为100



write(写)

```xml
<operation type="write" ratio="20" config="containers=c(2);objects=u(1,1000);sizes=c(2)MB" />
```

| 参数       | 类型    | 默认值        | 注释                                                         |
| :--------- | :------ | :------------ | :----------------------------------------------------------- |
| containers | 字符串  |               | 容器选择表达式；例如 c(1), u(1,100)                          |
| cprefix    | 字符串  | mycontainers_ | 容器前缀                                                     |
| csuffix    | 字符串  |               | 容器后缀                                                     |
| objects    | 字符串  |               | 对象选择表达式；例如 c(1), u(1,100)                          |
| oprefix    | 字符串  | myobjects_    | 对象前缀                                                     |
| osuffix    | 字符串  |               | 对象后缀                                                     |
| sizes      | 字符串  |               | 带单位(B/KB/MB/GB)的大小选择表达式；例如: c(128)KB, u(2,10)MB |
| chunked    | 布尔型  | False         | 是否以chunked模式上传数据                                    |
| content    | 字符串  | random        | 使用随机数据或全零填充对象内容，可选参数为random、zero       |
| hashCheck  | Boolean | False         | 做与对象完整性检查相关的工作                                 |



read（读）

```xml
<operation type="read" ratio="70" config="containers=c(1);objects=u(1,100)" />
```

| 参数       | 类型   | 默认值        | 注释                                |
| :--------- | :----- | :------------ | :---------------------------------- |
| containers | 字符串 |               | 容器选择表达式；例如 c(1), u(1,100) |
| cprefix    | 字符串 | mycontainers_ | 容器前缀                            |
| csuffix    | 字符串 |               | 容器后缀                            |
| objects    | 字符串 |               | 对象选择表达式；例如 c(1), u(1,100) |
| oprefix    | 字符串 | myobjects_    | 对象前缀                            |
| osuffix    | 字符串 |               | 对象后缀                            |
| hashCheck  | 布尔型 | False         | 做与对象完整性检查相关的工作        |



filewrite（上传）

```xml
<operation type="filewrite" ratio="20" config="containers=c(2);fileselection=s;files=/tmp/testfiles" />
```
| 参数          | 类型   | 默认值        | 注释                                                    |
| :------------ | :----- | :------------ | :------------------------------------------------------ |
| containers    | 字符串 |               | 容器选择表达式；例如 c(1), u(1,100)                     |
| cprefix       | 字符串 | mycontainers_ | 容器前缀                                                |
| csuffix       | 字符串 |               | 容器后缀                                                |
| fileselection | 字符串 |               | 哪种选择器应该只使用put选择器标识符(例如，s代表顺序)。* |
| files         | 字符串 |               | 包含要上载的文件的文件夹的路径，路径必须存在            |
| chunked       | 布尔型 | False         | 是否以chunked模式上传数据                               |
| hashCheck     | 布尔型 | False         | 做与对象完整性检查相关的工作                            |



delete（删除）
```xml
<operation type="delete" ratio="10" config="containers=c(2);objects=u(1,1000)" />
```

| 参数       | 类型   | 默认值        | 注释                                |
| :--------- | :----- | :------------ | :---------------------------------- |
| containers | 字符串 |               | 容器选择表达式；例如 c(1), u(1,100) |
| cprefix    | 字符串 | mycontainers_ | 容器前缀                            |
| csuffix    | 字符串 |               | 容器后缀                            |
| objects    | 字符串 |               | 对象选择表达式；例如 c(1), u(1,100) |
| oprefix    | 字符串 | myobjects_    | 对象前缀                            |
| osuffix    | 字符串 |               | 对象后缀                            |



## Cosbench 选择器

在测试参数文件中，auth、storage、storage、work定义中支持config属性配置，该属性包含一个可选的参数列表（使用键值对格式表示，如"a=a_val;b=b_val"）

在参数列表中，常用的键包括containers、objects、sizes，用来指定如何选择容器、对象、大小。

- 选择器

```conf
c(number)---constant：仅使用指定数字，一般在常用于对象大小定义,如sizes=c(512)KB，则表示对象大小为512KB
u(min, max)---uniform：从（min，max）中均匀选择，u(1,100)表示从1到100中均匀地选取一个数字，选择是随机的，有些数字可能被选中多次，有些数字永远不会被选中
r(min,max)---range：从（min，max）递增选择，r(1,100)表示从1到100递增地选取一个数字，这通常被用于特殊work（init、prepare、cleanup、dispose）
s(min,max)---sequential：从（min，max）递增选择，s(1,100)表示从1到100递增地选取一个数字（每个数字只被选中一次），这通常被用于常规work
h(min1|max1|weight1,…)---histogram：它提供了一个加权直方图生成器，要配置它，需要指定一个逗号分隔的桶列表，其中每个桶由一个范围和一个整数权重定义。例如: h(1|64|10,64|512|20,512|2048|30)KB 其中定义了一个配置文件，其中（1,64）KB被加权为10，（64,512）KB被加权为20，（512,2048）KB被加权为30.权重之和不一定是100

注：一般常用的选择器通常为c(number)、u(min,max)、s(min,max)
```

- 参数组合-元素类型选择器

基于元素类型和工作类型的选择器有额外的约束，下面两个表列出了允许的组合

| key        | constant (c(num)) | uniform (u(min,max)) | range (r(min,max)) | sequential (s(min,max)) | histogram(h(min/max/ratio)) |
| ---------- | ----------------- | -------------------- | ------------------ | ----------------------- | --------------------------- |
| containers | ✔                 | ✔                    | ✔                  | ✔                       |                             |
| objects    | ✔                 | ✔                    | ✔                  | ✔                       |                             |
| sizes      | ✔                 | ✔                    |                    | ✔                       | ✔                           |

- 参数组合-工作类型选择器

| Key        | init     | prepare       | normal (read)      | normal (write)     | normal (delete)    | cleanup  | dispose  |
| :--------- | :------- | :------------ | :----------------- | :----------------- | :----------------- | :------- | :------- |
| containers | r(), s() | r(), s()      | c(), u(), r(), s() | c(), u(), r(), s() | c(), u(), r(), s() | r(), s() | r(), s() |
| objects    |          | r(), s()      | c(), u(), r(), s() | c(), u(), r()      | c(), u(), r(), s() | r(), s() |          |
| sizes      |          | c(), u(), h() |                    | c(), u(), h()      |                    |          |          |

