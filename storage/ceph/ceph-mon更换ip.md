root@qdss-node-01:~# ceph mon getmap -o ./monmap
got monmap epoch 4


root@qdss-node-01:~# monmaptool --print monmap
monmaptool: monmap file monmap
epoch 4
fsid 52048039-1f82-48f6-8d5a-1f46b4c96a4e
last_changed 2022-01-05T00:02:55.839460+0800
created 2022-01-05T00:02:21.177613+0800
min_mon_release 15 (octopus)
0: [v2:10.103.0.42:3300/0,v1:10.103.0.42:6789/0] mon.qdss-node-02
1: [v2:10.103.0.41:3300/0,v1:10.103.0.41:6789/0] mon.qdss-node-01
2: [v2:10.103.0.43:3300/0,v1:10.103.0.43:6789/0] mon.qdss-node-03


root@qdss-node-01:~# monmaptool --rm qdss-node-01 --rm qdss-node-02 --rm qdss-node-03 ./monmap
monmaptool: monmap file ./monmap
monmaptool: removing qdss-node-01
monmaptool: removing qdss-node-02
monmaptool: removing qdss-node-03
monmaptool: writing epoch 4 to ./monmap (0 monitors)


root@qdss-node-01:~# monmaptool --print monmap
monmaptool: monmap file monmap
epoch 4
fsid 52048039-1f82-48f6-8d5a-1f46b4c96a4e
last_changed 2022-01-05T00:02:55.839460+0800
created 2022-01-05T00:02:21.177613+0800
min_mon_release 15 (octopus)




root@qdss-node-01:~# monmaptool --add qdss-node-01 10.103.1.41:6789 --add qdss-node-02 10.103.1.42:6789 --add qdss-node-03 10.103.1.43:6789 monmap
monmaptool: monmap file monmap
monmaptool: writing epoch 4 to monmap (3 monitors)


root@qdss-node-01:~# monmaptool --print monmap
monmaptool: monmap file monmap
epoch 4
fsid 52048039-1f82-48f6-8d5a-1f46b4c96a4e
last_changed 2022-01-05T00:02:55.839460+0800
created 2022-01-05T00:02:21.177613+0800
min_mon_release 15 (octopus)
0: v1:10.103.1.41:6789/0 mon.qdss-node-01
1: v1:10.103.1.42:6789/0 mon.qdss-node-02
2: v1:10.103.1.43:6789/0 mon.qdss-node-03

scp ./monmap qdss-node-01:/root/
systemctl stop ceph.service
ceph-mon -i qdss-node-01 --inject-monmap ./monmap