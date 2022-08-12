# 离线部署Tiup组件

环境信息：

|     IP      |         部署服务         |
| :---------: | :----------------------: |
| 172.16.1.23 | 1pd * 1db * 1tikv * Tiup |
| 172.16.1.24 |    1pd * 1db * 1tikv     |
| 172.16.1.25 |    1pd * 1db * 1tikv     |

### 1. tiup安装

以下操作在 ：**172.16.1.23** 执行

- 拉取Tiup离线环境包到/root目录中

```apl
root@node3:~# cp /var/www/html/soft/tidb-community-server-v5.0.0-linux-amd64.tar.gz /root
```

- 解压改软件包

```apl
# 确认当前位置
root@node3:~# root@ubuntu:~# pwd
/root

root@node3:~# tar -xzvf tidb-community-server-v5.0.0-linux-amd64.tar.gz
```

- 安装Tiup组件

```apl
root@node3:~# bash /root/tidb-community-server-v5.0.0-linux-amd64/local_install.sh
```

- 声明环境变量

```apl
root@node3:~# source /root/.bashrc
```

- 安装 TiUP cluster 组件

```apl
root@node3:~# cd /root/.tiup/

root@node3:~/.tiup# tiup cluster
```

- 更新 TiUP cluster 组件至最新版本

```apl
root@node3:~/.tiup# tiup update --self && tiup update cluster
```

- 验证当前 TiUP cluster 版本信息

```apl
root@node3:~/.tiup# tiup --binary cluster

预期回显如下即表示安装成功：
/root/.tiup/components/cluster/v1.5.2/tiup-cluster
```

### 2. 初始化集群配置文件

以下操作在 ：**172.16.1.23**  执行

- 生成YAML格式的配置文件

```apl
root@node3:~# cd /root/.tiup/

root@node3:~/.tiup# pwd
/root/.tiup

root@node3:~/.tiup# vim /root/.tiup/topology.yaml
添加：
global:
  user: "tidb"
  ssh_port: 22
  deploy_dir: "/data/tidb/tidb-deploy"                  
  data_dir: "/data/tidb/tidb-data"
  arch: "amd64"
monitored:
  node_exporter_port: 9100
  blackbox_exporter_port: 9115
pd_servers:
  - host: 172.16.1.23
    ssh_port: 22
    name: "pd-1"
    client_port: 2379
    peer_port: 2380
    deploy_dir: "/data/tidb/tidb-deploy/pd-2379"
    data_dir: "/data/tidb/tidb-data/pd-2379"
    log_dir: "/data/tidb/tidb-deploy/pd-2379/log"
  - host: 172.16.1.24
    ssh_port: 22
    name: "pd-2"
    client_port: 2379
    peer_port: 2380
    deploy_dir: "/data/tidb/tidb-deploy/pd-2379"
    data_dir: "/data/tidb/tidb-data/pd-2379"
    log_dir: "/data/tidb/tidb-deploy/pd-2379/log"
  - host: 172.16.1.25
    ssh_port: 22
    name: "pd-3"
    client_port: 2379
    peer_port: 2380
    deploy_dir: "/data/tidb/tidb-deploy/pd-2379"
    data_dir: "/data/tidb/tidb-data/pd-2379"
    log_dir: "/data/tidb/tidb-deploy/pd-2379/log"
tidb_servers:
  - host: 172.16.1.23
    ssh_port: 22
    port: 4000
    status_port: 10080
    deploy_dir: "/data/tidb/tidb-deploy/tidb-4000"
    log_dir: "/data/tidb/tidb-deploy/tidb-4000/log"
  - host: 172.16.1.24
    ssh_port: 22
    port: 4000
    status_port: 10080
    deploy_dir: "/data/tidb/tidb-deploy/tidb-4000"
    log_dir: "/data/tidb/tidb-deploy/tidb-4000/log"
  - host: 172.16.1.25
    ssh_port: 22
    port: 4000
    status_port: 10080
    deploy_dir: "/data/tidb/tidb-deploy/tidb-4000"
    log_dir: "/data/tidb/tidb-deploy/tidb-4000/log"
tikv_servers:
  - host: 172.16.1.23
    ssh_port: 22
    port: 20160
    status_port: 20180
    deploy_dir: "/data/tidb-deploy/tikv-20160"
    data_dir: "/data/tidb-data/tikv-20160"
    log_dir: "/data/tidb-deploy/tikv-20160/log"
  - host: 172.16.1.24
    ssh_port: 22
    port: 20160
    status_port: 20180
    deploy_dir: "/data/tidb-deploy/tikv-20160"
    data_dir: "/data/tidb-data/tikv-20160"
    log_dir: "/data/tidb-deploy/tikv-20160/log"
  - host: 172.16.1.25
    ssh_port: 22
    port: 20160
    status_port: 20180
    deploy_dir: "/data/tidb-deploy/tikv-20160"
    data_dir: "/data/tidb-data/tikv-20160"
    log_dir: "/data/tidb-deploy/tikv-20160/log"
    
# 根据实际情况修改：host（节点IP），deploy_dir（配置文件目录），data_dir（数据目录）， log_dir（日志文件目录）
```

### 3. 部署Tidb集群

以下操作在 ：**172.16.1.23**  执行

```apl
root@node3:~# cd /root/.tiup/

root@node3:~/.tiup# pwd
/root/.tiup

root@node3:~/.tiup# tiup cluster deploy tidb-test v5.0.0 ./topology.yaml --user root -p

# 预取输出为 “Deployed cluster `tidb-test` successfully”即部署成功
```

说明：

- 通过 Tiup cluster 部署的集群名称为 `tidb-test`
- [-i] 及 [-p]：非必选项，如果已经配置免密登陆目标机，则不需填写。否则选择其一即可，[-i] 为可登录到目标机的 root 用户（或 --user 指定的其他用户）的私钥，也可使用 [-p] 交互式输入该用户的密码

### 4. 启动集群

```apl
root@node3:~/.tiup# tiup cluster start tidb-test

# 预期输出 “Started cluster `tidb-test` successfully” 即启动成功

root@node3:~/.tiup# tiup cluster display tidb-test
# 查询tidb集群状态，预期输出包括 tidb-test 集群中实例 ID、角色、主机、监听端口和状态，目录信息（如果集群已经正常启动，status为Up；如果集群还未启动，status为 Down/inactive）
```

