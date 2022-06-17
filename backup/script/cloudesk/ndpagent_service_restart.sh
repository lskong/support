#!/bin/sh
for i in `ps -ef|grep [m]ono|awk '{print $2}'`
do
    kill -9 $i
done
systemctl start nbp-mono