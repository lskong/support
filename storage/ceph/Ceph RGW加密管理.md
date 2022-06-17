# Ceph RGW加密管理

- 关于Ceph对象网关加密
- 基于Vault密钥管理服务集成
- 测试环境配置介绍
- Vault和Ceph部署
- 基于Vault KV引擎和Token访问集成CephRGW
- 基于Vault KV引擎和Agent访问集成CephRGW
- 基于Vault Transit引擎集成CephRGW


## 关于加密
> Ceph官方文档：https://docs.ceph.com/en/octopus/radosgw/encryption/
> Vault官方文档：https://www.vaultproject.io/docs

- 支持对象上传服务端加密，服务端加密意味着数据以未加密的形式通过HTTP发送，有3个选项用于加密密钥管理
  - 客户端提供密钥：密钥由客户端自己提供，服务端无需特殊处理
  - 密钥管理服务：密钥由专有的密钥管理服务，提供给rgw进行加密解密
  - 自动加密（仅用于测试）：Ceph配置文件指定密钥

- 服务器端加密密钥必须为 256 位长并采用 base64 编码

- 密钥管理服务--Vault
  - Vault可以提供安全地存储、访问和管理机密和其他敏感数据。
  - Vault可用作 服务器端加密(SSE-KMS) 的安全密钥管理服务

- 服务器端加密(SSE-KMS),Server-side Encryption
  - 服务器端加密是接收数据的应用程序或服务在其目的地对数据进行加密
  - 参考文件：https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html



## 基于Vault密钥管理服务集成
> Ceph官方文档：https://docs.ceph.com/en/octopus/radosgw/vault/
> Redhat参考文档：https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html-single/object_gateway_configuration_and_administration_guide/index#the-hashicorp-vault

- Vault密钥管理服务支持KV引擎和Transit引擎
  - KV引擎支持Token访问和agent代理访问
  - Transit引擎称为传输中的数据，即数据进行加密并不会持久化保存，又视为“加密即服务”



## 测试环境配置介绍
```shell
# vault 
host 172.16.103.254
OS Centos7

# ceph环境
172.16.103.21 node01
172.16.103.22 node02
172.16.103.23 node03

OS ubuntu18.04
```


## Vault和Ceph部署

- 容器部署Vault

```bash
# 下载vault镜像
docker pull vault

# 启动vault
docker run -d -p 8200:8200 --name vault vault:latest

# 查看vault初始化结果
[root@rock-c76-dev ~]# docker logs -f vault
You may need to set the following environment variable:

    $ export VAULT_ADDR='http://0.0.0.0:8200'

The unseal key and root token are displayed below in case you want to
seal/unseal the Vault or re-authenticate.

Unseal Key: QmFLqxTIlQ6yr71pKFcz8Mt3BFPRDYew62VU/FLVAlg=       # 解封密钥
Root Token: hvs.fsmiXY1YrOaDZHgfNUK8hBJv                       # root登录token,后面集成到ceph也使用这个token

# 浏览器查看
http://172.16.103.254:8200/
```


- Ceph部署
本环境使用qdss-zxcloud底座配置的ceph集群，ceph部署（略），rgw部署（略）



## 基于KV引擎和Token访问的Vault配置（cmd）

生产环境不推荐使用Token访问，Token有生命周期，且Token需要以明文方式存放在存储指定位置。

```bash
# 进入器
[root@rock-c76-dev ~]# docker exec -it vault sh
/ # vault --version
Vault v1.10.1 (e452e9b30a9c2c8adfa1611c26eb472090adc767)

# 加载临时环境变量
/ # export VAULT_ADDR='http://0.0.0.0:8200'


# 登录vault
/ # vault login hvs.fsmiXY1YrOaDZHgfNUK8hBJv
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.fsmiXY1YrOaDZHgfNUK8hBJv
token_accessor       JOq2fV7B7csoyeCc3eIYS02Q
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]


# 启动kv-v2引擎，默认已经启动
/ # vault secrets enable kv-v2


# 创建访问安全策略，rgw访问vault只要可读权限即可。
vault policy write rgw-kv-policy -<<EOF
  path "secret/data/*" {
    capabilities = ["read"]
  }
EOF

Success! Uploaded policy: rgw-kv-policy

# 基于访问策略创建访问token
Key                  Value
---                  -----
token                hvs.CAESIFxtgXUwQZE_gRkN0EArDxL9QtVeH-PULDKHw-_CfffiGh4KHGh2cy5MVUVVS1BTMFg0MTRJbHlZd01Ya280UVM
token_accessor       xNyabQEjcy0BJbsnT3svdgTz
token_duration       768h
token_renewable      true
token_policies       ["default" "rgw-kv-policy"]
identity_policies    []
policies             ["default" "rgw-kv-policy"]


# 创建vualt kv2引擎密钥路径
# 格式：vault kv put secret/PROJECT_NAME/BUCKET_NAME key=$(openssl rand -base64 32)
## 报错 openssl: not found，是因为容器没有openssl的命令
## 执行安装：apk add openssl

/ # vault kv put secret/rgw/bucket-a1 key=$(openssl rand -base64 32)
====== Secret Path ======
secret/data/rgw/bucket-a1

======= Metadata =======
Key                Value
---                -----
created_time       2022-04-26T09:19:48.876576908Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            2

# 查看key
/ # vault kv get secret/rgw/bucket-a1
====== Secret Path ======
secret/data/rgw/bucket-a1

======= Metadata =======
Key                Value
---                -----
created_time       2022-04-26T09:19:48.876576908Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            2

=== Data ===
Key    Value
---    -----
key    9NP5jwcs0x3QIyX5vbK7RBNtLZxowB/OWSGYJOl/JAQ=


# 此时可以使用postman工具来调试，完整的api接口应该是
http://172.16.103.254:8200/v1/secret/data/rgw/bucket-a1

## /v1/secret/data  密钥路径前缀
## rgw/bucket-a1    密钥路径ID
```


