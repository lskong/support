# tidb物理机部署

### 1. 主机清单

```shell
# 硬件配置
CPU：Intel Xeon E5-2680 v2 2.80GHz 20C/40T *2
内存：128G
系统盘：SAMSUNG 250GB SSD *1
数据盘：Intel S4510 480GB SSD *1
数据盘tikv：1TB SSD M.2转pcie
网卡：Intel X520-DA2 10GB（2光口）
```

|                   |                            node4                             |                            node5                             |                            node6                             |
| :---------------: | :----------------------------------------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: |
|        IP         |                          10.0.0.26                           |                          10.0.0.27                           |                          10.0.0.28                           |
|     部署服务      |                   1pd * 1db * 1tikv * Tiup                   |                      1pd * 1db * 1tikv                       |                      1pd * 1db * 1tikv                       |
|     组件端口      |                2379/2380 & 4000/10080 & 20160                |                2379/2380 & 4000/10080 & 20160                |                2379/2380 & 4000/10080 & 20160                |
|     数据目录      | /data/tidb/tidb-data/pd-2379 <br />/kvdata/tidb-data/tikv-20160 | /data/tidb/tidb-data/pd-2379 <br />/kvdata/tidb-data/tikv-20160 | /data/tidb/tidb-data/pd-2379 <br />/kvdata/tidb-data/tikv-20160 |
| 配置目录/日志目录 | /data/tidb/tidb-deploy/pd-2379<br />/data/tidb/tidb-deploy/tidb-4000<br />/kvdata/tidb-deploy/tikv-20160 | data/tidb/tidb-deploy/pd-2379<br />/data/tidb/tidb-deploy/tidb-4000<br />/kvdata/tidb-deploy/tikv-20160 | data/tidb/tidb-deploy/pd-2379<br />/data/tidb/tidb-deploy/tidb-4000<br />/kvdata/tidb-deploy/tikv-20160 |

### 2. 在线部署Tiup组件

- 下载Tiup组件

```apl
root@node4:~# curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
```

- 配置Tiup环境变量

```apl
root@node4:~# source .bashrc
```

- 确认 TiUP 工具是否安装

```apl
root@node4:~# which tiup
/root/.tiup/bin/tiup

# tiup工具所在位置/root/.tiup
```

- 安装 TiUP cluster 组件

```apl
root@node4:~# cd /root/.tiup/

root@node4:~/.tiup# tiup cluster
```

- 更新 TiUP cluster 组件至最新版本

```apl
root@node4:~/.tiup# tiup update --self && tiup update cluster

# 预期输出“Update successfully!”即成功
```

- 验证当前 TiUP cluster 版本信息

```apl
root@node4:~/.tiup# tiup --binary cluster
```

### 3. 初始化集群配置文件

- 生成YAML格式的配置文件

```apl
root@node4:~/.tiup# tiup cluster template > topology.yaml
```

- 配置该YMAL文件

