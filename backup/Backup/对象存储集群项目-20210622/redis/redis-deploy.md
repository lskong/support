## redis5.x容器集群部署

### 1. 准备

#### 1.1 安装环境
```shell
# 三台物理机安装docker和docker-compose

# 主机容器IP和端口规划如下：

# node4 10.0.0.0.26
redis-6381 10.0.0.121:6381
redis-6382 10.0.0.122:6382

# node5 10.0.0.0.27
redis-6383 10.0.0.123:6383
redis-6384 10.0.0.124:6384

# node6 10.0.0.0.28
redis-6385 10.0.0.125:6385 
redis-6386 10.0.0.126:6386


# 每个节点启动两个redis（一主一从）,主从交叉部署

# 主从关系图：
#  主：6381  6383  6385
#      |     |     |
#  从：6384  6386  6382


# 工作目录，每个节点
/data/redis/        # 包括yaml和容器的持久数据
```

#### 1.2 配置文件
redis.conf 配置文件修改

> port 6381       # 修改端口
> cluster-announce-ip 10.0.0.121   # 修改IP
> cluster-announce-bus-port 16381   # 修改端口


####  1.3 node4
redis-6381.conf 配置文件
```shell
$ cat /data/cluster/6381/conf/redis.conf
port 6381
requirepass 1234
masterauth 1234
protected-mode no
daemonize no
appendonly yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-announce-ip 10.0.0.121
cluster-announce-port 6381
cluster-announce-bus-port 16381
```

redis-6382.conf 配置文件
```shell
$ cat /data/cluster/6382/conf/redis.conf
port 6382
requirepass 1234
masterauth 1234
protected-mode no
daemonize no
appendonly yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-announce-ip 10.0.0.122
cluster-announce-port 6382
cluster-announce-bus-port 16382
```
docker-compose.yaml
```shell
$ cat /data/redis/docker-compose.yaml
version: '3.8'
networks:
  macvlan10:
    external:
      name: macvlan10
services:
  redis-6381:
    image: redis
    container_name: redis-6381
    restart: always
    volumes:
      - /data/redis/cluster/6381/conf/:/usr/local/etc/redis/
      - /data/redis/cluster/6381/data:/data
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      macvlan10:
        ipv4_address: 10.0.0.121
  redis-6382:
    image: redis
    container_name: redis-6382
    restart: always
    volumes:
      - /data/redis/cluster/6382/conf/:/usr/local/etc/redis
      - /data/redis/cluster/6382/data:/data
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      macvlan10:
        ipv4_address: 10.0.0.122
```

####  1.4 node5
redis-6383.conf 配置文件
```shell
$ cat /data/cluster/6383/conf/redis.conf
port 6383
requirepass 1234
masterauth 1234
protected-mode no
daemonize no
appendonly yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-announce-ip 10.0.0.123
cluster-announce-port 6383
cluster-announce-bus-port 16383
```

redis-6384.conf 配置文件
```shell
$ cat /data/cluster/6384/conf/redis.conf
port 6384
requirepass 1234
masterauth 1234
protected-mode no
daemonize no
appendonly yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-announce-ip 10.0.0.124
cluster-announce-port 6384
cluster-announce-bus-port 16384
```
docker-compose.yaml
```shell
$ cat /data/redis/docker-compose.yaml
version: '3.8'
networks:
  macvlan10:
    external:
      name: macvlan10
services:
  redis-6383:
    image: redis
    container_name: redis-6383
    restart: always
    volumes:
      - /data/redis/cluster/6383/conf/:/usr/local/etc/redis/
      - /data/redis/cluster/6383/data:/data
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      macvlan10:
        ipv4_address: 10.0.0.123
  redis-6384:
    image: redis
    container_name: redis-6384
    restart: always
    volumes:
      - /data/redis/cluster/6384/conf/:/usr/local/etc/redis
      - /data/redis/cluster/6384/data:/data
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      macvlan10:
        ipv4_address: 10.0.0.124
```

####  1.5 node6
redis-6385.conf 配置文件
```shell
$ cat /data/cluster/6385/conf/redis.conf
port 6385
requirepass 1234
masterauth 1234
protected-mode no
daemonize no
appendonly yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-announce-ip 10.0.0.125
cluster-announce-port 63835
cluster-announce-bus-port 16385
```

