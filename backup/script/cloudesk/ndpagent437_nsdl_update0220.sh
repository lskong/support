#!/bin/bash
# +-------------------------------------------------------------------+
# | Install the script for NSDL desktop backup                        |
# +-------------------------------------------------------------------+
# | This script works with NSDL Desktop V3/V4                         |
# |                                                                   |
# |                                                                   |
# +-------------------------------------------------------------------+
# | Auther    :     rockchou                                          |
# | Date      :     2021-01-21                                        |
# | Contact   :                                                       |
# | Version   :     v4.3.7                                            |
# +-------------------------------------------------------------------+
# | This Script module                                                |
# | [Global]  : Loading system function and Custom variable eg        |
# | [Main]    : The core statement of the script.                     |
# | [Error]   : Log some error messages.                              |
# +-------------------------------------------------------------------+
# | Note:                                                             |
# | - This script works for the CentOS8 platform.                     |
# | - Before running,determine the "Custom variable" of the [Global]  |
# | - If there is a problem in operation, please contact and record   |
# | - the problem information.                                        |
# +-------------------------------------------------------------------+



# +-------------------------------------------------------------------+
# | [Global]                                                          |
# +-------------------------------------------------------------------+
# Reload System lib
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
. /etc/profile

# Custom variable
G_REMOTE_IP="10.31.184.9"
G_NDP_NSDL_VER="NDP_NSDL_V4.3.7"
G_NDP_NSDL_PATH="/opt/NDP"
G_MONO_SERVICE="nbp-mono.service"
G_DATE_FORMAT=`date +%Y%m%d_%H:%M`
G_HISTORY_PATH=`find /opt/NDP/ -type d -name 'NDP_NSDL*'`
G_MESSAGE=""



# +-------------------------------------------------------------------+
# | [Main]                                                            |
# +-------------------------------------------------------------------+
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
# edit crontab
timed_task(){
    G_MESSAGE="++++++>>> redo crontab"
        crontab -l > /tmp/crontab_bak
	sed -i '/ndpagent/d' /tmp/crontab_bak
	echo "* */2 * * * ${G_NDP_NSDL_PATH}/${G_NDP_NSDL_VER}/ndpagent_check_cron.sh" >> /tmp/crontab_bak
        crontab /tmp/crontab_bak
	systemctl restart crond
        exit 1
}

# check mono process
check(){
    G_MESSAGE="++++++>>> Check mono process..."
    echo ${G_MESSAGE}
    sleep 2
    M_CHECK=`ps -ef|grep [m]ono|wc -l`
    if [ ${M_CHECK} -ge 2 ];then
        echo "++++++>>> Mono is running, proces a ${M_CHECK}..."
    fi
}

killmono(){
    for i in `ps -ef|grep [m]ono|awk '{print $2}'`
    do
        kill -9 $i
    done
}

# Start Service
service(){
    systemctl daemon-reload
    systemctl enable nbp-mono.service  >>/dev/null 2>&1
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
    G_MESSAGE="++++++>>> Configure NDP NSDL Agent..."
    echo ${G_MESSAGE}
    sleep 2
    cd ${G_NDP_NSDL_PATH}
    if [ -f ${G_NDP_NSDL_VER}.zip ];then
        unzip -oq ${G_NDP_NSDL_VER}.zip && rm ${G_NDP_NSDL_VER}.zip
        chmod +x ${G_NDP_NSDL_VER}/*.sh
	find /tmp/ -name '*.sqlite' -exec mv -f {} ${G_NDP_NSDL_PATH}/${G_NDP_NSDL_VER} \;
        service
        print
#        rm -f ${G_NDP_NSDL_PATH}/${G_NDP_NSDL_VER}.zip
    else
        echo "++++++>>> NDPAgent Installation package not ${G_NDP_NSDL_VER} version, will exit."
        for i in 5 4 3 2 1;do echo "++++++>>> ${i}...";sleep 1;done
        exit 9
    fi
}

# Install Mono
mono(){
    G_MESSAGE="++++++>>> Installing Mono service..."
    echo ${G_MESSAGE}
    sleep 2
    M_MONO=`rpm -qa|grep [m]ono|wc -l`
    if [ ${M_MONO} -gt 0 ];then
        echo "++++++>>> Mono already exists, no installation is required."
        killmono
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
        rm -f /opt/NDP/mono8.tar.gz
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

# remove ndp
removendp(){
    G_MESSAGE="++++++>>> Remove NDP Agent service..."
    echo ${G_MESSAGE}
    sleep 2

    # new NDP version number
   # M_NEW_VER_NUMBER=`echo ${G_NDP_NSDL_VER} | sed -r 's#(.*)_V(.*)#\2#g' | awk -F "." '{print $1$2$3}'`

    # rm old NDP
   # [ -d ${G_NDP_NSDL_PATH} ]  && cd ${G_NDP_NSDL_PATH}
   # M_OLD_VER_NUMBER=`ls | grep NDP_NSDL | sed -r 's#(.*)_V(.*)#\2#g' | awk -F "." '{print $1$2$3}'`
   #
   # if [ "${M_NEW_VER_NUMBER}" = "${M_OLD_VER_NUMBER}" ];then
   #     echo "++++++>>> NDP Agent version is ${G_NDP_NSDL_VER}, No need to update, will exit."
   #     sleep 1
   #     for i in 5 4 3 2 1;do echo "++++++>>> ${i}...";sleep 1;done
   #     exit
   # else
        # kill NDP process
        systemctl disable nbp-mono.service
        ps -ef|grep [N]DP.Server.exe >>/dev/null 2>&1
        if [ $? -eq 0 ];then
            killmono
            echo "++++++>>> NDP Agent service is stop successfully."
        else
            echo "++++++>>> NDP Agent service did not start or does not exist ."
        fi
#	find ${G_NDP_NSDL_PATH}/${G_NDP_NSDL_VER} -name '*.sqlite' -exec cp {} /tmp \;
	cd ${G_NDP_NSDL_PATH} && rm -rf ./NDP_NSDL*
        echo "++++++>>> NDP Agent is remove successfully."
   # fi
}

#copy sqlite
sqlite(){
    if [ -d ${G_HISTORY_PATH} ];then
        find ${G_HISTORY_PATH} -name '*.sqlite' -exec cp {} /tmp \;
#	cp /tmp/*.sqlite /zwy
    else
        echo "++++++>>> No history NDP."
    fi
}

# Main Running
main(){
    sqlite
    removendp
    sshp
    cpnsdl
    mono
    ndp
    check
    timed_task
}

rootuser(){
    if [ $UID -ne 0 ]; then
        echo "Insufficient permissions, please use root user."
    else
        main
    fi
}

rootuser


# Main End


# +-------------------------------------------------------------------+
# | [Error]                                                           |
# +-------------------------------------------------------------------+
