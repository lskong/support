# zookeeper+kafka
[toc]

## 1. 概念
参考资料：https://blog.csdn.net/weixin_45778734/article/details/105689685


### 1.1 zookeeper

### 1.2 kafka
Kafka是由Apache软件基金会开发的一个开源流处理平台，由Scala和Java编写。Kafka是一种高吞吐量的分布式发布订阅消息系统，它可以处理消费者在网站中的所有动作流数据。 这种动作（网页浏览，搜索和其他用户的行动）是在现代网络上的许多社会功能的一个关键因素。 这些数据通常是由于吞吐量的要求而通过处理日志和日志聚合来解决。 对于像Hadoop一样的日志数据和离线分析系统，但又要求实时处理的限制，这是一个可行的解决方案。Kafka的目的是通过Hadoop的并行加载机制来统一线上和离线的消息处理，也是为了通过集群来提供实时的消息。

kafka的架构师jay kreps对于kafka的名称由来是这样讲的，由于jay kreps非常喜欢franz kafka,并且觉得kafka这个名字很酷，因此取了个和消息传递系统完全不相干的名称kafka，该名字并没有特别的含义。

kafka的诞生，是为了解决linkedin的数据管道问题，起初linkedin采用了ActiveMQ来进行数据交换，大约是在2010年前后，那时的ActiveMQ还远远无法满足linkedin对数据传递系统的要求，经常由于各种缺陷而导致消息阻塞或者服务无法正常访问，为了能够解决这个问题，linkedin决定研发自己的消息传递系统，当时linkedin的首席架构师jay kreps便开始组织团队进行消息传递系统的研发；

### 1.3 kafka特性
Kafka 是一种高吞吐量的分布式发布订阅消息系统，有如下特性：

- 加粗样式通过O(1)的磁盘数据结构提供消息的持久化，这种结构对于即使数以TB的消息存储也能够保持长时间的稳定性能。
- 高吞吐量 ：即使是非常普通的硬件Kafka也可以支持每秒数百万的消息。
- 支持通过Kafka服务器和消费机集群来分区消息。
- 支持Hadoop并行数据加载。


### 1.4 kafka语术
**Broker:**
Kafka集群包含一个或多个服务器，这种服务器被称为broker，类似于集群的节点。

**Topic:**
每条发布到Kafka集群的消息都有一个类别，这个类别被称为Topic。（物理上不同Topic的消息分开存储，逻辑上一个Topic的消息虽然保存于一个或多个broker上但用户只需指定消息的Topic即可生产或消费数据而不必关心数据存于何处）

**Partition:**
Partition是物理上的概念，每个Topic包含一个或多个Partition.

**Producer:**
负责发布消息到Kafka broker，消息的生产者

**Consumer:**
消息消费者，向Kafka broker读取消息的客户端。

**Consumer Group:**
每个Consumer属于一个特定的Consumer Group（可为每个Consumer指定group name，若不指定group name则属于默认的group）



## 2. docker-compose
使用docker-compose搭建zookeeper+kafka集群
- kafka集群在docker网络中可用，和zookeeper处于同一网络
- 宿主机可以访问zookeeper集群和kafka的broker list
- docker重启时集群自动重启
- 集群的数据文件映射到宿主机器目录中
- 使用yml文件和$ docker-compose up -d命令创建或重建集群



容器列表：

| hostname      | ipaddress   | port      | listener |
| :------------ | ----------- | --------- | -------- |
| zoo1          | 172.19.0.11 | 2181:2181 |          |
| zoo2          | 172.19.0.12 | 2182:2181 |          |
| zoo3          | 172.19.0.13 | 2183:2181 |          |
| kafka1        | 172.19.0.14 | 9092:9092 | kafka1   |
| kafka2        | 172.19.0.15 | 9093:9093 | kafka2   |
| kafka3        | 172.19.0.16 | 9094:9094 | kafka3   |
| kafka-manager | 172.19.0.17 | 9000:9000 |          |



### 2.1 创建网络
```shell
docker network create --driver bridge --subnet 172.19.0.0/16 --gateway 172.19.0.1 kafka
```

