#!/bin/sh
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
. /etc/profile

# Defaults options
FILES_NAME="*"
FILES_PATH=""

# Judge the number of input options
if [ $# -lt 2 ]; then
    echo "[ Error ] ----> USAGE: $0 [ -p <PATH> | -n <FileName> ]"
    exit
fi

# main command
function main(){
    FILES_LIST=`find ${FILES_PATH} -type f -name "${FILES_NAME}"`
    FILES_NUMBER=`find ${FILES_PATH} -type f -name "${FILES_NAME}"|xargs ls|wc -l`
    echo -e "[ Debug  ] ----> $(date +%F" "%T:%N) starting time. \n"
    local COUNTER=0
    for FILES in ${FILES_LIST}
    do
        echo "# hello" >> ${FILES}
        echo "[ Modify ] ----> $(date +%F" "%T:%N) ${FILES}"
        let COUNTER++
        sleep 1
    done
    echo -e "\n[ Debug  ] ----> $(date +%F" "%T:%N) Endding time."
    echo -e "[ Debug  ] ----> Total number of files: [ ${COUNTER} ] \n"
}

# options setting
case $1 in
    -p)
        # files path
        FILES_PATH=$2
        if [ -d ${FILES_PATH} ];then
            FILES_PATH=${FILES_PATH}
        else
            echo "[ Error ] ----> Path does not exist! please re-enter. "
            exit
        fi

        # files name 
        if  [ $# -eq 4 ];then
            FILES_NAME=$4
        else 
            FILES_NAME=${FILES_NAME}
        fi
        main
        ;;
    -n)
        FILES_NAME=$2
        if  [ $# -eq 4 ];then
            FILES_PATH=$4
            if [ -d ${FILES_PATH} ];then
                FILES_PATH=${FILES_PATH}
            else
                echo "[ Error ] ----> Path does not exist! please re-enter. "
                exit
            fi 
        else 
            FILES_PATH=${FILES_PATH}
        fi
        main
        ;;
    *)
        echo "[ Error ] ----> USAGE: $0 [ -p <PATH> | -n <FileName> ]"
esac