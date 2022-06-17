# ceph-deploy

## 环境信息
- 节点信息
```shell
node1   172.16.1.23   10.0.0.23   10.0.1.23    ubuntu20.04
node2   172.16.1.24   10.0.0.24   10.0.1.24    ubuntu20.04
node3   172.16.1.25   10.0.0.25   10.0.1.25    ubuntu20.04
```

- 网络规划
```shell
172.16.1.0/16 管理网
10.0.0.0/24   公共网
10.0.1.0/24   集群网
```

- 主机规划
```shell
node1：mon/mgr/rgw/osd*7
node2：mon/mgr/rgw/osd*7
node3：mon/mgr/rgw/osd*7

# 多rgw规划
node1：rgw.bucket1~12
node2：rgw.bucket13~24
node3：rgw.bucket25~36
```


## 前置条件

- 禁用swap
swapoff -a   # 临时
vim /etc/fstab	#永久
    #/mnt/swap swap swap defaults 0 0

sed -ri 's/.*swap.*/#&/' /etc/fstab
```

- 开启root远程登录

```shell
# 切root用户
sudo su - root

# 设置root用户密码
echo root:123456|chpasswd

# 允许root远程登录
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
service sshd reload
```


- 主机名

```shell
vim /etc/hosts
10.0.0.23 node1
10.0.0.24 node2
10.0.0.25 node3
```

- 设置时区

```shell
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 
```


- ssh免密

```shell
ssh-keygen
ssh-copy-id -o StrictHostKeyChecking=no node1
ssh-copy-id -o StrictHostKeyChecking=no node2
ssh-copy-id -o StrictHostKeyChecking=no node3
```


- NTP同步

```shell
apt-get -y install ntpdate
ntpdate ntp.aliyun.com

tee /var/spool/cron/crontabs/root <<-'EOF'
*/5 * * * * ntpdate ntp.aliyun.com
EOF
```


## 清理旧集群
- 卸载集群
```shell
# 卸载ceph，在ceph-deploy节点上执行
# 初始化文件目录在node1上：/root/myceph
ceph-deploy purge node1 node2 node3
ceph-deploy purgedata node1 node2 node3
ceph-deploy forgetkeys