```apl
root@node4:~/.tiup# vim /root/.tiup/topology.yaml

# # Global variables are applied to all deployments and used as the default value of
# # the deployments if a specific deployment value is missing.
global:
  # # The user who runs the tidb cluster.
  user: "tidb"
  # # group is used to specify the group name the user belong to if it's not the same as user.
  # group: "tidb"
  # # SSH port of servers in the managed cluster.
  ssh_port: 22
  # # Storage directory for cluster deployment files, startup scripts, and configuration files.
  deploy_dir: "/data/tidb/tidb-deploy"
  # # TiDB Cluster data storage directory
  data_dir: "/data/tidb/tidb-data"
  # # Supported values: "amd64", "arm64" (default: "amd64")
  arch: "amd64"
  # # Resource Control is used to limit the resource of an instance.
  # # See: https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html
  # # Supports using instance-level `resource_control` to override global `resource_control`.
  # resource_control:
  #   # See: https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html#MemoryLimit=bytes
  #   memory_limit: "2G"
  #   # See: https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html#CPUQuota=
  #   # The percentage specifies how much CPU time the unit shall get at maximum, relative to the total CPU time available on one CPU. Use values > 100% for allotting CPU time on more than one CPU.
  #   # Example: CPUQuota=200% ensures that the executed processes will never get more than two CPU time.
  #   cpu_quota: "200%"
  #   # See: https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html#IOReadBandwidthMax=device%20bytes
  #   io_read_bandwidth_max: "/dev/disk/by-path/pci-0000:00:1f.2-scsi-0:0:0:0 100M"
  #   io_write_bandwidth_max: "/dev/disk/by-path/pci-0000:00:1f.2-scsi-0:0:0:0 100M"

# # Monitored variables are applied to all the machines.
monitored:
  # # The communication port for reporting system information of each node in the TiDB cluster.
  node_exporter_port: 9100
  # # Blackbox_exporter communication port, used for TiDB cluster port monitoring.
  blackbox_exporter_port: 9115
  # # Storage directory for deployment files, startup scripts, and configuration files of monitoring components.
  # deploy_dir: "/tidb-deploy/monitored-9100"
  # # Data storage directory of monitoring components.
  # data_dir: "/tidb-data/monitored-9100"
  # # Log storage directory of the monitoring component.
  # log_dir: "/tidb-deploy/monitored-9100/log"

# # Server configs are used to specify the runtime configuration of TiDB components.
# # All configuration items can be found in TiDB docs:
# # - TiDB: https://pingcap.com/docs/stable/reference/configuration/tidb-server/configuration-file/
# # - TiKV: https://pingcap.com/docs/stable/reference/configuration/tikv-server/configuration-file/
# # - PD: https://pingcap.com/docs/stable/reference/configuration/pd-server/configuration-file/
# # - TiFlash: https://docs.pingcap.com/tidb/stable/tiflash-configuration
# #
# # All configuration items use points to represent the hierarchy, e.g:
# #   readpool.storage.use-unified-pool
# #           ^       ^
# # - example: https://github.com/pingcap/tiup/blob/master/examples/topology.example.yaml.
# # You can overwrite this configuration via the instance-level `config` field.
# server_configs:
  # tidb:
  # tikv:
  # pd:
  # tiflash:
  # tiflash-learner:

# # Server configs are used to specify the configuration of PD Servers.
pd_servers:
  # # The ip address of the PD Server.
  - host: 10.0.0.26
    # # SSH port of the server.
    ssh_port: 22
    # # PD Server name
    name: "pd-1"
    # # communication port for TiDB Servers to connect.
    client_port: 2379
    # # Communication port among PD Server nodes.
    peer_port: 2380
    # # PD Server deployment file, startup script, configuration file storage directory.
    deploy_dir: "/data/tidb/tidb-deploy/pd-2379"
    # # PD Server data storage directory.
    data_dir: "/data/tidb/tidb-data/pd-2379"
    # # PD Server log file storage directory.
    log_dir: "/data/tidb/tidb-deploy/pd-2379/log"
    # # numa node bindings.
    # numa_node: "0,1"
    # # The following configs are used to overwrite the `server_configs.pd` values.
    # config:
    #   schedule.max-merge-region-size: 20
    #   schedule.max-merge-region-keys: 200000
  - host: 10.0.0.27
    ssh_port: 22
    name: "pd-2"
    client_port: 2379
    peer_port: 2380
    deploy_dir: "/data/tidb/tidb-deploy/pd-2379"
    data_dir: "/data/tidb/tidb-data/pd-2379"
    log_dir: "/data/tidb/tidb-deploy/pd-2379/log"
    # numa_node: "0,1"
    # config:
    #   schedule.max-merge-region-size: 20
    #   schedule.max-merge-region-keys: 200000
  - host: 10.0.0.28
    ssh_port: 22
    name: "pd-3"
    client_port: 2379
    peer_port: 2380
    deploy_dir: "/data/tidb/tidb-deploy/pd-2379"
    data_dir: "/data/tidb/tidb-data/pd-2379"
    log_dir: "/data/tidb/tidb-deploy/pd-2379/log"
    # numa_node: "0,1"
    # config:
    #   schedule.max-merge-region-size: 20
    #   schedule.max-merge-region-keys: 200000
    
# # Server configs are used to specify the configuration of TiDB Servers.
tidb_servers:
  # # The ip address of the TiDB Server.
  - host: 10.0.0.26
    # # SSH port of the server.
    ssh_port: 22
    # # The port for clients to access the TiDB cluster.
    port: 4000
    # # TiDB Server status API port.
    status_port: 10080
    # # TiDB Server deployment file, startup script, configuration file storage directory.
    deploy_dir: "/data/tidb/tidb-deploy/tidb-4000"
    # # TiDB Server log file storage directory.
    log_dir: "/data/tidb/tidb-deploy/tidb-4000/log"
  # # The ip address of the TiDB Server.
  - host: 10.0.0.27
    ssh_port: 22
    port: 4000
    status_port: 10080
    deploy_dir: "/data/tidb/tidb-deploy/tidb-4000"
    log_dir: "/data/tidb/tidb-deploy/tidb-4000/log"
  - host: 10.0.0.28
    ssh_port: 22
    port: 4000
    status_port: 10080
    deploy_dir: "/data/tidb/tidb-deploy/tidb-4000"
    log_dir: "/data/tidb/tidb-deploy/tidb-4000/log"

# # Server configs are used to specify the configuration of TiKV Servers.
tikv_servers:
  # # The ip address of the TiKV Server.
  - host: 10.0.0.26
    # # SSH port of the server.
    ssh_port: 22
    # # TiKV Server communication port.
    port: 20160
    # # TiKV Server status API port.
    status_port: 20180
    # # TiKV Server deployment file, startup script, configuration file storage directory.
    deploy_dir: "/kvdata/tidb-deploy/tikv-20160"
    # # TiKV Server data storage directory.
    data_dir: "/kvdata/tidb-data/tikv-20160"
    # # TiKV Server log file storage directory.
    log_dir: "/kvdata/tidb-deploy/tikv-20160/log"
    # # The following configs are used to overwrite the `server_configs.tikv` values.
    # config:
    #   log.level: warn
  # # The ip address of the TiKV Server.
  - host: 10.0.0.27
    ssh_port: 22
    port: 20160
    status_port: 20180
    deploy_dir: "/kvdata/tidb-deploy/tikv-20160"
    data_dir: "/kvdata/tidb-data/tikv-20160"
    log_dir: "/kvdata/tidb-deploy/tikv-20160/log"
    # config:
    #   log.level: warn
  - host: 10.0.0.28
    ssh_port: 22
    port: 20160
    status_port: 20180
    deploy_dir: "/kvdata/tidb-deploy/tikv-20160"
    data_dir: "/kvdata/tidb-data/tikv-20160"
    log_dir: "/kvdata/tidb-deploy/tikv-20160/log"
    # config:
    #   log.level: warn

# # Server configs are used to specify the configuration of TiFlash Servers.
#tiflash_servers:
  # # The ip address of the TiFlash Server.
  # - host: 10.0.1.20
    # # SSH port of the server.
    # ssh_port: 22
    # # TiFlash TCP Service port.
    # tcp_port: 9000
    # # TiFlash HTTP Service port.
    # http_port: 8123
    # # TiFlash raft service and coprocessor service listening address.
    # flash_service_port: 3930
    # # TiFlash Proxy service port.
    # flash_proxy_port: 20170
    # # TiFlash Proxy metrics port.
    # flash_proxy_status_port: 20292
    # # TiFlash metrics port.
    # metrics_port: 8234
    # # TiFlash Server deployment file, startup script, configuration file storage directory.
    # deploy_dir: /tidb-deploy/tiflash-9000
    ## With cluster version >= v4.0.9 and you want to deploy a multi-disk TiFlash node, it is recommended to
    ## check config.storage.* for details. The data_dir will be ignored if you defined those configurations.
    ## Setting data_dir to a ','-joined string is still supported but deprecated.
    ## Check https://docs.pingcap.com/tidb/stable/tiflash-configuration#multi-disk-deployment for more details.
    # # TiFlash Server data storage directory.
    # data_dir: /tidb-data/tiflash-9000
    # # TiFlash Server log file storage directory.
    # log_dir: /tidb-deploy/tiflash-9000/log
  # # The ip address of the TiKV Server.
  # - host: 10.0.1.21
    # ssh_port: 22
    # tcp_port: 9000
    # http_port: 8123
    # flash_service_port: 3930
    # flash_proxy_port: 20170
    # flash_proxy_status_port: 20292
    # metrics_port: 8234
    # deploy_dir: /tidb-deploy/tiflash-9000
    # data_dir: /tidb-data/tiflash-9000
    # log_dir: /tidb-deploy/tiflash-9000/log

# # Server configs are used to specify the configuration of Prometheus Server.
#monitoring_servers:
  # # The ip address of the Monitoring Server.
  #- host: 10.0.1.22
  # # SSH port of the server.
    # ssh_port: 22
    # # Prometheus Service communication port.
    # port: 9090
    # # Prometheus deployment file, startup script, configuration file storage directory.
    # deploy_dir: "/tidb-deploy/prometheus-8249"
    # # Prometheus data storage directory.
    # data_dir: "/tidb-data/prometheus-8249"
    # # Prometheus log file storage directory.
    # log_dir: "/tidb-deploy/prometheus-8249/log"

# # Server configs are used to specify the configuration of Grafana Servers.
#grafana_servers:
  # # The ip address of the Grafana Server.
  #- host: 10.0.1.22
    # # Grafana web port (browser access)
    # port: 3000
    # # Grafana deployment file, startup script, configuration file storage directory.
    # deploy_dir: /tidb-deploy/grafana-3000

# # Server configs are used to specify the configuration of Alertmanager Servers.
#alertmanager_servers:
  # # The ip address of the Alertmanager Server.
  #- host: 10.0.1.22
    # # SSH port of the server.
    # ssh_port: 22
    # # Alertmanager web service port.
    # web_port: 9093
    # # Alertmanager communication port.
    # cluster_port: 9094
    # # Alertmanager deployment file, startup script, configuration file storage directory.
    # deploy_dir: "/tidb-deploy/alertmanager-9093"
    # # Alertmanager data storage directory.
    # data_dir: "/tidb-data/alertmanager-9093"
    # # Alertmanager log file storage directory.
    # log_dir: "/tidb-deploy/alertmanager-9093/log"
```

