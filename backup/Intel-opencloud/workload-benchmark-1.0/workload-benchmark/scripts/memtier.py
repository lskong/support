# This script will create the memtier execution command for each client VM
# Each memtier client will send requests to a redis server 
# The following 2 files are required for an 1-1 mapping
# servers - redis server VM IPs
# clients - memtier client VM IPs

import subprocess
tmpfile="tmp/run_memtier.sh"
servers_path="./servers"
clients_path="./clients"

servers = [line.rstrip('\n') for line in open(servers_path)]
clients = [line.rstrip('\n') for line in open(clients_path)]

ttt = zip(servers, clients)

for s,c in ttt:
    # print("Server is :%s, client is : %s" % (s, c))
    cmd = "/usr/local/bin/memtier_benchmark --server {} -p 6379 --threads 8 --clients 1 --test-time 300 --ratio 1:10 --data-size 1024 --key-pattern S:S --random-data".format(s)
    f = open(tmpfile, 'w')
    f.write(cmd)
    f.close()
    print("Copy following cmd to %s" % c)
    print(cmd)
    subprocess.check_call(['scp', tmpfile, '{}:~/'.format(c)])

