# Example procedures and helper scripts for installing and executing workload benchmark.

Please note partners might need to make customization to the scripts below for their own deployment environment.

Default VM Operating System: CentOS 7.6.

# Helper Scripts 

Please review and check the content of the script (and make necessary changes) before running.

* Create server VMs with volume attached, and generate files for ansible run (For use as VDBench and Redis instances)

  ./scripts/create_servers.sh $num-of-vms $num-of-vols-per-vm

* Clean up all the server VMs and volumes

  ./scripts/delete_server.sh 

* Create client VMs with volume attached, and generate files for ansible run (For use as memtier clients)

  ./scripts/create_clients.sh $num-of-vms $num-of-vols-per-vm

* Clean up all the client VMs and volumes

  ./scripts/delete_clients.sh 

* Display # VMs for each hypervisor

  ./scripts/vmstat.sh

* Reference procedure to install OpenStack Rally

  ./scripts/install_rally.sh

* Reference procedure to create OpenStack compute flavor for redis and memtier

  ./scripts/create_redis_flavors.sh

* Reference procedure to install memtier (1-1 redis-memtier server-client mapping)

  ./scripts/python memtier.py

* Ansible playbook to install vdbench and start rsh daemon

  ./scripts/vdbench.yaml 


# Storage Benchmark 

Please review and check the content of the script (and make necessary changes) before running.

1. Launch 30 VMs m1.large (CentOS 7.6, 4 vCPU, 8GB RAM), attach 2x 50GB volume for each VM. 

   ./scripts/create_servers.sh 30 2

2. Install and run VDBench on each VMs

   ./ansible-playbook -i servers example/vdbench.yaml

3. Launch VDBench Master VM (CentOS 7.6, 8 vCPU, 16GB RAM, 20GB Volume)

   Remember to update the command arguments for your OpenStack deployment environment.

   openstack server create --image CentOS --flavor m1.xlarge --key-name mykey --nic net-id=demo-net vdbench-master

4. Copy vdbench50407.zip to Master VM

   ./scp ansible/roles/vdbench/files/vdbench50407.zip centos@<Master VM IP>

   ./scp ansible/roles/vdbench/files/iss.param centos@<Master VM IP>

   Remember to update the "Host Definition" ip address in iss.param to the 30 VMs in above step.

5. Install VDBench on Master VM

   $yum install –y java-1.8.0-openjdk

   $unzip vdbench50407.zip 

6. Run VDBench benchmark with parameter file

   $./vdbench –f iss.param –o output-result-dir


# OpenStack Rally Benchmark

Please review and check the content of the script (and make necessary changes) before running.

1. Install Rally

   ./scripts/install_rally.sh

2. Sample rally template

   ./rally/boot-server-attach-volume-and-list-attachments.json

3. Run Rally benchmark. 

   Remember to update flavor_name and runner_times for rally testing.

   Base config verification - flavor_name: m1.small, runner_times: 200.

   Plus config verification - flavor_name: m1.small, runner_times: 1000. 

   ./rally task start boot-server-attach-volume-and-list-attachments.json 

   ./rally task report <rally-task-id> --out output.html

# Redis/Memtier Benchmark

Please review and check the content of the script (and make necessary changes) before running.

1. Create compute flavor for Redis servers and Memtier clients.

   ./scripts/create_redis_flavors.sh

2. Launch X VMs for Redis server (CentOS 7.6, 16GB RAM). 

   Base config verification - 20 VMs.

   Plus config verification - 60 VMs.

   Remember to update the flavor name in the script to the above redis flavor.

   ./scripts/create_servers.sh 20 0

3. Install Redis servers

   ./ansible-playbook -i servers example/redis.yaml

4. Launch X VMs for Memtier client (CentOS 7.6, 8GB RAM). 

   Base config verification: 20 VMs.

   Plus config verification: 60 VMs.

   Remember to update the flavor name in the script to the above memtier flavor.

   ./scripts/create_clients.sh 20 0

5. Install Memtier clients

   ./ansible-playbook -i clients example/memtier.yaml

6. Execute Redis/Memtier benchmark

   Copy the above "servers" and 'clients" inventory file to the same location as memtier.py.

   You need to have the appropriate OpenStack SSH keypair for accessing servers or clients VM.

   ./python memtier.py

