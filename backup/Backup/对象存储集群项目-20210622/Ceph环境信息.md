## Ceph对象存储环境信息

### 1. 物理机信息
```shell
# 七台品牌Dell的物理主机；分别有：三台R740部署ceph集群，三台R720部署yig的相关网关组件，一台R730部署cosbench。

# 物理机硬件配置
【R740】--->ceph集群
CPU：Intel Xeon Silver 4214R 2.40GHz 24C/40T *2
内存：128G
系统盘：Intel S4510 480GB SSD *1
缓存盘：SAMSUNG 1.5TB NVMe *1
数据盘：Toshiba 2.0TB SATA HDD *7
网卡：Intel X520-DA2 10GB（2光口）


【R720】--->各组件
CPU：Intel Xeon E5-2680 v2 2.80GHz 20C/40T *2
内存：128G
系统盘：SAMSUNG 250GB SSD *1
数据盘：Intel S4510 480GB SSD *1
数据盘tikv：1TB SSD M.2转pcie
网卡：Intel X520-DA2 10GB（2光口）


【R730】--->cosbench
CPU：Intel Xeon E5-2620 v3 2.40GHz 12C/24T *2
内存：64G
系统盘：Intel S4510 240GB SSD *1
数据盘：-
网卡：Intel X520-DA2 10GB（2光口）
```


### 2. 主机规划
| 主机型号 | Host      | 管理网      | 存储业务网 | Ceph存储网 | 系统        | 部署服务               |
| -------- | --------- | ----------- | ---------- | ---------- | ----------- | ---------------------- |
| R730     | ceph-test | 172.16.1.21 | 10.0.0.21  |            | centos7     | cosbench               |
| R740     | node1     | 172.16.1.23 | 10.0.0.23  | 10.0.1.23  | ubuntu20.04 | ceph、radosgw、yig     |
| R740     | node2     | 172.16.1.24 | 10.0.0.24  | 10.0.1.24  | ubuntu20.04 | ceph、radosgw、yig     |
| R740     | node3     | 172.16.1.25 | 10.0.0.25  | 10.0.1.25  | ubuntu20.04 | ceph、radosgw、yig     |
| R720     | node4     | 172.16.1.26 | 10.0.0.26  |            | ubuntu20.04 | kakfka+zk、redis、tidb |
| R720     | node5     | 172.16.1.27 | 10.0.0.27  |            | ubuntu20.04 | kakfka+zk、redis、tidb |
| R720     | node6     | 172.16.1.28 | 10.0.0.28  |            | ubuntu20.04 | kakfka+zk、redis、tidb |


### 3. 端口规划

| 主机      | 组件          | 默认端口      | 修改后端口 | 说明                       |
| --------- | ------------- | ------------- | ---------- | -------------------------- |
| node1     | ceph mon      | 6789          | -          | 默认                       |
|           | ceph radosgw  | 7480          | -          | 保留                       |
|           | ceph radosgw  | 100001~100012 | -          | 追加12个端口给rgw s3做接口 |
|           | yig           | 8080          | -          | 默认                       |
|           |               |               |            |                            |
| node2     | ceph mon      | 6789          | -          | 默认                       |
|           | ceph radosgw  | 7480          | -          | 保留                       |
|           | ceph radosgw  | 100013~100024 | -          | 追加12个端口给rgw s3做接口 |
|           | yig           | 8080          | -          | 默认                       |
|           |               |               |            |                            |
| node3     | ceph mon      | 6789          | -          | 默认                       |
|           | ceph radosgw  | 7480          | -          | 保留                       |
|           | ceph radosgw  | 100026~100036 | -          | 追加12个端口给rgw s3做接口 |
|           | yig           | 8080          | -          | 默认                       |
|           |               |               |            |                            |
| node4     | zookeeper     | 2181          | -          | 默认                       |
|           | kafka         | 9092          | -          | 默认                       |
|           | kafka-managre | 9000          | 9099       | 给其它端口让位             |
|           | redis-单机    | 6379          | -          | 默认                       |
|           | redis-集群    | 6379          | 6381~6382  | 主从                       |
|           | tidb-pd       | 2379          | -          | 默认                       |
|           |               | 2380          | -          | 默认                       |
|           | tidb-kv       | 20160         | -          | 默认                       |
|           | tidb-db       | 4000          | -          | 默认                       |
|           |               | 10080         | -          | 默认                       |
|           | haproxy-tidb  | 4000          | 4040       | 不与tidb-db冲突            |
|           |               |               |            |                            |
| node5     | zookeeper     | 2181          | -          | 默认                       |
|           | kafka         | 9092          | -          | 默认                       |
|           | redis-集群    | 6379          | 6383~6384  | 主从                       |
|           | tidb-pd       | 2379          | -          | 默认                       |
|           |               | 2380          | -          | 默认                       |
|           | tidb-kv       | 20160         | -          | 默认                       |
|           | tidb-db       | 4000          | -          | 默认                       |
|           |               | 10080         | -          | 默认                       |
|           | haproxy-yig   | 8080          | 8088       | 不与yig本身冲突            |
|           |               |               |            |                            |
| node6     | zookeeper     | 2181          | -          | 默认                       |
|           | kafka         | 9092          | -          | 默认                       |
|           | redis-集群    | 6379          | 6385~6386  | 主从                       |
|           | tidb-pd       | 2379          | -          | 默认                       |
|           |               | 2380          | -          | 默认                       |
|           | tidb-kv       | 20160         | -          | 默认                       |
|           | tidb-db       | 4000          | -          | 默认                       |
|           |               | 10080         | -          | 默认                       |
|           | haproxy-rgw   | 7480          | -          | 默认，不修改               |
|           |               |               |            |                            |
| ceph-test | cosbench      | 19088         | -          | 默认                       |
|           |               | 18088         | -          | 默认                       |
|           |               |               | 18078      | 模拟第二个driver           |
|           |               |               | 18068      | 模拟第三个driver           |