# 每个node执行
rm -fr /var/lib/ceph/
rm -fr /etc/ceph/
rm -fr /var/run/ceph/
```


- Sub-process /usr/bin/dpkg returned an error code (1)

```shell
sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bk
sudo mkdir /var/lib/dpkg/info
sudo apt-get update
sudo apt-get install -f
sudo mv /var/lib/dpkg/info/* /var/lib/dpkg/info.bk
sudo rm -rf /var/lib/dpkg/info
sudo mv /var/lib/dpkg/info.bk /var/lib/dpkg/info
```


- 清理ceph自建的pv/vg
```shell
# 清理vg
vgremove -f `pvs|grep ceph|awk '{print$2}'`

# 清理pv
pvremove -f `pvs|grep -v a--|awk '{print$1}'`

# 取消挂载
for i in `ls /var/lib/ceph/osd/ |awk -F "-" '{print $2}'`
do
  umount /var/lib/ceph/osd/ceph-${i}
done &&  df -h

# 格式化数据盘
for i in {b..h};do mkfs.ext4 /dev/sd${i};done

# 格式化缓存盘
mkfs.ext4 /dev/nvme1n1

# 清理数据
dd if=/dev/zero of=/dev/nvme0n1 count=10000K
```


## ceph-deploy工具
```shell
# 本部署使用ceph-deploy工具
# 初始化文件目录在node1上：/root/myceph

# 部署ceph-deploy 2.1
apt-get install python3 python3-pip -y
mkdir /home/cephadmin
cd /home/cephadmin
git clone https://github.com/ceph/ceph-deploy.git
cd ceph-deploy
pip3 install setuptools
python3 setup.py install
cd ../
ceph-deploy --version

# 在安装ceph-deploy后，使用ceph-deploy在ubuntu系统上会自动更新源列表，目前ceph-deploy自支持到15的版本。
```

## 部署ceph集群
- 安装ceph
```shell
ceph-deploy install node1 node2 node3

root@node1:~# ceph --version
ceph version 15.2.8 (bdf3eebcd22d7d0b3dd4d5501bee5bac354d5b55) octopus (stable)

```

- 初始化集群
```shell
# 初始化集群
mkdir /root/myceph
cd /root/myceph
ceph-deploy new --cluster-network 10.0.1.0/24 --public-network 10.0.0.0/24 node1 node2 node3

# 查看配置文件
root@node1:~/myceph# cat ceph.conf 
[global]
fsid = 9cd3d995-04aa-40a8-b740-eddfbcbcd784
public_network = 10.0.0.0/24
cluster_network = 10.0.1.0/24
mon_initial_members = node1, node2, node3
mon_host = 10.0.0.23,10.0.0.24,10.0.0.25
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
mon_allow_pool_delete = true


# 初始化mon
ceph-deploy --overwrite-conf mon create-initial

# 分发配置文件
ceph-deploy --overwrite-conf admin node1 node2 node3

# 验证集群
root@node1:~/myceph# ceph -s
  cluster:
    id:     dcd76409-5127-45ae-975a-0355bbae1aed
    health: HEALTH_WARN
            mons are allowing insecure global_id reclaim
 
  services:
    mon: 3 daemons, quorum node1,node2,node3 (age 19s)
    mgr: no daemons active
    osd: 0 osds: 0 up, 0 in
 
  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0 B
    usage:   0 B used, 0 B / 0 B avail
    pgs:     

```

- 部署mgr节点
```shell
ceph-deploy mgr create node1 node2 node3
```

- 部署rgw节点
```shell
ceph-deploy rgw create node1 node2 node3
```

- osd部署
```shell
for node in node1
do
for i in {1..7}
do
ceph-deploy osd create --data /dev/cas1-$i \
--bluestore ${node}
sleep 2
done
done && ceph osd tree

# OCF驱动的盘需要给开通LVM类型识别，在下默174行文件添加类型
vim /etc/lvm/lvm.conf
types = [ "cas", 16 ]


# 验证osd
root@node1:~/myceph# ceph osd tree
ID  CLASS  WEIGHT    TYPE NAME       STATUS  REWEIGHT  PRI-AFF
-1         38.19452  root default                             
-3         12.73151      host node1                           
 0    hdd   1.81879          osd.0       up   1.00000  1.00000
 1    hdd   1.81879          osd.1       up   1.00000  1.00000
 2    hdd   1.81879          osd.2       up   1.00000  1.00000
 3    hdd   1.81879          osd.3       up   1.00000  1.00000
 4    hdd   1.81879          osd.4       up   1.00000  1.00000
 5    hdd   1.81879          osd.5       up   1.00000  1.00000
 6    hdd   1.81879          osd.6       up   1.00000  1.00000
-5         12.73151      host node2                           
 7    hdd   1.81879          osd.7       up   1.00000  1.00000
 8    hdd   1.81879          osd.8       up   1.00000  1.00000
 9    hdd   1.81879          osd.9       up   1.00000  1.00000
10    hdd   1.81879          osd.10      up   1.00000  1.00000
11    hdd   1.81879          osd.11      up   1.00000  1.00000
12    hdd   1.81879          osd.12      up   1.00000  1.00000
13    hdd   1.81879          osd.13      up   1.00000  1.00000
-7         12.73151      host node3                           
14    hdd   1.81879          osd.14      up   1.00000  1.00000
15    hdd   1.81879          osd.15      up   1.00000  1.00000
16    hdd   1.81879          osd.16      up   1.00000  1.00000
17    hdd   1.81879          osd.17      up   1.00000  1.00000
18    hdd   1.81879          osd.18      up   1.00000  1.00000
19    hdd   1.81879          osd.19      up   1.00000  1.00000
20    hdd   1.81879          osd.20      up   1.00000  1.00000


# 查看磁盘信息
root@node1:~/myceph# lsblk
...
sdb                                                                                                       8:16    0   1.8T  0 disk 
└─cas1-1                                                                                                252:0     0   1.8T  0 disk 
  └─ceph--88453687--eca0--4ed6--a7d1--2f2f3b0a7c67-osd--block--2f9d425e--0d58--45a2--9538--60c67279f840 253:15    0   1.8T  0 lvm  
sdc                                                                                                       8:32    0   1.8T  0 disk 
└─cas1-2                                                                                                252:256   0   1.8T  0 disk 
  └─ceph--ccf575a5--2cbc--4f1b--b58b--93505f58cb45-osd--block--5ca897e4--496b--4b3f--b715--f6c1be33423b 253:16    0   1.8T  0 lvm  
sdd                                                                                                       8:48    0   1.8T  0 disk 
└─cas1-3                                                                                                252:512   0   1.8T  0 disk 
  └─ceph--aba481bc--427c--4499--a5e4--77beab80d3d8-osd--block--190eafb5--a4de--470e--bb6e--de4b0196e349 253:17    0   1.8T  0 lvm  
sde                                                                                                       8:64    0   1.8T  0 disk 
└─cas1-4                                                                                                252:768   0   1.8T  0 disk 
  └─ceph--46b1109a--19b3--4d0d--9496--77921d6e4b50-osd--block--14fc3708--9bd0--4872--943e--5f03ea755b6e 253:18    0   1.8T  0 lvm  
sdf                                                                                                       8:80    0   1.8T  0 disk 
└─cas1-5                                                                                                252:1024  0   1.8T  0 disk 
  └─ceph--cfe29a74--b101--44d0--835a--0f209d90ece5-osd--block--55cd9678--5868--49df--af1c--0ac08b18dc20 253:19    0   1.8T  0 lvm  
sdg                                                                                                       8:96    0   1.8T  0 disk 
└─cas1-6                                                                                                252:1280  0   1.8T  0 disk 
  └─ceph--552bdad0--a7e7--49ac--b4e4--7d9c77122291-osd--block--69a9fd1b--0ffa--4744--ba05--88c8b658d754 253:20    0   1.8T  0 lvm  
sdh                                                                                                       8:112   0   1.8T  0 disk 
└─cas1-7                                                                                                252:1536  0   1.8T  0 disk 
  └─ceph--95c2d36d--d956--4ee8--b66f--81c83f17b956-osd--block--efd3ed5c--33fd--4fd2--a98d--313e5c412669 253:21    0   1.8T  0 lvm  

# 查看集群状态
root@node1:~/myceph# ceph -s
  cluster:
    id:     93c640e2-bbce-4ef2-9799-7ed7933db5cd
    health: HEALTH_WARN
            mons are allowing insecure global_id reclaim
 
  services:
    mon: 3 daemons, quorum node1,node2,node3 (age 11m)
    mgr: node1(active, since 8m), standbys: node2, node3
    osd: 21 osds: 21 up (since 2m), 21 in (since 2m)
    rgw: 3 daemons active (node1, node2, node3)
 
  task status:
 
  data:
    pools:   5 pools, 107 pgs
    objects: 191 objects, 7.0 KiB
    usage:   22 GiB used, 38 TiB / 38 TiB avail
    pgs:     107 active+clean
 
  progress:
    PG autoscaler decreasing pool 5 PGs from 32 to 8 (3m)
      [================............] (remaining: 2m)
```

## 对象网关
- 配置步骤
```shell
# 前面已经为三台添加rgw
root@node3:~# ceph -s |grep rgw
    rgw: 3 daemons active (node1, node2, node3)

# 网关创建之后默认已创建存储池（三副本）
root@node3:~# ceph df |grep rgw
.rgw.root               1   32  3.6 KiB        8  1.5 MiB      0     12 TiB
default.rgw.log         3   32  3.4 KiB      207    6 MiB      0     12 TiB
default.rgw.control     4   32      0 B        8      0 B      0     12 TiB
default.rgw.meta        5    8      0 B        0      0 B      0     12 TiB

# 创建一对三副本对象存储池
ceph osd pool create default.rgw.buckets.data 32 32
ceph osd pool create default.rgw.buckets.index 32 32

ceph osd pool create rabbit 32 32
ceph osd pool create tiger 32 32
ceph osd pool create turtle 32 32

# 初始化存储池
ceph osd pool application enable default.rgw.buckets.data rgw
ceph osd pool application enable default.rgw.buckets.index rgw
ceph osd pool application enable rabbit rgw
ceph osd pool application enable tiger rgw
ceph osd pool application enable turtle rgw

# 再次验证
root@node3:~# ceph df |grep rgw
POOL                       ID  PGS  STORED   OBJECTS  USED     %USED  MAX AVAIL
.rgw.root                   1   32  3.6 KiB        8  1.5 MiB      0     12 TiB
device_health_metrics       2    1      0 B        0      0 B      0     12 TiB
default.rgw.log             3   32  3.4 KiB      207    6 MiB      0     12 TiB
default.rgw.control         4   32      0 B        8      0 B      0     12 TiB
default.rgw.meta            5    8  326 KiB      203   39 MiB      0     12 TiB
default.rgw.buckets.index   8    8   90 MiB    1.10k  269 MiB      0     12 TiB
default.rgw.buckets.data    9   32  762 MiB  199.75k   37 GiB   0.10     12 TiB

# 存储池性能测试
root@node3:~# rados bench -p default.rgw.buckets.data 60 write -b 4K
Total time run:         60.0013
Total writes made:      444703
Write size:             4096
Object size:            4096
Bandwidth (MB/sec):     28.9514
Stddev Bandwidth:       8.56193
Max bandwidth (MB/sec): 32.9297
Min bandwidth (MB/sec): 0
Average IOPS:           7411
Stddev IOPS:            2191.88
Max IOPS:               8430
Min IOPS:               0
Average Latency(s):     0.00215593
Stddev Latency(s):      0.0280296
Max latency(s):         5.00999
Min latency(s):         0.000766621

# 此测试不保留测试生成的数据
# 测试出来的平均IOPS是正常值。
```

- S3接口配置
```shell
# 创建网关租户
root@node1:~/myceph# radosgw-admin user create --uid="admin" --display-name="admin user" --system
{
    "user_id": "admin",
    "display_name": "admin user",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "subusers": [],
    "keys": [
        {
            "user": "admin",
            "access_key": "1CHO9S9JSEMVEBNZT4DU",
            "secret_key": "CkdjaOzXFVdleIMAl0yGUP6jhZCQis1QB3SKteiA"
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
    "system": "true",
    "default_placement": "",
    "default_storage_class": "",
    "placement_tags": [],
    "bucket_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "user_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "temp_url_keys": [],
    "type": "rgw",
    "mfa_ids": []
}

# 注意--system参数。如果是普通租户则不需要添加参数。如果需要管理权限，比如管理dashboard的对象存储页面，则需要添加，否正不能使用模块。

# 记录key
"access_key": "1CHO9S9JSEMVEBNZT4DU",
"secret_key": "CkdjaOzXFVdleIMAl0yGUP6jhZCQis1QB3SKteiA"

# 创建后可以通过命令查询
radosgw-admin user info --uid=admin
```

- s3cmd测试
```shell
# 安装s3cmd
apt install s3cmd

# 配置
vim /root/.s3cfg
[default]
access_key = 1CHO9S9JSEMVEBNZT4DU
secret_key = CkdjaOzXFVdleIMAl0yGUP6jhZCQis1QB3SKteiA
default_mime_type = binary/octet-stream
enable_multipart = True
encoding = UTF-8
encrypt = False
host_base = 10.0.0.23:7480
host_bucket = 10.0.0.23:7480
use_https = False
multipart_chunk_size_mb = 5

# 测试
# 创建bucket
root@node3:~# s3cmd mb s3://my-bucket-s3cmd-1
Bucket 's3://my-bucket-s3cmd-1/' created
# 列举
root@node3:~# s3cmd ls
2021-06-08 03:33  s3://my-bucket-s3cmd-1
# 上传
s3cmd put file.txt s3://my-bucket-s3cmd-1/file.txt
# 删除文件
s3cmd del s3://my-bucket-s3cmd-1/file.txt
# 删除空bucket
s3cmd rb s3://my-bucket-s3cmd-1
```

## dashboard功能
- 开启dashborad
```shell
# 安装
apt-get -y install ceph-mgr-dashboard

# 启动模块
ceph mgr module enable dashboard
# 如果有多台初始化的mgr，则必须保证每个节点都安装ceph-mgr-dashboard

# 顺便开启premetheus模块
ceph mgr module enable prometheus

# 可以同步查询当前已启动的模块
ceph mgr module ls |more

# 配置
ceph config set mgr mgr/dashboard/ssl false
ceph config set mgr mgr/dashboard/server_addr 0.0.0.0
ceph config set mgr mgr/dashboard/server_port 8080

# 生成登录密码
root@node1:~# cat /etc/ceph/ceph-dashboard.passwd
Ceph12345

# 创建账户
root@node1:~# ceph dashboard ac-user-create admin -i /etc/ceph/ceph-dashboard.passwd administrator
{"username": "admin", "password": "$2b$12$m9jnDsX9N2XVUAbkYkllZOQLI9/yLmBckjdMS1IaQY3fs15le.uNm", "roles": ["administrator"], "name": null, "email": null, "lastUpdate": 1623121731, "enabled": true, "pwdExpirationDate": null, "pwdUpdateRequired": false}
# 密钥文件发送给其它节点
scp /etc/ceph/ceph-dashboard.passwd administrator node2:/etc/ceph/
scp /etc/ceph/ceph-dashboard.passwd administrator node3:/etc/ceph/

# 启动服务
root@node1:~# ceph mgr services
{
    "dashboard": "http://node1:8080/",
    "prometheus": "http://node1:9283/"
}

# 关闭模块
ceph mgr module disable dashboard
```

- 开启对象网关
```shell
# 查询账户key
radosgw-admin user info --uid=admin

# 创建用户key文件
cat /etc/ceph/admin.access.key
1CHO9S9JSEMVEBNZT4DU

cat /etc/ceph/admin.secret.key
CkdjaOzXFVdleIMAl0yGUP6jhZCQis1QB3SKteiA

# 导入key
root@node1:~# ceph dashboard set-rgw-api-access-key -i /etc/ceph/admin.access.key 
Option RGW_API_ACCESS_KEY updated

root@node1:~# ceph dashboard set-rgw-api-secret-key -i /etc/ceph/admin.secret.key
Option RGW_API_SECRET_KEY updated

# 禁止ssl
root@node1:~# ceph dashboard set-rgw-api-ssl-verify False
Option RGW_API_SSL_VERIFY updated


# 如果配置错误可以通过reset来重置配置
ceph dashboard reset-rgw-api-secret-key
ceph dashboard reset-rgw-api-access-key
ceph dashboard reset-rgw-api-ssl-verify

# 两个key一起发给其它mgr节点，备用
scp  /etc/ceph/admin.*.key node2:/etc/ceph/
scp  /etc/ceph/admin.*.key node3:/etc/ceph/
```



## 健康状态处理

- 1 pool(s) do not have an application enabled
```shell
# 存储池没有初始化应用
root@node1:~# ceph health detail
[WRN] POOL_APP_NOT_ENABLED: 1 pool(s) do not have an application enabled
    application not enabled on pool 'rabbit'
    use 'ceph osd pool application enable <pool-name> <app-name>', where <app-name> is 'cephfs', 'rbd', 'rgw', or freeform for custom applications.

# 解决
ceph osd pool application enable rabbit rgw

```


- 1 daemons have recently crashed
```shell
# 最近有一个或多个Ceph守护进程崩溃，管理员尚未对该崩溃进行存档(确认)。这可能表示软件错误、硬件问题(例如，故障磁盘)或某些其它问题。
root@node1:~# ceph health detail
[WRN] RECENT_CRASH: 1 daemons have recently crashed
    client.rgw.node1 crashed on host node1 at 2021-06-09T08:52:37.673294Z

# 新的崩溃可以通过以下方式列出
root@node3:~# ceph crash ls-new
ID                                                                ENTITY            NEW  
2021-06-09T08:52:37.673294Z_e91a2e86-960f-4e94-b60c-d03f691f4d0b  client.rgw.node1   * 

# 有关特定崩溃的信息可以通过以下方式检查
root@node3:~# ceph crash info 2021-06-09T08:52:37.673294Z_e91a2e86-960f-4e94-b60c-d03f691f4d0b

# 可以通过“存档”崩溃（可能是在管理员检查之后）来消除此警告，从而不会生成此警告：
root@node3:~# ceph crash archive 2021-06-09T08:52:37.673294Z_e91a2e86-960f-4e94-b60c-d03f691f4d0b

# 所有新的崩溃都可以通过以下方式存档：
ceph crash archive-all

# 可以通过以下方式完全禁用这些警告：
ceph config set mgr mgr/crash/warn_recent_interval 0
```

- mons are allowing insecure global_id reclaim
```shell
root@node3:~# ceph health detail
HEALTH_WARN mons are allowing insecure global_id reclaim; 1 pools have many more objects per pg than average
[WRN] AUTH_INSECURE_GLOBAL_ID_RECLAIM_ALLOWED: mons are allowing insecure global_id reclaim
    mon.node1 has auth_allow_insecure_global_id_reclaim set to true
    mon.node2 has auth_allow_insecure_global_id_reclaim set to true
    mon.node3 has auth_allow_insecure_global_id_reclaim set to true

# 禁用不安全模式
ceph config set mon auth_allow_insecure_global_id_reclaim false
```

## OSD处理
- 删除osd
```shell
# 如果使用了OCF，请先停掉
casctl stop

# 从ceph移除
for i in `ls /var/lib/ceph/osd/ |awk -F "-" '{print $2}'`
do 
  systemctl stop ceph-osd@${i}.service
  ceph osd out osd.${i}
  ceph osd crush remove osd.${i}
  ceph osd rm osd.${i}
  ceph auth del osd.${i}
done && ceph osd tree

for i in {7..13}
do 
  ceph osd out osd.${i}
  ceph osd crush remove osd.${i}
  ceph osd rm osd.${i}
  ceph auth del osd.${i}
done && ceph osd tree

# 取消挂载
for i in `ls /var/lib/ceph/osd/ |awk -F "-" '{print $2}'`
do
  umount /var/lib/ceph/osd/ceph-${i}
done &&  df -h

# 删除PV/VG
vgremove -f `pvs|grep ceph|awk '{print$2}'`
pvremove -f ` pvs|grep -v PV|grep -v a--|awk '{print$1}'`

# 单独停止osd
for i in `ls /var/lib/ceph/osd/ |awk -F "-" '{print $2}'`
do
  systemctl stop ceph-osd@${i}.service
done

for i in `ls /var/lib/ceph/osd/ |awk -F "-" '{print $2}'`
do
  systemctl start ceph-osd@${i}.service
done
```



- 重新添加osd
```shell
for node in node1 node2 node3
do
for i in {1..7}
do
ceph-deploy osd create --data /dev/cas1-$i \
--bluestore ${node}
sleep 2
done
done && ceph osd tree
```shell

- ceph pool
```shell
# 查看池
root@node1:~/myceph# ceph df
--- RAW STORAGE ---
CLASS  SIZE    AVAIL   USED     RAW USED  %RAW USED
hdd    38 TiB  38 TiB  7.7 GiB    29 GiB       0.07
TOTAL  38 TiB  38 TiB  7.7 GiB    29 GiB       0.07
 
--- POOLS ---
POOL                       ID  PGS   STORED  OBJECTS  USED  %USED  MAX AVAIL
.rgw.root                   1    32     0 B        0   0 B      0     12 TiB
device_health_metrics       2     1     0 B        0   0 B      0     12 TiB
default.rgw.log             3    32     0 B        0   0 B      0     12 TiB
default.rgw.control         4    32     0 B        0   0 B      0     12 TiB
default.rgw.meta            5     8     0 B        0   0 B      0     12 TiB
default.rgw.data            6    32     0 B        0   0 B      0     12 TiB
default.rgw.index           7    64     0 B        0   0 B      0     12 TiB
default.rgw.buckets.index   8     8     0 B        0   0 B      0     12 TiB
default.rgw.buckets.data    9    32     0 B        0   0 B      0     12 TiB
tiger                      10    32     0 B        0   0 B      0     12 TiB
rabbit                     11  1024     0 B        0   0 B      0     12 TiB
turtle                     12    32     0 B        0   0 B      0     12 TiB

# 删除池
ceph osd pool rm default.rgw.buckets.index default.rgw.buckets.index --yes-i-really-really-mean-it
ceph osd pool rm default.rgw.buckets.data default.rgw.buckets.data --yes-i-really-really-mean-it
ceph osd pool rm rabbit rabbit --yes-i-really-really-mean-it
ceph osd pool rm default.rgw.meta  default.rgw.meta  --yes-i-really-really-mean-it
ceph osd pool rm default.rgw.data  default.rgw.data  --yes-i-really-really-mean-it
ceph osd pool rm default.rgw.index   default.rgw.index   --yes-i-really-really-mean-it
```