redis-6386.conf 配置文件
```shell
$ cat /data/cluster/6386/conf/redis.conf
port 6386
requirepass 1234
masterauth 1234
protected-mode no
daemonize no
appendonly yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-announce-ip 10.0.0.124
cluster-announce-port 6386
cluster-announce-bus-port 16386
```

docker-compose.yaml
```shell
$ cat /data/redis/docker-compose.yaml
version: '3.8'
networks:
  macvlan10:
    external:
      name: macvlan10
services:
  redis-6385:
    image: redis
    container_name: redis-6385
    restart: always
    volumes:
      - /data/redis/cluster/6385/conf/:/usr/local/etc/redis/
      - /data/redis/cluster/6385/data:/data
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      macvlan10:
        ipv4_address: 10.0.0.125
  redis-6386:
    image: redis
    container_name: redis-6386
    restart: always
    volumes:
      - /data/redis/cluster/6386/conf/:/usr/local/etc/redis
      - /data/redis/cluster/6386/data:/data
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      macvlan10:
        ipv4_address: 10.0.0.126
```



### 2. 启动服务
```shell
# node4
docker-compose up -d

# 查看
docker ps 
```


### 3. 创建集群
```shell
# 随意进入一个容器
docker exec -it redis-6381 bash

# 进入redis数据库
redis-cli -a 1234 -h 127.0.0.1 -p 6381

# 创建集群
redis-cli -a 1234 --cluster create 10.0.0.121:6381 10.0.0.123:6383 10.0.0.125:6385 10.0.0.122:6382 10.0.0.124:6384 10.0.0.126:6386 --cluster-replicas 1
# 需要输入yes

# 验证集群
CLUSTER NODES
CLUSTER INFO

# -c参数
redis-cli -c -a 1234 -h 127.0.0.1 -p 6381
# 随意从哪一台容器进入都可以，然后get/set测试
set k1 v1
set k2 v1
```



## redis6.2.4集群部署

### 部署环境
- 端口规划
```shell
# node1 10.0.0.23
redis port: 6381 6382

# node2 10.0.0.24
redis port: 6381 6382

# node3 10.0.0.25
redis port: 6381 6382

# redis-cluster-proxy
node3 10.0.0.25 6379
```

- 目录规划
```shell
# 节点
/data/redis-cluster/6381/data
/data/redis-cluster/6381/conf

/data/redis-cluster/6382/data
/data/redis-cluster/6382/conf
```


- 配置文件
```shell
# redis.conf
$ cat /data/redis-cluster/6381/conf/redis.conf
port 6381
requirepass 1234
masterauth 1234
protected-mode no
daemonize no
appendonly yes
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-announce-ip 10.0.0.23
cluster-announce-port 6381
cluster-announce-bus-port 16381
```


### 部署步骤
- 安装redis6.2.4
```shell
sudo add-apt-repository ppa:redislabs/redis
sudo apt-get update
sudo apt-get install redis

# 查看版本
root@node1:~# redis-cli --version
redis-cli 6.2.4

# 关闭默认6379
systemctl stop redis-server.service
systemctl enable redis-server.service
```

- 配置集群文件
```shell
# 创建目录，每个节点执行
mkdir /data/redis-cluster/redis-{6381,6382}/{conf,data,logs} -p

# 生成配置文件
cat > /data/redis-cluster/redis-6381/conf/redis-6381.conf <<EOF
port 6381
requirepass 1234
masterauth 1234
protected-mode no
daemonize no
appendonly yes
cluster-enabled yes
cluster-config-file nodes-6381.conf
cluster-node-timeout 15000
cluster-announce-ip 10.0.0.23
cluster-announce-port 6381
cluster-announce-bus-port 16381
EOF

cat > /data/redis-cluster/redis-6382/conf/redis-6382.conf <<EOF
port 6382
requirepass 1234
masterauth 1234
protected-mode no
daemonize no
appendonly yes
cluster-enabled yes
cluster-config-file nodes-6382.conf
cluster-node-timeout 15000
cluster-announce-ip 10.0.0.23
cluster-announce-port 6382
cluster-announce-bus-port 16382
EOF

# 发送配置文件到其它节点
root@node1:/data# scp -r /data/redis-cluster node2:/data
root@node1:/data# scp -r /data/redis-cluster node3:/data

# node2/node3修改配置文件
sed -i 's/10.0.0.23/10.0.0.24/g' /data/redis-cluster/redis-6381/conf/redis-6381.conf
sed -i 's/10.0.0.23/10.0.0.24/g' /data/redis-cluster/redis-6382/conf/redis-6382.conf

sed -i 's/10.0.0.23/10.0.0.25/g' /data/redis-cluster/redis-6381/conf/redis-6381.conf
sed -i 's/10.0.0.23/10.0.0.25/g' /data/redis-cluster/redis-6382/conf/redis-6382.conf
```

