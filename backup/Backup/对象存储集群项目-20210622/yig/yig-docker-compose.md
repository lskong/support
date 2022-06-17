```shell
mkdir ~/package
cd ~/package
mkdir -p ~/package/yig{1,2,3}/log

cat > docker-compose.yml << \EOF
version: "2"

services:
  yig1:
    image: docker.xdxoazq.com.cn/library/yig:v1
    container_name: yig1
    networks:
      aiotest:
        ipv4_address: "192.168.4.221"
    volumes:
      - /etc/ceph/:/etc/ceph/
      - /etc/yig/:/etc/yig/
      - ./yig1/log:/var/log/yig
    command: /etc/yig/yig

  yig2:
    image: docker.xdxoazq.com.cn/library/yig:v1
    container_name: yig2
    networks:
      aiotest:
        ipv4_address: "192.168.4.222"
    volumes:
      - /etc/ceph/:/etc/ceph/
      - /etc/yig/:/etc/yig/
      - ./yig2/log:/var/log/yig
    command: /etc/yig/yig

  yig3:
    image: docker.xdxoazq.com.cn/library/yig:v1
    container_name: yig3
    networks:
      aiotest:
        ipv4_address: "192.168.4.223"
    volumes:
      - /etc/ceph/:/etc/ceph/
      - /etc/yig/:/etc/yig/
      - ./yig3/log:/var/log/yig
    command: /etc/yig/yig

networks:
  aiotest:
    driver: macvlan
    driver_opts:
      parent: ens38
      macvlan_mode: bridge
    ipam:
     config:
       - subnet: 192.168.4.0/24
         gateway: 192.168.4.1
EOF

# 如果不行，则单机测试
sudo docker run --name yig002 -it -v /etc/ceph/:/etc/ceph/ -v /etc/yig/:/etc/yig/ docker.xdxoazq.com.cn/library/yig:v1 bash
```