### 4. 部署Tidb集群

```apl
root@node4:~/.tiup# tiup cluster deploy tidb-test v5.0.0 ./topology.yaml --user root -p

# 预取输出为 “Deployed cluster `tidb-test` successfully”即部署成功
```

参数说明：

- 通过 Tiup cluster 部署的集群名称为 `tidb-test`
- 可以通过执行 `tiup list tidb` 来查看 Tiup 支持的最新可用版本，后续内容以版本 `v5.0.0` 为例
- 初始化配置文件为 `topology.yaml`（注意路径）
- --user root：通过 root 用户登录到目标主机完成集群部署，该用户需要有 ssh 到目标机器的权限，并且在目标机器有 sudo 权限。也可以用其他有 ssh 和 sudo 权限的用户完成部署。
- [-i] 及 [-p]：非必选项，如果已经配置免密登陆目标机，则不需填写。否则选择其一即可，[-i] 为可登录到目标机的 root 用户（或 --user 指定的其他用户）的私钥，也可使用 [-p] 交互式输入该用户的密码

### 5. 启动集群

```apl
root@node4:~/.tiup# tiup cluster start tidb-test

# 预期输出 “Started cluster `tidb-test` successfully” 即启动成功
```

### 6. 查看集群状态

- 查看Tiup 管理的集群情况