- Ceph RGW配置

```bash
# 需要添加的参数
rgw_crypt_s3_kms_backend = vault
rgw_crypt_vault_secret_engine = kv
rgw_crypt_vault_auth = token
rgw_crypt_vault_token_file = /etc/ceph/vault.token
rgw_crypt_vault_addr = http://172.16.103.254:8200
rgw_crypt_vault_prefix = /v1/secret/data
rgw_crypt_require_ssl = false

# 参数说明
## 使用kms vault作为加密后端
rgw_crypt_s3_kms_backend = vault

## vault 使用kv引擎
rgw_crypt_vault_secret_engine = kv

## 访问方式使用token，虽然生产不建议这样使用。
rgw_crypt_vault_auth = token

## 存储集群主机token文件放置位置，根据rgw所在节点添加该文件，并修改token文件属组和权限，
rgw_crypt_vault_token_file = /etc/ceph/vault.token

echo "hvs.CAESIFxtgXUwQZE_gRkN0EArDxL9QtVeH-PULDKHw-_CfffiGh4KHGh2cy5MVUVVS1BTMFg0MTRJbHlZd01Ya280UVM" > /etc/ceph/vault.token
chown ceph.ceph /etc/ceph/vault.token
chmod 600 /etc/ceph/vault.token

## ceph集群连接vault地址信息，注意网络须联通
rgw_crypt_vault_addr = http://172.16.103.254:8200


## vault密钥路径前缀，如上命令vault kv get secret/rgw/bucket-a1的结果路径为secret/data/rgw/bucket-a1，前缀是从v1开始到data结束，这是固定格式
rgw_crypt_vault_prefix = /v1/secret/data

## 要使用SSE-KMS加密管理，Ceph需要开启SSL才能正常数据传输
rgw_crypt_require_ssl = false
### > rgw_crypt_require_ssl=true时默认为禁用SSL，如果在HTTP下面使用SSE-KMS，则会出现400错误


## 重启所有rgw服务
systemctl restart ceph-radosgw.target

## 查看配置
root@node01:~# ceph config show rgw.node01|grep rgw
rgw_crypt_require_ssl               false                                                                                                                                  
rgw_crypt_s3_kms_backend            vault                                                                                                                                      
rgw_crypt_vault_addr                http://172.16.103.254:8200                                                                                                                 
rgw_crypt_vault_auth                token                                                                                                                                      
rgw_crypt_vault_prefix              /v1/secret/data                                                                                                                            
rgw_crypt_vault_secret_engine       kv                                                                                                                                         
rgw_crypt_vault_token_file          /etc/ceph/vault.token

## 调试建议把rgw的日志等级提高
debug_rgw = 20/20
```



- s3cmd工具上传下载对象验证

