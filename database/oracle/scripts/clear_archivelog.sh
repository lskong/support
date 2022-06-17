#!/bin/bash
#Author heyuanming
#FileName clear_archivelog.sh
#Date 2018-10-23
#DESC Delete all archivelog.

if [ -f ~/.bash_profile ]; then
    . ~/.bash_profile
fi

#set env
echo "Oracle home:"$ORACLE_HOME
echo "Oracle SID:"$ORACLE_SID

$ORACLE_HOME/bin/rman target  sys/kingdee@easdb log=/oradata/script/clear_archive.log <<EOF
crosscheck archivelog all;
delete noprompt expired archivelog all;
delete noprompt archivelog all completed before 'sysdate - 2';
exit;
EOF
