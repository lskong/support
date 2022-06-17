# haproxy

## 安装

```bash
# ubuntu/debian
sudo apt install haproxy

# centos
sudo yum install haproxy
```

## 重启

```bash
systemctl start haproxy

```

## 配置文件

- 基本配置

```bash
global
    log         localhost local6
    maxconn     4000
    daemon

defaults
    log global
    retries 2
    timeout connect  2s
    timeout client 30000s
    timeout server 30000s

listen admin_stats
    bind 0.0.0.0:8889
    mode http
    option httplog
    maxconn 10
    stats refresh 30s
    stats uri /haproxy?stats
    stats realm HAProxy
    stats hide-version
    stats  admin if TRUE

```


- 负载均衡配置

```
listen tidb-cluster
    bind 0.0.0.0:4400
    mode tcp
    balance leastconn
    server tidb-1 10.105.0.41:4000 check inter 2000 rise 2 fall 3
    server tidb-2 10.105.0.42:4000 check inter 2000 rise 2 fall 3
    server tidb-3 10.105.0.43:4000 check inter 2000 rise 2 fall 3
```

- TLS负载均衡配置

```bash
global
    log         localhost local6
    maxconn     4000
    daemon
    ca-base /opt/petasan/config/certificates
    crt-base /opt/petasan/config/certificates
    ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
    ssl-default-bind-options no-sslv3

frontend qcos-gw
    bind *:8181
    bind *:8281 ssl crt /opt/petasan/config/certificates/server.pem
    redirect scheme https if !{ ssl_fc }
    default_backend qcos-gw-end

backend qcos-gw-end
    balance roundrobin
    server qcos-1 10.105.0.41:8180 check inter 2000 rise 2 fall 3
    server qcos-2 10.105.0.42:8180 check inter 2000 rise 2 fall 3
    server qcos-3 10.105.0.43:8180 check inter 2000 rise 2 fall 3
```

- 读写分离负载均衡

```bash

```