```bash
# 安装s3cmd
apt -y install s3cmd

# s3cmd配置文件
root@node01:~# cat .s3cfg 
[default]
access_key = 11XU0FCPA1U6PUHJIPRQ
secret_key = fBifUxvfD8Dl7t23TRelDTK8HfobglsoFTBAimDZ
default_mime_type = binary/octet-stream
enable_multipart = True
encoding = UTF-8
encrypt = False
host_base = 172.16.103.21:7480
host_bucket = 172.16.103.21:7480
use_https = False
multipart_chunk_size_mb = 5

# 创建bucket
root@node01:~# s3cmd mb s3://bucket-a1
Bucket 's3://bucket-a1/' created
## 此桶名与vualt中的KV路径名“bucket-a1”并无实际的关联，只是一个命名

# 创建测试文件
root@node01:~# echo "Test SSE-KMS" > test1.txt
root@node01:~# cat test1.txt 
Test SSE-KMS

# 上传对象
root@node01:~# s3cmd put test1.txt s3://bucket-a1 --server-side-encryption --server-side-encryption-kms-id=rgw/bucket-a1
upload: 'test1.txt' -> 's3://bucket-a1/test1.txt'  [1 of 1]
 13 of 13   100% in    0s    24.57 B/s  done

## --server-side-encryption             启动SSE-KMS
## --server-side-encryption-kms-id      vualt中KV路径，也是kms的ID
## /v1/secret/data  密钥路径前缀
## rgw/bucket-a1    密钥路径以及密钥的ID

# 查看ceph对象存储日志
root@node01:/var/log/ceph~# tail -f -n 1000 client.ceph.log
2022-04-27T13:30:10.628+0800 7f71e57fa700 20 Getting KMS encryption key for key rgw/bucket-a1
2022-04-27T13:30:10.628+0800 7f71e57fa700 20 SSE-KMS backend is vault
2022-04-27T13:30:10.628+0800 7f71e57fa700 20 Vault authentication method: token
2022-04-27T13:30:10.628+0800 7f71e57fa700 20 Vault Secrets Engine: kv
2022-04-27T13:30:10.628+0800 7f71e57fa700  0 Loading Vault Token from filesystem
2022-04-27T13:30:10.628+0800 7f71e57fa700 20 Vault token file: /etc/ceph/vault.token
2022-04-27T13:30:10.640+0800 7f71e57fa700 20 sending request to http://172.16.103.254:8200/v1/secret/data/rgw/bucket-a1
2022-04-27T13:30:10.640+0800 7f71e57fa700 20 register_request mgr=0x55e7ccfcf900 req_data->id=0, curl_handle=0x7f71c003e2c0
2022-04-27T13:30:10.640+0800 7f72d8d46700 20 link_request req_data=0x7f71c003d6a0 req_data->id=0, curl_handle=0x7f71c003e2c0
2022-04-27T13:30:10.644+0800 7f71e57fa700 20 Request to Vault returned 0 and HTTP status 200
2022-04-27T13:30:10.644+0800 7f71e57fa700 20 Parse response into JSON Object
2022-04-27T13:30:10.656+0800 7f71e57fa700  5 req 23 0.088000002s s3:put_obj NOTICE: call to do_aws4_auth_completion
2022-04-27T13:30:10.656+0800 7f71e57fa700 10 req 23 0.088000002s s3:put_obj v4 auth ok -- do_aws4_auth_completion
2022-04-27T13:30:10.720+0800 7f71e57fa700  5 req 23 0.152000003s s3:put_obj NOTICE: call to do_aws4_auth_completion
2022-04-27T13:30:10.720+0800 7f71e57fa700 10 x>> x-amz-content-sha256:806c9b5d5d44838828915e8e9c544127a90f6d0f8385358aa0ccae137d0e8182
2022-04-27T13:30:10.720+0800 7f71e57fa700 10 x>> x-amz-date:20220427T053010Z
2022-04-27T13:30:10.720+0800 7f71e57fa700 10 x>> x-amz-meta-s3cmd-attrs:atime:1651037076/ctime:1651037071/gid:0/gname:root/md5:f4f2fe795fd0ad2af3ef13be1d29efd9/mode:33188/mtime:1651037071/uid:0/uname:root
2022-04-27T13:30:10.720+0800 7f71e57fa700 10 x>> x-amz-server-side-encryption:aws:kms
2022-04-27T13:30:10.720+0800 7f71e57fa700 10 x>> x-amz-server-side-encryption-aws-kms-key-id:rgw/bucket-a1
## Request to Vault returned 0 and HTTP status 200，上传成功

# 使用s3cmd debug模式上传对象
root@node01:~# s3cmd --debug put test2.txt s3://bucket-a1 --server-side-encryption --server-side-encryption-kms-id=rgw/bucket-a1
...
DEBUG: Response:
{'data': b'',
 'headers': {'accept-ranges': 'bytes',
             'content-length': '0',
             'date': 'Wed, 27 Apr 2022 05:39:30 GMT',
             'etag': '"f447b20a7fcbf53a5d5be013ea0b15af"',
             'x-amz-request-id': 'tx000000000000000000019-006268d711-2c03fe-default',
             'x-amz-server-side-encryption': 'aws:kms',
             'x-amz-server-side-encryption-aws-kms-key-id': 'rgw/bucket-a1'},
 'reason': 'OK',
 'size': 7,
 'status': 200}
 7 of 7   100% in    0s     9.06 B/s  done


# 模拟vualt异常，下载对象
## vault服务器，关闭vault
[root@rock-c76-dev ~]# docker stop vault

## s3cmd工具下载
root@node01:~# s3cmd get s3://bucket-a1/text1.txt --server-side-encryption --server-side-encryption-kms-id=rgw/bucket-a1
download: 's3://bucket-a1/text1.txt' -> './text1.txt'  [1 of 1]
ERROR: S3 error: 404 (NoSuchKey)

root@node01:~# s3cmd get s3://bucket-a1/text1.txt --server-side-encryption --server-side-encryption-kms-id=rgw/bucket-a1 --debug
DEBUG: S3Error: 404 (Not Found)
DEBUG: HttpHeader: content-length: 220
DEBUG: HttpHeader: x-amz-request-id: tx000000000000000000009-006268ec62-2c508d-default
DEBUG: HttpHeader: accept-ranges: bytes
DEBUG: HttpHeader: content-type: application/xml
DEBUG: HttpHeader: date: Wed, 27 Apr 2022 07:10:26 GMT
DEBUG: ErrorXML: Code: 'NoSuchKey'
DEBUG: ErrorXML: BucketName: 'bucket-a1'
DEBUG: ErrorXML: RequestId: 'tx000000000000000000009-006268ec62-2c508d-default'
DEBUG: ErrorXML: HostId: '2c508d-default-default'
DEBUG: object_get failed for './text1.txt', deleting...
DEBUG: DeUnicodising './text1.txt' using UTF-8
ERROR: S3 error: 404 (NoSuchKey)

```


