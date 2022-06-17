# samba

## ubuntu 20.04

- Install

```bash
sudo apt update
sudo apt install samba
```

- Setting Config

```bash
# 设置共享目录
sudo mkdir /home/<username>/sambashare

# 修改配置文件
sudo nano /etc/samba/smb.conf

[sambashare]
    comment = Samba on Ubuntu
    path = /home/<username>/sambashare
    read only = no
    browsable = yes

# 重启服务
sudo systemctl restart smb.service

# 开放防火墙
sudo ufw allow samba

```

- Setting User

```bash
sudo smbpasswd -a username
```