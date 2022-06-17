# python3.6开发环境配置 - ubuntu 18.04

[toc]

## virtualenv环境配置

### virtualenvwrapper是virtualenv的升级版

```shell
virtualenvwrapper的作用如下:
https://www.jianshu.com/p/bfc4be124e37

Virtaulenvwrapper是virtualenv的扩展包，用于更方便管理虚拟环境，它可以做：

将所有虚拟环境组织在一个目录下
管理（新增，删除，复制）虚拟环境
更方便的在不同的虚拟环境下进行切换
用户可以为所有的命令操作自定义hooks (详见官网 Per-User Customization)

```

### 初始化部署说明

- virtualenvwrapper安装

```shell
# 如果不确定安装的是python2的还是python3的，就老老实实先卸载了
susu@pc:~$ sudo dpkg -l | grep virtualenv
ii  python-virtualenv                          15.1.0+ds-1.1                                    all          Python virtual environment creator
ii  python3-virtualenv                         15.1.0+ds-1.1                                    all          Python virtual environment creator
ii  virtualenv                                 15.1.0+ds-1.1                                    all          Python virtual environment creator
ii  virtualenv-clone                           0.2.5-1                                          all          script for cloning a non-relocatable virtualenv
ii  virtualenvwrapper                          4.3.1-2                                          all          extension to virtualenv for managing multiple virtual Python environments

# 重点: 上面的包，最好不要使用apt install来安装，一则不知道装到哪里去了，二则不好统一管理
```shell
sudo apt remove virtualenv virtualenv-clone virtualenvwrapper python3-virtualenv python-virtualenv

# pip要版本20以上才可以进行config操作
sudo apt install python3-pip
sudo pip3 install pip --upgrade
sudo pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
Writing to /root/.config/pip/pip.conf
sudo pip3 install virtualenv==15.1.0 virtualenv-clone==0.2.5 virtualenvwrapper==4.3.1
```

- 初始化配置

```shell
# apt安装virtualenvwrapper后的virtualenvwrapper.sh路径
source /usr/share/virtualenvwrapper/virtualenvwrapper.sh

# pip3安装的路径是 -> /usr/local/bin/virtualenvwrapper.sh

# 重点: During startup, virtualenvwrapper.sh finds the first python and virtualenv programs on the $PATH and remembers them to use later. 
# 系统默认的python和virtualenv的可执行路径要告诉virtualenvwrapper，因为其依赖之
# export PATH=/usr/local/bin:$PATH

# 更直接的方法指定

# cat >> ~/.bashrc << EOF
cat >>  ~/.bash_profile << EOF
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
source /usr/share/virtualenvwrapper/virtualenvwrapper.sh
EOF
```

### 使用virtualenv

- mkvirtualenv

```shell

# 创建虚拟项目
root@ubuntu:~# mkvirtualenv petasan
Using base prefix '/usr'
New python executable in /root/.virtualenvs/petasan/bin/python3
Also creating executable in /root/.virtualenvs/petasan/bin/python
Installing setuptools, pip, wheel...done.
(petasan) root@ubuntu:~#                        # 进入虚拟项目

# 离开虚拟环境
(petasan) root@ubuntu:~# deactivate 
root@ubuntu:~# 

# 查看现有虚拟环境
root@ubuntu:~# workon 
petasan

root@ubuntu:~# lsvirtualenv
petasan
=======

# 复制虚拟环境
root@ubuntu:~# cpvirtualenv petasan petasan1
Copying petasan as petasan1...

# 删除虚拟环境
oot@ubuntu:~# rmvirtualenv petasan1
Removing petasan1...


# 重新进入虚拟环境
root@ubuntu:~# workon petasan
(petasan) root@ubuntu:~# 

# 可以将初始化配置，放入用户环境下，这样每次登入就可以直接shiyong 
cat >>  ~/.bash_profile << EOF
source /usr/share/virtualenvwrapper/virtualenvwrapper.sh
EOF
```
