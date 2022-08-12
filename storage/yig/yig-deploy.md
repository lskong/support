# yig-deploy

## 依赖安装
```shell
apt install librados-dev libradosstriper-dev librdkafka-dev
```


mkdir /var/log/yig/


## 配置
- yig.toml
```toml
root@node3:/etc/yig# cat yig.toml 
s3domain = ["s3.test.com", "s3-internal.test.com"]
region = "cn-bj-1"
log_path = "/var/log/yig/yig.log"
access_log_path = "/var/log/yig/access.log"
access_log_format = "{combined}"
panic_log_path = "/var/log/yig/panic.log"
log_level = "error"
pid_file = "/var/run/yig/yig.pid"
api_listener = "0.0.0.0:8480"
admin_listener = "0.0.0.0:9400"
admin_key = "secret"
ssl_key_path = ""
ssl_cert_path = ""
piggyback_update_usage = true

debug_mode = true
enable_pprof = true
pprof_listener = "0.0.0.0:8730"
reserved_origins = "s3.test.com,s3-internal.test.com"

# Meta Config
meta_cache_type = 2
meta_store = "tidb"
tidb_info = "root:123456@tcp(10.0.0.24:3306)/yig"
keepalive = true
enable_compression = false
enable_usage_push = false 
redis_address = "10.0.0.26:6379"   # 物理机redis
#redis_address = "10.0.0.90:6379"  # redis_cluster+haproxy
#redis_address = "10.0.0.121:6381,10.0.0.123:6383,10.0.0.125:6385,10.0.0.122:6382,10.0.0.124:6384,10.0.0.126:6386"
redis_password = "1234" ###记得换复杂密码
redis_connection_number = 10
memory_cache_max_entry_count = 100000
enable_data_cache = true
redis_connect_timeout = 1
redis_read_timeout = 1
redis_write_timeout = 1
redis_keepalive = 60
redis_pool_max_idle = 3
redis_pool_idle_timeout = 30

cache_circuit_check_interval = 3
cache_circuit_close_sleep_window = 1
cache_circuit_close_required_count = 3
cache_circuit_open_threshold = 1
cache_circuit_exec_timeout = 5
cache_circuit_exec_max_concurrent = -1

db_max_open_conns = 10240
db_max_idle_conns = 1024
db_conn_max_life_seconds = 300

download_buf_pool_size = 8388608 #8MB
upload_min_chunk_size = 524288 #512KB
upload_max_chunk_size = 8388608 #8MB

# Ceph Config
ceph_config_pattern = "/etc/ceph/*.conf"

# Plugin Config
[plugins.dummy_compression]
path = "/etc/yig/plugins/dummy_compression_plugin.so"
enable = true

[plugins.dummy_encryption_kms]
path = "/etc/yig/plugins/dummy_kms_plugin.so"
enable = true
[plugins.dummy_encryption_kms.args]
url = "KMS"

[plugins.dummy_iam]
path = "/etc/yig/plugins/dummy_iam_plugin.so"
enable = true
[plugins.dummy_iam.args]
url="s3.test.com"

[plugins.dummy_mq]
path = "/etc/yig/plugins/dummy_mq_plugin.so"
enable = true
[plugins.dummy_mq.args]
topic = "testTopic2"
url = "kafka:29092"

[plugins.not_exist]
path = "not_exist_so"
enable = false
```


## 启动

- 临时启动
```shell
./yig
```

- 制作daemon启动
```shell
cp yig /usr/sbin/yig
mkdir /var/log/yig/

# 生产daemon文件
cat > /usr/lib/systemd/system/yig.service <<-"EOF"
[Unit]
Description=yig daemon
After=network.target yig.service
Wants=yig.service

[Service]
Type=simple
#PIDFile=/var/run/yig.pid
#EnvironmentFile=/etc/yig/yig.env
ExecStart=/usr/sbin/yig
ExecReload=/bin/kill -HUP '$MAINPID'
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

# 启动
systemctl daemon-reload
systemctl start yig.service
systemctl status yig.service
systemctl enable yig.service

# 验证
root@node1:/usr/lib/systemd/system# ps -ef|grep yig
root      191470       1  0 16:38 ?        00:00:00 /usr/sbin/yig

```

## 初始化数据库
- mysql
```shelll
use mysql
select host,user from user;
update user set host='%' where user='root';
alter user 'root'@'%' identified with mysql_native_password by '123456';
flush privileges;

create database yig character set utf8;
use yig;
source /root/yig.sql;
```

- 清理redis key
```shell
redis-cli -a 1234 -h 10.0.0.23

keys * 
flushall
```
