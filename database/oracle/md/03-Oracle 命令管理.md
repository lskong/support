## Oracle命令

文章内使用小写的命令是在操作系统命令行窗口执行，使用大写的命令是在sqlplus的命令行执行。

[toc]

### 1. 基础命令

#### 1.1 监听服务

```plsql
# 查看监听 
lsnrctl status

# 开启监听服务
lsnrctl start

# 关闭监听
lsnrctl stop
```

#### 1.2 登录数据库

```plsql
# 本地登录
sqlplus / as sysdba  # 登录SYS用户并拥有dba权限
sqlplus /nolog  # 无用户和权限登录
sqlplus scott/12345@oracle11 as sysdba  # dba权限的scott用户登录oracle11实例

# 远程登录 
sqlplus scott/123456@//172.16.103.13:1521/oracle11 as sysdba
# 注意需要给用户授权 GRANT SYSDBA TO SCOTT;

# 切换用户 
CONN SCOTT/123456

# 切换用户和实例
CONN SCOTT/123456@ORACLE11

# 查看当前用户权限
SHOW USER;
```

#### 1.3 查看数据库

```plsql
# 查看当前数据库名
SELECT NAME FROM V$DATABASE;
SHOW PARAMETER DB_NAME;

# 查看当前实例名
SELECT INSTANCE_NAME,STATUS FROM V$INSTANCE;	#查看实例名和状态
SHOW PARAMETER INSTANCE_NAME;

# 查看数据库域名
SELECT VALUE FROM V$PARAMETER WHERE NAME='DB_DOMAIN';
SHOW PARAMETER DOMAIN;

# 查看数据库服务名
SELECT VALUE FROM V$PARAMETER WHERE NAME='SERVICE_NAME';
SELECT VALUE FROM V$PARAMETER WHERE NAME='SERVICE_NAME';
## 数据库服务名：此参数是数据库标识类参数，用service_name表示。数据库如果有域，则数据库服务名就是全局数据库名；如果没有，则数据库服务名就是数据库名

# 查看数据库文件路径
SELECT NAME FROM V$DATAFILE;
SHOW PRARMETER DB_FILE;
```

#### 1.4 启动数据库

```plsql
# 启动数据库
dbstart $ORACLE_HOME 	# 仅在Linux下有此命令 

# sqlplus启动
STARTUP 				# 启动实例
STARTUP NOMOUNT;    	# 启动实例，不加载数据库 
ALTER DATABASE MOUNT;   # 加载数据库（挂起） 
ALTER DATABASE OPEN;    # 打开数据库 
## 注：STARTUP等同于执行了后三步

## startup nomount ##启动实例，不加载数据库（模式一） 
在这一阶段，只需要读取initSID.ora文件，启动数据库实例，创建后台进程。在initSID.ora文件中，可以定位 SPFILEORAC.ora文件，这是参数文件，通过它可以初始化SGA和启动后台进程。并可以定位控制文件位置。在此阶段，可以执行的操作有：重建控 制文件，重建数据库。
## alter database mount ##加载数据库（模式二） 
在nomount阶段，可以通过读取控制文件来转换到mount阶段。在数据库加载阶段（mount），所有的数据文件和联机日志文件的名称和位置都从控制文件中读取，但是并没有真正查找这些文件。在此阶段，可以执行的操作有：数据库日志归档、数据库介质恢复、使数据文件联机或脱机、重定位 数据文件和联机日志文件。 
## alter database open ##打开数据库（模式三） 
通过查找定位并打开数据文件和联机日志文件来切换到open阶段。此时数据库可用，可以建立会话。
```

#### 1.5 关闭数据库

```plsql
# 关闭数据库
SHUTDOWN IMMEDIATE
```



### 2. 表空间和表

#### 2.1 表空间

```plsql
# 查看当前数据库已经有的表空间和数据文件
SELECT tablespace_name,file_id,file_name,round(bytes / (1024 * 1024), 0) total_space 
FROM dba_data_files 
ORDER BY tablespace_name; 

# 查看当前表空间名和大小
SELECT t.tablespace_name, round(SUM(bytes / (1024 * 1024)), 0) ts_size 
FROM dba_tablespaces t, dba_data_files d 
WHERE t.tablespace_name = d.tablespace_name 
GROUP BY t.tablespace_name; 

# 创建表空间，临时表和数据表空间视为一套。
# 创建临时表空间（可选）
# 创建用户之前要创建"临时表空间"，若不创建则默认的临时表空间为temp
CREATE TEMPORARY TABLESPACE SIMON_TEMP
TEMPFILE 'E:\oracledb\oradatabase\simon_temp.dbf' 
SIZE 50M AUTOEXTEND ON
NEXT 50M MAXSIZE 20480M
EXTENT MANAGEMENT LOCAL; 

# 创建数据表空间 
# 创建用户之前先要创建数据表空间，若没有创建则默认永久性表空间是system
CREATE TABLESPACE SIMON_DATA 
DATAFILE 'E:\oracledb\oradatabase\simon_data.dbf'
SIZE 50M AUTOEXTEND ON
NEXT 50M MAXSIZE 20480M
EXTENT MANAGEMENT LOCAL;

# 删除临时表空间
DROP TABLESPACE SIMON_TEMP;

# 删除数据表空间
DROP TABLESPACE SIMON_DATA;
```

#### 2.2 表

```plsql
# 批量删除表
SELECT 'drop table '||TABLE_NAME ||';' FROM USER_TABLES WHERE TABLE_NAME LIKE 'HIS_%'; ## 执行后复制结果，重复执行直到删除干净
```



### 3. 用户管理

```plsql
#查看当前用户
SELECT USER FROM V$INSTANCE;

# 激活SCOTT用户并设置密码123456
ALTER USER SCOTT IDENTIFIED BY 123456 ACCOUNT UNLOCK;

# 创建用户simon并设置密码123456，且赋予默认表空间
CREATE USER SIMON 
IDENTIFIED BY 123456 
DEFAULT TABLESPACE SIMON_DATA 
TEMPORARY TABLESPACE SIMON_TEMP;

# 授权用户
GRANT CONNECT,RESOURCE,DBA TO SIMON;

# 撤销授权
REVOKE PRIVILEGES CONNECT,RESOURCE,DBA FROM SIMON;

# 删除用户 DROP USER SIMON CASCADE;

# 安装ORACLE时，若没有为下列用户重设密码
# 则其默认密码如下：
# {用户名/密码，登录身份，说明}
sys/change_on_install, SYSDBA或SYSOPER不能以NORMAL登录，可作为默认的系统管理员 system/manager, SYSDBA或NORMAL不能以SYSOPER登录，可作为默认的系统管理员
sysman/oem_temp, sysman为oms的用户名
scott/tiger, NORMAL普通用户
aqadm/aqadm, SYSDBA或NORMAL 高级队列管理员 
dbsnmp/dbsnmpm, SYSDBA或NORMAL 复制管理员创建表空间和用户
```



### 4. 查看触发器（trigger）

```plsql
# 查all_triggers表得到trigger_name 
select trigger_name from all_triggers where table_name='XXX';
select trigger_name from all_triggers where table_name like 'SYM%';

# 根据trigger_name查询出触发器详细信息
select text from all_source where type='TRIGGER' AND name='SYM_ON_I_FOR_SYM_CHNNL_CLNT';
```



