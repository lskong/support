# ubuntu_dpkg_deb制作


## 概念


## 工程准备

示例：将redis容器镜像的tar包，制作成deb包。使在dpkg安装时完成镜像导入到docker

- 初始化工程目录
```shell
# 工程目录mydeb-images
# 打包需要root权限
mkdir DEBIAN
mkdir -p opt/petasan/config/qdss/package/images
```

- 文件准备
```shell
ls ./opt/petasan/config/qdss/package/images/*
```


## 编辑工程

- control
```shell
tee DEBIAN/control <<EOF
Package: qdss-container-image
Version: 1.0
Architecture: all
Maintainer: zxcloud
Installed-Size: 128
Recommends:
Suggests:
Section: devel
Priority: optional
Multi-Arch: foreign
Description: zxcloud

EOF

# 注意结尾必须空一行
```

- postinst
```shell
tee DEBIAN/postinst <<-"EOF"
#!/bin/sh
#DIR="/opt/petasan/config/qdss/package/images"
#/usr/bin/docker network create qdss-cluster
#for list in $(ls $DIR/*)
#do
#/usr/bin/docker load -i $list
#done
echo "debs install done!"
EOF

chmod 755 DEBIAN/postinst
```

- prerm
```shell
sudo tee DEBIAN/prerm <<-"EOF"
#!/bin/sh
#IMAGE_ID="5d89766432d0"
#RECORD=$(/usr/bin/docker images|grep ${IMAGE_ID})|awk -F " " '{print $3}'
#if [ -n ${RECORD} ]; then
#/usr/bin/docker rmi ${IMAGE_ID}
#fi
echo "debs remove done!"
EOF

chmod 755 DEBIAN/prerm
```


## 构建工程

```shell
sudo dpkg -b ../mydeb-images ../qdss-container-image.deb
```


## 测试工程

- 安装deb
```shell
sudo dpkg -i ../qdss-container-image.deb


root@rock-dev:/home/ubuntu/deb/myredis# sudo dpkg -b ../myredis ../qdss-redis-6.2.4-container-image.deb
dpkg-deb: building package 'qdss-redis-6.2.4-container-image' in '../qdss-redis-6.2.4-container-image.deb'.
root@rock-dev:/home/ubuntu/deb/myredis# sudo dpkg -i ../qdss-redis-6.2.4-container-image.deb
Selecting previously unselected package qdss-redis-6.2.4-container-image.
(Reading database ... 206925 files and directories currently installed.)
Preparing to unpack .../qdss-redis-6.2.4-container-image.deb ...
Unpacking qdss-redis-6.2.4-container-image (1.0) ...
Setting up qdss-redis-6.2.4-container-image (1.0) ...
476baebdfbf7: Loading layer [==================================================>]  72.53MB/72.53MB
93d8d4a59913: Loading layer [==================================================>]  338.4kB/338.4kB
ba43519ed653: Loading layer [==================================================>]  4.194MB/4.194MB
4b32cd47950d: Loading layer [==================================================>]  31.73MB/31.73MB
8d8b11b85449: Loading layer [==================================================>]  2.048kB/2.048kB
cbdf3b39c399: Loading layer [==================================================>]  3.584kB/3.584kB
Loaded image: qdss/redis:latest
```

- 查看deb
```shell
dpkg -l|grep qdss


root@rock-dev:/home/ubuntu/myredis# dpkg -l|grep qdss
ii  qdss-redis-6.2.4-container-image             1.0                                           all          zxcloud
```


- 删除deb
```shell
sudo dpkg -P qdss-redis-6.2.4-container-image

root@rock-dev:/home/ubuntu/deb/myredis# sudo dpkg -P qdss-redis-6.2.4-container-image
(Reading database ... 206932 files and directories currently installed.)
Removing qdss-redis-6.2.4-container-image (1.0) ...
Untagged: qdss/redis:latest
Deleted: sha256:5d89766432d0b0b2ddc60fa3806812d64d7ffa6eb1166c85e3609639bfcfd83f
Deleted: sha256:440a5020c7fb071202570b7fe22131e28a0ac4b9bf44beaeab63ca1e931e985b
Deleted: sha256:7d95039f89d52559492377a2b966dfa0bf2c3a1725e2d2f361de2225491fbd26
Deleted: sha256:da72c87841e60f5efb4c11b7055fc8e4613b64885112a435e1959e43057cbd41
Deleted: sha256:42d416ab6c2ee3d6d49a5a7e5c8558ee4bf555dc5af0992b5b43f0430e1e8fe2
Deleted: sha256:be862a6916c1231de3f8a2603c168cf6c7990c98a6152b9e9665947e0f4ec964
Deleted: sha256:476baebdfbf7a68c50e979971fcd47d799d1b194bcf1f03c1c979e9262bcd364
dpkg: warning: while removing qdss-redis-6.2.4-container-image, directory '/opt' not empty so not removed
```


## 修改deb

```shell
mkdir psdeb
dpkg -e ./petasan_2.8.0.deb ./psdeb/DEBIAN    # 解压控制文件
dpkg -x ./petasan_2.8.0.deb ./psdeb           # 解压程序文件
vi ./psdeb/DEBIAN/control                          # 修改控制信息
dpkg -b psdeb petasan_2.8.0.deb               # 重新打包
dpkg -i petasan_2.8.0.deb           # 安装/升级

# deb安装之后的详情文件
/var/lib/dpkg/info/
```