- 运维脚本
```shell
cat >/usr/sbin/redis-shell <<"EOF"
#!/bin/bash

USAG(){
    echo "sh $0 {start|stop|restart|login|ps|tail} PORT"
}
if [ "$#" = 1 ]
then
    REDIS_PORT='6379'
elif
    [ "$#" = 2 -a -z "$(echo "$2"|sed 's#[0-9]##g')" ]
then
    REDIS_PORT="$2"
else
    USAG
    exit 0
fi

PASSWORD=1234
REDIS_IP=$(hostname -i|awk '{print $1}')
PATH_DIR=/data/redis-cluster/redis-${REDIS_PORT}
PATH_CONF=/data/redis-cluster/redis-${REDIS_PORT}/conf/redis-${REDIS_PORT}.conf
PATH_LOG=/data/redis-cluster/redis-${REDIS_PORT}/logs/redis-${REDIS_PORT}.log

CMD_START(){
    redis-server ${PATH_CONF} &
}

CMD_SHUTDOWN(){
    redis-cli -a ${PASSWORD} -c -h ${REDIS_IP} -p ${REDIS_PORT} shutdown
}

CMD_LOGIN(){
    redis-cli -a ${PASSWORD} -c -h ${REDIS_IP} -p ${REDIS_PORT}
}

CMD_PS(){
    ps -ef|grep redis
}

CMD_TAIL(){
    tail -f ${PATH_LOG}
}

case $1 in
    start)
        CMD_START
        CMD_PS
        ;;
    stop)
        CMD_SHUTDOWN
        CMD_PS
        ;;
    restart)
        CMD_SHUTDOWN
        CMD_START
        CMD_PS
        ;;
    login)
        CMD_LOGIN
        ;;
    ps)
        CMD_PS
        ;;
    tail)
        CMD_TAIL
        ;;
    *)
        USAG
esac
EOF

# 添加执行权限
chmod +x /usr/sbin/redis-shell
```

- 启动redis
```shell
redis-shell start 6381

root@node1:/data# redis-shell start 6381
645935:C 15 Jun 2021 14:09:27.780 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
645935:C 15 Jun 2021 14:09:27.780 # Redis version=6.2.4, bits=64, commit=00000000, modified=0, pid=645935, just started
645935:C 15 Jun 2021 14:09:27.780 # Configuration loaded
645935:M 15 Jun 2021 14:09:27.781 * Increased maximum number of open files to 10032 (it was originally set to 1024).
645935:M 15 Jun 2021 14:09:27.782 * monotonic clock: POSIX clock_gettime
645935:M 15 Jun 2021 14:09:27.782 * Node configuration loaded, I'm 798c1d1a51ceb0c881365ed6e29426fe40f12889
                _._                                                  
           _.-``__ ''-._                                             
      _.-``    `.  `_.  ''-._           Redis 6.2.4 (00000000/0) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._                                  
 (    '      ,       .-`  | `,    )     Running in cluster mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6381
 |    `-._   `._    /     _.-'    |     PID: 645935
  `-._    `-._  `-./  _.-'    _.-'                                   
 |`-._`-._    `-.__.-'    _.-'_.-'|                                  
 |    `-._`-._        _.-'_.-'    |           https://redis.io       
  `-._    `-._`-.__.-'_.-'    _.-'                                   
 |`-._`-._    `-.__.-'    _.-'_.-'|                                  
 |    `-._`-._        _.-'_.-'    |                                  
  `-._    `-._`-.__.-'_.-'    _.-'                                   
      `-._    `-.__.-'    _.-'                                       
          `-._        _.-'                                           
              `-.__.-'                                               

