# zookeeper+kafka物理机部署

### 1. 主机清单

| hostname | ipaddress |  service   |   port    |               data directory                |                        Log directory                         |
| :------: | :-------: | :--------: | :-------: | :-----------------------------------------: | :----------------------------------------------------------: |
|  node4   | 10.0.0.23 | zk1/kafka1 | 2181/9092 | /data/kafka/physics_kfk_zook/zookeeper/data | /data/kafka/physics_kfk_zook/zookeeper/logs<br />/data/kafka/physics_kfk_zook/kafka/logs |
|  node5   | 10.0.0.24 | zk2/kafka2 | 2181/9092 |                                             |                                                              |
|  node6   | 10.0.0.25 | zk3/kafka3 | 2181/9092 |                                             |                                                              |

### 2. java8安装

```apl
# apt安装java8
root@node4:~# apt install openjdk-8-jre-headless

# java版本信息
root@node4:~# java -version
```

> node4,node5,node6都需安装

### 3. 安装zookeeper

- 创建zookeeper安装目录

```apl
root@node4:~# mkdir -p /data/kafka/physics_kfk_zook

root@node4:~# cd /data/kafka/physics_kfk_zook
```

- 下载zookeeper安装包

```apl
root@node4:/data/kafka/physics_kfk_zook# wget https://mirrors.bfsu.edu.cn/apache/zookeeper/zookeeper-3.7.0/apache-zookeeper-3.7.0-bin.tar.gz

root@node4:/data/kafka/physics_kfk_zook# tar -xf apache-zookeeper-3.7.0-bin.tar.gz
```

- 链接软件包为zookeeper

```apl
root@node4:/data/kafka/physics_kfk_zook# ln -s /data/kafka/physics_kfk_zook/apache-zookeeper-3.7.0-bin /data/kafka/physics_kfk_zook/zookeepe
```

- 设置环境变量

```apl
root@node4:/data/kafka/physics_kfk_zook# echo 'PATH=/data/kafka/physics_kfk_zook/zookeeper/bin:$PATH' >> /root/.bashrc

root@node4:/data/kafka/physics_kfk_zook# source /root/.bashrc
```

> node4,node5,node6都需执行

### 4. 安装kafka

- 下载kafka安装包

```apl
root@node4:~# cd /data/kafka/physics_kfk_zook

root@node4:/data/kafka/physics_kfk_zook# wget https://mirrors.bfsu.edu.cn/apache/kafka/2.8.0/kafka_2.13-2.8.0.tgz

root@node4:/data/kafka/physics_kfk_zook# tar xf kafka_2.13-2.8.0.tgz
```

- 链接软件包为kafka

```apl
root@node4:/data/kafka/physics_kfk_zook# ln -s /data/kafka/physics_kfk_zook/kafka_2.13-2.8.0 /data/kafka/physics_kfk_zook/kafka
```

- 设置环境变量

```apl
root@node4:/data/kafka/physics_kfk_zook# echo 'PATH=/data/kafka/physics_kfk_zook/kafka/bin:$PATH' >> /root/.bashrc

root@node4:/data/kafka/physics_kfk_zook# source /root/.bashrc
```

> node4,node5,node6都需执行

### 5. 部署zookeeper集群

- 创建数据与日志目录

```apl
# 创建数据目录
root@node4:~# mkdir -p /data/kafka/physics_kfk_zook/zookeeper/data

# 创建日志目录
root@node4:~# mkdir -p /data/kafka/physics_kfk_zook/zookeeper/logs
```

- 创建配置文件

```apl
root@node4:~# vim /data/kafka/physics_kfk_zook/zookeeper/conf/zoo.cfg

tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data/kafka/physics_kfk_zook/zookeeper/data
dataLogDir=/data/kafka/physics_kfk_zook/zookeeper/logs
clientPort=2181
server.1=10.0.0.23:2888:3888
server.2=10.0.0.24:2888:3888
server.3=10.0.0.25:2888:3888
```

- 配置节点标识

