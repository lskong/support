#!/bin/bash

function exec_pro()
{
    filename=$1
    filename_so=$(echo "$filename" | awk -F [-.] '{print$2}')
	/usr/bin/ffmpeg -re -i "$filename" -vcodec h264 -acodec aac -f flv rtmp://"$api_url"/"$dirname"/"$filename_so"
}
 
if [ $# -eq 0 ];then
    echo "USAGE: $0 [OPTIONS...] "
    echo "    -d         live dir,eg: /root/dir1/dir2"
    echo "    -i         zlm ipaddress"
    exit 9
fi


while getopts ":d:i:" opt
do
    case $opt in
        d)
        dir_path=$OPTARG
        ;;
        i)
        api_url=$OPTARG
        ;;
        *)
        echo "USAGE: $0 [OPTIONS...] "
        echo "    -d         live dir,eg: /root/dir1/dir2"
        echo "    -i         zlm ipaddress"
    esac
done

dirname=$(echo "$dir_path"| awk -F '/' '{print$NF}')
count=$(find "$dir_path" -name "*.mp4" | wc -l)

 
for ((i=1; i<$count;))
do
	for f in $(find "$dir_path" -name "*.mp4")
	do
		exec_pro $f &
	done
	wait
	i=$(expr $i + 1)
done