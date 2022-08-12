#!/bin/sh
find $1 -type f -name "*" | \
xargs ls -lh |awk '{print $5}'| \
sort -n| \
uniq -c| \
sort -n \
>/tmp/CountFiles.txt