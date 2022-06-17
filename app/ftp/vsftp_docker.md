# vsftp_docker
[toc]


## vsftp docker介绍

容器vsftp具有以下特点：
- 采用centos7基础镜像
- 采用vsftp3.0
- 支持虚拟用户
- 支持被动模式
- 日志标准输出


Git项目：https://github.com/fauria/docker-vsftpd


## 部署
- 拉取容器

```shell
docker pull fauria/vsftpd
```

- 容器变量说明

```shell
FTP_USER             FTP用户，默认值admin        -e FTP_USER=myuser
FTP_PASS             FTP用户密码，默认随机生成    -e FTP_PASS=mypass
PASV_ADDRESS         被动模式的docker的主机IP或主机名
PASV_ADDR_RESOLVE    默认NO <NO|YES> 如果在PASV_ADDRESS中设置为主机名，则此参数需要设置为YES
PASV_ENABLE          默认YES <NO|YES> 不使用被动模式，设置为 NO。
PASV_MIN_PORT        起始端口，默认21100
PASV_MAX_PORT        结束端口，默认21100
XFERLOG_STD_FORMAT   默认NO，如果您希望以标准 xferlog 格式写入传输日志文件，请设置为 YES。
LOG_STDOUT           默认空值，表示禁用
FILE_OPEN_MODE       文件系统权限，默认0666
LOCAL_UMASK          文件系统权限，默认077
REVERSE_LOOKUP_ENABLE   默认YES，如果您想避免名称服务器不响应反向查找的性能问题，请设置为 NO。
PASV_PROMISCUOUS     默认NO，如果要禁用 PASV 安全检查以确保数据连接源自与控制连接相同的 IP 地址，请设置为 YES。 仅当您知道自己在做什么时才启用！ 唯一合法的用途是在某种形式的安全隧道方案中，或者可能是为了促进 FXP 支持。

PORT_PROMISCUOUS     默认NO，如果要禁用确保传出数据连接只能连接到客户端的 PORT 安全检查，请设置为 YES。 仅当您知道自己在做什么时才启用！ 这样做的合法用途是促进 FXP 支持

```

- 启动容器

```shell
# 启动主动和被动模式
docker run -d -v /home/rock/Project/:/home/vsftpd/ \
    -p 20:20 -p 21:21 -p 21100-21110:21100-21110 \
    -e FTP_USER=admin  -e FTP_PASS=admin \
    -e PASV_MIN_PORT=21100 -e PASV_MAX_PORT=21110 \
    --name vsftpd --restart=always fauria/vsftpd
```

- 手动启动

```shell
docker exec -i -t vsftpd bash
mkdir /home/vsftpd/myuser
echo -e "myuser\nmypass" >> /etc/vsftpd/virtual_users.txt  # 用户和密码换行
/usr/bin/db_load -T -t hash -f /etc/vsftpd/virtual_users.txt /etc/vsftpd/virtual_users.db  # 用户密码文件转换
exit
docker restart vsftpd

```


- 关于被动模式227 Entering Passive Mode

```shell
# 描述
在专有网络服务器中搭建FTP时，通过本地的计算机访问FTP的时候出现
220 switching to ASCII mode.
227 Entering Passive Mode (172,17,208,91,43,).

# 分析
专有网络VPC只支持【主动模式】的FTP服务，FTP服务端和客户端都必须配置为主动模式，才可以正常传输

# 解决
打开Internet选项
选择高级选项卡，找到选项，使用被动FTP（用于防火墙和DSL调制解调器的兼容）---》将勾去掉，点击确定

```