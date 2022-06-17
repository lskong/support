#!/usr/bin/bash
source /etc/kolla/admin-openrc.sh

## REMEMBER TO UPDATE THE HYPERVISOR COMPUTE HOST NAME
hypervisor="r7node2 r7node3 r7node4"

for host in $hypervisor
do
  echo "Test VMs in $host"
  openstack server list --host $host |grep isstest |wc -l
done
