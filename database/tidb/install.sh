#!/bin/bash

PROJECTDIR=$(cd $(dirname $0); pwd)

conf_rd=conf.ini
conf_fn=topology.yaml

# delete config file
rm -f $conf_fn

wconf() {
    cat >> "$conf_fn"
}

build_global() {
    global_user=$1
    global_group=$2
    global_ssh_port=$3
    global_deploy_dir=$4
    global_data_dir=$5

    echo "global:
  # # The user who runs the tidb cluster.
  user: \"$global_user\"
  # # group is used to specify the group name the user belong to if it's not the same as user.
  # group: \"$global_group\"
  # # SSH port of servers in the managed cluster.
  ssh_port: $global_ssh_port
  # # Storage directory for cluster deployment files, startup scripts, and configuration files.
  deploy_dir: \"$global_deploy_dir\"
  # # TiDB Cluster data storage directory
  data_dir: \"$global_data_dir\"
  # # Supported values: \"amd64\", \"arm64\" (default: \"amd64\")
  arch: \"amd64\"
  # # Resource Control is used to limit the resource of an instance.
  # # See: https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html
  # # Supports using instance-level \`resource_control\` to override global \`resource_control\`.
  # resource_control:
  #   # See: https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html#MemoryLimit=bytes
  #   memory_limit: \"2G\"
  #   # See: https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html#CPUQuota=
  #   # The percentage specifies how much CPU time the unit shall get at maximum, relative to the total CPU time available on one CPU. Use values > 100% for allotting CPU time on more than one CPU.
  #   # Example: CPUQuota=200% ensures that the executed processes will never get more than two CPU time.
  #   cpu_quota: \"200%\"
  #   # See: https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html#IOReadBandwidthMax=device%20bytes
  #   io_read_bandwidth_max: \"/dev/disk/by-path/pci-0000:00:1f.2-scsi-0:0:0:0 100M\"
  #   io_write_bandwidth_max: \"/dev/disk/by-path/pci-0000:00:1f.2-scsi-0:0:0:0 100M\"" 
}



build_monitored(){
    mon_node_exporter_port=$1
    mon_blackbox_exporter_port=$2
    mon_deploy_dir=$3
    mon_data_dir=$4

    echo "monitored:
    # # The communication port for reporting system information of each node in the TiDB cluster.
    node_exporter_port: $mon_node_exporter_port
    # # Blackbox_exporter communication port, used for TiDB cluster port monitoring.
    blackbox_exporter_port: $mon_blackbox_exporter_port
    # # Storage directory for deployment files, startup scripts, and configuration files of monitoring components.
    # deploy_dir: \"$mon_deploy_dir/monitored-$mon_node_exporter_port\"
    # # Data storage directory of monitoring components.
    # data_dir: \"$mon_data_dir/monitored-$mon_node_exporter_port\"
    # # Log storage directory of the monitoring component.
    # log_dir: \"$mon_deploy_dir/monitored-$mon_node_exporter_port/log\""
}

build_pd_server(){
    pd_host=$1
    pd_ssh_port=$2
    pd_name=$3
    pd_client_port=$4
    pd_peer_port=$5
    pd_deploy_dir=$6
    pd_data_dir=$7

    echo "  - host: $pd_host
    # # SSH port of the server.
    ssh_port: $pd_ssh_port
    # # PD Server name
    name: "$pd_name"
    # # communication port for TiDB Servers to connect.
    client_port: $pd_client_port
    # # Communication port among PD Server nodes.
    peer_port: $pd_peer_port
    # # PD Server deployment file, startup script, configuration file storage directory.
    deploy_dir: \"$pd_deploy_dir/pd-$pd_client_port\"
    # # PD Server data storage directory.
    data_dir: \"$pd_data_dir/pd-$pd_client_port\"
    # # PD Server log file storage directory.
    log_dir: \"$pd_deploy_dir/pd-$pd_client_port/log\"
    # # numa node bindings.
    # numa_node: \"0,1\"
    # # The following configs are used to overwrite the \`server_configs.pd\` values.
    # config:
    #   schedule.max-merge-region-size: 20
    #   schedule.max-merge-region-keys: 200000"
}

build_tidb_servers(){
    tidb_host=$1
    tidb_ssh_port=$2
    tidb_port=$3
    tidb_status_port=$4
    tidb_deploy_dir=$5

    echo "  - host: $tidb_host
    # # SSH port of the server.
    ssh_port: $tidb_ssh_port
    # # The port for clients to access the TiDB cluster.
    port: $tidb_port
    # # TiDB Server status API port.
    status_port: $tidb_status_port
    # # TiDB Server deployment file, startup script, configuration file storage directory.
    deploy_dir: \"$tidb_deploy_dir/tidb-$tidb_port\"
    # # TiDB Server log file storage directory.
    log_dir: \"$tidb_deploy_dir/tidb-$tidb_port/log\""
}

build_tikv_servers() {
    tikv_host=$1
    tikv_ssh_port=$2
    tikv_port=$3
    tikv_status_port=$4
    tikv_deploy_dir=$5
    tikv_data_dir=$6

    echo "  - host: $tikv_host
    # # SSH port of the server.
    ssh_port: $tikv_ssh_port
    # # TiKV Server communication port.
    port: $tikv_port
    # # TiKV Server status API port.
    status_port: $tikv_status_port
    # # TiKV Server deployment file, startup script, configuration file storage directory.
    deploy_dir: \"/kvdata/tidb-deploy/tikv-$tikv_port\"
    # # TiKV Server data storage directory.
    data_dir: \"$tikv_deploy_dir/tikv-$tikv_port\"
    # # TiKV Server log file storage directory.
    log_dir: \"$tikv_data_dir/tikv-$tikv_port/log\""
}