645935:M 15 Jun 2021 14:09:27.783 # Server initialized
645935:M 15 Jun 2021 14:09:27.783 * Ready to accept connections
root      645928  628744  0 14:09 pts/0    00:00:00 /bin/bash /usr/sbin/redis-shell start 6381
root      645935  645928  0 14:09 pts/0    00:00:00 redis-server *:6381 [cluster]
root      645937  645928  0 14:09 pts/0    00:00:00 grep redis


# 告警处理
639921:M 15 Jun 2021 12:47:15.016 # WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
639921:M 15 Jun 2021 12:47:15.017 * Ready to accept connections

## 在主机上执行（临时生效）
sysctl vm.overcommit_memory=1
```

- 初始化集群
```shell
# 创建集群
redis-cli -a 1234 --cluster create 10.0.0.23:6381 10.0.0.24:6381 10.0.0.25:6381 10.0.0.24:6382 10.0.0.25:6382 10.0.0.23:6382 --cluster-replicas 1
# 需要输入yes

# 执行过程
root@node1:/data# redis-cli -a 1234 --cluster create 10.0.0.23:6381 10.0.0.24:6381 10.0.0.25:6381 10.0.0.24:6382 10.0.0.25:6382 10.0.0.23:6382 --cluster-replicas 1
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 10.0.0.24:6382 to 10.0.0.23:6381
Adding replica 10.0.0.25:6382 to 10.0.0.24:6381
Adding replica 10.0.0.23:6382 to 10.0.0.25:6381
M: 798c1d1a51ceb0c881365ed6e29426fe40f12889 10.0.0.23:6381
   slots:[0-5460] (5461 slots) master
M: bbae0daeaae4ab1b23e50dc8cae954157b844c38 10.0.0.24:6381
   slots:[5461-10922] (5462 slots) master
M: a5d43a738fe11ea277396d6402b2c766ccd51d6d 10.0.0.25:6381
   slots:[10923-16383] (5461 slots) master
S: 441720afb4fefa753f009756d735da21acf745c4 10.0.0.24:6382
   replicates 798c1d1a51ceb0c881365ed6e29426fe40f12889
S: aa1852a5a845aaefc89a5a0ad38bfa8bd1e29af1 10.0.0.25:6382
   replicates bbae0daeaae4ab1b23e50dc8cae954157b844c38
S: cbf05527126a751d6e555e7e613e40cb754d645d 10.0.0.23:6382
   replicates a5d43a738fe11ea277396d6402b2c766ccd51d6d
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
645935:M 15 Jun 2021 14:18:20.058 # configEpoch set to 1 via CLUSTER SET-CONFIG-EPOCH
645949:M 15 Jun 2021 14:18:20.060 # configEpoch set to 6 via CLUSTER SET-CONFIG-EPOCH
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
.
645935:M 15 Jun 2021 14:18:22.065 * Replica 10.0.0.24:6382 asks for synchronization
645935:M 15 Jun 2021 14:18:22.065 * Partial resynchronization not accepted: Replication ID mismatch (Replica asked for 'e13c2390bc99f973a8bff560aabf95476167cf4d', my replication IDs are '63e6ac59e4587eaf3effacf8e56b8f60c9fb6a6c' and '0000000000000000000000000000000000000000')
645935:M 15 Jun 2021 14:18:22.065 * Replication backlog created, my new replication IDs are 'ab28d5e57051ccc5c5ea453eb58efa58ae20dc6b' and '0000000000000000000000000000000000000000'
645935:M 15 Jun 2021 14:18:22.065 * Starting BGSAVE for SYNC with target: disk
645949:S 15 Jun 2021 14:18:22.065 * Before turning into a replica, using my own master parameters to synthesize a cached master: I may be able to synchronize with the new master with just a partial transfer.
645949:S 15 Jun 2021 14:18:22.065 * Connecting to MASTER 10.0.0.25:6381
645949:S 15 Jun 2021 14:18:22.065 * MASTER <-> REPLICA sync started
645949:S 15 Jun 2021 14:18:22.065 # Cluster state changed: ok
645935:M 15 Jun 2021 14:18:22.065 * Background saving started by pid 646683
645949:S 15 Jun 2021 14:18:22.066 * Non blocking connect for SYNC fired the event.
645949:S 15 Jun 2021 14:18:22.066 * Master replied to PING, replication can continue...
645949:S 15 Jun 2021 14:18:22.066 * Trying a partial resynchronization (request 9f3decc36a148984cbd7dfde24ce276f10da4527:1).
645949:S 15 Jun 2021 14:18:22.067 * Full resync from master: 69e6ccf0a33f0aabbe0c500a84526130753ed13c:0
645949:S 15 Jun 2021 14:18:22.067 * Discarding previously cached master state.
646683:C 15 Jun 2021 14:18:22.067 * DB saved on disk
646683:C 15 Jun 2021 14:18:22.068 * RDB: 0 MB of memory used by copy-on-write
>>> Performing Cluster Check (using node 10.0.0.23:6381)
M: 798c1d1a51ceb0c881365ed6e29426fe40f12889 10.0.0.23:6381
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 441720afb4fefa753f009756d735da21acf745c4 10.0.0.24:6382
   slots: (0 slots) slave
   replicates 798c1d1a51ceb0c881365ed6e29426fe40f12889
