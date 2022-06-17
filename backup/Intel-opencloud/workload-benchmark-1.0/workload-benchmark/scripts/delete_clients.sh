#!/usr/bin/bash
source /etc/kolla/admin-openrc.sh

vm_name=issclient

echo "Deleting all $vm_name-* instances"

openstack server list -c Name |grep $vm_name |awk '{print $2}' |xargs openstack server delete

# delete all $vm_name volumes
echo "Deleting all $vm_name-* volumes"
openstack volume list -c Name |grep isstest |awk '{print $2}' |xargs openstack volume delete


