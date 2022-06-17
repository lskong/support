#!/usr/bin/bash
## USAGE
## create_clients.sh <num-servers> <num-volumes>
## eg. create_clients.sh 30 2
##
## REMEMBER UPDATE THE PARAMETERS
## image = glance image name
## flavor = nova flavor name
## keypair = keypair name
## network = network name
## vol_size = the size of cinder volume in GB
source /etc/kolla/admin-openrc.sh

vm_number=${1:-1}
vol_number=${2:-0}
vol_size=20
vm_name=issclient
image=CentOS
flavor=client
keypair=mykey
network=demo-net

echo "Create $vm_number instances, each with $vol_number volumes"

openstack server create --image $image --flavor $flavor --key-name $keypair --nic net-id=$network \
 --min $vm_number --max $vm_number $vm_name --wait

# Create volumes 
for i in `seq 1 ${vm_number}`
do
  echo "Creating $vol_number volumes for $vm_name-$i"
  for j in `seq 1 ${vol_number}`
    do
      echo "Creating $vm_name-$i-vol$j"
      openstack volume create --size $vol_size ${vm_name}-$i-vol$j
      openstack server add volume ${vm_name}-$i ${vm_name}-$i-vol$j
    done
done

# Generating inventory file for ansible
echo "Generating inventory file for ansible"
openstack server list -f value -c Networks -c Name |grep $vm_name | awk -F"=" '{print $2}' > clients