### 2.2 下载镜像
Zookeeper和Kafka集群分别运行在不同的容器中，zookeeper官方镜像。
kafka采用wurstmeister/kafka镜像，
kafka-manager采用sheepkiller/kafka-manager:latest镜像。

```shell
docker pull zookeeper
docker pull wurstmeister/kafka
```

### 2.3 准备compose.yaml文件doc
```yaml
version: '3.4'
services:
  zoo1:
    image: zookeeper
    restart: always
    hostname: zoo1
    container_name: zoo1
    ports:
      - 2181:2181
    volumes:
      - "/data/app/kafka/data/zkcluster/zoo1/data:/data"
      - "/data/app/kafka/data/zkcluster/zoo1/datalog:/datalog"
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=0.0.0.0:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=zoo3:2888:3888;2181
    networks:
      kafka:
        ipv4_address: 172.19.0.11

  zoo2:
    image: zookeeper
    restart: always
    hostname: zoo2
    container_name: zoo2
    ports:
      - 2182:2181
    volumes:
      - "/data/app/kafka/data/zkcluster/zoo2/data:/data"
      - "/data/app/kafka/data/zkcluster/zoo2/datalog:/datalog"
    environment:
      ZOO_MY_ID: 2
      ZOO_SERVERS: server.1=zoo1:2888:3888;2181 server.2=0.0.0.0:2888:3888;2181 server.3=zoo3:2888:3888;2181
    networks:
      kafka:
        ipv4_address: 172.19.0.12

  zoo3:
    image: zookeeper
    restart: always
    hostname: zoo3
    container_name: zoo3
    ports:
      - 2183:2181
    volumes:
      - "/data/app/kafka/data/zkcluster/zoo3/data:/data"
      - "/data/app/kafka/data/zkcluster/zoo3/datalog:/datalog"
    environment:
      ZOO_MY_ID: 3
      ZOO_SERVERS: server.1=zoo1:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=0.0.0.0:2888:3888;2181
    networks:
      kafka:
        ipv4_address: 172.19.0.13


  kafka1:
    image: wurstmeister/kafka
    restart: always
    hostname: kafka1
    container_name: kafka1
    ports:
      - 9092:9092
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ADVERTISED_HOST_NAME: kafka1
      KAFKA_ADVERTISED_PORT: 9092
      KAFKA_ZOOKEEPER_CONNECT: zoo1:2181,zoo2:2181,zoo3:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka1:9092
      KAFKA_LISTENERS: PLAINTEXT://kafka1:9092
    volumes:
      - /data/app/kafka/data/kfkluster/kafka1/logs:/kafka
    external_links:
      - zoo1
      - zoo2
      - zoo3
    networks:
      kafka:
        ipv4_address: 172.19.0.14

  kafka2:
    image: wurstmeister/kafka
    restart: always
    hostname: kafka2
    container_name: kafka2
    ports:
      - 9093:9093
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_ADVERTISED_HOST_NAME: kafka2
      KAFKA_ADVERTISED_PORT: 9093
      KAFKA_ZOOKEEPER_CONNECT: zoo1:2181,zoo2:2181,zoo3:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka2:9093
      KAFKA_LISTENERS: PLAINTEXT://kafka2:9093
    volumes:
      - /data/app/kafka/data/kfkluster/kafka2/logs:/kafka
    external_links:
      - zoo1
      - zoo2
      - zoo3
    networks:
      kafka:
        ipv4_address: 172.19.0.15

  kafka3:
    image: wurstmeister/kafka
    restart: always
    hostname: kafka3
    container_name: kafka3
    ports:
      - 9094:9094
    environment:
      KAFKA_BROKER_ID: 3
      KAFKA_ADVERTISED_HOST_NAME: kafka3
      KAFKA_ADVERTISED_PORT: 9094
      KAFKA_ZOOKEEPER_CONNECT: zoo1:2181,zoo2:2181,zoo3:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka3:9094
      KAFKA_LISTENERS: PLAINTEXT://kafka3:9094
    volumes:
      - /data/app/kafka/data/kfkluster/kafka3/logs:/kafka
    external_links:
      - zoo1
      - zoo2
      - zoo3
    networks:
      kafka:
        ipv4_address: 172.19.0.16

  kafka-manager:      # Kafka 图形管理界面
    image: sheepkiller/kafka-manager:latest
    restart: unless-stopped
    container_name: kafka-manager
    hostname: kafka-manager
    ports:
      - 9000:9000
    links:            # 连接本compose文件创建的container
      - kafka1
      - kafka2
      - kafka3
    external_links:   # 连接外部compose文件创建的container
      - zoo1
      - zoo2
      - zoo3
    environment:
      ZK_HOSTS: zoo1:2181,zoo2:2181,zoo3:2181
      KAFKA_BROKERS: kafka1:9092,kafka2:9093,kafka3:9094
    networks:
      kafka:
        ipv4_address: 172.19.0.17

networks:
  kafka:
    external:
      name: kafka
```


