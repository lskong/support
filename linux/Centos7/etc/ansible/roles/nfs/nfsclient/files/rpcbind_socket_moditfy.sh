#!/bin/sh
[ ! -z `rpm -ql rpcbind|grep rpcbind.socket` ] && \
rpcbind_socket_file=`rpm -ql rpcbind|grep rpcbind.socket`
sed -i 's/ListenStream=\[::\]:111/\#ListenStream=[::]:111/g' $rpcbind_socket_file
systemctl daemon-reload
systemctl restart rpcbind.socket
systemctl start rpcbind