M: a5d43a738fe11ea277396d6402b2c766ccd51d6d 10.0.0.25:6381
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: aa1852a5a845aaefc89a5a0ad38bfa8bd1e29af1 10.0.0.25:6382
   slots: (0 slots) slave
   replicates bbae0daeaae4ab1b23e50dc8cae954157b844c38
S: cbf05527126a751d6e555e7e613e40cb754d645d 10.0.0.23:6382
   slots: (0 slots) slave
   replicates a5d43a738fe11ea277396d6402b2c766ccd51d6d
M: bbae0daeaae4ab1b23e50dc8cae954157b844c38 10.0.0.24:6381
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
root@node1:/data# 645935:M 15 Jun 2021 14:18:22.096 * Background saving terminated with success
645935:M 15 Jun 2021 14:18:22.096 * Synchronization with replica 10.0.0.24:6382 succeeded
645949:S 15 Jun 2021 14:18:22.166 * MASTER <-> REPLICA sync: receiving 175 bytes from master to disk
645949:S 15 Jun 2021 14:18:22.166 * MASTER <-> REPLICA sync: Flushing old data
645949:S 15 Jun 2021 14:18:22.166 * MASTER <-> REPLICA sync: Loading DB in memory
645949:S 15 Jun 2021 14:18:22.167 * Loading RDB produced by version 6.2.4
645949:S 15 Jun 2021 14:18:22.167 * RDB age 0 seconds
645949:S 15 Jun 2021 14:18:22.167 * RDB memory usage when created 2.59 Mb
645949:S 15 Jun 2021 14:18:22.167 * MASTER <-> REPLICA sync: Finished with success
645949:S 15 Jun 2021 14:18:22.167 * Background append only file rewriting started by pid 646684
645949:S 15 Jun 2021 14:18:22.190 * AOF rewrite child asks to stop sending diffs.
646684:C 15 Jun 2021 14:18:22.190 * Parent agreed to stop sending diffs. Finalizing AOF...
646684:C 15 Jun 2021 14:18:22.190 * Concatenating 0.00 MB of AOF diff received from parent.
646684:C 15 Jun 2021 14:18:22.190 * SYNC append only file rewrite performed
646684:C 15 Jun 2021 14:18:22.191 * AOF rewrite: 0 MB of memory used by copy-on-write
645949:S 15 Jun 2021 14:18:22.208 * Background AOF rewrite terminated with success
645949:S 15 Jun 2021 14:18:22.208 * Residual parent diff successfully flushed to the rewritten AOF (0.00 MB)
645949:S 15 Jun 2021 14:18:22.208 * Background AOF rewrite finished successfully
645935:M 15 Jun 2021 14:18:25.009 # Cluster state changed: ok


# 验证集群
# 随意登录一个节点
redis-shell login 6381

CLUSTER NODES
CLUSTER INFO
```

### redis-cluster-proxy
- 安装proxy
```shell
# 拉取redis-cluster-proxy源码包
git clone https://github.com/artix75/redis-cluster-proxy

cd redis-cluster-proxy

# 安装gcc 5.0+ 以上得版本
gcc -v 
```

- 编译安装
```shell
# 编译hiredis
cd /root/redis-cluster-proxy/deps/hiredis && make

# 编译 redis-cluster-proxy
cd /root/redis-cluster-proxy/ && make

