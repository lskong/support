#install expect
yum install -y expect

#user su
su - oldboy

##expect scripts
cat >>/server/scripts/handout_sshkey.exp<<"EOF"
#! /usr/bin/expect
if { $argc !=2 } {
        send_user "usage:expect handout_sshkey.exp file host\n"
        exit
}
#define var
set file [lindex $argv 0]
set host [lindex $argv 1]
set user "oldboy"
set password "123456"
spawn ssh-copy-id -i $file "-p52113 $user@$host"
expect {
        -timeout 20
        "yes/no"      {send "yes\r";exp_continue}
        "*password"   {send "$password\r"}
        timeout {puts "expect connect timeout,pls contact admin."; return}
}
expect eof
exit -onexit {
    send_user "That's OK, good bye!\n"
}
EOF

#ssh keygen
ssh-keygen -t dsa -P "" -f ~/.ssh/id_dsa

##ssh scripts
cat >>/server/scripts/handout_sshkey.sh<<"EOF"
#!/bin/sh
. /etc/init.d/functions
iplist=`sed -n '3,$'p /server/scripts/hosts|awk '{print $1}'`
for n in $iplist
do
  /usr/bin/expect handout_sshkey.exp ~/.ssh/id_dsa.pub $n &>/dev/null
  if [ $? -eq 0 ]
  then
        action "$n" /bin/true
  else
        action "$n" /bin/false
  fi
done
EOF

#make ssh scripts
sh /server/scripts/handout_sshkey.sh