- aws工具上传下载对象验证

```bash
# 安装
$ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 创建创建默认配置文件
root@node01:~# aws configure
AWS Access Key ID [None]: 11XU0FCPA1U6PUHJIPRQ
AWS Secret Access Key [None]: fBifUxvfD8Dl7t23TRelDTK8HfobglsoFTBAimDZ
Default region name [None]: us-east-1
Default output format [None]: json 

root@node01:~# cat .aws/config 
[default]
region = us-east-1
output = json


root@node01:~# cat .aws/credentials 
[default]
aws_access_key_id = 11XU0FCPA1U6PUHJIPRQ
aws_secret_access_key = fBifUxvfD8Dl7t23TRelDTK8HfobglsoFTBAimDZ

## 也可以创建指定配置文件
## $ aws configure --profile produser

## 创建桶
root@node01:~# aws --endpoint=http://172.16.103.21:7480 s3 mb s3://aws-bucket
make_bucket: aws-bucket

# 上传对象
root@node01:~# aws --endpoint=http://172.16.103.21:7480 s3 cp test2.txt s3://aws-bucket --sse=aws:kms --sse-kms-key-id rgw/bucket-a1
upload: ./test2.txt to s3://aws-bucket/test2.txt 

```



## 基于Vault KV引擎和Agent访问集成CephRGW

这里使用二进制部署的vault配置，当然也可以使用容器启动的vault

- 二进制部署vault

```bash
# 部署
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install vault

# 修改配置文件，使用http模式，参照如下修改
[root@rock-c76-dev ~]# vim /etc/vault.d/vault.hcl
# HTTP listener
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

# HTTPS listener
#listener "tcp" {
#  address       = "0.0.0.0:8200"
#  tls_cert_file = "/opt/vault/tls/tls.crt"
#  tls_key_file  = "/opt/vault/tls/tls.key"
#}


# 启动vault
systemctl start vault.service

# 访问vault并初始化
http://172.16.103.254:8200/

unseal key = X5vlljpo8GZ/hFwANYZw6IdgbdKJQEp2xvHFtNVLvDs=
root token =  hvs.7mFgYb3HaGA9uncFmkP3yYf6

# 解封vault，并登录，ui操作

# cmd操作登录vault
export VAULT_ADDR='http://0.0.0.0:8200'

[root@rock-c76-dev ~]# vault login hvs.7mFgYb3HaGA9uncFmkP3yYf6
Success! You are now authenticated. The token information displayed below is
already stored in the token helper. You do NOT need to run "kms login" again.
Future kms requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.7mFgYb3HaGA9uncFmkP3yYf6
token_accessor       1OQosdL06Y9X6yz9RXlUegf1
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]


# 启动kv引擎，并创建跟路径secret/
[root@rock-c76-dev ~]# vault secrets enable -path=secret kv-v2
Success! Enabled the kv-v2 secrets engine at: secret/

# 创建安全策略
vault policy write rgw-kv-policy -<<EOF
  path "secret/data/*" {
    capabilities = ["read"]
  }
EOF

```

- Vault agent部署
agent一般部署在存储rgw节点上，测试环境可以直接使用vault的环境，agent客户端与vault是绑定一起的

```bash
vim /etc/vault/agent-config.hcl

```


## 基于Vault Transit引擎集成CephRGW



