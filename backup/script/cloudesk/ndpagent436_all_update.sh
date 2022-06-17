#!/bin/sh
# +-----------------------------------------------------------------
# | Install the script for NSDL desktop backup
# +-----------------------------------------------------------------
# | This script works with NSDL Desktop V3/V4
# | 
# | 
# +-----------------------------------------------------------------
# | Auther    :   	rock
# | Date      :		2020-07-16
# | Contact   :		
# | Version   :   	v2.7
# +-----------------------------------------------------------------
# | This Script module
# | [Global]	: Loading system function and Custom variable eg.
# | [Main]	: The core statement of the script.
# | [Error]	: Log some error messages.
# +-----------------------------------------------------------------
# | Note:
# | - This script works for the CentOS8 platform.
# | - Before running,determine the "Custom variable" of the [Global]
# | - If there is a problem in operation, please contact and record 
# |	- the problem information.
# +-----------------------------------------------------------------



# +----------------------------------------------------------
# | [Global] 
# +----------------------------------------------------------
# Reload System lib
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
. /etc/profile

# Custom variable
G_REMOTE_IP="10.31.184.9"
G_NDP_NSDL_VER="NDP_NSDL_V4.3.6"
G_NDP_NSDL_PATH="/opt/NDP"
G_MONO_SERVICE="nbp-mono.service"
G_DATE_FORMAT=`date +%Y%m%d_%H:%M`
G_MESSAGE=""



# +----------------------------------------------------------
# | [Main] 
# +----------------------------------------------------------
# Print message
print(){
    if [ $? -eq 0 ];then
        action "${G_MESSAGE}  Success!" /bin/true
        echo -e "\n"
    else
        action "${G_MESSAGE} Fail!" /bin/false
        exit 9
        echo -e "\n"
    fi
} 

# check mono process
check(){
    G_MESSAGE="++++++>>> Check mono process..."
    echo ${G_MESSAGE}
    sleep 2
    M_CHECK=`ps -ef|grep mono|wc -l`
    if [ ${M_CHECK} -ge 2 ];then
        echo "++++++>>> Mono is running, proces a ${M_CHECK}..."
        exit 1
    fi
}


# Start Service
service(){
    systemctl daemon-reload
    systemctl enable nbp-mono.service
    systemctl start nbp-mono.service
}

# Create mono.repo file
mrepo(){
cat >mono.repo<<EOF
[mono]
name=mono
baseurl=file:///${G_NDP_NSDL_PATH}/mono8
gpgcheck=0
EOF
}

# Create mono service
mserv(){
cat >nbp-mono.service<<EOF
[Unit]
Description=nbp mono daemon
After=network.target sshd.service
Wants=sshd.service

[Service]
Type=simple
PIDFile=/var/run/nbp-mono.pid
EnvironmentFile=/etc/sysconfig/nbp-mono
ExecStart=/usr/bin/mono-sgen /opt/NDP/${G_NDP_NSDL_VER}/NDP.Server.exe
ExecReload=/bin/kill -HUP '$MAINPID'
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF
}


# Install NDP_Client
ndp(){
    G_MESSAGE="++++++>>> Configure NDP NSDL Client..."
    echo ${G_MESSAGE}
    sleep 2
    cd ${G_NDP_NSDL_PATH}
    # curl -o ${G_NDP_NSDL_VER}.zip  http://${G_REMOTE_IP}/NSDL/${G_NDP_NSDL_VER}.zip
    unzip -oq ${G_NDP_NSDL_VER}.zip
    chmod +x ${G_NDP_NSDL_VER}/nsdl_uuid.sh
    service
    print
    rm -f ${G_NDP_NSDL_VER}.zip
}

# Install Mono
mono(){
    check
    G_MESSAGE="++++++>>> Installing Mono service..."
    echo ${G_MESSAGE}
    sleep 2
    M_MONO=`rpm -qa|grep mono|wc -l`
    if [ ${M_MONO} -ge 10 ];then
        echo "++++++>>> Mono already exists, no installation is required."
        echo -e "\n"
    else
        cd ${G_NDP_NSDL_PATH}
        tar xf mono8.tar.gz
        cd /etc/yum.repos.d/
        [ -f mono.repo ] && mv mono.repo mono.repo.${G_DATE_FORMAT}
        # curl -o mono.repo http://${G_REMOTE_IP}/NSDL/mono.repo
        mrepo
        yum makecache
        yum -y install mono-devel
        print
        rm -f mono.repo
        cd ${G_NDP_NSDL_PATH}
        rm -f mono8.tar.gz
        rm -rf mono8
    fi

    # Add mono service file
    G_MESSAGE="++++++>>> Add mono service file ..."
    echo ${G_MESSAGE}
    sleep 2
    cd /usr/lib/systemd/system
    [ -f ${G_MONO_SERVICE} ] && mv ${G_MONO_SERVICE} ${G_MONO_SERVICE}.${G_DATE_FORMAT}
    # curl -o /usr/lib/systemd/system/${G_MONO_SERVICE} http://${G_REMOTE_IP}/NSDL/${G_MONO_SERVICE}
    mserv
    print
    touch /var/run/nbp-mono.pid
    touch /etc/sysconfig/nbp-mono
    
}

# copy NSDL file
cpnsdl(){
    G_MESSAGE="++++++>>> Copy NDP NSDL file..."
    echo ${G_MESSAGE}
    [ ! -d ${G_NDP_NSDL_PATH} ] && mkdir -p ${G_NDP_NSDL_PATH}
    cd ${G_NDP_NSDL_PATH}    
    sshpass -p "ndp@123" scp -P2222 -o StrictHostKeyChecking=no nsdl@${G_REMOTE_IP}:~/* .
    print
}

# Install sshpass
sshp(){
    G_MESSAGE="++++++>>> Install sshpass service..."
    echo ${G_MESSAGE}
    sleep 2
    M_SSHP=`rpm -qa|grep sshpass|wc -l`
    if [ ${M_SSHP} -gt 0 ];then
        echo "++++++>>> sshpass already exists, no installation is required."
        echo -e "\n"
    else
        yum -y install sshpass
        print
    fi
}

# Main Running
main(){
    sshp
    cpnsdl
    mono
    ndp
    check
}

main

# Main End



# +---------------------------------------------------------
# | [Error]
# +---------------------------------------------------------