### 2.4 启动集群
```shell
docker-compose up -d
```


### 2.5 验证zk集群
```shell
# 进入容器
docker exec -it zoo1 bash

# 查看zk状态
zkServer.sh status

root@zoo1:/apache-zookeeper-3.7.0-bin# zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /conf/zoo.cfg
Client port found: 2181. Client address: localhost. Client SSL: false.
Mode: follower

# 陆续查看其它zk容器，获取的结果应该是1个leader和2follower

```

### 2.6 验证kf集群
```shell
# 随意进入容器
docker exec -it kafka1 sh

# 创建topic
kafka-topics.sh --create --zookeeper zoo1:2181,zoo2:2181,zoo3:2181 --replication-factor 1 --partitions 3 --topic testTopic
kafka-topics.sh --create --zookeeper 10.0.0.101:2181,10.0.0.102:2181,10.0.0.103:2181 --replication-factor 1 --partitions 3 --topic testTopic

# 列出topic
kafka-topics.sh --list --zookeeper 10.0.0.101:2181,10.0.0.102:2181,10.0.0.103:2181

# 生产消息
kafka-console-producer.sh --broker-list kafka1:9092,kafka2:9093,kafka3:9094 --topic testTopic
kafka-console-producer.sh --broker-list 10.0.0.104:9092,10.0.0.105:9092,10.0.0.105:9092 --topic testTopic

# 在登录其它kf容器
docker exec -it kafka2 sh

# 消费消息
kafka-console-consumer.sh --bootstrap-server kafka1:9092,kafka2:9093,kafka3:9094 --topic testTopic
kafka-console-consumer.sh --bootstrap-server 10.0.0.104:9092,10.0.0.105:9092,10.0.0.105:9092 --topic testTopic

# 在kf1上随意输入生产消息，然后在kf2上能看到消费消息
# 同时也可以在kf1和3上消费消息

```


### 2.7 kafka manager（可选）

step1：打开浏览器输入：http://{宿主机IP}:9000

step2：依次点击Cluster-->Add Cluster

step3：再新窗口中填入集群名、zk集群主机、启动JMX Polling

step4：保存

![image-20210526174504927](zookeeper+kafka.assets/image-20210526174504927.png)



## 3. 物理主机部署

### 3.1 环境准备

| hostname | ipaddres      | service    | port      |
| -------- | ------------- | ---------- | --------- |
| node1    | 172.16.103.31 | zk1/kafka1 | 2181/9092 |
| node2    | 172.16.103.32 | zk2/kafka2 | 2181/9092 |
| node3    | 172.16.103.33 | zk3/kafka3 | 2181/9092 |

所有节点均需要安装JDK8
参考CentOS下部署Java7/Java8： https://ken.io/note/centos-java-setup



### 3.1 java8安装

```shell
# 准备java安装包

# 解压指定目录
mkdir -p /usr/java
tar xf jdk-8u221-linux-x64.tar.gz -C /usr/java

# 配置环境变量
tee >> /etc/profile <<-'EOF'
export JAVA_HOME=/usr/java/jdk1.8.0_221
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
EOF

# 使环境变量生效
source /etc/profile

# 检查
java -version


## 直接yum部署
yum install -y java-1.8.0-openjdk
java -version
```





### 3.2 处理安装包

