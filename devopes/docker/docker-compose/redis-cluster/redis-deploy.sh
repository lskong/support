#!/bin/sh

[ $# -ne 2 ] && echo $"Usage: $0 {6381|6382|6383|...}" && exit

for port in $1 $2
do
mkdir -p ./cluster/${port}/conf
mkdir -p ./cluster/${port}/data
PORT=${port} envsubst < ./redis.conf.tmpl > ./cluster/${port}/conf/redis.conf
PORT=${port} envsubst < ./redis.yaml.tmpl > ./redis-${port}.yaml
docker-compose -f ./redis-${port}.yaml up -d 
done