# 安装 redis-cluster-proxy（可自定义安装目录）
make install PREFIX=/data/redis_proxy/proxy

# 复制配置文件到次安装目录
cp /root/redis-cluster-proxy/proxy.conf /data/redis_proxy/proxy/
```

- 配置文件
```shell
vim /data/redis_proxy/proxy/proxy.conf

# redis cluster集群自身节点信息，这里是3主3从的6个节点

cluster 10.0.0.23:6381
cluster 10.0.0.23:6382
cluster 10.0.0.24:6381
cluster 10.0.0.24:6382
cluster 10.0.0.25:6381
cluster 10.0.0.25:6382

port 7777    ## redis-cluster-proxy 端口号指定

bind 10.0.0.23   ## IP地址绑定，这里指定为redis-proxy-cluster所在节点的IP地址

threads 8            ## 线程数量


## 连接池配置
daemonize yes   # 运行模式，一开始最好指定为no，运行时直接打印出来启动日志或者异常信息，这样可以方便地查看启动异常

#logfile ""   # 日志文件指定，如果可以正常启动，强烈建议指定一个输出日志文件，所有的运行异常或者错误都可以从日志中查找
logfile "/var/log/redis-cluster-proxy.log"

enable-cross-slot yes    # 跨slot操作，这里设置为yes，允许

# max-clients 10000      # 最大客户端连接数

# auth mypassw
auth 1234     # 连接到redis cluster时候的身份认证，如果redis集群节点设置了身份认证的话，强烈建议redis集群所有节点设置一个统一的auth

log-level error
```

- 启动redis-cluster-proxy

```shell
/data/redis_proxy/proxy/bin/redis-cluster-proxy -c /data/redis_proxy/proxy/proxy.conf
```


## redis单机部署
```shell
# 安装
apt install redis

# 修改配置
vim /etc/redis/redis.conf
bind 0.0.0.0
protected-mode no     # 开启远程访问
requirepass 1234
masterauth 1234

systemctl daemon-reload
systemctl restart redis.service
```


## redis-benchmark

- redis集群随意入口
```shell
root@node2:~# redis-benchmark -a 1234 --cluster -h 10.0.0.23 -p 6381 -c 100 -n 100000 -q
Cluster has 3 master nodes:

Master 0: 6053fdef8849decfc3637f40f291410cc7f90b98 10.0.0.25:6381
Master 1: 2ff815b15d46db067e59a8afd67ee24fdc6ff1f9 10.0.0.24:6381
Master 2: 5c5cf78847ae578030b8b132f2fd6d08ec064553 10.0.0.23:6381