```shell
# zookeeper
wget https://mirrors.bfsu.edu.cn/apache/zookeeper/zookeeper-3.7.0/apache-zookeeper-3.7.0-bin.tar.gz
tar xf apache-zookeeper-3.7.0-bin.tar.gz
mv apache-zookeeper-3.7.0-bin /data/
ln -s /data/apache-zookeeper-3.7.0-bin /data/zookeeper
echo 'PATH=/data/zookeeper/bin:$PATH' >> /root/.bashrc
source /root/.bashrc


# kafka
wget https://mirrors.bfsu.edu.cn/apache/kafka/2.8.0/kafka_2.13-2.8.0.tgz
tar xf kafka_2.13-2.8.0.tgz
mv kafka_2.13-2.8.0 /data/
ln -s /data/kafka_2.13-2.8.0 /data/kafka
echo 'PATH=/data/kafka/bin:$PATH' >> /root/.bashrc
source /root/.bashrc

```



### 3.3 部署zk集群

```shell
# 创建数据目录
for i in {1..3}
do
ssh node${i} "mkdir -p /data/zookeeper/data"
ssh node${i} "mkdir -p /data/zookeeper/logs"
done

# 创建配置文件
tee > /data/zookeeper/conf/zoo.cfg <<-'EOF'
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data/zookeeper/data
dataLogDir=/data/zookeeper/logs
clientPort=2181
server.1=172.16.103.31:2888:3888
server.2=172.16.103.32:2888:3888
server.3=172.16.103.33:2888:3888
EOF

# 配置节点标识
for i in {1..3}
do
ssh node${i} "echo $i > /data/zookeeper/data/myid"
done

# 启动服务
zkServer.sh start 


# 查看集群
zkServer.sh status
# 每个节点执行，可以看到1个leader,2个follower

# 客户端连接测试
zkCli.sh -server 172.16.103.31:2181,172.16.103.32:2181,172.16.103.33:2181


# 输入命令测试：（查看根目录ls /）
[zk: 172.16.103.31:2181,172.16.103.32:2181,172.16.103.33:2181(CONNECTED) 0] ls /
[zookeeper]
[zk: 172.16.103.31:2181,172.16.103.32:2181,172.16.103.33:2181(CONNECTED) 1] 

```





### 3.4 部署kafka集群

```shell
# 创建数据目录
for i in {1..3}
do
ssh node${i} "mkdir -p /data/kafka/logs"
done

# 修改配置文件
vim /data/kafka/config/server.properties

broker.id=1			# node1
log.dirs=/data/kafka/logs/
listeners=PLAINTEXT://172.16.103.31:9092
zookeeper.connect=172.16.103.31:2181,172.16.103.32:2181,172.16.103.33:2181

broker.id=2			# node2
log.dirs=/data/kafka/logs/
listeners=PLAINTEXT://172.16.103.32:9092
zookeeper.connect=172.16.103.31:2181,172.16.103.32:2181,172.16.103.33:2181

broker.id=3			# node3
log.dirs=/data/kafka/logs/
listeners=PLAINTEXT://172.16.103.33:9092
zookeeper.connect=172.16.103.31:2181,172.16.103.32:2181,172.16.103.33:2181

# 启动服务
kafka-server-start.sh -daemon /data/kafka/config/server.properties

# 停止服务
kafka-server-stop.sh /opt/kafka/config/server.properties


# 验证
# 创建topic
kafka-topics.sh --create --zookeeper 172.16.103.31:2181,172.16.103.32:2181,172.16.103.33:2181 --replication-factor 1 --partitions 3 --topic testTopic

# 列出topic
kafka-topics.sh --list --zookeeper 172.16.103.31:2181,172.16.103.32:2181,172.16.103.33:2181
kafka-topics.sh --list --zookeeper 172.16.103.31:2181
kafka-topics.sh --list --zookeeper 172.16.103.32:2181
kafka-topics.sh --list --zookeeper 172.16.103.33:2181
# 注意如果都能看到testTopic，证明集群正常

# 生产消息
kafka-console-producer.sh --broker-list 172.16.103.31:9092,172.16.103.32:9092,172.16.103.33:9092 --topic testTopic

# 消费消息
kafka-console-consumer.sh --bootstrap-server 172.16.103.31:9092,172.16.103.32:9092,172.16.103.33:9092 --topic testTopic

# 在kf1上随意输入生产消息，然后在kf2上能看到消费消息
# 同时也可以在kf1和3上消费消息
```





## 4. 容器network-host模式

