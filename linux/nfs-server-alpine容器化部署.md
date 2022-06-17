# nfs-server-alpine容器化部署

## 容器启动命令

```bash
docker run -d --name nfs \
--privileged \
--restart=always \
-p 2049:2049 \
-v /some/where/fileshare:/nfsshare \
-v /some/where/else:/nfsshare/another \
-e SHARED_DIRECTORY=/nfsshare \
-e SHARED_DIRECTORY_2=/nfsshare/another \
itsthenetwork/nfs-server-alpine:latest
```

## Dockerfile

```bash
FROM alpine:3.13
LABEL maintainer "wly <1228022817@qq.com>"
LABEL source "https://github.com/sjiveson/nfs-server-alpine"
LABEL branch "master"
COPY Dockerfile README.md /

RUN apk add --no-cache --update --verbose nfs-utils bash iproute2 && \
    rm -rf /var/cache/apk /tmp /sbin/halt /sbin/poweroff /sbin/reboot && \
    mkdir -p /var/lib/nfs/rpc_pipefs /var/lib/nfs/v4recovery && \
    echo "rpc_pipefs    /var/lib/nfs/rpc_pipefs rpc_pipefs      defaults        0       0" >> /etc/fstab && \
    echo "nfsd  /proc/fs/nfsd   nfsd    defaults        0       0" >> /etc/fstab

COPY exports /etc/
COPY nfsd.sh /usr/bin/nfsd.sh
COPY .bashrc /root/.bashrc

RUN chmod +x /usr/bin/nfsd.sh

ENTRYPOINT ["/usr/bin/nfsd.sh"]
```

## nfsd.sh

```bash
#!/bin/bash

# Make sure we react to these signals by running stop() when we see them - for clean shutdown
# And then exiting
trap "stop; exit 0;" SIGTERM SIGINT

stop()
{
  # We're here because we've seen SIGTERM, likely via a Docker stop command or similar
  # Let's shutdown cleanly
  echo "SIGTERM caught, terminating NFS process(es)..."
  /usr/sbin/exportfs -uav
  /usr/sbin/rpc.nfsd 0
  pid1=`pidof rpc.nfsd`
  pid2=`pidof rpc.mountd`
  # For IPv6 bug:
  pid3=`pidof rpcbind`
  kill -TERM $pid1 $pid2 $pid3 > /dev/null 2>&1
  echo "Terminated."
  exit
}

# Check if the SHARED_DIRECTORY variable is empty
if [ -z "${SHARED_DIRECTORY}" ]; then
  echo "The SHARED_DIRECTORY environment variable is unset or null, exiting..."
  exit 1
else
  echo "Writing SHARED_DIRECTORY to /etc/exports file"
  /bin/sed -i "s@{{SHARED_DIRECTORY}}@${SHARED_DIRECTORY}@g" /etc/exports
fi

# This is here to demonsrate how multiple directories can be shared. You
# would need a block like this for each extra share.
# Any additional shares MUST be subdirectories of the root directory specified
# by SHARED_DIRECTORY.

# Check if the SHARED_DIRECTORY_2 variable is empty
if [ ! -z "${SHARED_DIRECTORY_2}" ]; then
  echo "Writing SHARED_DIRECTORY_2 to /etc/exports file"
  echo "{{SHARED_DIRECTORY_2}} {{PERMITTED}}({{READ_ONLY}},{{SYNC}},no_subtree_check,no_auth_nlm,insecure,no_root_squash)" >> /etc/exports
  /bin/sed -i "s@{{SHARED_DIRECTORY_2}}@${SHARED_DIRECTORY_2}@g" /etc/exports
fi

# Check if the PERMITTED variable is empty
if [ -z "${PERMITTED}" ]; then
  echo "The PERMITTED environment variable is unset or null, defaulting to '*'."
  echo "This means any client can mount."
  /bin/sed -i "s/{{PERMITTED}}/*/g" /etc/exports
else
  echo "The PERMITTED environment variable is set."
  echo "The permitted clients are: ${PERMITTED}."
  /bin/sed -i "s/{{PERMITTED}}/"${PERMITTED}"/g" /etc/exports
fi

# Check if the READ_ONLY variable is set (rather than a null string) using parameter expansion
if [ -z ${READ_ONLY+y} ]; then
  echo "The READ_ONLY environment variable is unset or null, defaulting to 'rw'."
  echo "Clients have read/write access."
  /bin/sed -i "s/{{READ_ONLY}}/rw/g" /etc/exports
else
  echo "The READ_ONLY environment variable is set."
  echo "Clients will have read-only access."
  /bin/sed -i "s/{{READ_ONLY}}/ro/g" /etc/exports
fi

# Check if the SYNC variable is set (rather than a null string) using parameter expansion
if [ -z "${SYNC+y}" ]; then
  echo "The SYNC environment variable is unset or null, defaulting to 'async' mode".
  echo "Writes will not be immediately written to disk."
  /bin/sed -i "s/{{SYNC}}/async/g" /etc/exports
else
  echo "The SYNC environment variable is set, using 'sync' mode".
  echo "Writes will be immediately written to disk."
  /bin/sed -i "s/{{SYNC}}/sync/g" /etc/exports
fi

# Partially set 'unofficial Bash Strict Mode' as described here: http://redsymbol.net/articles/unofficial-bash-strict-mode/
# We don't set -e because the pidof command returns an exit code of 1 when the specified process is not found
# We expect this at times and don't want the script to be terminated when it occurs
set -uo pipefail
IFS=$'\n\t'

# This loop runs till until we've started up successfully
while true; do

  # Check if NFS is running by recording it's PID (if it's not running $pid will be null):
  pid=`pidof rpc.mountd`

  # If $pid is null, do this to start or restart NFS:
  while [ -z "$pid" ]; do
    echo "Displaying /etc/exports contents:"
    cat /etc/exports
    echo ""

    # Normally only required if v3 will be used
    # But currently enabled to overcome an NFS bug around opening an IPv6 socket
    echo "Starting rpcbind..."
    /sbin/rpcbind -w
    echo "Displaying rpcbind status..."
    /sbin/rpcinfo

    # Only required if v3 will be used
    # /usr/sbin/rpc.idmapd
    # /usr/sbin/rpc.gssd -v
    # /usr/sbin/rpc.statd

    echo "Starting NFS in the background..."
    /usr/sbin/rpc.nfsd --debug 8 --no-udp --no-nfs-version 2 --no-nfs-version 3
    echo "Exporting File System..."
    if /usr/sbin/exportfs -rv; then
      /usr/sbin/exportfs
    else
      echo "Export validation failed, exiting..."
      exit 1
    fi
    echo "Starting Mountd in the background..."These
    /usr/sbin/rpc.mountd --debug all --no-udp --no-nfs-version 2 --no-nfs-version 3
# --exports-file /etc/exports

    # Check if NFS is now running by recording it's PID (if it's not running $pid will be null):
    pid=`pidof rpc.mountd`

    # If $pid is null, startup failed; log the fact and sleep for 2s
    # We'll then automatically loop through and try again
    if [ -z "$pid" ]; then
      echo "Startup of NFS failed, sleeping for 2s, then retrying..."
      sleep 2
    fi

  done

  # Break this outer loop once we've started up successfully
  # Otherwise, we'll silently restart and Docker won't know
  echo "Startup successful."
  break

done

while true; do

  # Check if NFS is STILL running by recording it's PID (if it's not running $pid will be null):
  pid=`pidof rpc.mountd`
  # If it is not, lets kill our PID1 process (this script) by breaking out of this while loop:
  # This ensures Docker observes the failure and handles it as necessary
  if [ -z "$pid" ]; then
    echo "NFS has failed, exiting, so Docker can restart the container..."
    break
  fi

  # If it is, give the CPU a rest
  sleep 1

done

sleep 1
exit 1

```

