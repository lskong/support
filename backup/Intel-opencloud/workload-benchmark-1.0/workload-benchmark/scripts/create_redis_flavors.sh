# REMEMBER TO UPDATE THE DISK, RAM or VCPUS
# DEFAULT 16GB RAM for redis server and 8GB for memtier client.

openstack flavor create --disk 40 --ram 16384 --vcpus 8 redis
openstack flavor create --disk 40 --ram 8192 --vcpus 4 client
