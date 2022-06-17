#!/bin/sh

[ $# -ne 2 ] && echo $"Usage: $0 {6381|6382|6383|...}" && exit

# config file
for port in $1 $2
do
    mkdir -p ./cluster/638${port}/conf
    PORT=${port} envsubst < ./redis.conf.tmpl > ./cluster/638${port}/conf/redis.conf
done

# start redis
docker-compose down
docker-compose up -d


# sh redis-deploy.sh 1 2
# docker exec -it redis-6381 bash
# redis-cli -a 1234 --cluster create 10.0.0.121:6381 10.0.0.123:6383 10.0.0.125:6385 10.0.0.122:6382 10.0.0.124:6384 10.0.0.126:6386 --cluster-replicas 1