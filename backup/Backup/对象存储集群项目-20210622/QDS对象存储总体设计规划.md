## QDS对象存储总体设计规划

### 1. 物理机信息

- 对象存储节点

```shell
# 单节点硬件配置，共计三台
CPU：Intel Xeon Silver 4214R 2.40GHz 24C/40T *2
内存：128G
系统盘：Intel S4510 480GB SSD *1
缓存盘：SAMSUNG 1.5TB NVMe *1
数据盘：Toshiba 2.0TB SATA HDD *7
网卡：Intel X520-DA2 10GB（2光口）
```


- 压力测试节点

```shell
# 测试工具cosbench
CPU：Intel Xeon E5-2620 v3 2.40GHz 12C/24T *2
内存：64G
系统盘：Intel S4510 240GB SSD *1
网卡：Intel X520-DA2 10GB（2光口）
```


### 2. 主机规划
| Host  | 管理网      | 存储业务网 | Ceph存储网 | 部署服务                                                     |
| ----- | ----------- | ---------- | ---------- | ------------------------------------------------------------ |
| node1 | 172.16.1.23 | 10.0.0.23  | 10.0.1.23  | docker、docker-compose、redis-cluster、redis-proxy、tidb、ceph、yig、nginx |
| node2 | 172.16.1.24 | 10.0.0.24  | 10.0.1.24  | docker、docker-compose、redis-cluster、tidb、ceph、yig、haproxy |
| node3 | 172.16.1.25 | 10.0.0.25  | 10.0.1.25  | docker、docker-compose、redis-cluster、tidb、ceph、yig、haproxy |
| Test  | 172.16.1.21 | 10.0.0.21  |            | cosbench                                                     |



### 3. 端口规划

| 主机  | 组件                | 默认端口    | 修改后端口 | 说明   |
| ----- | ------------------- | ----------- | ---------- | ------ |
| node1 | ceph mon            | 6789        | -          | 默认   |
|       | ceph metrics        | 9283        | -          | 默认   |
|       | ceph dashboard      | -           | 8081       | 自定义 |
|       | redis-cluster       | -           | 6381/6382  | 自定义 |
|       | redis-proxy         | 7777        | 6379       | 自定义 |
|       | tipd                | 2379/2380   | -          | 默认   |
|       | tikv                | 20160       | -          | 默认   |
|       | tidb                | 4000/10080  | -          | 默认   |
|       | zookeeper           | 2181        | -          | 默认   |
|       | kafka               | 9092        | -          | 默认   |
|       | yig                 | 8480/9480   | -          | 默认   |
|       | nginx               | -           | 8080       | 自定义 |
|       | WebUi               | -           | 8082       | 自定义 |
|       | prometheous         | 9090        | -          | 默认   |
|       | grafana             | 3000        | -          | 默认   |
|       | node-exporter       | 9100        | 19100      | 自定义 |
|       | cadvisor            | 8080        | 18100      | 自定义 |
|       |                     |             |            |        |
| node2 | ceph mon            | 6789        | -          | 默认   |
|       | ceph metrics        | 9283        | -          | 默认   |
|       | ceph dashboard      | -           | 8081       | 自定义 |
|       | redis-cluster       | -           | 6381/6382  | 自定义 |
|       | redis-proxy         | 7777        | 6379       | 自定义 |
|       | tipd                | 2379/2380   | -          | 默认   |
|       | tikv                | 20160       | -          | 默认   |
|       | tidb                | 4000/10080  | -          | 默认   |
|       | zookeeper           | 2181        | -          | 默认   |
|       | kafka               | 9092        | -          | 默认   |
|       | yig                 | 8480/9480   | -          | 默认   |
|       | haproxy             | 8888        | -          | 默认   |
|       | haproxy-yig         | -           | 8479       | 自定义 |
|       | node-exporter       | 9100        | 19100      | 自定义 |
|       | cadvisor            | 8080        | 18100      | 自定义 |
|       |                     |             |            |        |
| node3 | ceph mon            | 6789        | -          | 默认   |
|       | ceph metrics        | 9283        | -          | 默认   |
|       | ceph dashboard      | -           | 8081       | 自定义 |
|       | redis-cluster       | -           | 6381/6382  | 自定义 |
|       | redis-proxy         | 7777        | 6379       | 自定义 |
|       | tipd                | 2379/2380   | -          | 默认   |
|       | tikv                | 20160       | -          | 默认   |
|       | tidb                | 4000/10080  | -          | 默认   |
|       | zookeeper           | 2181        | -          | 默认   |
|       | kafka               | 9092        | -          | 默认   |
|       | yig                 | 8480/9480   | -          | 默认   |
|       | haproxy             | 8888        | -          | 默认   |
|       | haproxy-tidb        | -           | 4400       | 自定义 |
|       | node-exporter       | 9100        | 19100      | 自定义 |
|       | cadvisor            | 8080        | 18100      | 自定义 |
|       |                     |             |            |        |
| Test  | cosbench-controller | 19089       |            | 默认   |
|       | cosbench-driver     | 18088/18089 |            | 默认   |



