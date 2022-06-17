# dnsmasq podman



## 下载容器

```shell
sudo podman search dnsmasq
INDEX       NAME                                        DESCRIPTION                                       STARS   OFFICIAL   AUTOMATED
docker.io   docker.io/andyshinn/dnsmasq                 This repository has moved to https://hub.doc...   205                [OK]
docker.io   docker.io/jpillora/dnsmasq                  dnsmasq with a web UI                             153                [OK]
docker.io   docker.io/aciobanu/dnsmasq                  Docker image providing dnsmasq service that ...   3                  [OK]
docker.io   docker.io/strm/dnsmasq                      Dnsmasq, a simple and reliable DNS Server !       9                  [OK]
docker.io   docker.io/storytel/dnsmasq                  dnsmasq inside docker for use on CoreOS           5                  [OK]


sudo podman pull docker.io/andyshinn/dnsmasq
```


## 创建配置文件

```shell
sudo mkdir /data/dns/ -p

sudo cat >> /data/dns/dnsmasq.conf <<EOF
#no-hosts
#no-resolv
#no-poll
#log-queries
address=/.s3.qcos.com/172.16.1.23
conf-dir=/etc/dnsmasq.d,.rpmnew,.rpmsave,.rpmorig
EOF
```

## 宿主机dns处理

```shell
sudo systemctl stop systemd-resolved.service
sudo systemctl disable systemd-resolved.service

```


## 启动容器

```shell
podman run -d --pod new:dnsmasq -p 53:53/udp  \
-v /data/dns/dnsmasq.conf:/etc/dnsmasq.conf \
--restart=always \
--name=dnsmasq-container \
--hostname=dnsmasq-container \
docker.io/andyshinn/dnsmasq

```