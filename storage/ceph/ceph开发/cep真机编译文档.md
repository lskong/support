

- [1. 编译](#1-编译)
  - [1.1. 拉取源码](#11-拉取源码)
  - [1.2. 选择指定的版本进行编译，当前选择的是v15.2.10](#12-选择指定的版本进行编译当前选择的是v15210)
  - [1.3. 安装依赖](#13-安装依赖)
  - [1.4. 生成cmake文件](#14-生成cmake文件)
  - [1.5. 解决sh: 1: ng: not found：](#15-解决sh-1-ng-not-found)
    - [1.5.1. 执行命令， 将node，npm加入环境变量](#151-执行命令-将nodenpm加入环境变量)
    - [1.5.2. 解决sh: 1: node: Permission denied](#152-解决sh-1-node-permission-denied)
    - [1.5.3. 安装@angular/cli](#153-安装angularcli)
- [2. 集群测试](#2-集群测试)
- [3. 测试完成后停止](#3-测试完成后停止)

## 1. 编译
编译硬件环境：
操作系统：ubuntu20.04 LTS
内存： 推荐32G 
磁盘空间： 推荐300G及以上
cpu： 推荐24core

编译命令：
### 1.1. 拉取源码
git clone git@github.com:ceph/ceph

rm -rf ceph/*
cd ceph

### 1.2. 选择指定的版本进行编译，当前选择的是v15.2.10
git checkout v15.2.10

### 1.3. 安装依赖
./install-deps.sh

### 1.4. 生成cmake文件
./do_cmake.sh

执行do_cmake.sh前先翻好墙，否则执行git submodules大概率失败， 如果编译机器不方便翻墙， 可以用别人执行过git submodules的git库, 执行成功后， 会生成一个build目录， 里面编译用的Makefile及各种依赖文件， 下面命令的-j24指的是cpu核数， 记得改成本机对应的核数

cd build
make -j24

### 1.5. 解决sh: 1: ng: not found：

        [build:en-US -- -- --progress=false] sh: 1: ng: not found
        [build:en-US -- -- --progress=false] npm ERR! code ELIFECYCLE
        [build:en-US -- -- --progress=false] npm ERR! syscall spawn
        [build:en-US -- -- --progress=false] npm ERR! file sh
        [build:en-US -- -- --progress=false] npm ERR! errno ENOENT

#### 1.5.1. 执行命令， 将node，npm加入环境变量
export PATH=/build/src/pybind/mgr/dashboard/node-env/bin:$PATH

#### 1.5.2. 解决sh: 1: node: Permission denied

    > @angular/cli@8.3.29 postinstall ceph/src/pybind/mgr/dashboard/frontend/node_modules/@angular/cli
    > node ./bin/postinstall/script.js

    sh: 1: node: Permission denied

=======================================

    npm config set user 0
    npm config set unsafe-perm true

#### 1.5.3. 安装@angular/cli
    npm install @angular/cli@8.3.29

结束后再make就可以继续往下编译

## 2. 集群测试

编译成功后进行集群测试(默认会启动3个mds， 3个mon， 3个osd, 1个mgr， 在执行前需要安装python3-routes，务必使用sudo apt install python3-routes -y安装好, 否则dashboard的web界面无法启动，./bin/ceph -s的执行结果会是health: HEALTH_ERR, ../src/vstart.sh --debug --new -x --localhost --bluestore执行完成后， 会打印当前dashboard与resetful的端口)

    cd build
    make vstart 
    ../src/vstart.sh --debug --new -x --localhost --bluestore
    ./bin/ceph -s

## 3. 测试完成后停止
    ../src/stop.sh