### 4. 物理机部署


### 5. 容器部署
#### 5.1 容器部署规划

| 组件      | 容器名        | 容器IP     | 服务端口                                       | 宿主机(业务网)  | 宿主机资料目录 | 所属集群         |
| --------- | ------------- | ---------- | ---------------------------------------------- | --------------- | -------------- | ---------------- |
| yig       | yig           | 10.0.0.80  | 8080 s3<br />9000 http                         | node4 10.0.0.26 | /data/yig      |                  |
|           |               |            |                                                |                 |                |                  |
| haproxy   | haproxy       | 10.0.0.90  | 4000 tidb<br />6379 redis<br />8888 http_admin | node4 10.0.0.26 | /data/haproxy  |                  |
|           |               |            |                                                |                 |                |                  |
| zookeeper | zoo1          | 10.0.0.101 | 2181                                           | node4 10.0.0.26 | /data/kafka    | kafka cluster    |
|           | zoo2          | 10.0.0.102 | 2181                                           | node5 10.0.0.27 | /data/kafka    | kafka cluster    |
|           | zoo3          | 10.0.0.103 | 2181                                           | node6 10.0.0.28 | /data/kafka    | kafka cluster    |
| kafka     | kafka1        | 10.0.0.104 | 9092                                           | node4 10.0.0.26 | /data/kafka    | kafka cluster    |
|           | kafka2        | 10.0.0.105 | 9092                                           | node5 10.0.0.27 | /data/kafka    | kafka cluster    |
|           | kafka3        | 10.0.0.106 | 9092                                           | node6 10.0.0.28 | /data/kafka    | kafka cluster    |
|           | kafka-manager | 10.0.0.100 | 9000                                           | node4 10.0.0.26 | /data/kafka    | kafka cluster    |
|           |               |            |                                                |                 |                |                  |
| tidb      | pd1           | 10.0.0.111 | 2379/2380                                      | node4 10.0.0.26 | /data/tidb     | tidb cluster     |
|           | pd2           | 10.0.0.112 | 2379/2380                                      | node5 10.0.0.27 | /data/tidb     | tidb cluster     |
|           | pd3           | 10.0.0.113 | 2379/2380                                      | node6 10.0.0.28 | /data/tidb     | tidb cluster     |
|           | tikv1         | 10.0.0.114 | 20160                                          | node4 10.0.0.26 | /data/tidb     | tidb cluster     |
|           | tikv2         | 10.0.0.115 | 20160                                          | node5 10.0.0.27 | /data/tidb     | tidb cluster     |
|           | tikv3         | 10.0.0.116 | 20160                                          | node6 10.0.0.28 | /data/tidb     | tidb cluster     |
|           | tidb1         | 10.0.0.117 | 4000/10080                                     | node4 10.0.0.26 | /data/tidb     | tidb cluster     |
|           | tidb2         | 10.0.0.118 | 4000/10080                                     | node5 10.0.0.27 | /data/tidb     | tidb cluster     |
|           | tidb3         | 10.0.0.119 | 4000/10080                                     | node6 10.0.0.28 | /data/tidb     | tidb cluster     |
|           |               |            |                                                |                 |                |                  |
| redis     | redis-6381    | 10.0.0.121 | 6381                                           | node4 10.0.0.26 | /data/redis    | redis cluster 主 |
|           | redis-6382    | 10.0.0.122 | 6382                                           | node4 10.0.0.26 | /data/redis    | redis cluster 备 |
|           | redis-6383    | 10.0.0.123 | 6383                                           | node5 10.0.0.27 | /data/redis    | redis cluster 主 |
|           | redis-6384    | 10.0.0.124 | 6384                                           | node5 10.0.0.27 | /data/redis    | redis cluster 备 |
|           | redis-6385    | 10.0.0.125 | 6385                                           | node6 10.0.0.28 | /data/redis    | redis cluster 主 |
|           | redis-6385    | 10.0.0.126 | 6386                                           | node6 10.0.0.28 | /data/redis    | redis cluster 备 |


#### 5.2 容器组件部署顺序

```shell
1.docker/docker-compose
2.macvlan
3.redis
4.kafka+zk
5.tidb
6.haproxy
7.yig
```
