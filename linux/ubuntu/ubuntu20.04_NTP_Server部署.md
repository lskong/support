# Ubuntu 20.04 NTP Service

## 主机
```shell
172.16.103.31 node1 (server)
172.16.103.32 node2
172.16.103.33 node3
```

## install ntp Service

```shell
# all node
apt -y install ntp

```


## ntp config
```shell
# node1
cat > /etc/ntp.conf << EOF
driftfile /var/lib/ntp/ntp.drift
server  127.127.1.0
fudge   127.127.1.0 stratum 7

# othe two node

cat > /etc/ntp.conf << EOF
driftfile /var/lib/ntp/ntp.drift
server  172.16.103.31 burst  iburst
server  127.127.1.0
fudge   127.127.1.0 stratum 9
EOF

```

## restart ntp
```shell
# all node
systemctl daemon-reload
systemctl restart ntp.service
systemctl enable ntp.service
```
