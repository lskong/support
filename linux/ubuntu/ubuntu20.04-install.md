# ubuntu20.04操作系统安装

系统镜像位置：

\\\192.168.3.12\samba-iso\ISO-Linux\ubuntu\ubuntu-20.04.2-live-server-amd64.iso

### 1. 进入安装

![image-20210622180112641](ubuntu20.04-install.assets/image-20210622180112641.png)

### 2. 安装前检查

![image-20210622123606503](ubuntu20.04-install.assets/image-20210622123606503.png)

### 3. 选择语言

![image-20210622124024076](ubuntu20.04-install.assets/image-20210622124024076.png)

该处选择English

### 4. 键盘设置

![image-20210622124403858](ubuntu20.04-install.assets/image-20210622124403858.png)

默认即可`english（US）`，选择done继续

### 5. 网络配置

![image-20210622124644465](ubuntu20.04-install.assets/image-20210622124644465.png)

- 选择`Edit IPv4`进入配置

![image-20210622125115971](ubuntu20.04-install.assets/image-20210622125115971.png)

- 选择`Manual`开始进行配置

![image-20210622125300160](ubuntu20.04-install.assets/image-20210622125300160.png)

- 网络配置

![image-20210622125609825](ubuntu20.04-install.assets/image-20210622125609825.png)

其中：

 `Subnet`：子网掩码

`Address`：IP地址

`Gateway`：网关

`Name servers`：DNS地址

选择**save**保存配置

- 确认配置

![image-20210622134926495](ubuntu20.04-install.assets/image-20210622134926495.png)

选择done完成配置

### 6. 配置代理服务器

![image-20210622135029907](ubuntu20.04-install.assets/image-20210622135029907.png)

默认为空即可，选择done继续

### 7. 镜像源配置

![image-20210622204103789](ubuntu20.04-install.assets/image-20210622204103789.png)

保持默认即可，选择done继续

### 8. 磁盘选择

![image-20210622135846511](ubuntu20.04-install.assets/image-20210622135846511.png)

默认即可，选择done继续

### 9. 存储配置

- 删除原配置

![image-20210622204634273](ubuntu20.04-install.assets/image-20210622204634273.png)

选择unmount删除原`/`目录的配置

- 重新创建`/`目录

![image-20210622204908063](ubuntu20.04-install.assets/image-20210622204908063.png)

选择Edit开始进行配置

- `/`目录参考配置

![image-20210622205159184](ubuntu20.04-install.assets/image-20210622205159184.png)

其中：

Name：可自定义

Size：选择可选的最大值

Format：文件系统可自选

Mount：选择挂载`/`目录



- 确认配置

![image-20210622205450011](ubuntu20.04-install.assets/image-20210622205450011.png)

磁盘分配完成后，选择done继续

![image-20210622153430037](ubuntu20.04-install.assets/image-20210622153430037.png)

选择`continue`继续

### 10. 用户配置

![image-20210622154632797](ubuntu20.04-install.assets/image-20210622154632797.png)

其中：

- your name：系统名称
- your server’s name ： 服务器名称
- pick a username：用户名称
- choose a password：用户密码
- confirm your password：确认密码

选择done继续

### 11. ssh安装

![image-20210622160358446](ubuntu20.04-install.assets/image-20210622160358446.png)

使用`空格`确认安装openssh服务，选择done继续

### 12. 组件安装

![image-20210622160824402](ubuntu20.04-install.assets/image-20210622160824402.png)

可使用`空格`选择想安装的组件，这里选择默认不安装，选择done继续

### 13. 系统开始安装

- 安装进度查看

![image-20210622161004093](ubuntu20.04-install.assets/image-20210622161004093.png)

- 安装完成

![image-20210622161129667](ubuntu20.04-install.assets/image-20210622161129667.png)

选择reboot now重启以完成安装

### 14. 登陆

- 使用`ubuntu`用户登陆

![image-20210622163059526](ubuntu20.04-install.assets/image-20210622163059526.png)

- 配置`root`用户

![image-20210622211105951](ubuntu20.04-install.assets/image-20210622211105951.png)

- 切换`root`用户登陆

![image-20210622211152174](ubuntu20.04-install.assets/image-20210622211152174.png)

- 查看IP

![image-20210622163630565](ubuntu20.04-install.assets/image-20210622163630565.png)

- 开启root用户可远程登陆

![image-20210622163958620](ubuntu20.04-install.assets/image-20210622163958620.png)

编辑该`/etc/ssh/sshd_config`文件

- 在配置文件中开启root用户远程登陆

![image-20210622164822185](ubuntu20.04-install.assets/image-20210622164822185.png)

添加参数`PermitRootLogin yes` 并重启ssh服务

