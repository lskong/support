# ubuntu20.04_openssl_ssl证书颁发

## 1. 概念

- 签证机构：CA（Certificate Authority）
- 注册机构：RA（Register Authority）
- 证书吊销列表：CRL（Certificate Revoke Lists）
- 证书存取库
- X.509：定义了证书的结构和认证协议的标准。包括版本号、序列号、签名算法、颁发者、有效期限、主体名称、主体公钥、CRL分发点、扩展信息、发行者签名等

- 获取证书的两种方法：
  - 使用证书授权机构
  - 生成签名请求（csr）
  - 将csr发送给CA
  - 从CA处接收签名
  - 自签名的证书
  - 自已签发自己的公钥重点介绍一下自建CA颁发机构和自签名。
  
- 证书申请及签署步骤：
  - 生成申请请求
  - CA核验
  - CA签署
  - 获取证书

## 2. 环境和版本

- 环境

```shell
# 172.16.103.10 node1
```

- 版本

```shell
$ openssl version
OpenSSL 1.1.1f  31 Mar 2020
```

- openssl配置文件

我们自签证书不使用默认配置，全部使用自定义。

```shell
$ cat /etc/ssl/openssl.cnf
####################################################################
[ ca ]
default_ca	= CA_default		# The default ca section

####################################################################
[ CA_default ]

dir		= ./demoCA		# Where everything is kept
certs		= $dir/certs		# Where the issued certs are kept
crl_dir		= $dir/crl		# Where the issued crl are kept
database	= $dir/index.txt	# database index file.
#unique_subject	= no			# Set to 'no' to allow creation of
					# several certs with same subject.
new_certs_dir	= $dir/newcerts		# default place for new certs.

certificate	= $dir/cacert.pem 	# The CA certificate
serial		= $dir/serial 		# The current serial number
crlnumber	= $dir/crlnumber	# the current crl number
					# must be commented out to leave a V1 CRL
crl		= $dir/crl.pem 		# The current CRL
private_key	= $dir/private/cakey.pem# The private key

x509_extensions	= usr_cert		# The extensions to add to the cert

# Comment out the following two lines for the "traditional"
# (and highly broken) format.
name_opt 	= ca_default		# Subject Name options
cert_opt 	= ca_default		# Certificate field options

# Extension copying option: use with caution.
# copy_extensions = copy

# Extensions to add to a CRL. Note: Netscape communicator chokes on V2 CRLs
# so this is commented out by default to leave a V1 CRL.
# crlnumber must also be commented out to leave a V1 CRL.
# crl_extensions	= crl_ext

default_days	= 365			# how long to certify for
default_crl_days= 30			# how long before next CRL
default_md	= default		# use public key default MD
preserve	= no			# keep passed DN ordering

# A few difference way of specifying how similar the request should look
# For type CA, the listed attributes must be the same, and the optional
# and supplied fields are just that :-)
policy		= policy_match

# For the CA policy
[ policy_match ]
countryName		= match
stateOrProvinceName	= match
organizationName	= match
organizationalUnitName	= optional
commonName		= supplied
emailAddress		= optional

# For the 'anything' policy
# At this point in time, you must list all acceptable 'object'
# types.
[ policy_anything ]
countryName		= optional
stateOrProvinceName	= optional
localityName		= optional
organizationName	= optional
organizationalUnitName	= optional
commonName		= supplied
emailAddress		= optional

####################################################################
[ req ]
default_bits		= 2048
default_keyfile 	= privkey.pem
distinguished_name	= req_distinguished_name
attributes		= req_attributes
x509_extensions	= v3_ca	# The extensions to add to the self signed cert
```

## 3. 创建CA

在CA服务器上操作

- 目录准备

```shell
mkdir -p /root/ssl/{private,certs,key}
```

- 生成自签根密钥

```shell
(umask 077;openssl genrsa -out /root/ssl/private/cakey.pem 2048)
```

- 生成自签根证书

```shell
openssl req -x509 -days 7300 -new \
-key /root/ssl/private/cakey.pem \
-out /root/ssl/certs/cacert.pem \
-subj "/C=CN/ST=Shanghai/L=Shanghai/O=Qualstor.com/OU=Qualstor/CN=Qualstor CA/emailAddress=ca@qualstor.com"

-----
Country Name (2 letter code) [AU]:CN
State or Province Name (full name) [Some-State]:Shanghai
Locality Name (eg, city) []:Shanghai
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Qualstor
Organizational Unit Name (eg, section) []:Qualstor
Common Name (e.g. server FQDN or YOUR name) []:Qualstor
Email Address []:info@qualstor.com

# 注解
-new    生成新证书签署请求
-x509   专用于CA生成自签证书
-key    生成请求时用到的私钥文件
-days n 证书有效期限
-out    证书保持路径
-subj   非交互式生成证书

```

## 4. 签发证书

- 生成自签证书私钥

```shell
(umask 077;openssl genrsa -out /root/ssl/key/nginx.key 2048)
```

- 生成自签证书

```shell
openssl req -new \
-key /root/ssl/key/nginx.key \
-out /root/ssl/certs/nginx.csr \
-subj "/C=CN/ST=Shanghai/L=Shanghai/O=Qualstor/OU=Qualstor/CN=Qualstor ngixn/emailAddress=nginx@qualstor.com"


# 重要说明：
# Common Name：即是域名
```

- 签发证书

```shell
openssl x509 -req -days 7300 -sha256 \
-in /root/ssl/certs/nginx.csr \
-CA /root/ssl/certs/cacert.pem \
-CAkey /root/ssl/key/cakey.pem \
-CAcreateserial -out /root/ssl/certs/nginx.crt
```

## 5. 应用证书

- 部署nginx服务

```shell
apt -y install nginx
```

- nginx配置

```shell
vim /etc/nginx/conf.d/nginx_ssl.conf
server {
    listen 443 ssl;
    server_name 0.0.0.0;
    root /var/www/html/;
    index index.html index.htm index.nginx-debian.html;
    ssl_certificate  /root/ssl/certs/nginx.crt;
    ssl_certificate_key /root/ssl/private/nginx.key;
    ssl_session_timeout 5m;
    ssl_prefer_server_ciphers on;
    location / {
        try_files $uri $uri/ =404;
    }
}
server {
    listen 80;
    server_name 0.0.0.0;
    rewrite ^(.*)$ https://$host$1 permanent;
}
```

- 重启验证

```shell
nginxt -t
systemctl restart nginx.service
systemctl status nginx.service
```

## 浏览器应用证书

这里使用了自建的CA来颁布证书，只要下载根证书，即：/root/ssl/certs/cacert.pem
之后所有从CA签发的证书，将不需求在导入证书，都可以被识别。
cacert.pem在windows下可以改后缀名为crt，这样双击可以导入证书。