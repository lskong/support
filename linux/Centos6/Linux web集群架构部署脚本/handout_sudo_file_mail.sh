#!/bin/sh
. /etc/init.d/functions

iplist=`sed -n '3,$'p /server/scripts/hosts|awk '{print $1}'`
user=$(whoami)

if [ $# -ne 2 ]
    then
        echo "USAGE:$0 FileName and FilePath"
        exit 1
fi

for n in $iplist
do
  /usr/bin/scp -r -P52113 $1 $user@$n:~ &>/dev/null &&\
  /usr/bin/ssh -t -p52113 $user@$n /usr/bin/sudo /usr/bin/rsync $1 $2 &>/dev/null
  if [ $? -eq 0 ]
  then
        echo "$n $1 to $2 This's ok" >>/tmp/handout_sudo_file_mail.ok.log
  else
        echo "$n $1 to $2 This's fail" >>/tmp/handout_sudo_file_mail.fail.log
  fi
done
if [ -s "/server/scripts/handout_sudo_file_mail.fail.log" ]
  then
        /bin/mail -s "$(date %F\ %T) Handout $1" -a "/tmp/handout_sudo_file_mail.fail.log" rockchou@kungi.com.cn </tmp/handout_sudo_file_mail.fail.log
        >/tmp/handout_sudo_file_mail.ok.log
        >/tmp/handout_sudo_file_mail.fail.log
fi
