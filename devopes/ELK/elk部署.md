elk部署



**必须先部署kafka**



介质路径：

\\192.168.3.12\samba-iso\ISO-Qualstor\Qualstor_QDSS_v2.0\Release\2021-07-20\qdss_elk.zip



节点软件包所在路径（可自定义）

```apl
root@node1:/data/qdss/install/elk# pwd
/data/qdss/install/elk
```



解压该软件包：

```apl
root@node1:/data/qdss/install/elk# tar -xvf qdss_elk.zip
```



导入镜像：

```apl

root@node1:/data/qdss/install/elk# docker load -i elasticsearch.7.13.2.tar


root@node1:/data/qdss/install/elk# docker load -i kibana.7.13.2.tar


root@node1:/data/qdss/install/elk# docker load -i logstash.7.13.2.tar
```



解压配置包：

```apl
root@node1:/data/qdss/install/elk# tar -xvf elk_dist.tgz
```



导入配置：

```apl
root@node1:/data/qdss/install/elk# pwd
/data/qdss/install/elk

root@node1:/data/qdss/install/elk# cd dist/

root@node1:/data/qdss/install/elk/dist# mkdir -p /data/elk/logstash_conf

root@node1:/data/qdss/install/elk/dist# chmod -R 777 /data/elk/

root@node1:/data/qdss/install/elk/dist# cp -r logstash_conf/* /data/elk/logstash_conf/
```



更改配置：

```apl
root@node1:~# vim /data/elk/logstash_conf/config/conf.d/qcos.conf
修改第4行和14行

4     bootstrap_servers => ["172.16.180.21:9092"]                    # kafka节点IP

14     hosts => ["172.16.180.21:9200"]                               # es节点IP
```



```apl
root@node1:~# vim /data/elk/logstash_conf/config/logstash.yml
修改第2行：

2 xpack.monitoring.elasticsearch.hosts: [ "http://172.16.180.21:9200" ]       # es节点IP
```



配置nginx文件：

```apl
root@node1:~# vim /data/qcos-web/nginx/conf.d/default.conf

添加server段：

server {
   listen       0.0.0.0:8443;
   server_name  _;

   location / {
        proxy_pass http://172.16.180.21:5601;
   }
}

```



配置yaml文件：

```apl
root@node1:~# vim /data/qcos-web/web/docker-compose.yaml

在qdss-web段添加端口映射：

 qdss-web:
    image: qdss/qdss_web:v20210720
    container_name: qdss-web
    hostname: qdss-web
    restart: always
    volumes:
      - /data/qcos-web/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf
    ports:
     - "8088:84"
     - "8443:8443"           # 添加端口
    networks:
      - qdss-cluster
```



重启UI：

```apl
root@node1:~# cd /data/qcos-web/web/

root@node1:/data/qcos-web/web# docker-compose down

root@node1:/data/qcos-web/web# docker-compose up -d
```



启动elk：

```apl
root@node1:~# cd /data/qdss/install/elk/dist/

root@node1:/data/qdss/install/elk/dist# docker-compose up -d
```



更新qcos版本：

介质路径：

\\192.168.3.12\samba-iso\ISO-Qualstor\Qualstor_QDSS_v2.0\Release\2021-07-22\qcos1.6.tar.gz



更新三个qcos实例（所有节点），包含实例：qcos，lc，delete

```apl
root@node1:/data/qcos# pwd
/data/qcos

root@node1:/data/qcos# tar -xvf qcos1.6.tar.gz

root@node1:/data/qcos# cd qcos1.6/

root@node1:/data/qcos/qcos1.6# chmod +x delete
root@node1:/data/qcos/qcos1.6# chmod +x lc
root@node1:/data/qcos/qcos1.6# chmod +x qcos

root@node1:/data/qcos/qcos1.6# cp -r plugins/ ../conf/

root@node1:/data/qcos/qcos1.6# dcoker cp qcos 1ec56ede6df8:/work

root@node1:/data/qcos/qcos1.6# dcoker cp lc c4761615409e:/work
```

修改qcos.toml

```apl
root@node1:/data/qcos/conf# pwd
/data/qcos/conf

root@node1:/data/qcos/conf# vim qcos.toml
在该配置结尾添加：

[plugins.kafka]
path = "/etc/qcos/plugins/kafka_plugin.so"
enable = true
[plugins.kafka.args]
topic = "testTopic2"
broker_list = "PLAINTEXT://172.16.180.21:9092"   # kafka节点IP
auto_offset_store = true
request_timeout_ms = "10"
message_timeout_ms = "10"
send_max_retries = "8192"

[plugins.not_exist]
path = "not_exist_so"
enable = false
```

数据库添加
```sql
use qcos

CREATE TABLE `bucketlimit` (
  `bucketname` varchar(255) NOT NULL DEFAULT '',
  `usagelimit` bigint(20) DEFAULT 0,
  PRIMARY KEY (`bucketname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

insert into bucketlimit(bucketname) SELECT bucketname FROM buckets;
```


**重启qcos所有实例**



导入kibana-dashboard.ndjson文件：

该文件路径：
/data/qdss/install/elk/kibana-dashboard.ndjson

进入qdss_web的 [ 对象存储 - 访问日志/统计界面 ]，找到左侧Save Objects栏目进行此ndjson的导入，开启访问日志面板与统计图表



