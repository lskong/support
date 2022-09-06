---
id: registry
title: docker registry
---

- [docker registry](#docker-registry)
  - [1.快速搭建](#1快速搭建)
  - [2.采用TLS](#2采用tls)
    - [2.1 证书制作](#21-证书制作)
    - [2.2 证书启动registry](#22-证书启动registry)
    - [2.3 加入基本身份认证](#23-加入基本身份认证)
    - [2.4 使用yaml配置启动](#24-使用yaml配置启动)
  - [3.完整的配置](#3完整的配置)
    - [3.1 后端存储配置项](#31-后端存储配置项)
    - [3.2 用户认证配置项](#32-用户认证配置项)
    - [3.3 http配置项](#33-http配置项)
  - [4.S3存储配置示例](#4s3存储配置示例)
  - [4.S3存储vault配置示例](#4s3存储vault配置示例)

# docker registry

**docker registry**的作用就是存储我们的镜像。通常情况下我们可以使用官方的docker hub存储在公网上面，不过如果是在公司内部使用，不想将镜像公开，可以手动搭建一个本地registry，比如docker registry或harbor。



## 1.快速搭建

搭建registry最基础的命令为：
```bash
docker run -d -v /data/registry:/var/lib/registry -p 5000:5000 registry:2
```

registry定义的对外服务端口为5000，我们也可以通过环境变量``REGISTRY_HTTP_ADDR``来修改服务端口。

例如：如5000修改为5001

```bash
docker run -d \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:5001 \
  -p 5001:5001 \
  registry:2
```

推拉测试

```bash
docker pull ubuntu
docker image tag ubuntu localhost:5000/myfirstimage
docker push localhost:5000/myfirstimage
docker rmi localhost:5000/myfirstimage
docker pull localhost:5000/myfirstimage
```

非localhost的其他局域网主机推送镜像时，需要在/etc/docker/daemon.json或C:\ProgramData\docker\config\daemon.json文件中添加以下配置，并重启docker。
```json
{
    "insecure-registries":[
        "xxx.xxx.xxx.xx:port" #仓库IP地址和端口，或者是域名
    ]
}
```


## 2.采用TLS

### 2.1 证书制作
证书申请流程：先生成一个私钥，然后用私钥生成证书请求(证书请求里应含有公钥信息)，再利用证书服务器的CA根证书来签发证书。


```bash
$ mkdir /opt/docker/tls/ -p
$ cd /opt/docker/tls/

# 生成根证书:
# 生成CA私钥（.key）-->生成CA证书请求（.csr）-->自签名得到根证书（.crt）（CA给自已颁发的证书）。
$ openssl genrsa -out "root-ca.key" 4096

$ openssl req \
          -new -key "root-ca.key" \
          -out "root-ca.csr" -sha256 \
          -subj '/C=CN/ST=Shanghai/L=Shanghai/O=Qualstor/CN=docker.qualstor.com'


$ openssl x509 -req  -days 3650  -in "root-ca.csr" \
               -signkey "root-ca.key" -sha256 -out "root-ca.crt" \
               -extfile "root-ca.cnf" -extensions \
               root_ca

$ cat root-ca.crt root-ca.key > root-ca.pem   # 生成pem格式的证书

# 生成服务端证书
# 生成私钥（.key）-->生成证书请求（.csr）-->用CA根证书签名得到证书（.crt）
$ openssl genrsa -out "server.key" 4096

$ openssl req -new -key "server.key" -out "server.csr" -sha256 \
          -subj '/C=CN/ST=Shanghai/L=Shanghai/O=Qualstor/CN=docker.qualstor.com'

$ openssl x509 -req -days 750 -in "server.csr" -sha256 \
    -CA "root-ca.crt" -CAkey "root-ca.key"  -CAcreateserial \
    -out "server.crt"

$ cat server.crt server.key > server.pem
```

### 2.2 证书启动registry

```bash
mkdir /opt/docker/registry -p

docker run -d \
  --restart=always \
  --name registry \
  -v /opt/docker/registry:/var/lib/registry \
  -v /opt/docker/tls:/certs \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/server.key \
  -p 443:443 \
  registry:2
```

推拉测试

```bash
docker pull centos
docker image tag centos localhost:443/centos
docker push localhost:443/centos
docker rmi localhost:443/centos
docker pull localhost:443/centos
```

### 2.3 加入基本身份认证

为了提高regsitry的安全性，可以开启访问控制，用户需要登陆后才可以使用registry。

1.创建一个密码文件，里面包含一条用户名密码(stark/catherine)。

```bash
mkdir /opt/docker/auth -p
docker run \
  --entrypoint htpasswd \
  httpd:2 -Bbn stark catherine > /opt/docker/auth/htpasswd
```

> windows系统下需要修改编码格式：
docker run --rm --entrypoint htpasswd httpd:2 -Bbn testuser testpassword | Set-Content -Encoding ASCII auth/htpasswd

2.启动容器

```bash
docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry \
  -v /opt/docker/registry:/var/lib/registry \
  -v "/opt/docker/auth:/auth" \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -v "/opt/docker/tls:/certs" \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/server.key \
  registry:2
```

3.推拉测试

```bash
docker pull ubuntu
docker image tag ubuntu localhost:5000/ubuntu
docker login localhost:5000
docker push localhost:5000/ubuntu
docker rmi localhost:5000/ubuntu
docker pull localhost:5000/ubuntu
```

> 注：使用身份认证，建议开启TLS，否则登录信息明文传输（header中），一样不安全。


### 2.4 使用yaml配置启动

1.创建yaml配置文件,

```bash
mkdir /opt/docker/config
vim /opt/docker/config/config.yml
```

2.配置文件内容
```yml
version: 0.1
storage:
  filesystem:
    rootdirectory: /var/lib/registry # docker镜像在容器内的存储位置。
    maxthreads: 100
  cache: # 可以是redis或inmemory，加速层 metadata（layerinfo/blobdescriptor）的读取。
    blobdescriptor: inmemory
auth:
  htpasswd:
    realm: basic-realm
    path: /auth/htpasswd

http:
  addr: 0.0.0.0:5000 # registry服务的地址。
  net: tcp
  tls:
    certificate: /tls/server.crt # x509公钥的绝对路径
    key: /tls/server.key # x509私钥的绝对路径
```

3.启动registry

```bash
docker run -d \
    --restart=always \
    --name registry \
    -v /opt/docker/config/config.yml:/etc/docker/registry/config.yml \
    -v /opt/docker/auth:/auth \
    -v /opt/docker/tls:/tls \
    -p 5000:5000 \
    -v /opt/docker/registry:/var/lib/registry \
    registry:2
```

4.推拉测试

```bash
docker pull ubuntu
docker image tag ubuntu localhost:5000/ubuntu
docker login localhost:5000
docker push localhost:5000/ubuntu
docker rmi localhost:5000/ubuntu
docker pull localhost:5000/ubuntu
```

## 3.完整的配置

> 官方解释：https://docs.docker.com/registry/configuration/

```yml
version: 0.1
log:
  accesslog:
    disabled: true
  level: debug
  formatter: text
  fields:
    service: registry
    environment: staging
  hooks:
    - type: mail
      disabled: true
      levels:
        - panic
      options:
        smtp:
          addr: mail.example.com:25
          username: mailuser
          password: password
          insecure: true
        from: sender@example.com
        to:
          - errors@example.com
loglevel: debug # deprecated: use "log"
storage:
  filesystem:
    rootdirectory: /var/lib/registry
    maxthreads: 100
  azure:
    accountname: accountname
    accountkey: base64encodedaccountkey
    container: containername
  gcs:
    bucket: bucketname
    keyfile: /path/to/keyfile
    credentials:
      type: service_account
      project_id: project_id_string
      private_key_id: private_key_id_string
      private_key: private_key_string
      client_email: client@example.com
      client_id: client_id_string
      auth_uri: http://example.com/auth_uri
      token_uri: http://example.com/token_uri
      auth_provider_x509_cert_url: http://example.com/provider_cert_url
      client_x509_cert_url: http://example.com/client_cert_url
    rootdirectory: /gcs/object/name/prefix
    chunksize: 5242880
  s3:
    accesskey: awsaccesskey
    secretkey: awssecretkey
    region: us-west-1
    regionendpoint: http://myobjects.local
    bucket: bucketname
    encrypt: true
    keyid: mykeyid
    secure: true
    v4auth: true
    chunksize: 5242880
    multipartcopychunksize: 33554432
    multipartcopymaxconcurrency: 100
    multipartcopythresholdsize: 33554432
    rootdirectory: /s3/object/name/prefix
  swift:
    username: username
    password: password
    authurl: https://storage.myprovider.com/auth/v1.0 or https://storage.myprovider.com/v2.0 or https://storage.myprovider.com/v3/auth
    tenant: tenantname
    tenantid: tenantid
    domain: domain name for Openstack Identity v3 API
    domainid: domain id for Openstack Identity v3 API
    insecureskipverify: true
    region: fr
    container: containername
    rootdirectory: /swift/object/name/prefix
  oss:
    accesskeyid: accesskeyid
    accesskeysecret: accesskeysecret
    region: OSS region name
    endpoint: optional endpoints
    internal: optional internal endpoint
    bucket: OSS bucket
    encrypt: optional data encryption setting
    secure: optional ssl setting
    chunksize: optional size valye
    rootdirectory: optional root directory
  inmemory:  # This driver takes no parameters
  delete:
    enabled: false
  redirect:
    disable: false
  cache:
    blobdescriptor: redis
  maintenance:
    uploadpurging:
      enabled: true
      age: 168h
      interval: 24h
      dryrun: false
    readonly:
      enabled: false
auth:
  silly:
    realm: silly-realm
    service: silly-service
  token:
    autoredirect: true
    realm: token-realm
    service: token-service
    issuer: registry-token-issuer
    rootcertbundle: /root/certs/bundle
  htpasswd:
    realm: basic-realm
    path: /path/to/htpasswd
middleware:
  registry:
    - name: ARegistryMiddleware
      options:
        foo: bar
  repository:
    - name: ARepositoryMiddleware
      options:
        foo: bar
  storage:
    - name: cloudfront
      options:
        baseurl: https://my.cloudfronted.domain.com/
        privatekey: /path/to/pem
        keypairid: cloudfrontkeypairid
        duration: 3000s
        ipfilteredby: awsregion
        awsregion: us-east-1, use-east-2
        updatefrenquency: 12h
        iprangesurl: https://ip-ranges.amazonaws.com/ip-ranges.json
  storage:
    - name: redirect
      options:
        baseurl: https://example.com/
reporting:
  bugsnag:
    apikey: bugsnagapikey
    releasestage: bugsnagreleasestage
    endpoint: bugsnagendpoint
  newrelic:
    licensekey: newreliclicensekey
    name: newrelicname
    verbose: true
http:
  addr: localhost:5000
  prefix: /my/nested/registry/
  host: https://myregistryaddress.org:5000
  secret: asecretforlocaldevelopment
  relativeurls: false
  draintimeout: 60s
  tls:
    certificate: /path/to/x509/public
    key: /path/to/x509/private
    clientcas:
      - /path/to/ca.pem
      - /path/to/another/ca.pem
    letsencrypt:
      cachefile: /path/to/cache-file
      email: emailused@letsencrypt.com
      hosts: [myregistryaddress.org]
  debug:
    addr: localhost:5001
    prometheus:
      enabled: true
      path: /metrics
  headers:
    X-Content-Type-Options: [nosniff]
  http2:
    disabled: false
notifications:
  events:
    includereferences: true
  endpoints:
    - name: alistener
      disabled: false
      url: https://my.listener.com/event
      headers: <http.Header>
      timeout: 1s
      threshold: 10
      backoff: 1s
      ignoredmediatypes:
        - application/octet-stream
      ignore:
        mediatypes:
           - application/octet-stream
        actions:
           - pull
redis:
  addr: localhost:6379
  password: asecret
  db: 0
  dialtimeout: 10ms
  readtimeout: 10ms
  writetimeout: 10ms
  pool:
    maxidle: 16
    maxactive: 64
    idletimeout: 300s
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
  file:
    - file: /path/to/checked/file
      interval: 10s
  http:
    - uri: http://server.to.check/must/return/200
      headers:
        Authorization: [Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==]
      statuscode: 200
      timeout: 3s
      interval: 10s
      threshold: 3
  tcp:
    - addr: redis-server.domain.com:6379
      timeout: 3s
      interval: 10s
      threshold: 3
proxy:
  remoteurl: https://registry-1.docker.io
  username: [username]
  password: [password]
compatibility:
  schema1:
    signingkeyfile: /etc/registry/key.json
    enabled: true
validation:
  manifests:
    urls:
      allow:
        - ^https?://([^/]+\.)*example\.com/
      deny:
        - ^https?://www\.example\.com/
```

### 3.1 后端存储配置项

registry支持的后端存储有filesystem（本地存储）, azure, gcs, s3, swift, oss, inmemory。存储只能配置一个，否则会出错。inmemory表示存储在内存中，仅供测试使用。使用本地存储时，不建议使用windows本地的存储，因为windows对路径长度有限制。
完整的配置文件及其说明如下：

```yml
storage:
  filesystem:
    rootdirectory: /var/lib/registry
  azure:
    accountname: accountname
    accountkey: base64encodedaccountkey
    container: containername
  gcs:
    bucket: bucketname
    keyfile: /path/to/keyfile
    credentials:
      type: service_account
      project_id: project_id_string
      private_key_id: private_key_id_string
      private_key: private_key_string
      client_email: client@example.com
      client_id: client_id_string
      auth_uri: http://example.com/auth_uri
      token_uri: http://example.com/token_uri
      auth_provider_x509_cert_url: http://example.com/provider_cert_url
      client_x509_cert_url: http://example.com/client_cert_url
    rootdirectory: /gcs/object/name/prefix
  s3:
    accesskey: awsaccesskey
    secretkey: awssecretkey
    region: us-west-1
    regionendpoint: http://myobjects.local
    bucket: bucketname
    encrypt: true
    keyid: mykeyid
    secure: true
    v4auth: true
    chunksize: 5242880
    multipartcopychunksize: 33554432
    multipartcopymaxconcurrency: 100
    multipartcopythresholdsize: 33554432
    rootdirectory: /s3/object/name/prefix
  swift:
    username: username
    password: password
    authurl: https://storage.myprovider.com/auth/v1.0 or https://storage.myprovider.com/v2.0 or https://storage.myprovider.com/v3/auth
    tenant: tenantname
    tenantid: tenantid
    domain: domain name for Openstack Identity v3 API
    domainid: domain id for Openstack Identity v3 API
    insecureskipverify: true
    region: fr
    container: containername
    rootdirectory: /swift/object/name/prefix
  oss:
    accesskeyid: accesskeyid
    accesskeysecret: accesskeysecret
    region: OSS region name
    endpoint: optional endpoints
    internal: optional internal endpoint
    bucket: OSS bucket
    encrypt: optional data encryption setting
    secure: optional ssl setting
    chunksize: optional size valye
    rootdirectory: optional root directory
  inmemory:
  delete:  # 表示允许通过digest删除镜像blob和manifest。（删除镜像的时候同时删除对应的layer?）
    enabled: false
  cache: # 可以是redis或inmemory，加速层 metadata（layerinfo/blobdescriptor）的读取。
    blobdescriptor: inmemory
  maintenance:
    uploadpurging: # 定期清理超过age的无效文件（夹）
      enabled: true
      age: 168h
      interval: 24h
      dryrun: false
    readonly:  # 设置registry只读，通常在后端存储gc的时候会开启。
      enabled: false
  redirect: # 不经过registry直接传输数据到后端存储
    disable: false
```

### 3.2 用户认证配置项

用户认证支持silly, token, htpasswd中的一个或者不配置。silly实际上不认证，只要请求头中有Authorization字段就直接通过；使用token认证的认证流程参考；使用htpasswd，需要事先准备好密码文件，如果新增用户，需要重启registry来加载。

```yml
auth:
  silly: # 不推荐，只要请求头中带有Authorization 就认证通过。
    realm: silly-realm
    service: silly-service
  token:
    realm: token-realm # realm为提供token签发服务的服务地址
    service: token-service # service为registry的名称或域名？表示registry在token签发服务中注册的域名。
    issuer: registry-token-issuer # token的签发者。签发着会在token中写入，且必须与此处的值相匹配。
    rootcertbundle: /root/certs/bundle # 根证书所在的绝对路径，路径下必须存在证书的公钥。
  htpasswd:
    realm: basic-realm
    path: /path/to/htpasswd # 密码文件，如果不存在，则自动创建一个，并添加一个默认用户，并将密码打印到stdout。该文件只在registry启动的时候加载一次，支持的加密方式为bcrypt。
```


### 3.3 http配置项

```yml
http:
  addr: localhost:5000 # registry服务的地址。根据下面net的不同，配置为ip:port或unix socket文件。
  net: tcp # tcp或unix。
  prefix: /my/nested/registry/ # 如果服务不是运行在跟路径下（ip:port后，还带有的一些其他路径），需要补充上该路径，前后都要带"/"。一般以docker容器方式启动的regsitry不需要配置。
  host: https://myregistryaddress.org:5000 # 对外提供服务的URL地址。
  secret: asecretforlocaldevelopment
  relativeurls: false 
  draintimeout: 60s # registry收到停止信号后，等待连接结束的时间。
  tls:
    certificate: /path/to/x509/public # x509公钥的绝对路径
    key: /path/to/x509/private # x509私钥的绝对路径
    clientcas: # x509 ca证书文件列表，绝对路径
      - /path/to/ca.pem
      - /path/to/another/ca.pem
    minimumtls: tls1.2 # 支持的tls版本
    ciphersuites: # 加密算法
      - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
      - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
    letsencrypt: # 可选，使用let's encrypt的证书
      cachefile: /path/to/cache-file
      email: emailused@letsencrypt.com
      hosts: [myregistryaddress.org]
  debug: # debug信息获取地址
    addr: localhost:5001
  prometheus：
    enabled: false
    path: /metrics # 通过上面debug定义的地址，获取prometheus监控信息。localhost:5001/metrics
  headers: # response中需要包含的header
    X-Content-Type-Options: [nosniff] # 不要解析为HTML？？
  http2:
    disabled: false # 是否支持http2
```

## 4.S3存储配置示例

1.配置文件
> s3的AK/SK/桶需要对象存储的配置
```yml
version: 0.1
storage:
  s3:
    accesskey: T1OCX9KG9YWOVD2M5GZE
    secretkey: 6ZLncgSUGn2ihaYpkswBOX4yFCpB3WhO06pawGdq
    region: us-west-1
    regionendpoint: http://172.16.103.11:7480
    bucket: bucket01
    #encrypt: true
    #keyid: mykeyid
    secure: true
    #v4auth: true
    chunksize: 5242880
    multipartcopychunksize: 33554432
    multipartcopymaxconcurrency: 100
    multipartcopythresholdsize: 33554432
    storageclass: STANDARD
    #rootdirectory: /s3/object/name/prefix
  cache: 
    blobdescriptor: inmemory
# auth:
#   htpasswd:
#     realm: basic-realm
#     path: /auth/htpasswd

http:
  addr: 0.0.0.0:5000
  net: tcp
  tls:
    certificate: /tls/server.crt
    key: /tls/server.key
```

2.启动registry

```bash
docker run -d \
    --restart=always \
    --name registry \
    -v /opt/docker/config/config.yml:/etc/docker/registry/config.yml \
    -v /opt/docker/auth:/auth \
    -v /opt/docker/tls:/tls \
    -p 5000:5000 \
    -v /opt/docker/registry:/var/lib/registry \
    registry:2
```

3.推拉测试

```bash
docker pull ubuntu
docker image tag ubuntu localhost:5000/ubuntu
docker push localhost:5000/ubuntu
docker rmi localhost:5000/ubuntu
docker pull localhost:5000/ubuntu

# s3cmd 查看对象桶
s3cmd ls s3://bucket01
        DIR   s3://bucket01/docker/
s3cmd ls s3://bucket01/docker/
        DIR   s3://bucket01/docker/registry/
s3cmd ls s3://bucket01/docker/registry/
        DIR   s3://bucket01/docker/registry/v2/
s3cmd ls s3://bucket01/docker/registry/v2
        DIR   s3://bucket01/docker/registry/v2/
s3cmd ls s3://bucket01/docker/registry/v2/
        DIR   s3://bucket01/docker/registry/v2/blobs/
        DIR   s3://bucket01/docker/registry/v2/repositories/
```

## 4.S3存储vault配置示例

1.vault安装

```bash
sudo docker pull vault

sudo docker run -d -p 8200:8200 --name vault vault:latest

sudo docker logs -f vault

#Unseal Key: sz+G3CoQ3KtHGVcF4lRS/Jayr+Vrzd1OMCcYTtifUl4=
#Root Token: s.gMwXMvEhCEraFq9ZlFPYvgYR
```

2.配置vault

```bash
sudo docker exec -it vault sh

export VAULT_ADDR='http://0.0.0.0:8200'
vault login s.gMwXMvEhCEraFq9ZlFPYvgYR

vault policy write rgw-kv-policy -<<EOF
  path "secret/data/*" {
    capabilities = ["read"]
  }
EOF

apk add openssl
vault kv put secret/rgw/bucket-a1 key=$(openssl rand -base64 32)
vault kv get secret/rgw/bucket-a1
```

3.ceph-rgw配置

```bash
rgw_crypt_s3_kms_backend = vault
rgw_crypt_vault_secret_engine = kv
rgw_crypt_vault_auth = token
rgw_crypt_vault_token_file = /etc/ceph/vault.token
rgw_crypt_vault_addr = http://172.16.103.254:8200
rgw_crypt_vault_prefix = /v1/secret/data
rgw_crypt_require_ssl = false

$ systemctl restart ceph-radosgw.target
$ echo "s.gMwXMvEhCEraFq9ZlFPYvgYR" > /etc/ceph/vault.token
$ chown ceph.ceph /etc/ceph/vault.token
$ chmod 600 /etc/ceph/vault.token
```

4.s3cmd验证

```bash
s3cmd mb s3://bucket-a1
echo "test SSE-KMS" > test1.txt
s3cmd put test1.txt s3://bucket-a1 --server-side-encryption --server-side-encryption-kms-id=rgw/bucket-a1
```

5.registry配置

```yml
version: 0.1
storage:
  s3:
    accesskey: T1OCX9KG9YWOVD2M5GZE
    secretkey: 6ZLncgSUGn2ihaYpkswBOX4yFCpB3WhO06pawGdq
    region: us-west-1
    regionendpoint: http://172.16.103.11:7480
    bucket: bucket-a1
    encrypt: true
    keyid: "rgw/bucket-a1"
    secure: false
    v4auth: false
    chunksize: 5242880
    multipartcopychunksize: 33554432
    multipartcopymaxconcurrency: 100
    multipartcopythresholdsize: 33554432
    storageclass: STANDARD
  cache: 
    blobdescriptor: inmemory
http:
  addr: 0.0.0.0:5000
  net: tcp
  tls:
    certificate: /tls/server.crt
    key: /tls/server.key
```

6.启动registry

```bash
docker run -d \
    --restart=always \
    --name registry \
    -v /opt/docker/config/config.yml:/etc/docker/registry/config.yml \
    -v /opt/docker/auth:/auth \
    -v /opt/docker/tls:/tls \
    -p 5000:5000 \
    -v /opt/docker/registry:/var/lib/registry \
    registry:2
```

7.推拉测试

```bash
docker pull ubuntu
docker image tag ubuntu localhost:5000/ubuntu
docker push localhost:5000/ubuntu
docker rmi localhost:5000/ubuntu
docker pull localhost:5000/ubuntu

```

8.rgw错误日志分析

```text
1 op->ERRORHANDLER: err_no=-2 new_err_no=-2
2 req 821 0s s3:get_obj http status=404

chain_cache_entry: cache_locator=
20 chain_cache_entry: couldn't find cache locator
20 couldn't put bucket_sync_policy cache entry, might have raced with data changes

civetweb:  HTTP/1.1" 404

s3:copy_obj ERROR: copy op for encrypted object

结论：目前rgw不支持kms加密的registry使用copy的方式进行推拉镜像
```