### 4. 组件版本

| No.  | Type       | Name                | Release           | Deploy mode      |
| ---- | ---------- | ------------------- | ----------------- | ---------------- |
| 1    | OS         | ubuntu server       | 20.04.2 LTS       | physical-single  |
| 2    | container  | docker              | docker-ec-20.10.7 | physical-single  |
| 3    | container  | docker-compose      | 1.27.4            | physical-single  |
| 4    | storage    | ceph                | 15.2.11           | physical-cluster |
| 5    | cache      | redis               | 6.2.4(or 5.0)     | physical-cluster |
| 6    | cache      | redis-cluster-proxy | 0.9.102           | physical-single  |
| 7    | database   | tidb                | 1.5.1             | physical-cluster |
| 8    | mq         | kafka               | 2.8.0             | physical-cluster |
| 9    | register   | zookeeper           | 3.7               | physical-cluster |
| 10   | tools      | java                | 1.8.0_292         | physical-single  |
| 11   | tools      | haproxy             | 2.0.13            | physical-single  |
| 12   | tools      | nginx               | 1.18              | physical-single  |
| 13   | s3gateway  | qcos-s3             | 1.3               | physical-single  |
| 14   | WebUI      | qcos-web            | 1.3               | physical-single  |
| 15   | monitor    | prometheous         | 2.28              | container-single |
| 16   | monitor    | grafana             | 7.5.7             | container-single |
| 17   | Test tools | Cosbench            | 0.4.2.c4          | physical-cluster |
| 18   | DNS        | dnsmasq             | 2.7.6             | physical-cluster |


### 5. 部署方法

- 部署步骤

```shell
# 安装操作系统并调优，初始化磁盘和目录
# 部署docker和docker-compose
# 部署ceph集群
# 部署redis集群和redis-proxy
# 部署tidb集群
# 部署java
# 部署kafka和zookeeper集群
# 部署yig
# 部署haproxy
# 部署prometheous和grafana，监控组件node-exporter和cadvisor

# 部署测试工具cosbench
# 部署dnsmasq

# 部署nginx
# 部署webUI
```


- 部署注意事项：

```shell
# 内网部署，提前下载好安装包和制作源（apt）,制作后打包成docker镜像
# 
```

### 5. 系统优化
以下过程都在ubuntu 20.04 server 上验证过。

- 关闭swap


- 文件描述符
```shell
cat >> /etc/security/limits.conf << EOF
* soft nofile 2048576
* hard nofile 2048576
root soft nofile 2048576
root hard nofile 2048576
* soft nproc 80480
* hard nproc 80960
root soft nproc 80480
root hard nproc 80960
EOF

echo 'DefaultLimitNOFILE=2048576' | sudo tee -a /etc/systemd/user.conf
echo 'DefaultLimitNOFILE=2048576' | sudo tee -a /etc/systemd/system.conf 

echo 'fs.nr_open = 10000000' | sudo tee -a /etc/sysctl.conf

sysctl -p
```

- 关闭系统透明大页
```shell
# 临时生效
cat /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# 永久生效
# 新建一个服务
cat > /etc/systemd/system/disable-thp.service <<-"EOF"
[Unit]
Description=Disable Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start disable-thp
systemctl enable disable-thp
```

- 高并发内核优化
```shell

fs.file-max = 999999
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 600
```

- 