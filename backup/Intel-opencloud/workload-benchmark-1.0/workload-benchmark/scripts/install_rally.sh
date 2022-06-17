# Install OpenStack Rally as a regular user into a virtualenv
wget -q -O- https://raw.githubusercontent.com/openstack/rally/master/install_rally.sh | bash

source ~/rally/bin/activate
# install openstack plugin
pip install rally-openstack

# fix python package compatibility issue
pip install urllib3==1.24.2
pip install pyasn1==0.4.6

# create deployment
source /etc/kolla/admin-openrc.sh
rally deployment create --fromenv --name current

# Fix the cinder client version issue
#TypeError: create() got an unexpected keyword argument 'multiattach'
pip install python-cinderclient==4.3.0 

# Start tasks
# You may uncomment the following lines to execute the rally benchmark
# rally task start ./boot-server-attach-volume-and-list-attachments.json
