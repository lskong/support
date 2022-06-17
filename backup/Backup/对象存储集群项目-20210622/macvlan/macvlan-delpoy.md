
## macVlan-docker

### 1. 环境
```shell
# node4
eno0,千兆网卡，172.16.1.26/16（管理网）
enp5s0f0，万兆网卡，10.0.0.26/24（业务网，docker数据网）

# node5
eno0,千兆网卡，172.16.1.27/16（管理网）
enp5s0f0，万兆网卡，10.0.0.27/24（业务网，docker数据网）

# node6
eno0,千兆网卡，172.16.1.28/16（管理网）
enp5s0f0，万兆网卡，10.0.0.28/24（业务网，docker数据网）
```


### 2. 设置网卡混杂模式
```shell
# 查看enp5sf0网卡模式
root@node5:~# ip a |grep enp5s0f0
6: enp5s0f0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    inet 10.0.0.27/24 brd 10.0.0.255 scope global enp5s0f0

# 没有开启混杂模式 <BROADCAST,MULTICAST,UP,LOWER_UP>

# 开启混杂模式
ip link set enp5s0f0 promisc on

# 验证
root@node5:~# ip a |grep enp5s0f0
6: enp5s0f0: <BROADCAST,MULTICAST,PROMISC,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    inet 10.0.0.27/24 brd 10.0.0.255 scope global enp5s0f0

# 每个node都执行
```

### 3. 创建macvlan网络
```shell
# 创建macvlan
docker network create --driver macvlan --subnet 10.0.0.0/24 --gateway 10.0.0.1 -o parent=enp5s0f0 macvlan10
# --subnet掩码和--gateway要于宿主机一致

# 宿主机多网卡情况下，如果10.0.0.0/24没有网关，--gateway可以不指定，但最好指定哪怕是虚拟的。

# 查看网络
docker network ls
# 每个node执行
```

### 4. 测试macvlan
```shell
# 指定IP地址运行容器
docker run -it -d --name bs100 --net macvlan10 --ip 10.0.0.101 busybox
docker run -it -d --name bs100 --net macvlan10 --ip 10.0.0.102 busybox
docker run -it -d --name bs100 --net macvlan10 --ip 10.0.0.103 busybox

# 进入容器测试
docker exec -it bs100 sh

/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
27378: eth0@if6: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue 
    link/ether 02:42:0a:00:00:65 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.101/24 brd 10.0.0.255 scope global eth0
       valid_lft forever preferred_lft forever

/ # ping 10.0.0.102
PING 10.0.0.102 (10.0.0.102): 56 data bytes
64 bytes from 10.0.0.102: seq=0 ttl=64 time=0.313 ms
64 bytes from 10.0.0.102: seq=1 ttl=64 time=0.300 ms
64 bytes from 10.0.0.102: seq=2 ttl=64 time=0.266 ms
64 bytes from 10.0.0.102: seq=3 ttl=64 time=0.236 ms

# 删除容器
docker rm -f bs100

# 暴露端口测试
docker run -it -d --name nginx1 --net macvlan10 --ip 10.0.0.101 nginx
# nginx默认80端口，容器到容器telnet。
# 也可以从非宿主机的任何一台网络通的物理机telnet测试。注意是：“非宿主机”

# 默认情况下

```

### 5. 宿主机与容器网络联通
- 解决办法
```
https://docs.docker.com/network/macvlan/

1. When using macvlan, you cannot ping or communicate with the default namespace IP address. For example, if you create a container and try to ping the Docker host’s eth0, it will not work. 
That traffic is explicitly filtered by the kernel modules themselves to offer additional provider isolation and security.

2. A macvlan subinterface can be added to the Docker host, to allow traffic between the Docker host and containers. The IP address needs to be set on this subinterface and removed from the parent address.

# --aux-address -> This will prevent Docker from assigning that address to a container.
docker network create -d macvlan -o parent=ens39 \
  --subnet 192.168.4.0/24 \
  --gateway 192.168.4.1 \
  --ip-range 192.168.4.0/24 \
  --aux-address 'host=192.168.4.199' \
  aiotest

# 在HOST上创建一个macvlan的子网卡
sudo ip link add macnet01 link ens39 type macvlan mode bridge

# 给子网卡配置IP地址，并且添加路由
sudo ip addr add 192.168.4.199/32 dev macnet01
sudo ip link set macnet01 up
sudo ip route add 192.168.4.0/24 dev macnet01
sudo ip route del 192.168.4.0/24 dev ens39
```

#!/bin/bash

sudo ip link set vLAN down
sudo ip addr del 10.0.0.254/24 brd + dev vLAN
sudo ip link del link enp5s0f0 vLAN type macvlan mode bridge

sudo ip link add link enp5s0f0 vLAN type macvlan mode bridge
sudo ip addr add 10.0.0.254/24 brd + dev vLAN
sudo ip link set vLAN up

ip route add 10.0.0.90 dev vLAN
ip route add 10.0.0.104 dev vLAN
ip route add 10.0.0.121 dev vLAN
ip route add 10.0.0.117 dev vLAN


docker network create --driver ipvlan --subnet 10.0.0.0/24 -o parent=enp5s0f0 ipvlan10


sudo ip link add macnet01 link ens2f0 type macvlan mode bridge
sudo ip addr add 10.0.0.253/32 dev macnet01
sudo ip link set macnet01 up
ip route add 10.0.0.0/24 dev macnet01
ip route add 10.0.0.70 dev macnet01
ip route add 10.0.0.71 dev macnet01
ip route add 10.0.0.72 dev macnet01
ip route add 10.0.0.73 dev macnet01
ip route add 10.0.0.74 dev macnet01
ip route add 10.0.0.75 dev macnet01
ip route add 10.0.0.76 dev macnet01
ip route add 10.0.0.77 dev macnet01
ip route add 10.0.0.78 dev macnet01
ip route add 10.0.0.79 dev macnet01

sudo ip link add macnet01 link ens2f0 type macvlan mode bridge
sudo ip addr add 10.0.0.252/32 dev macnet01
sudo ip link set macnet01 up
ip route add 10.0.0.60 dev macnet01
ip route add 10.0.0.61 dev macnet01
ip route add 10.0.0.62 dev macnet01
ip route add 10.0.0.63 dev macnet01
ip route add 10.0.0.64 dev macnet01
ip route add 10.0.0.65 dev macnet01
ip route add 10.0.0.66 dev macnet01
ip route add 10.0.0.67 dev macnet01
ip route add 10.0.0.68 dev macnet01
ip route add 10.0.0.69 dev macnet01

sudo ip link add macnet01 link ens2f0 type macvlan mode bridge
sudo ip addr add 10.0.0.251/32 dev macnet01
sudo ip link set macnet01 up
ip route add 10.0.0.50 dev macnet01
ip route add 10.0.0.51 dev macnet01
ip route add 10.0.0.52 dev macnet01
ip route add 10.0.0.53 dev macnet01
ip route add 10.0.0.54 dev macnet01
ip route add 10.0.0.55 dev macnet01
ip route add 10.0.0.56 dev macnet01
ip route add 10.0.0.57 dev macnet01
ip route add 10.0.0.58 dev macnet01
ip route add 10.0.0.59 dev macnet01
