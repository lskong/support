## flannel部署

```shell
sudo apt install etcd-server etcd-client

susu@susu-pc:~$ sudo vim /etc/default/etcd

ETCD_DATA_DIR="/var/lib/etcd/default"
ETCD_LISTEN_CLIENT_URLS="http://192.168.4.99:2379"
ETCD_NAME="default"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.4.99:2379"

sudo systemctl restart etcd

# 写入子网信息
etcdctl --endpoint="http://192.168.4.99:2379" set /atomic.io/network/config '{"Network": "10.100.0.0/16", "Backend": {"Type": "vxlan"}}'

sudo apt install flannel

# host1上执行
sudo flannel -etcd-endpoints http://192.168.4.99:2379 -etcd-prefix /atomic.io/network -iface 192.168.4.99

# host2上执行
sudo flannel -etcd-endpoints http://192.168.4.99:2379 -etcd-prefix /atomic.io/network -iface 192.168.4.110

# 修改docker.service文件
sudo cp /lib/systemd/system/docker.service .
sudo vim /lib/systemd/system/docker.service

# 这个地址不是乱配的，flannel启动后，会生成一个虚拟的flannel网卡，这里需要跟其配成一直

susu@susu-pc:~$ ip a | grep flannel
6: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default
    inet 10.100.7.0/32 scope global flannel.1
    
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --bip=10.100.22.1/24 --ip-masq=true --mtu=1450

sudo systemctl daemon-reload
sudo systemctl restart docker


# 注意: host2上配置下不同子网，其实相同子网应该也无所谓
susu@desk001:~$ ip a | grep flannel
5: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default
    inet 10.100.22.0/32 scope global flannel.1

ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --bip=10.100.22.1/24 --ip-masq=true --mtu=1450



sudo docker run -it --name bs200 busybox
```