#----------------------------------------------------------------------------------------
# global conf
global_user=$(awk -F "=" '/global_user/ {print $2}' $conf_rd)
global_group=$(awk -F "=" '/global_group/ {print $2}' $conf_rd)
global_ssh_port=$(awk -F "=" '/global_ssh_port/ {print $2}' $conf_rd)
global_deploy_dir=$(awk -F "=" '/global_deploy_dir/ {print $2}' $conf_rd)
global_data_dir=$(awk -F "=" '/global_data_dir/ {print $2}' $conf_rd)

out=`build_global $global_user $global_group $global_ssh_port $global_deploy_dir $global_data_dir`
wconf << EOF
$out
EOF

#----------------------------------------------------------------------------------------
# monitored conf
mon_node_exporter_port=$(awk -F "=" '/mon_node_exporter_port/ {print $2}' $conf_rd)
mon_blackbox_exporter_port=$(awk -F "=" '/mon_blackbox_exporter_port/ {print $2}' $conf_rd)
mon_deploy_dir=$(awk -F "=" '/mon_deploy_dir/ {print $2}' $conf_rd)
mon_data_dir=$(awk -F "=" '/mon_data_dir/ {print $2}' $conf_rd)
out=`build_monitored $mon_node_exporter_port $mon_blackbox_exporter_port $mon_deploy_dir $mon_data_dir`
wconf << EOF
$out
EOF

#----------------------------------------------------------------------------------------
# pd_server conf
pd_host=$(awk -F "=" '/pd_host/ {print $2}' $conf_rd)
pd_ssh_port=$(awk -F "=" '/pd_ssh_port/ {print $2}' $conf_rd)
pd_name=$(awk -F "=" '/pd_name/ {print $2}' $conf_rd)
pd_client_port=$(awk -F "=" '/pd_client_port/ {print $2}' $conf_rd)
pd_peer_port=$(awk -F "=" '/pd_peer_port/ {print $2}' $conf_rd)
pd_deploy_dir=$(awk -F "=" '/pd_deploy_dir/ {print $2}' $conf_rd)
pd_data_dir=$(awk -F "=" '/pd_data_dir/ {print $2}' $conf_rd)
# echo $pd_host
arr=($pd_host)
wconf << EOF
pd_servers:

EOF

for i in "${!arr[@]}";   
do

out=`build_pd_server ${arr[$i]} $pd_ssh_port $pd_name-$i $pd_client_port $pd_peer_port $pd_deploy_dir $pd_data_dir`
wconf << EOF
$out
EOF

done

#----------------------------------------------------------------------------------------
# tidb_servers conf

tidb_host=$(awk -F "=" '/tidb_host/ {print $2}' $conf_rd)
tidb_ssh_port=$(awk -F "=" '/tidb_ssh_port/ {print $2}' $conf_rd)
tidb_port=$(awk -F "=" '/tidb_port/ {print $2}' $conf_rd)
tidb_status_port=$(awk -F "=" '/tidb_status_port/ {print $2}' $conf_rd)
tidb_deploy_dir=$(awk -F "=" '/tidb_deploy_dir/ {print $2}' $conf_rd)

wconf << EOF
tidb_servers:
EOF
# echo $tidb_host
arr=($tidb_host)
for element in ${arr[@]}
do

out=`build_tidb_servers $element $tidb_ssh_port $tidb_port $tidb_status_port $tidb_deploy_dir`
wconf << EOF
$out
EOF

done


#----------------------------------------------------------------------------------------
# tikv_servers conf
tikv_host=$(awk -F "=" '/tikv_host/ {print $2}' $conf_rd)
tikv_ssh_port=$(awk -F "=" '/tikv_ssh_port/ {print $2}' $conf_rd)
tikv_port=$(awk -F "=" '/tikv_port/ {print $2}' $conf_rd)
tikv_status_port=$(awk -F "=" '/tikv_status_port/ {print $2}' $conf_rd)
tikv_deploy_dir=$(awk -F "=" '/tikv_deploy_dir/ {print $2}' $conf_rd)
tikv_data_dir=$(awk -F "=" '/tikv_data_dir/ {print $2}' $conf_rd)

wconf << EOF
tikv_servers:
EOF
# echo $tikv_host
arr=($tikv_host)
for element in ${arr[@]}
do

out=`build_tikv_servers $element $tikv_ssh_port $tikv_port $tikv_status_port $tikv_deploy_dir tikv_data_dir`
wconf << EOF
$out
EOF

done


$PROJECTDIR/tidb-community-server-v5.0.0-linux-amd64/local_install.sh

source ~/.profile

result=`tiup --binary cluster`
if [ -z "$result" ]; then
    echo "tiup no found!!!! result:"$result
    exit
fi

tikv_cluster=$(awk -F "=" '/tikv_cluster/ {print $2}' $conf_rd)
tiup cluster deploy -y $tikv_cluster v5.0.0 ./topology.yaml --user root|tee -a output.data
result=`cat output.data|grep successfully`
rm -f output.data
if [ -z "$result" ]; then
    echo "tiup deployed fail!!!"
    exit
else
    echo "tidb deployed successfully!!!"
fi

timeout 90 tiup cluster start $tikv_cluster
tiup cluster display $tikv_cluster|tee -a output.data
result=`cat output.data|grep Down`
rm -f output.data
if [ "$result" ]; then
    echo "tiup cluster start fail!!!"
    exit
else
    echo "tiup cluster start successfully!!!"
fi


