# ubuntu_iso_squashfs打包

## 环境准备

- 说明
```shell
# 环境：172.16.3.11 ubuntu18.04.2
# 原版iso：ubuntu-18.04.5-live-server-amd64.iso
# 工作目录：/root
```

- 目录准备
```shell
sudo mkdir -p ./custom/{_squash,_work,iso,newiso,newlive,project}
```

- 挂载iso
```shell
sudo mount -o loop ./ubuntu-18.04.5-live-server-amd64.iso ./custom/iso/
sudo cp -a ./custom/iso/* ./custom/newiso/
```

- 挂载squashfs
```shell
sudo mount -t squashfs ./custom/iso/casper/filesystem.squashfs ./custom/_squash

```

- 复制squashfs并创建新的squashfs
```shell
sudo mount -t overlay overlay -onoatime,lowerdir=./custom/_squash,upperdir=./custom/project,workdir=./custom/_work ./custom/newlive
```

- 使用systemd-nspawn自定义实时文件系统（比chroot好）
```shell
sudo apt install systemd-container
sudo systemd-nspawn --bind-ro=/run/systemd/resolve/resolv.conf:/etc/resolv.conf --setenv=RUNLEVEL=1 -D ./custom/newlive
```


## systemd-nspawn

- 添加petasan源
```shell
cat > /etc/apt/sources.list.d/petasan.list <<EOF
deb http://archive.petasan.org/repo/  petasan-v2 updates
EOF
```

- 添加petasan的key
```shell
curl -fsSL http://archive.petasan.org/repo/release.asc | sudo apt-key add -
apt update
```

- 安装petasan包
```shell
apt install petasan
```

- 安装其它包
```shell
apt install docker.io mysql-client redis-tools unzip lrzsz tree bash-completion
apt clean
```


- 退出systemd-nspawn
```shell
<ctrl-d>

# 再次进入
sudo systemd-nspawn --bind-ro=/run/systemd/resolve/resolv.conf:/etc/resolv.conf --setenv=RUNLEVEL=1 -D ./custom/newlive
```

- 清理多余
```shell
sudo rm ./custom/newlive/root/.bash_history
sudo rm ./custom/newlive/var/lib/dbus/machine-id
```

- 同步新内容
```shell
sudo rsync -av --exclude casper/filesystem.squashfs ./custom/iso/ ./custom/newiso/

sudo mksquashfs ./custom/newlive ./custom/newiso/casper/filesystem.squashfs -noappend -b 1048576 -comp xz -Xdict-size 100%

printf $(sudo du -s --block-size=1 ./custom/newlive | cut -f1) | sudo tee ./custom/newiso/casper/filesystem.size
```

- 删除
```shell
sudo umount ./custom/_squash ./custom/newlive ./custom/iso
# sudo rm -rf ./custom/newiso
```



## 生成iso

```shell
apt install genisoimage

VOLUME_NAME="zxcloud"

(cd ./custom/newiso && find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" ) | sudo tee ./custom/newiso/md5sum.txt

sudo genisoimage -r -cache-inodes -J -l \
    -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
    -boot-load-size 4 -boot-info-table \
    -V "$VOLUME_NAME" \
    -o /root/custom-image.iso /root/custom/newiso/

sudo isohybrid ./custom-image.iso

# optionaly update isolinux/isolinux.bin and isolinux/*.c32 with newer from isolinux, might make it more compatible with isohybrid below

# sudo dd if=./custom-image.iso of=/dev/sdb bs=4M status=progress
```