PING_INLINE: 199600.80 requests per second, p50=0.207 msec                    
PING_MBULK: 199600.80 requests per second, p50=0.199 msec                    
SET: 199600.80 requests per second, p50=0.231 msec                    
GET: 199600.80 requests per second, p50=0.207 msec                    
INCR: 199600.80 requests per second, p50=0.231 msec                    
LPUSH: 199600.80 requests per second, p50=0.239 msec                    
RPUSH: 199600.80 requests per second, p50=0.263 msec                    
LPOP: 199203.20 requests per second, p50=0.231 msec                    
RPOP: 199600.80 requests per second, p50=0.239 msec                        
SADD: 199600.80 requests per second, p50=0.215 msec                    
HSET: 199203.20 requests per second, p50=0.247 msec                    
SPOP: 199600.80 requests per second, p50=0.231 msec                    
ZADD: 199600.80 requests per second, p50=0.231 msec                    
ZPOPMIN: 199600.80 requests per second, p50=0.247 msec                  
LPUSH (needed to benchmark LRANGE): 199203.20 requests per second, p50=0.247 msec                    
LRANGE_100 (first 100 elements): 99800.40 requests per second, p50=0.495 msec                        
LRANGE_300 (first 300 elements): 39888.31 requests per second, p50=1.183 msec                   
LRANGE_500 (first 500 elements): 26518.17 requests per second, p50=1.863 msec                   
LRANGE_600 (first 600 elements): 22109.22 requests per second, p50=2.255 msec                   
MSET (10 keys): 132100.39 requests per second, p50=0.447 msec                        
```

- 单机redis
```shell
root@node2:~# redis-benchmark -a 1234 -h 10.0.0.23 -p 6379 -c 100 -n 100000 -q
PING_INLINE: 108695.65 requests per second, p50=0.495 msec                    
PING_MBULK: 93023.25 requests per second, p50=0.567 msec                   
SET: 97751.71 requests per second, p50=0.559 msec                    
GET: 113250.28 requests per second, p50=0.463 msec                    
INCR: 97656.24 requests per second, p50=0.551 msec                    
LPUSH: 92936.80 requests per second, p50=0.583 msec                   
RPUSH: 94517.96 requests per second, p50=0.559 msec                   
LPOP: 93283.58 requests per second, p50=0.559 msec                   
RPOP: 90909.09 requests per second, p50=0.583 msec                   
SADD: 97656.24 requests per second, p50=0.551 msec                    
HSET: 96711.80 requests per second, p50=0.559 msec                    
SPOP: 94428.70 requests per second, p50=0.559 msec                   
ZADD: 91407.68 requests per second, p50=0.575 msec                   
ZPOPMIN: 93984.96 requests per second, p50=0.583 msec                   
LPUSH (needed to benchmark LRANGE): 96246.39 requests per second, p50=0.559 msec                    
LRANGE_100 (first 100 elements): 45289.86 requests per second, p50=1.127 msec                   
LRANGE_300 (first 300 elements): 17346.05 requests per second, p50=2.935 msec                   
LRANGE_500 (first 500 elements): 11781.34 requests per second, p50=4.359 msec                   
LRANGE_600 (first 600 elements): 10197.84 requests per second, p50=5.071 msec                   
MSET (10 keys): 90171.33 requests per second, p50=0.623 msec                   
```

- redis-proxy
```shell
root@node2:~# redis-benchmark  -h 10.0.0.23 -p 7777 -c 100 -n 100000 -q
ERROR: ERR unsupported command `config`
ERROR: failed to fetch CONFIG from 10.0.0.23:7777
WARN: could not fetch server CONFIG
PING_INLINE: 103412.62 requests per second, p50=0.527 msec                    
PING_MBULK: 124533.01 requests per second, p50=0.447 msec                    
SET: 109890.11 requests per second, p50=0.559 msec                    
GET: 100908.17 requests per second, p50=0.575 msec                    
INCR: 97465.88 requests per second, p50=0.631 msec                    
LPUSH: 117233.30 requests per second, p50=0.535 msec                    
RPUSH: 92336.11 requests per second, p50=0.631 msec                   
LPOP: 96153.85 requests per second, p50=0.615 msec                    
RPOP: 91743.12 requests per second, p50=0.623 msec                   
SADD: 91407.68 requests per second, p50=0.607 msec                   
HSET: 92421.44 requests per second, p50=0.647 msec                   
SPOP: 92678.41 requests per second, p50=0.599 msec                   
ZADD: 90415.91 requests per second, p50=0.623 msec                   
ZPOPMIN: 91491.30 requests per second, p50=0.607 msec                   
LPUSH (needed to benchmark LRANGE): 92936.80 requests per second, p50=0.631 msec                   
LRANGE_100 (first 100 elements): 47915.67 requests per second, p50=1.207 msec                   
LRANGE_300 (first 300 elements): 17510.07 requests per second, p50=3.047 msec                   
LRANGE_500 (first 500 elements): 12030.80 requests per second, p50=4.439 msec                   
LRANGE_600 (first 600 elements): 10388.53 requests per second, p50=5.159 msec                   
MSET (10 keys): 89525.52 requests per second, p50=0.807 msec 
```

## redis 参数优化

- 取消持久化
```shell
# 临时
config set save ""

# 永久
vim /etc/redis.conf
save ""
# save 3600 1
# save 300 100
# save 60 10000
```

- 慢查询分析
> 参考：https://blog.csdn.net/qianghaohao/article/details/81052461
```shell
# 配置
config set slowlog-log-slower-than 10000
config set slowlog-max-len 1000

# 获取慢查询
slowlog get [n]
# 可以通过参数 n 指定查看条数

# 获取当前慢查询日志记录数
slowlog len

# 慢查询日志重置
slowlog reset
```

## 告警处理

- WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
```shell
$ vim /etc/sysctl.conf
vm.overcommit_memory = 1

$ sysctl vm.overcommit_memory=1
```