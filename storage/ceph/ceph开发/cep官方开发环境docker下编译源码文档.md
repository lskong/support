# 1. 编译
编译硬件环境：
操作系统：ubuntu20.04 LTS
内存： 推荐32G 
磁盘空间： 推荐300G及以上
cpu： 推荐24core


## 拉取代码：

git clone https://github.com/ricardoasmarques/ceph-dev-docker.git

## 创建容器

## 基于ceph master分支创建编译环境
编译目录为/home/$USER/ceph, 映射在docker内部的/ceph路径下, 如果想指定编译路径, 进脚本自己改

        ./setup.sh 

## 基于ceph 指定大版本创建编译环境
编译目录为/home/$USER/ceph, 映射在docker内部的/ceph路径下, 如果想指定编译路径, 进脚本自己改

        ./setup.sh -f nautilus

## 基于ceph 老版本创建编译环境
编译目录为/home/$USER/ceph, 映射在docker内部的/ceph路径下, 如果想指定编译路径, 进脚本自己改

        ./setup.sh -f mimic

## 自行定制docker参数创建编译环境
编译目录为/home/$USER/ceph, 映射在docker内部的/ceph路径下, 如果想指定编译路径, 进脚本自己改

        docker run -it -d --net=host --hostname=ceph-dev --add-host=ceph-dev:127.0.0.1 -v/home/ubuntu/ceph-master:/ceph ceph-dev-docker

## [编译请参考 cep真机编译文档](ceph开发流程架构文档.md)
  
