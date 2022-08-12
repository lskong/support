# apt-get源搭建

环境信息：

|     IP      |              服务              |                    源包存储位置                    |
| :---------: | :----------------------------: | :------------------------------------------------: |
| 172.16.1.23 | 源服务器（包含本地源与网络源） | 本地源：/data/debs  &&  网络源：/var/www/html/soft |
| 172.16.1.24 |            应用节点            |            http://172.16.1.23:81/ soft/            |
| 172.16.1.25 |            应用节点            |            http://172.16.1.23:81/ soft/            |

### 1. 制作本地源

``` shell
# node1
// 创建初始化data目录，传软件包到data目录，解压软包；
mkdir -p /data;cd /data
tar xf Qualstor_QDSS_v2.0.tar.gz
ls -l ./qdss

// 本地源
mv /etc/apt/sources.list /etc/apt/sources.list.defaults
cat > /etc/apt/sources.list <<-"EOF"
deb [trusted=yes] file:///data/qdss/package/local_source/ debs/
EOF
apt update
apache2 -v

// 局域网源
sed -i "s/80/81/g" /etc/apache2/ports.conf
systemctl restart apache2.service

cd /var/www/html/
rm -f ./index.html
ln -s /data/qdss/package/network_source/ soft


cat > /etc/apt/sources.list.d/qdss.list <<-"EOF"
deb [trusted=yes] http://node1:81/ soft/
EOF
apt update


```
操作节点：**172.16.1.23**

- 创建缓存目录

```apl
root@node3:~# mkdir -p /data/debs
```

- 复制软件包到缓存目录

```
root@node3:~# cp -r /root/{软件包} /data/debs/
```

- 添加本地源

```apl
root@node3:~# vim /etc/apt/sources.list
注释原所有内容，添加：
deb [trusted=yes] file:///data/ debs/

# 注意上面的 /data 和 debs/ 之间的空格，以及 “/”
```

- 更新并升级源

```apl
root@node3:~# apt-get update
root@node3:~# apt-get upgrade
```

- 安装包索引文件

```apl
root@node3:~# apt install dpkg-dev
```



### 2. 局域网源制作

操作节点：**172.16.1.23**（该节点配置为源服务器）

- 安装apache2

  **该apache2软件用于发布源，用作局域网源**

```apl
root@node3:~# apt install apache2

root@node3:~# apache2 -v
Server version: Apache/2.4.41 (Ubuntu)
Server built:   2021-06-17T18:27:53
```

- 配置apache2

```apl
# 修改配置文件第5行监听端口为”81“，原监听端口为”80“
root@node3:~# sed -i "s/80/81/g" /etc/apache2/ports.conf

# 重启apache2服务
root@node3:~# systemctl restart apache2.service
```

- 创建软件缓存目录

```apl
root@node3:~# mkdir -p /var/www/html/soft

# apache2软件默认发布目录为：/var/www/html/
```

- 复制软件包到缓存目录

```apl
root@node3:~# cp -r /root/{软件包} /var/www/html/soft
```



### 3. 客户机应用该网络源

操作节点：**172.16.1.24** 或 **172.16.1.25**

- 添加网络源

```apl
root@node3:~# vim /etc/apt/sources.list

注释原所有内容，添加：
deb [trusted=yes] http://172.16.1.23:81/ soft/

# 添加从源服务器发布出的源,格式为：http://{sourceIP}：{port}/ {cache directory}/
```

- 更新并升级源

```apl
root@node3:~# apt-get update
root@node3:~# apt-get upgrade
```

