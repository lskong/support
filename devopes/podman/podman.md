# podman 

[toc]


## podman 介绍

- docker
  docker是很流行的容器技术，它在运行的时候有一个守护进程，需要把服务启动起来，才能通过CLI管理容器和镜像；守护进程复制处理很多的事情，所有就可以能有单点故障风险，当docker服务程序挂了，依赖它启动的容器就都不能使用了。

- podman
  podman是做什么的呢，它无需守护进程，可以用来管理容器和镜像，以下是它的一些特点：

  - 无需安装docker，安装podman就可以进行管理
  - podman的命令与docker几乎相同
  - docker下的镜像podman也可以使用
  - podman存储它的镜像和容器与docker的位置不同
  
  podman一个很不错的特性是拥有rootless模式，非root用户也可以使用podman来启动容器，用户和root用户的镜像/容器是互不影响的。


## 安装

- ubuntu

```shell
sudo apt update

sudo apt install curl wget gnupg2 -y
source /etc/os-release
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | sudo apt-key add -

sudo apt update
sudo apt install podman

sudo podman --version
Version:      3.2.3
API Version:  3.2.3
Go Version:   go1.15.2
Built:        Thu Jan  1 08:00:00 1970
OS/Arch:      linux/amd64

```


## 使用

```shell
# 搜索容器
podman search nginx

# 下载容器
podman pull nginx

# 启动容器
podman run -d --name nginx nginx

# 基本命令都与docker类型，具体可以使用--help

```


## pod的使用

pod-容器组，pod与k8s中pod相仿。

podman的pod需要一个容器后台，用来保持容器组的状态等。这个小容器为“k8s.gcr.io/pause:3.1”。

Pod里面的容器，查看它们的 hostname，都为pod的名称，也就是说，容器组里面的容器可以指定容器名来互相访问

```shell
# 创建pod
podman pod create --name super_pod -p 8080:80 -p 6379:6379

# 在pod创建nginx
podman run --name nginx --pod super_pod -d nginx

# 在pod里创建redis
podman run -d --name redis --pod super_pod -v /etc/localtime:/etc/localtime:ro redis:latest redis-server --requirepass redis --notify-keyspace-events Ex
# 因为容器组已经绑定了端口号，那么在容器组里面启动的容器则不需要绑定端口

# 查看pod
podman pod list[ps]

# 查看运行中的pod容器信息
podman pod top super_pod

# 使用主机模式
--net host

```

## 开启启动

相较于 Docker 守护进程指定 --restart 来启动容器，Podman 没有守护进程，该如何在系统启动的时候把容器启动呢？—— systemd

此处以启动一个 Redis 服务为例
```shell

# 创建文件及映射目录
sudo mkdir -p /opt/containers/var/lib/redis/data$ sudo mkdir -p /opt/containers/var/lib/redis/data
sudo chown 1001:1001 /opt/containers/var/lib/redis/data
sudo setfacl -m u:1001:-wx /opt/containers/var/lib/redis/data

# 创建配置文件 /etc/systemd/system/redis-service.service
[Unit]
Description=Redis Podman Container
After=network.target

[Service]
Type=simple
TimeoutStartSec=5m
ExecStartPre=-/usr/bin/podman rm "redis-service"

ExecStart=/usr/bin/podman run --name redis-service -v /opt/containers/var/lib/redis/data:/var/lib/redis/data:Z -e REDIS_PASSWORD=redis --net host daocloud.io/library/redis:latest

ExecReload=-/usr/bin/podman stop "redis-service"
ExecReload=-/usr/bin/podman rm "redis-service"
ExecStop=-/usr/bin/podman stop "redis-service"
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target

# 启动redis
sudo systemctl start redis-service

# 设置开机启动
sudo systemctl enable redis-service
```

## 排错

- Error: failed to mount overlay for metacopy check with "nodev,metacopy=on" options: invalid argument

```shell
注释配置文件/etc/containers/storage.conf的
# mountopt = "nodev,metacopy=on"

```