```apl
root@node4:~# touch /data/kafka/physics_kfk_zook/zookeeper/data/myid

# 该node4节点标识为1,以此类推node5与node6节点标识分别应为"2","3".
root@node4:~# echo "1" >> /data/kafka/physics_kfk_zook/zookeeper/data/myid
```

> node4,node5,node6都需执行

### 6. 启动zookeeper集群

- 启动服务

```apl
root@node4:~# zkServer.sh start
```

- 查看集群

```apl
root@node4:~# zkServer.sh status

/usr/bin/java
ZooKeeper JMX enabled by default
Using config: /data/kafka/physics_kfk_zook/zookeeper/bin/../conf/zoo.cfg
Client port found: 2181. Client address: localhost. Client SSL: false.
Mode: leader

# 每个节点执行，可以看到1个leader,2个follower
```

- 客户端连接测试

```apl
root@node4:~# zkCli.sh -server 10.0.0.23:2181,10.0.0.24:2181,10.0.0.25:2181

# 输入命令查看根目录
[zk: 10.0.0.23:2181,10.0.0.24:2181,10.0.0.25:2181(CONNECTED) 0] ls /
[zookeeper]
```

> node4,node5,node6都需执行

### 7. 部署kafka集群

- 创建日志目录

```apl
root@node4:~# mkdir -p /data/kafka/physics_kfk_zook/kafka/logs
```
    
- 修改配置文件

```apl
root@node4:~# vim /data/kafka/physics_kfk_zook/kafka/config/server.properties

# node4节点修改:
 21 broker.id=1
 31 listeners=PLAINTEXT://10.0.0.23:9092
 60 log.dirs=/data/kafka/physics_kfk_zook/kafka/logs/
 123 zookeeper.connect=10.0.0.23:2181,10.0.0.24:2181,10.0.0.25:2181
 
# node5节点修改:
 21 broker.id=2
 31 listeners=PLAINTEXT://10.0.0.24:9092
 60 log.dirs=/data/kafka/physics_kfk_zook/kafka/logs/
 123 zookeeper.connect=10.0.0.23:2181,10.0.0.24:2181,10.0.0.25:2181
 
# node6节点修改:
 21 broker.id=3
 31 listeners=PLAINTEXT://10.0.0.25:9092
 60 log.dirs=/data/kafka/physics_kfk_zook/kafka/logs/
 123 zookeeper.connect=10.0.0.23:2181,10.0.0.24:2181,10.0.0.25:2181
```

> node4,node5,node6都需执行

### 8. 启动kafka集群

- 启动服务

```apl
root@node4:~# kafka-server-start.sh -daemon /data/kafka/physics_kfk_zook/kafka/config/server.properties

# 停止服务
kafka-server-stop.sh /data/kafka/physics_kfk_zook/kafka/config/server.properties
```

- 验证

```apl
# 创建topic
root@node4:~# kafka-topics.sh --create --zookeeper 10.0.0.23:2181,10.0.0.24:2181,10.0.0.25:2181 --replication-factor 1 --partitions 3 --topic testTopic

# 列出topic
root@node4:~# kafka-topics.sh --list --zookeeper 10.0.0.23:2181,10.0.0.24:2181,10.0.0.25:2181
root@node4:~# kafka-topics.sh --list --zookeeper 10.0.0.23:2181
root@node4:~# kafka-topics.sh --list --zookeeper 10.0.0.24:2181
root@node4:~# kafka-topics.sh --list --zookeeper 10.0.0.25:2181
## 如果都能看到testTopic，证明集群正常

# 生产消息
kafka-console-producer.sh --broker-list 10.0.0.23:9092,10.0.0.24:9092,10.0.0.25:9092 --topic testTopic

# 消费消息
kafka-console-consumer.sh --bootstrap-server 10.0.0.23:9092,10.0.0.24:9092,10.0.0.25:9092 --topic testTopic

# 在kf1上随意输入生产消息，然后在kf2上能看到消费消息
# 同时也可以在kf1和3上消费消息

```