```apl
root@node4:~/.tiup# tiup cluster list
```

TiUP 支持管理多个 TiDB 集群，该命令会输出当前通过 TiUP cluster 管理的所有集群信息，包括集群名称、部署用户、版本、密钥信息等，回显信息为：

```apl
Starting component `cluster`: /root/.tiup/components/cluster/v1.4.4/tiup-cluster list
Name       User  Version  Path                                            PrivateKey
----       ----  -------  ----                                            ----------
tidb-test  tidb  v5.0.0   /root/.tiup/storage/cluster/clusters/tidb-test  /root/.tiup/storage/cluster/clusters/tidb-test/ssh/id_rsa
```

- 查看Tidb集群情况

```apl
root@node4:~/.tiup# tiup cluster display tidb-test
```

预期输出包括 `tidb-test` 集群中实例 ID、角色、主机、监听端口和状态，目录信息（如果集群还未启动，状态为 Down/inactive），回显信息为：

```apl
Starting component `cluster`: /root/.tiup/components/cluster/v1.4.4/tiup-cluster display tidb-test
Cluster type:       tidb
Cluster name:       tidb-test
Cluster version:    v5.0.0
SSH type:           builtin
Dashboard URL:      http://10.0.0.26:2379/dashboard
ID               Role  Host       Ports        OS/Arch       Status  Data Dir                      Deploy Dir
--               ----  ----       -----        -------       ------  --------                      ----------
10.0.0.26:2379   pd    10.0.0.26  2379/2380    linux/x86_64  Up|UI   /data/tidb/tidb-data/pd-2379  /data/tidb/tidb-deploy/pd-2379
10.0.0.27:2379   pd    10.0.0.27  2379/2380    linux/x86_64  Up|L    /data/tidb/tidb-data/pd-2379  /data/tidb/tidb-deploy/pd-2379
10.0.0.28:2379   pd    10.0.0.28  2379/2380    linux/x86_64  Up      /data/tidb/tidb-data/pd-2379  /data/tidb/tidb-deploy/pd-2379
10.0.0.26:4000   tidb  10.0.0.26  4000/10080   linux/x86_64  Up      -                             /data/tidb/tidb-deploy/tidb-4000
10.0.0.27:4000   tidb  10.0.0.27  4000/10080   linux/x86_64  Up      -                             /data/tidb/tidb-deploy/tidb-4000
10.0.0.28:4000   tidb  10.0.0.28  4000/10080   linux/x86_64  Up      -                             /data/tidb/tidb-deploy/tidb-4000
10.0.0.26:20160  tikv  10.0.0.26  20160/20180  linux/x86_64  Up      /kvdata/tidb-data/tikv-20160  /kvdata/tidb-deploy/tikv-20160
10.0.0.27:20160  tikv  10.0.0.27  20160/20180  linux/x86_64  Up      /kvdata/tidb-data/tikv-20160  /kvdata/tidb-deploy/tikv-20160
10.0.0.28:20160  tikv  10.0.0.28  20160/20180  linux/x86_64  Up      /kvdata/tidb-data/tikv-20160  /kvdata/tidb-deploy/tikv-20160
Total nodes: 9
```

- 销毁集群

```apl
root@node4:~/.tiup# tiup cluster destroy tidb-test
```