## .bashrc

```bash
    # General Aliases
    alias apk='apk --progress'
    alias ll="ls -ltan"

    alias hosts='cat /etc/hosts'
    alias ..="cd .."
    alias ...="cd ../.."
    alias ....="cd ../../.."
    alias untar="tar xzvkf"
    alias mv="mv -nv"
    alias cp="cp -i"
    alias ip4="ip -4 addr"
    alias ip6="ip -6 addr"

    COL_YEL="\[\e[1;33m\]"
    COL_GRA="\[\e[0;37m\]"
    COL_WHI="\[\e[1;37m\]"
    COL_GRE="\[\e[1;32m\]"
    COL_RED="\[\e[1;31m\]"

    # Bash Prompt
    if test "$UID" -eq 0 ; then
        _COL_USER=$COL_RED
        _p=" #"
    else
        _COL_USER=$COL_GRE
        _p=">"
    fi
    COLORIZED_PROMPT="${_COL_USER}\u${COL_WHI}@${COL_YEL}\h${COL_WHI}:\w${_p} \[\e[m\]"
    case $TERM in
        *term | rxvt | screen )
            PS1="${COLORIZED_PROMPT}\[\e]0;\u@\h:\w\007\]" ;;
        linux )
            PS1="${COLORIZED_PROMPT}" ;;
        * ) 
            PS1="\u@\h:\w${_p} " ;;
    esac

```

## 客户端挂载

```bash
mount -v NFS_SERVER_IP:/ /www/wwwroot/open.iuiweb.com/nfsshare
```


## 开机自启

```shell
NFS_SERVER_IP:/  /www/wwwroot/open.iuiweb.com/nfsshare  nfs  defaults 0 0
```