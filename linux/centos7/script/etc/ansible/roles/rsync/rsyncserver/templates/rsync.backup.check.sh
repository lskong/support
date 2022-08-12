#!/bin/sh
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ -f /etc/profile ] && . /etc/profile

# Custom variable
g_date=`date +%F`
g_path="/server/scripts/"
g_name="backup_check_mail.log"
g_file="${g_path}${g_name}"
g_mail_user="rockchou@kungi.com.cn"
g_mail_tilte="${g_date} backup check server" 

# than md5
find /backup/ -type f -name "flag_md5_${g_date}"|xargs md5sum -c >${g_file}

# send mail
cat ${g_file}|mail -s "${g_mail_tilte}" -a "${g_path}${g_name}" ${g_mail_user}