#!/bin/sh
. /etc/init.d/functions

iplist=`sed -n '3,$'p /server/scripts/hosts|awk '{print $1}'`
user=$(whoami)

if [ $# -ne 2 ]
    then
        echo "USAGE:$0 FileName and remote Path"
        exit 1
fi

for n in $iplist
do
  /usr/bin/scp -r -P52113 $1 $user@$n:~ &>/dev/null &&\
  /usr/bin/ssh -t -p52113 $user@$n /usr/bin/sudo /usr/bin/rsync $1 $2 &>/dev/null
  if [ $? -eq 0 ]
  then
        action "$1 to $n:$2 " /bin/true
  else
        action "$1 to $n:$2 " /bin/false
  fi
done