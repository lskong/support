# Oracle DG

Oracle DG英文全称Oracle Data Guard，DG提供全面的服务包括：创建、维护、管理、以及监控standby数据库，确保数据安全。DG用途是构建企业数据高可用应用环境。

[toc]

## 1. Data Guard 介绍

### 1.1 DG架构

DG是一个集合，由一个primary数据库和一个或多个standby数据库组成（standby最多9个）。组成Data Guard的数据库通过Oracle Net连接，并且有可能分布于不同的地域。只要库之间可以互相通信，他们的物理位置并没有什么限制。

### 1.2 DG特点

数据库服务器采用DG灾备模式，可以满足对可用性有特殊需求的应用场景，它具备以下特点：

- 需要冗余的服务器设备。
- 需要冗余的存储设备。
- 安装配置比较复杂。
- 管理维护成本高。
- 具备一定的容灾特性。
- 备机可用用作只读查询，减轻主机的压力。

### 1.3 DG机制

逻辑standby是通过接收primary数据库的redo log并转换成sql语句的，然后再standby数据库执行sql语句（SQL Apply）实现同步。

物理standby是通过接收并应用primary数据库的redo log以介质恢复的方式（Redo Apply）实现同步。

### 1.4 DG保护模式

DG提供了三种数据保护模式：最大保护，最高性能，最高可用性

- 最大保护（Maximum Protection）

这种模式能够确保绝对无数据丢失。要实现这一步当然是有代价的，它要求所有的事务在提交前其redo不仅被写入到本地的online redo log还要同时提交到standby数据库的standby redo log，并确定redo数据至少在一个standby数据可用，然后才会在primary数据库上提交。如果出现了什么故障导致standby数据库不可用的话，primary数据库会被shutdown。

- 最高性能（Maximun Performanace）

这种模式提供在不影响primary数据库性能前提下最高级别的数据保护策略。事务随时提交，当前primary数据库的redo数据也需要至少写入一个standby数据库，不过这种写入是不同步的。如果网络条件理想的话，这种模式能够提供类似最高可用性的数据库保护而仅对primary数据库有轻微的性能影响。

- 最高可用性（Maximum availability）

这种模式提供在不影响primary数据库可用前提下最高级别的数据保护策略。其实现方式与最大保护模式类似，也是要求所有事务在提交前必须保障redo数据至少在一个standby数据库可用，不过与之前不同的是，如果出现故障导入无法同时写入standby数据库redo log primary数据库并会shutdown，而是自动转为最高性模式，等standby数据库恢复正常之后，它优惠再自动转换成最高可用性模式。

### 1.5 DG总结

- 灾难恢复及高可用性

- 全面的数据保护
- 有效利用系统资源
- 再高可用及高性能之间更加灵活的平衡机制
- 故障自动检查及解决方案
- 集中的易用管理模式
- 自动化角色模式

同一个DG配置包含一个primary数据库和最多九个standby数据库。primary的创建就不说了，standby数据库初始可以通过primary数据库的备份创建。一旦创建并配置成standby后，DG负责传输primary数据库redo data到standby数据库，standby数据库通过应用接收到的redo data保持与primary数据库事务一致。

### 1.6 DG名词

- Primary 数据库

DG包含一个primary数据库被大部分应用访问的生产数据库，该数据库可以是单实例数据库，也可以是RAC。

- Standby 数据库

Standby数据库是primary数据库复制（事务上一致）。在同个DG中最多能创建9个standby数据库。一旦创建完成，DG通过应用primary数据库的redo自动维护每一个standby数据库。standby数据库同样即可以是单实例数据库，也可以是RAC。

关于standby数据库，通常分两类：逻辑standby和物理standby。

- 逻辑standby

就像素描画像，基本的器官都会有，但都会有相差

- 物理standby

就像相机拍照，你长什么样，照片就是什么样。具体搭配数据库就是不仅文件的物理结构相同，甚至连块在磁盘上的存储位置都是一模一样的。

- Redo传输服务（Redo Transport Services）

控制redo数据的传输到一个或多个归档目的地

- Log应用服务（Log Apply Services）

应用redo数据到standby数据库，以保持与primary事务一致。redo数据即可以从standby数据库的归档文件读取，也可以直接应用standby redo log文件（如果实时应用打开了的话）

- 角色转换服务（Role Transitions）

DG中只有两种角色primary和standby。所谓角色转换就是数据库在这个连个角色中切换；切换也分两种swithchover和failover。

swithchover：转换primary数据库与standby数据库，swithchover可以确保数据不丢。

failover：当primary数据库出现故障并且不能被及时恢复时，会调用failover将一个standby数据库转换为新的primary数据库。在最大保护模式或或最高可用性模式下，faliover可以保证数据不丢失。



## 2. Standby数据库类型

前面我们简单介绍了standby数据库，并且也知道其分为两类：物理standby和逻辑standby，同时也简短的描述了其各自的特点，下面我们就相关方面进行一些稍深入的研究。

### 2.1 物理standby

我们知道物理standby与primary数据库完全一模一样，DG通过redo应用维护物理standby数据库，通常在不应用恢复的时候，可以以read-only模式打开，如果数据库指定了快速恢复区的话，也可以被临时性的置为read-write模式。

#### 2.1.1 Redo应用

物理standby通过应用归档文件或直接从standby系统中通过oracle恢复机制应用redo文件。恢复操作属于块对块的应用，即成块复制。如果正在应用redo，数据库不能被open。

redo应用是物理standby的核心，务必要搞清楚其概念和原理，后续还有专门章节介绍。

#### 2.1.2 Read-only模式

以read-only模式打开后，你可以在standby数据库执行查询，或备份等操作（变相减轻primary数据库压力），此时Standby数据库仍然可以继续接收redo数据，不过并不会触发操作，直到数据库恢复redo应用。也就是说redo-only模式时不能执行redo应用。redo应用时数据库肯定处于未打开状态。如果需要的话，可以在两种状态间转换，比如先应用redo，然后read-only。再切换数据库状态再应用redo。

#### 2.1.3 Read-write模式

如果以read-write模式打开，则standby数据库将暂停从primary数据库接收redo数据，并且暂时失去灾难保护的功能，当然，以read-write模式打开也并非一无是处，比如你可能需要临时调试一些数据，但是又不方便再正式库操作，那就可以临时将standby数据库置为read-write模式，操作完之后将数据库闪回到操作前的状态。

#### 2.1.4 物理standby特点

- 灾难恢复及高可以用性

物理standby提供一个健全而且极高效的灾难恢复及高用性的解决方案。更加易于管理的switchover/failover角色转换及最更短的计划内或计划外停机时间。

- 数据保护

应用物理standby数据库，DG能够确保即使面对无法预料的灾害也能够不丢失数据。前面也提到物理standby是基于块对块的复制，因此对象、语句统统无关，primary数据库上有什么，物理standby也会有什么。

- 分担primary数据库压力

通过将一些备份任务、仅查询的需求转移到物理standby，可以节省primary数据库的cpu和io资源

- 提示性能

物理standby所使用的redo应用技术使用最底层的恢复机制，这种机制能够绕过sql级代码层，因此效率最高。



### 2.2逻辑standby

逻辑standby是逻辑上与primary数据库相同，结构可以不一致。逻辑standby通过sql应用于primary数据库保存一致，也正因如此，逻辑standby可以以read-write模式打开。你可以再任何时候访问逻辑standby数据库。同样也有利弊，逻辑standby对于某些数据类型以及一些ddl，dml会有操作上的限制。

逻辑standby的特点：

除了上述物理standby中提到的类似灾难恢复，高可用性及数据保护等之外，还有下列一些特点：

- 有效的利用standby硬件资源

除灾难恢复外，逻辑standby数据库还可用于其他业务需求，比如通过再standby数据库创建额外的索引、物化视图等提供查询性能，并满足特定业务需求。又比如创建新的schema（primary数据库并不存在）然后在这些schema中执行ddl或dml操作。

- 分担primary数据库压力

逻辑standby数据库可以在更新表的时候仍然保存打开，此时这些表可同时用于只读访问。者使得逻辑standby数据库能够同时用于数据保护和报表操作。从而将主数据库从那些报表和查询任何中解脱出来，节约宝贵的cpu和io资源

- 平滑升级

比如跨版本升级，打小补丁等，应该说应用的空间很大，而带来的风险却小（前提是如果你拥有足够的技术实力）。另外虽能物理standby也能够实现一些升级操作，但如果跨平台的话恐怕就力不从心，所以此项就不作为物理standby特点列出。



## 3. Data Guard操作方式

作为Oracle环境中一项非常重要的特性，oracle提供了多种方式搭建、操作、管理、维护DG配置，如：

- OEM（Oracle Enterprise Manager）

Oracle EM提供了一个窗口化的管理方式，基本上你只需要点点鼠标就能完成DG的配置管理维护等操作。其实是调用Oracle为DG专门提供的一个管理器Data Guard Broker来实施管理操作。

- Sqlplus命令行

命令行方式的管理是我们主要采用的管理方式，DG的命令并不多。

- DGMGRL（Data Guard Broker命令行方式）

就是DGB，不过是命令行方式操作。

- 初始化参数文件

我感觉不能把参数化参数视为一种操作方式，应该说在这里，通过初始化参数更多是提供灵活的DG配置



## 4. Data Guard软硬件需求

### 4.1 硬件及操作系统

同一个DG配置中的所有Oracle数据库必须运行于相同的平台。比如inter架构的32为Linux系统可以与inter架构下的32位linux系统组成组DG。

不同服务器的硬件配置可以不同，比如cpu、内存、存储，但必须满足standby数据库服务器有足够的磁盘空间用来接收及应用redo数据。

primary数据库和standby数据库的操作系统必须是一致，不过操作系统版本可以略有差异。primart数据库和standby数据库目录也可以不同。

### 4.2 软件需求

DG是Oracle企业版的一个特性，标准版不支持。

通过DG的SQL应用，可以实现滚动升级服务器数据库版本。

同一个DG配置中所有数据库初始化参数：COMPATIBIE的值必须相同。

primary数据库必须运行于归档模式，并且务必确保在primary数据库打开force logging（强日志），以避免用户通过nologging的等方式，在redo操作无法传输到standby数据库。

primary和standby数据库均可应用于单实例或RAC架构下，并且同一个DG配置可以混合使用逻辑standby和物理standby。

使用具有sysdba系统权限的用户管理primary和standby数据库。

建议数据库必须采用相同的存储架构，比如存储采用ASM/OMF的话，那primary和standby也需采用ASM/OMF存储。

另外，注意各服务器的时间设置，不要因为时区设置不一致造成同步问题。



## 5. Redo Logs

Online Redo Logs、Archived Redo Logs、Standby Redo Logs

分清某某redo logs，这里比较关键，不把redo高清楚，后面就被redo高混了。

redo：中文直译是重做，与undo对应。重做什么？为什么要重做呢？

首先重做是Oracle对操作的处理机制，我们在操作的增删改并非直接反映到数据库文件，而是先被记录就是Online redo logs，等时机合适的时候，再由相应的进程通过读取redo log将操作提交到数据文件。

而把这些online redo log日志保存下来，就拥有数据库做过的所有操作，oracle并实现了这个功能，这就是archived' redo ogs，简称archive log即归档日志。

我们再回来看DG，由于standby数据库的数据通常都来自于primary数据库，怎么来的呢，通过RFS进程接收primary数据库的redo，保存在本地，这就是standby redo logs。然后standby数据库的ARC在将其写入归档，就是standby服务器的archived redo logs。

保存之后数据又是怎么生成的呢，两种方式，物理standby通过redo应用，逻辑standby通过sql应用。不管是那种应用，应用的是什么呢？它是应用redo log中的内容。默认情况下应用archived redo logs，如果打开了实时应用，则直接从standby redo logs读取。至于如何应用，那就是redo应用和sql应用机制的事情。

针对上述内容我们试着总结一下：

对于primary数据库和逻辑standby数据库，online redo logs文件是必须。对于primary数据库和物理standby数据库，毕竟物理standby不会有写的操作，所以物理standby应该不会生成redo数据。为保证数据库的事务一致性必然需要归档，也就是是不管primary或standby都不行运行于归档模式。

standby redo logs是standby数据库特有的文件，就本身的特点比如文件存储特性，配置特性等等斗鱼online redo logs非常相似，不过它存储的是接收自primary数据库的redo数据库，而online redo logs中记录的是本机的操作。



## 6. Data Gurad单实例部署

### 6.1 安装环境

在主机1上安装数据库软件，并建监听和实例，在主机2上安装数据库软件，并建监听，但不建实例

|    项目    | 主机1（主库）                        | 主机2（备库）                        |
| :--------: | ------------------------------------ | ------------------------------------ |
|  操作系统  | Centos7.6 64                         | Centos7.6 64                         |
|  主机名称  | db15                                 | db16                                 |
|   IP地址   | 172.16.103.15                        | 172.16.103.16                        |
| Oracle版本 | Oracle 11.2.0.4                      | Oracle 11.2.0.4                      |
|    BASE    | /data/app/oracle                     | /data/app/oracle                     |
|    HOME    | /data/app/oracle/product/11.2.0/db_1 | /data/app/oracle/product/11.2.0/db_1 |
|  db_name   | oracle11                             | oracle11                             |
| db_unqiue  | db15                                 | db16                                 |
|   闪回区   | 开启                                 |                                      |
|    归档    | 开启                                 |                                      |



### 6.2 主端配置

#### 6.2.1 设置数据库归档

- 查看数据库是否开启归档模式

```plsql
SQL> archive log list;
Database log mode	       No Archive Mode
Automatic archival	       Disabled
Archive destination	       USE_DB_RECOVERY_FILE_DEST
Oldest online log sequence     20
Current log sequence	       22
```

- 开启归档日志

```plsql
# 关闭数据库
SQL> shutdown immediate;
Database closed.
Database dismounted.
ORACLE instance shut down.

# 启动到mount状态（挂起）
SQL> startup mount;
ORACLE instance started.
Total System Global Area 2505338880 bytes
Fixed Size		    2255832 bytes
Variable Size		  637535272 bytes
Database Buffers	 1845493760 bytes
Redo Buffers		   20054016 bytes
Database mounted.

# 开启归档
SQL> alter database archivelog;
Database altered.

# open数据库
SQL> alter database open;
Database altered.

# 设置归档路径（可以跳过）
SQL> alter system set log_archive_dest_1='location=D:\app\Administrator\virtual\fast_recovery_area\oracle12\ORACLE12\ARCHIVELOG';
System altered.

# 检查归档日志
SQL> archive log list;
Database log mode	       Archive Mode
Automatic archival	       Enabled
Archive destination	       /data/oracle/archivelog
Oldest online log sequence     20
Next log sequence to archive   22
Current log sequence	       22
```



#### 6.2.2 设置数据库闪回

- 验证是否开启闪回

```plsql
SQL> select flashback_on from v$database;
FLASHBACK_ON
------------------------------------
NO
```

- 开启闪回

```plsql
# 设置闪回区路径
SQL> alter system set db_recovery_file_dest='/data/oracle';
System altered.

# 设置闪回区大小
SQL> alter system set db_recovery_file_dest_size='40G';
System altered.

# 关闭数据库
SQL> shutdown immediate;
Database closed.
Database dismounted.
ORACLE instance shut down.

# 开启mount状态
SQL> startup mount;
ORACLE instance started.
Total System Global Area 2505338880 bytes
Fixed Size		    2255832 bytes
Variable Size		  637535272 bytes
Database Buffers	 1845493760 bytes
Redo Buffers		   20054016 bytes
Database mounted.

# 开启闪回
SQL> alter database flashback on;
Database altered.

# open数据库
SQL> alter database open;
Database altered.

# 验证闪回是否开启
SQL> select flashback_on from v$database;
FLASHBACK_ON
------------------------------------
YES

# 查看闪回路径
SQL> show parameter db_recovery_file_dest;

NAME				     TYPE					VALUE
---------------------- ----------------------  ------------------------------
db_recovery_file_dest		     string         /data/oracle
db_recovery_file_dest_size	     big integer    5G
```



#### 6.2.3 设置数据库强制归档

- 验证是否开启force logging

```plsql
SQL> select force_logging from v$database;
FORCE_
---------------------
NO
```

- 开启强制归档

```plsql
# 开启强制归档
SQL> alter database force logging;
Database altered.

# 验证
SQL> select force_logging from v$database;
FORCE_
------
YES
```



#### 6.2.4 添加standby日志文件

- 查看主库online日志大小和组

```PLSQL
SQL> SELECT GROUP#,ARCHIVED,STATUS,BYTES/1024/1024 FROM V$LOG;
    GROUP# ARCHIV STATUS			   BYTES/1024/1024
---------- ------ -------------------------------- ---------------
	 1 YES	  INACTIVE					50
	 2 NO	  CURRENT					50
	 3 YES	  INACTIVE					50
```

- 查看主库online日志路径

```PLSQL
SQL> SELECT GROUP#,MEMBER FROM V$LOGFILE;
 GROUP#   MEMBER
-------	 -------------------------------------------------------------------------
	3	 /data/app/oracle/oradata/oracle11/redo03.log
	2	 /data/app/oracle/oradata/oracle11/redo02.log
	1    /data/app/oracle/oradata/oracle11/redo01.log
```

- 添加standby日志文件（4组），这里不能与redo组相同

```PLSQL
SQL> 
ALTER DATABASE ADD STANDBY LOGFILE GROUP 11 'D:\app\Administrator\virtual\fast_recovery_area\oracle12\ORACLE12\ONLINELOG\redo11_stb01_log' size 200M;

ALTER DATABASE ADD STANDBY LOGFILE GROUP 12 'D:\app\Administrator\virtual\fast_recovery_area\oracle12\ORACLE12\ONLINELOG\redo12_stb02_log' size 200M;

ALTER DATABASE ADD STANDBY LOGFILE GROUP 13 'D:\app\Administrator\virtual\fast_recovery_area\oracle12\ORACLE12\ONLINELOG\redo13_stb03_log' size 200M;

ALTER DATABASE ADD STANDBY LOGFILE GROUP 14 'D:\app\Administrator\virtual\fast_recovery_area\oracle12\ORACLE12\ONLINELOG\redo14_stb04_log' size 200M;


*删除standby logfile*
ALTER DATABASE DROP STANDBY LOGFILE GROUP 11
```

- 查看standby日志文件

```PLSQL
SQL> SELECT GROUP#,ARCHIVED,STATUS FROM V$STANDBY_LOG;
    GROUP# ARCHIV STATUS
---------- ------ --------------------
	11 YES	  UNASSIGNED
	12 YES	  UNASSIGNED
	13 YES	  UNASSIGNED
	14 YES	  UNASSIGNED

SQL> SELECT MEMBER FROM V$LOGFILE;
GROUP#	MEMBER
------  ----------------------------------------------------------------------------
	3	/data/app/oracle/oradata/oracle11/redo03.log
	2	/data/app/oracle/oradata/oracle11/redo02.log
	1	/data/app/oracle/oradata/oracle11/redo01.log
	11	/data/app/oracle/oradata/oracle11/redo11_stb01_log
	12	/data/app/oracle/oradata/oracle11/redo12_stb02_log
	13	/data/app/oracle/oradata/oracle11/redo13_stb03_log
	14	/data/app/oracle/oradata/oracle11/redo14_stb04_log
```



#### 6.2.5 配置pfile文件

**pfile:** 初始化参数文件（Initialization Parameters Files），Oracle 9i之前，ORACLE一直采用pfile方式存储初始化参数，pfile 默认的名称为“init+例程名.ora”文件路径：$ORACLE_HOME/dbs，这是一个文本文件，可以用任何文本编辑工具打开。

**配置pfile文件是为了生成spfile，因为spfile是二进制文件，不可直接进行修改**

- 创建pfile文件

```plsql
SQL> create pfile from spfile;
File created.
```

- **拷贝pfile文件到备库**。（备库不在需要创建pfile）

```shell
[oracle@db15 dbs]$ pwd
/data/app/oracle/product/11.2.0/db_1/dbs

scp initoracle11.ora 172.16.103.16:/data/app/oracle/product/11.2.0/db_1/dbs/
```

- 修改pfile文件，在initoracle11.ora末尾追加下面内容

```plsql
*.db_unique_name='db19'
*.fal_server='db20'
*.log_archive_config='dg_config=(db19,db20)'
*.log_archive_dest_1='location=use_db_recovery_file_dest valid_for=(all_logfiles, all_roles) db_unique_name=db19'
*.log_archive_dest_2='service=db20 lgwr async valid_for=(online_logfile,primary_role) db_unique_name=db20'
*.log_archive_dest_state_1=ENABLE
*.log_archive_dest_state_2=ENABLE
*.standby_file_management='AUTO'
*.db_file_name_convert='D:\app\Administrator\virtual\oradata\ORACLE12','D:\app\Administrator\virtual\oradata\ORACLE12'
*.log_file_name_convert='D:\app\Administrator\virtual\oradata\ORACLE12','D:\app\Administrator\virtual\oradata\ORACLE12'
```



#### 6.2.6 配置spfile文件

**spfile:**服务器参数文件（Server Parameter Files），从Oracle 9i开始，Oracle引入了Spfile文件，spfile 默认的名称为“spfile+例程名.ora”文件路径：$ORACLE_HOME/dbs 以二进制文本形式存在，不能用vi编辑器对其中参数进行修改，只能通过SQL命令在线修改。

- 关闭数据库

```plsql
SQL> shutdown immediate;
Database closed.
Database dismounted.
ORACLE instance shut down.
```

- 创建spfile文件

```plsql
SQL> create spfile from pfile;
File created.
```

- 启动数据库

```plsql
SQL> startup
ORACLE instance started.

Total System Global Area 2505338880 bytes
Fixed Size		    2255832 bytes
Variable Size		  637535272 bytes
Database Buffers	 1845493760 bytes
Redo Buffers		   20054016 bytes
Database mounted.
Database opened.
```

* 查看spfile文件位置

```plsql
# select查询
SQL> SELECT NAME, VALUE, DISPLAY_VALUE FROM V$PARAMETER WHERE NAME ='spfile';
NAME
--------------------------------------------------------------------------------
VALUE
--------------------------------------------------------------------------------
DISPLAY_VALUE
--------------------------------------------------------------------------------
spfile
/data/app/oracle/product/11.2.0/db_1/dbs/spfileoracle11.ora
/data/app/oracle/product/11.2.0/db_1/dbs/spfileoracle11.ora

# show查询 spfile
SQL> show parameter spfile;
NAME				     TYPE
------------------------------------ ----------------------
VALUE
------------------------------
spfile				     string
/data/app/oracle/product/10.2.
0/db_1/dbs/spfileoracle11.ora

# show查询 pfile
SQL> show parameter pfile;

NAME				     TYPE
------------------------------------ ----------------------
VALUE
------------------------------
spfile				     string
/data/app/oracle/product/10.2.
0/db_1/dbs/spfileoracle11.ora

```

- 判断使用spfile还是pfile

```plsql
SQL> select decode(count(*),1,'spfile','pfile') from v$spparameter where rownum=1 and isspecified ='TRUE';

DECODE(COUNT
------------
spfile

# 查出的结果一致，就是表明使用哪种
SQL> show parameter spfile;
SQL> show parameter pfile;
```

- 如何更改为pfile启动？

```plsql
SQL> shutdown immediate;
SQL> startup pfile='/data/app/oracle/product/11.2.0/db_1/dbs/initoracle11.ora'
```



#### 6.2.7 复制密码文件到备库[^1]

Oracle数据库的密码文件存放有具有SYSDBA/SYSOPER权限用户的用户名、及口令，它一般存放在$ORACLE_HOME/dbs目录下。

使用密码文件认证方式登录的数据库时，默认查找密码文件的顺序是：---> orapw<sid> ---> orapw ---> Failure

```shell
oracle@zyp-c76-orc11-m dbs]$ scp orapworacle11 oracle@172.16.103.16:/data/app/oracle/product/11.2.0/db_1/dbs
oracle@172.16.103.16's password: 
orapworacle11                                          100% 1536     1.4MB/s   00:00   
```

#### 6.2.8 配置监听listener.ora

主库配置监听文件listener.ora

```shell
cd $ORACLE_HOME/network/admin
mv listener.ora listener.ora.defaults
vim listener.ora

# listener.ora Network Configuration File: D:\app\Administrator\virtual\product\12.2.0\dbhome_1\network\admin\listener.ora
# Generated by Oracle configuration tools.

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (SID_NAME = CLRExtProc)
      (ORACLE_HOME = D:\app\Administrator\virtual\product\12.2.0\dbhome_1)
      (PROGRAM = extproc)
      (ENVS = "EXTPROC_DLLS=ONLY:D:\app\Administrator\virtual\product\12.2.0\dbhome_1\bin\oraclr12.dll")
    )
    (SID_DESC =
      (GLOBAL_DBNAME = oracle12)
      (ORACLE_HOME = D:\app\Administrator\virtual\product\12.2.0\dbhome_1)
      (SID_NAME = oracle12)
      (ENVS = "EXTPROC_DLLS=ONLY:D:\app\Administrator\virtual\product\12.2.0\dbhome_1\bin\oraclr12.dll")
    )
  )

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.103.19)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
```

#### 6.2.9 配置TNS文件

配置tnsnames.ora，主库和备库的配置一样

```shell
cd $ORACLE_HOME/network/admin
mv tnsnames.ora tnsnames.ora.defaults
vim tnsnames.ora

# tnsnames.ora Network Configuration File: D:\app\Administrator\virtual\product\12.2.0\dbhome_1\network\admin\tnsnames.ora
# Generated by Oracle configuration tools.

LISTENER_ORACLE12 =
  (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.103.19)(PORT = 1521))


ORACLR_CONNECTION_DATA =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
    (CONNECT_DATA =
      (SID = CLRExtProc)
      (PRESENTATION = RO)
    )
  )

db19 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.103.19)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle12)
    )
  )
db20 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.103.20)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle12)
    )
  )
```

#### 6.2.10 重启监听服务

在配置好listener.ora后，需重启服务（主库备库都需要）。

```shell
[oracle@db15 ~]$ lsnrctl stop
[oracle@db15 ~]$ lsnrctl start
[oracle@db15 ~]$ lsnrctl status
```



<u>**注意，在继续往下之前，必须保证备库已完成到重启监听服务**</u>



#### 6.2.11 RMAN复制到备库

- RMAN连接到主库和备库

```shell
[oracle@db15 ~]$ rman target sys/123456@db19 auxiliary sys/123456@db20

Recovery Manager: Release 11.2.0.4.0 - Production on Wed Sep 2 00:37:30 2020

Copyright (c) 1982, 2011, Oracle and/or its affiliates.  All rights reserved.

connected to target database: ORACLE11 (DBID=2742673775)
connected to auxiliary database: ORACLE11 (not mounted)
```

- 使用RMAN的duplicate命令进行复制，两边目录结构相同，需要添加nofilenamecheck参数

```plsql
RMAN> duplicate target database for standby from active database nofilenamecheck;

# 执行过程请查看附录7.3
```





---

---

### 6.3 备端配置

#### 6.3.1 创建目录

使用oracle用户创建相关目录，避免权限问题。

```shell
mkdir -p /data/app/oracle/oradata/oracle11/
mkdir -p /data/app/oracle/admin/oracle11/adump/
mkdir -p /data/oracle/
mkdir -p /data/oracle/archivelog
```



#### 6.3.2 配置pfile文件

编辑从主库拷贝过来的pfile文件，在initoracle11.ora文件末尾添加如下内容

***这里配置pfile文件与主库配置pfile文件目的相同，是为生成spfile文件。***

```plsql
*.db_unique_name='db16'
*.fal_server='db15'
*.log_archive_config='dg_config=(db15,db16)'
*.log_archive_dest_1='location=use_db_recovery_file_dest valid_for=(all_logfiles, all_roles) db_unique_name=db16'
*.log_archive_dest_2='service=db15 lgwr async valid_for=(online_logfile,primary_role) db_unique_name=db15'
*.log_archive_dest_state_1=ENABLE
*.log_archive_dest_state_2=ENABLE
*.standby_file_management='AUTO'
*.db_file_name_convert='D:\app\Administrator\virtual\oradata\ORACLE12','D:\app\Administrator\virtual\oradata\ORACLE12'
*.log_file_name_convert='D:\app\Administrator\virtual\oradata\ORACLE12','D:\app\Administrator\virtual\oradata\ORACLE12'
```

#### 6.3.3 配置spfile文件

利用pfile文件创建spfile，操作步骤如下。

```plsql
SQL> shutdown immediate
SQL> create spfile from pfile
SQL> startup nomount	# 这里需注意使用nomount，不挂载数据库，因为没有数据库。
```

#### 6.3.4 配置监听listener.ora

备端配置监听文件listener.ora

```shell
cd $ORACLE_HOME/network/admin
mv listener.ora listener.ora.defaults
vim listener.ora

# listener.ora Network Configuration File: /data/app/oracle/product/11.2.0/db_1/network/admin/listener.ora
# Generated by Oracle configuration tools.

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = db16)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
SID_LIST_LISTENER =
  (SID_LIST = 
    (SID_DESC =
      (SID_NAME = PLSExtProc)
      (ORACLE_HOME = /data/app/oracle/product/11.2.0/db_1)
      (PROGRAM = extproc)
      )
    (SID_DESC = 
      (GLOBAL_DBNAME = oracle11)
      (ORACLE_HOME = /data/app/oracle/product/11.2.0/db_1)
      (SID_NAME = oracle11)
      )
   )
      
ADR_BASE_LISTENER = /data/app/oracle
```

#### 6.3.5 配置TNS文件

配置tnsnames.ora，主库和备库的配置一样

```shell
cd $ORACLE_HOME/network/admin
mv tnsnames.ora tnsnames.ora.defaults
vim tnsnames.ora

# tnsnames.ora Network Configuration File: /data/app/oracle/product/11.2.0/db_1/network/admin/tnsnames.ora
# Generated by Oracle configuration tools.

DB15 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = db15)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle11)
    )
  )
  
DB16 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = db16)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle11)
    )
  )
```

#### 6.3.5 重启监听服务

在配置好listener.ora后，需重启服务（主库备库都需要）。

```shell
[oracle@db16 ~]$ lsnrctl stop
[oracle@db16 ~]$ lsnrctl start
[oracle@db16 ~]$ lsnrctl status
```



#### 6.3.6 RMAN复制后的检查

执行完6.2.11复制成功后，备库自动被加载为mount模式，进入sqlplus查看

```plsql
SQL> select status from v$instance;

STATUS
------------------------
MOUNTED
```

#### 6.3.7 开启实时日志应用(开启同步)

```plsql
# 开启同步
SQL> alter database recover managed standby database using current logfile disconnect from session;

Database altered.

# 关闭同步
SQL> alter database recover managed standby database cancel; 
```



#### 6.2.8 开启备库闪回

在DG完成搭建和同步后，备库的控制文件都是来源与主库，但闪回区不是on的状态，需要手动调整一下。注意，此步骤并非必要步骤，也可以不调整。这是主要是为了后面做主备切换做准备，当备库切换为主库时闪回区则必须开启。

- 验证是否开启闪回

```plsql
SQL> select flashback_on from v$database;
FLASHBACK_ON
------------------------------------
NO
```

- 开启闪回

```plsql
# 关闭数据库
SQL> shutdown immediate;
Database closed.
Database dismounted.
ORACLE instance shut down.

# 开启mount状态
SQL> startup mount;
ORACLE instance started.
Total System Global Area 2505338880 bytes
Fixed Size		    2255832 bytes
Variable Size		  637535272 bytes
Database Buffers	 1845493760 bytes
Redo Buffers		   20054016 bytes
Database mounted.

# 开启闪回
SQL> alter database flashback on;
Database altered.

# open数据库
SQL> alter database open;
Database altered.

# 验证闪回是否开启
SQL> select flashback_on from v$database;
FLASHBACK_ON
------------------------------------
YES

# 查看闪回路径
SQL> show parameter db_recovery_file_dest

NAME				     TYPE					VALUE
---------------------- ----------------------  ------------------------------
db_recovery_file_dest		     string         /data/oracle
db_recovery_file_dest_size	     big integer    5G
```





### 6.4 验证配置

#### 6.4.1 验证主库状态

```plsql
SQL> select switchover_status,database_role from v$database;

SWITCHOVER_STATUS			 DATABASE_ROLE
--------------------------- --------------------------------
TO STANDBY 					 PRIMARY
```

主库显示：TO STANDBY和PRIMARY，如果显示SESSION ACTIVE表示还有活动的会话

#### 6.4.2 验证备库状态

```plsql
SQL> select switchover_status,database_role from v$database;

SWITCHOVER_STATUS			 DATABASE_ROLE
-------------------------- --------------------------------
NOT ALLOWED					 PHYSICAL STANDBY
```

备库显示：NOT ALLOWED和PHYSICAL STANDBY

#### 6.4.3 归档日志序号

- oracle12c在备库使用`archive log list;`命令显示归档日志序号都为0，需要使用如下命令查看。

```plsql
select thread#, max(sequence#) "Last Standby Seq Applied"
from v$archived_log val, v$database vdb
where val.resetlogs_change# = vdb.resetlogs_change#
and val.applied in ('YES','IN-MEMORY')
group by thread# order by 1;


select max(sequence#) from v$archived_log;
```



#### 6.4.4 查看备库启动的DG进程

```plsql
SQL> select process,client_process,sequence#,status from v$managed_standby;

PROCESS 	   CLIENT_PROCESS    SEQUENCE# STATUS
------------------ ---------------- ---------- ------------------------
ARCH		   ARCH 		     0 CONNECTED
ARCH		   ARCH 		     0 CONNECTED
ARCH		   ARCH 		     0 CONNECTED
ARCH		   ARCH 		    47 CLOSING
RFS		 	   ARCH 		     0 IDLE
RFS		 	   UNKNOWN		     0 IDLE
RFS			   UNKNOWN		     0 IDLE
RFS			   LGWR 		    48 IDLE
MRP0		   N/A			    48 APPLYING_LOG

# ARCH-ARCH-47-CLOSING	 	//归档进程
# RFS-LGWR-48-IDLE			//归档传输进程
# MRP0-N/A-48-APPLYING_LOG	//日志应用进程
```

#### 6.4.5 在备库上查看数据的保护模式

```plsql
SQL> select database_role,protection_mode,protection_level,open_mode from v$database;

DATABASE_ROLE	 	PROTECTION_MODE		  PROTECTION_LEVEL		OPEN_MODE
-----------------  --------------------- --------------------- ---------------
PHYSICAL STANDBY	MAXIMUM PERFORMANCE	  MAXIMUM PERFORMANCE	MOUNTED

//最大性能模式max performance-默认
//最大可用性模式max availability
//最大保护模式max protection
//数据库模式为：mount
```

#### 6.4.6 查看备库上DG日志

主库上的日志信息量

```plsql
select * from v$dataguard_status;
```

#### 6.4.7 创建临时表验证

```plsql
# 主库创建表
create table test as select * from dba_objects where rownum < 101;

# 备库查询
select count(*) from test;    ## 结果为100表示实时同步成功

# 主库删除
drop table test purge;
```





### 6.5 OPEN备库

#### 6.5.1 重新启动备库

```plsql
# 关闭数据库
SQL> studown immediate;

# 打开数据库
SQL> startup
```

#### 6.5.2 查看备库模式

```plsql
SQL> select database_role,protection_mode,protection_level,open_mode from v$database;

DATABASE_ROLE	 	PROTECTION_MODE		  PROTECTION_LEVEL		OPEN_MODE
-----------------  --------------------- --------------------- ---------------
PHYSICAL STANDBY	MAXIMUM PERFORMANCE	  MAXIMUM PERFORMANCE	READ ONLY

# 此时数据库模式默认为read-only
```

#### 6.5.3 查看DG进程

```plsql
SQL> select process,client_process,sequence#,status from v$managed_standby;

PROCESS 	   CLIENT_PROCESS    SEQUENCE# STATUS
------------------ ---------------- ---------- ------------------------
ARCH		   ARCH 		     0 CONNECTED
ARCH		   ARCH 		     0 CONNECTED
ARCH		   ARCH 		     0 CONNECTED
ARCH		   ARCH 		    48 CLOSING
RFS		   	   ARCH 		     0 IDLE
RFS		  	   UNKNOWN		     0 IDLE
RFS		  	   LGWR 		    49 IDLE
```

#### 6.5.4 开启实时日志应用(重启同步)

```plsql
SQL> alter database recover managed standby database using current logfile disconnect from session;
```

#### 6.5.5 验证同步

查看最大归档序号是否一致。

```plsql
SQL> SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME,APPLIED,DELETED FROM V$ARCHIVED_LOG WHERE DELETED='NO' ORDER BY SEQUENCE#;

 SEQUENCE# FIRST_TIME	       NEXT_TIME	   APPLIED	      DELETE
---------- ------------------- ------------------- ------------------ ------
	44 2020-09-01 23:27:01 2020-09-02 00:38:20 YES		      NO
	45 2020-09-02 00:38:20 2020-09-02 00:39:17 YES		      NO
	46 2020-09-02 00:39:17 2020-09-02 00:43:38 YES		      NO
	47 2020-09-02 00:43:38 2020-09-02 01:24:40 YES		      NO
	48 2020-09-02 01:24:40 2020-09-02 01:55:50 NO		      NO

//sequence		归档日志序号
//first_time	首次执行时间
//next_time		最后执行时间
//applied		是否已应用
//delete		是否删除
```



### 6.6 手动断开DG

在完成DG配置后，特殊场景，在不管主库情况下，将备库设置为read-write模式。这里主要是将备库在断开后，不在与主库同步，而是使用自己的归档。终止实现备库为read-write模式。

此方法相当做failover，只不过主库在线不去理会他而已。以下全部在备库操作。

```plsql
# 关闭同步
SQL> alter database recover managed standby database cancel; 

# 强制停止redo apply
SQL> alter database recover managed standby database finish force;

# 查看备库状态
SQL> select switchover_status,database_role from v$database;
SWITCHOVER_STATUS			 DATABASE_ROLE
---------------------------------------- --------------------------------
SESSIONS ACTIVE 			 PHYSICAL STANDBY

# 切换为primary
SQL> alter database commit to switchover to primary with session shutdown; 

# 打开数据库
SQL> alter database open;

# 验证数据库模式
SQL> select database_role,protection_mode,protection_level,open_mode from v$database;
DATABASE_ROLE	 	PROTECTION_MODE		  PROTECTION_LEVEL		OPEN_MODE
-----------------  --------------------- --------------------- ---------------
PHYSICAL STANDBY	MAXIMUM PERFORMANCE	  MAXIMUM PERFORMANCE	READ WRITE
```



## 7.Data Gurad切换与恢复

我们配置DG的目的就是为了在主库出现故障时，备库能够提供服务，保证业务的正常运行。DG的故障切换分为switchover和failover两种:

switchover是用户有计划的进行停机切换，能够保证不丢失数据。

failover是当主库真正出现严重系统故障，如数据库宕机，软硬件故障导致主库不能支持服务，从而进行的切换动作。

### 7.1 swithchover

```shell
// 验证主备归档序号
select max(sequence#),applied from v$archived_log group by applied;
# 如果主备归档序号相同，且备库applied为yes，则表示DG正常。否则不可切换。

// 查看主库状态
select switchover_status from v$database;
# 如显示“TO STANDBY”，表示primary支持转为未standby角色。否则不可切换。
# 如显示“session active”，则需要在命令后面加上with sesion shutdown子句。


// 主库切换到standby
alter database commit to switchover to physical standby;
alter database commit to switchover to physical standby with sesion shutdown；
# 执行之后，主库状态变成“RECOVERY NEEDED”。否则不可切换

// 主库重启到mount模式
shutdown immediate
startup mount

// 备库切换到
```



### 7.2 failover



## 8. 附录

### 8.1 SPFILE文件参数说明

#### 8.1.1 DB_NAME

数据库名字，需要保持同一个Data Guard中所有数据库DB_NAME相同。 一般情况下与实例名相同，也可以不同。查看数据库语句:` select name from v$database`或`show parameter db_name;`

例如：（主库和备库相同）

```plsql
DB_NAME='oracle11' 
DB_NAME='oracle11' 
```

#### 8.1.2 DB_UNIQUE_NAME

指定目标数据库的唯一名称。在DG中，主备库拥有相同的DB_NAME，为了区别就必须有不相同的DB_UNIQUE_NAME

例如：

```plsql
DB_UNIQUE_NAME=db15
DB_UNIQUE_NAME=db16
```

#### 8.1.3 LOG_ARCHIVE_CONFIG

用于初始化LOG_ARCHIVE_CONFIG参数，控制发送归档日志到远程位置、接收远程归档日志，并指定DG配置的唯一数据库名，默认值为send、receive、nodg_config。

可以通过ALTER SYSTEM SET log_archive_config='SEND';进行配置。

DG_CONFIG属性罗列同一个Data Guard中所有DB_UNIQUE_NAME(含primary db及standby db)，以逗号分隔。主库和备库相同 

| 参数        | 说明                        |
| ----------- | --------------------------- |
| send        | 允许归档日志发送到远程位置  |
| nosend      | 禁止归档日志发送到远程位置  |
| receive     | 启用远程接收归档日志        |
| noreveive   | 关闭远程接收归档日志        |
| dg_config   | 可以最多指定9个唯一数据库名 |
| nodg_config | 禁止指定唯一数据库名        |

例如：（主库和备库相同）

```plsql
LOG_ARCHIVE_CONFIG='DG_CONFIG=(db15,db16)' 
LOG_ARCHIVE_CONFIG='DG_CONFIG=(dn15,db16)'
```

#### 8.1.4 CONTROL_FILES

指定数据库控制文件路径，需指定具体的文件位置。

查看控制文件`select name from v$controlfile;`

例如：（主库和备库根据实际情况指定）

```plsql
control_files='/data/app/oracle/oradata/oracle11/control01.ctl','/data/app/oracle/oradata/oracle11/control02.ctl'
control_files='/data/app/oracle/oradata/oracle11/control01.ctl','/data/app/oracle/oradata/oracle11/control02.ctl'
```

#### 8.1.5 LOG_ARCHIVE_DEST_n

设置最多10个(n=[1..10])不同的归档路径，通过设置关键词location或service来指向本地路径或远程路径。每个目的必须制定location或者service属性。

| 参数      | 说明                                                         |
| --------- | ------------------------------------------------------------ |
| affirm    | 指定redo传输目的地在写redo数据到standby redo日志**之后**反馈给primary |
| noaffirm  | 指定redo传输目的地在写redo数据到standby redo日志**之前**反馈给primary |
|           | - 如果没有明确指定，当sync属性被指定时，默认是affirm。       |
|           | - 如果没有明确指定，当async属性被指定时，默认是noaffirm。    |
| delay     | 参数明确指定一个standby位置应用接收到的归档redo数据延迟的时间，delay是可选的，默认是没有任何延迟。delay属性的设置表明在standby目的地应用归档redo日志是不活动的，直到指定的时间间隔过期才会应用日志，在standby数据库上，当redo数据库成功传输和归档后开始计算时间，delay的时间间隔以分钟为单位，可以用于保护standby数据库免遭、来自主数据库的用户错误或者损坏带来的影响，是一种折中方案，在failover过程中必然需要更多的时间来应用日志。Delay不影响redo时间传送到standby目的地，如果启动实时应用，设置的任何延迟都将被忽略。改变delay属性设置会在下一次redo时间呗归档时起作用，正在归档的日志不受影响。 |
| location  | 本地归档日志路径                                             |
| service   | 远程归档日志路径，一般指定oracle net名称                     |
| sync      | 表明通过事务生成的redo数据在事务提交之前必须被每个启用的目的地接收 |
| async     | 表明通过事务生成的redo数据在事务提交之前不需要被目的地接收，没有指定默认为aysnc |
| valid_for | 定义何时使用(角色相关)LOG_ARCHIVE_DEST_n参数以及应该在哪类重做日志文件上运行。 |
|           | 参数格式：`VALID_FOR=(redo_log_type,database_role)`          |
|           | **redo_log_type**                                            |
|           | online_logfile：目的地只归档联机redo日志                     |
|           | standby_logfile：目的地只归档standby redo日志                |
|           | all_logfile：目的地既归档联机redo日志，也归档standby redo日志 |
|           | **database_role**                                            |
|           | primary_role：只有数据库是主，该目的地才会产生归档           |
|           | standby_role：只有数据库是备，该目的地才会产生归档           |
|           | all_role：当数据库不论是主还是备，该目的地都会产生归档       |
| arch/lgwr | 日志传输服务使用ARCH还是LGWR,默认的是ARCH，倾向设置为LGWR。  |
|           |                                                              |

综上所述，dg中LOG_ARCHIVE_DEST_n配置如下：
最大保护模式是保证零数据丢失，LOG_ARCHIVE_DEST_n配置为LGWR SYNC AFFIRM。
最高可用性是零数据丢失，LOG_ARCHIVE_DEST_n配置为LGWR SYNC AFFIRM。
最高性能是保证最小数据丢失 - 通常为几秒
LGWR ASYNC 或 ARCH可没有但推荐有 AFFIRM 或 NOAFFIRM
AFFIRM：表示主数据库上的REDO LOG只有被写入到从数据库的standby log才算有效。

例如：

```plsql
log_archive_dest_1='location=/data/oracle/archivelog valid_for=(all_logfiles, all_roles) db_unique_name=db15'
log_archive_dest_2='service=db16 lgwr async valid_for=(online_logfile,primary_role) db_unique_name=db16'
```

#### 8.1.6 LOG_ARCHIVE_DEST_STATE_n 

用于开启或禁止`LOG_ARCHIVE_DEST_n `归档日志的配置。

| 参数     | 说明                                     |
| -------- | ---------------------------------------- |
| enable   | 开启归档日志发送到目的地，此为默认值     |
| defer    | 禁止归档日志发送到目的地                 |
| alternat | 如果与关联的目标通信失败，则启用此目的地 |

例如：

```plsql
log_archive_dest_1='location=/data/oracle/archivelog valid_for=(all_logfiles, all_roles) db_unique_name=db15'
log_archive_dest_state_1=ENABLE
log_archive_dest_2='service=db16 lgwr async valid_for=(online_logfile,primary_role) db_unique_name=db16'
log_archive_dest_state_2=ENABLE
```

#### 8.1.7 LOG_ARCHIVE_FORMAT

指定归档文件格式，这里在主备端应保持一样的格式。 

%t -thread number 		# 线程号
%s -log sequence number 	# 日志序列号
%r -resetlogs ID 	重做日志ID
例如：

```plsql
LOG_ARCHIVE_FORMAT=log%t_%s_%r.arc 
LOG_ARCHIVE_FORMAT=log%t_%s_%r.arc 
```

#### 8.1.8 LOG_ARCHIVE_MAX_PROCESSES

指定归档进程的数量(1-30)，默认值通常是4。 

例如：

```plsql
LOG_ARCHIVE_MAX_PROCESSES=4
```

#### 8.1.9 COMPATIBLE

主数据库和备用数据库的Oracle兼容版本信息，主备设置必须保证一致。

例如：

```plsql
COMPATIBLE='11.2.0.4.0' 
COMPATIBLE='11.2.0.4.0' 
```

#### 8.1.10 FAL_SERVER

**备库端的参数**，指定一个数据库的`DB_UNIQUE_NAME`，通常该库为primary 角色。（FAL 是Fetch Archived Log 的缩写） 

例如：

```plsql
主库：(主库进行设置，是为了在切换后主备角色互换后使用)
FAL_SERVER=db16

备库： 
FAL_SERVER=db15
```

#### 8.1.11 FAL_CLIENT(废弃)==

**备库端的参数**，指定一个数据库`DB_UNIQUE_NAME`，通常该库为standby 角色。 Oracle11g已经废弃这个参数，直接所有FAL_SERVER即可，同样支持switchover或failover的切换。

```plsql
主库（主库进行设置，是为了在切换后主备角色互换后使用）： 
FAL_CLIENT=db15

备库： 
FAL_CLIENT=db16
```

#### 8.1.12 DB_FILE_NAME_CONVERT

主数据库和备数据库的数据文件转换目录对映（如果两数据库的目录结构不一样），如果有多个对应关系，需逐一给出。 

```plsql
主库（主库进行设置，是为了在切换后主备角色互换后使用）： 
DB_FILE_NAME_CONVERT='/data/app/oracle/oradata/oracle11/','/data/app/oracle/oradata/oracle11/' 

备库： 
DB_FILE_NAME_CONVERT='/data/app/oracle/oradata/oracle11/','/data/app/oracle/oradata/oracle11/' 
```

#### 8.1.13 LOG_FILE_NAME_CONVERT 

指明主数据库和备用数据库的log文件转换目录对应关系。 

```plsql
主库（主库进行设置，是为了在切换后主备角色互换后使用）
log_FILE_NAME_CONVERT='/data/app/oracle/oradata/oracle11','/data/app/oracle/oradata/oracle11'

备份
log_FILE_NAME_CONVERT='/data/app/oracle/oradata/oracle11','/data/app/oracle/oradata/oracle11'
```

#### 8.1.14 STANDBY_FILE_MANAGEMENT

如果主数据库数据文件发生修改（如新建，重命名等）则按照本参数的设置在备库中做相应修改。设为AUTO 表示自动管理；设为MANUAL表示需要手工管理。 

```plsql
主库（主库进行设置，是为了在切换后主备角色互换后使用）： 
STANDBY_FILE_MANAGEMENT=AUTO 

备库： 
STANDBY_FILE_MANAGEMENT=AUTO 
```



### 8.2 关于spfile和pfile

#### 8.2.1 启动优先级

1. startup 启动次序 spfile优先于pfile。查找文件的顺序是 spfileSID.ora-〉spfile.ora-〉initSID.ora-〉init.ora（spfile优先于pfile）
2. startup pfile='文件目录'      使用pfile启动，则需指定完整路径，或删除**spfile**.
3.  如果在数据库的$ORACLE_HOME/dbs/目录下既有spfile又有pfile,使用spfile启动数据库，不需要指定参数文件路径（因为数据库会优先选择spfile启动）
4. 如果参数文件不在$ORACLE_HOME/dbs/目录下，无论是通过spfile或pfile启动均需要指定完整路径。

#### 8.2.2 spfile参数的三种scope

1. scope=spfile: 对参数的修改记录在服务器初始化参数文件中，修改后的参数在下次启动DB时生效。适用于动态和静态初始化参数。

2. scope=memory: 对参数的修改记录在內存中，对于动态初始化参数的修改立即生效。在重启DB后会丟失,会复原为修改前的参数值。

3. scope=both:  对参数的修改会同时记录在服务器参数文件和內存中，对于动态参数立即生效，对静态参数不能用这个
4. 如果使用了服务器参数文件，则在执行alter system语句时，scope=both是default的选项。如果沒有使用服务器参数文件，而在执行alter system语句时指定scope=spfile|both都会出错。

| 参数类型 | spfile               | memory                   | both                       |
| -------- | -------------------- | ------------------------ | -------------------------- |
| 静态参数 | 可以，重启服务器生效 | 不可以                   | 不可以                     |
| 动态参数 | 可以，重启服务器生效 | 立即生效，重启服务器失效 | 立即生效，重启服务器仍生效 |



### 8.3 RMAN复制执行过程

```plsql
RMAN> duplicate target database for standby from active database nofilenamecheck;

Starting Duplicate Db at 2020-09-02 00:38:08
using target database control file instead of recovery catalog
allocated channel: ORA_AUX_DISK_1
channel ORA_AUX_DISK_1: SID=189 device type=DISK

contents of Memory Script:
{
   backup as copy reuse
   targetfile  '/data/app/oracle/product/11.2.0/db_1/dbs/orapworacle11' auxiliary format 
 '/data/app/oracle/product/11.2.0/db_1/dbs/orapworacle11'   ;
}
executing Memory Script

Starting backup at 2020-09-02 00:38:08
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=192 device type=DISK
Finished backup at 2020-09-02 00:38:10

contents of Memory Script:
{
   backup as copy current controlfile for standby auxiliary format  '/data/app/oracle/oradata/oracle11/control01.ctl';
   restore clone controlfile to  '/data/app/oracle/fast_recovery_area/oracle11/control02.ctl' from 
 '/data/app/oracle/oradata/oracle11/control01.ctl';
}
executing Memory Script

Starting backup at 2020-09-02 00:38:10
using channel ORA_DISK_1
channel ORA_DISK_1: starting datafile copy
copying standby control file
output file name=/data/app/oracle/product/11.2.0/db_1/dbs/snapcf_oracle11.f tag=TAG20200902T003810 RECID=1 STAMP=1050021491
channel ORA_DISK_1: datafile copy complete, elapsed time: 00:00:01
Finished backup at 2020-09-02 00:38:11

Starting restore at 2020-09-02 00:38:11
using channel ORA_AUX_DISK_1

channel ORA_AUX_DISK_1: copied control file copy
Finished restore at 2020-09-02 00:38:12

contents of Memory Script:
{
   sql clone 'alter database mount standby database';
}
executing Memory Script

sql statement: alter database mount standby database

contents of Memory Script:
{
   set newname for tempfile  1 to 
 "/data/app/oracle/oradata/oracle11/temp01.dbf";
   switch clone tempfile all;
   set newname for datafile  1 to 
 "/data/app/oracle/oradata/oracle11/system01.dbf";
   set newname for datafile  2 to 
 "/data/app/oracle/oradata/oracle11/sysaux01.dbf";
   set newname for datafile  3 to 
 "/data/app/oracle/oradata/oracle11/undotbs01.dbf";
   set newname for datafile  4 to 
 "/data/app/oracle/oradata/oracle11/users01.dbf";
   backup as copy reuse
   datafile  1 auxiliary format 
 "/data/app/oracle/oradata/oracle11/system01.dbf"   datafile 
 2 auxiliary format 
 "/data/app/oracle/oradata/oracle11/sysaux01.dbf"   datafile 
 3 auxiliary format 
 "/data/app/oracle/oradata/oracle11/undotbs01.dbf"   datafile 
 4 auxiliary format 
 "/data/app/oracle/oradata/oracle11/users01.dbf"   ;
   sql 'alter system archive log current';
}
executing Memory Script

executing command: SET NEWNAME

renamed tempfile 1 to /data/app/oracle/oradata/oracle11/temp01.dbf in control file

executing command: SET NEWNAME

executing command: SET NEWNAME

executing command: SET NEWNAME

executing command: SET NEWNAME

Starting backup at 2020-09-02 00:38:18
using channel ORA_DISK_1
channel ORA_DISK_1: starting datafile copy
input datafile file number=00001 name=/data/app/oracle/oradata/oracle11/system01.dbf
output file name=/data/app/oracle/oradata/oracle11/system01.dbf tag=TAG20200902T003818
channel ORA_DISK_1: datafile copy complete, elapsed time: 00:00:35
channel ORA_DISK_1: starting datafile copy
input datafile file number=00002 name=/data/app/oracle/oradata/oracle11/sysaux01.dbf
output file name=/data/app/oracle/oradata/oracle11/sysaux01.dbf tag=TAG20200902T003818
channel ORA_DISK_1: datafile copy complete, elapsed time: 00:00:15
channel ORA_DISK_1: starting datafile copy
input datafile file number=00003 name=/data/app/oracle/oradata/oracle11/undotbs01.dbf
output file name=/data/app/oracle/oradata/oracle11/undotbs01.dbf tag=TAG20200902T003818
channel ORA_DISK_1: datafile copy complete, elapsed time: 00:00:07
channel ORA_DISK_1: starting datafile copy
input datafile file number=00004 name=/data/app/oracle/oradata/oracle11/users01.dbf
output file name=/data/app/oracle/oradata/oracle11/users01.dbf tag=TAG20200902T003818
channel ORA_DISK_1: datafile copy complete, elapsed time: 00:00:01
Finished backup at 2020-09-02 00:39:17

sql statement: alter system archive log current

contents of Memory Script:
{
   switch clone datafile all;
}
executing Memory Script

datafile 1 switched to datafile copy
input datafile copy RECID=1 STAMP=1050021557 file name=/data/app/oracle/oradata/oracle11/system01.dbf
datafile 2 switched to datafile copy
input datafile copy RECID=2 STAMP=1050021557 file name=/data/app/oracle/oradata/oracle11/sysaux01.dbf
datafile 3 switched to datafile copy
input datafile copy RECID=3 STAMP=1050021557 file name=/data/app/oracle/oradata/oracle11/undotbs01.dbf
datafile 4 switched to datafile copy
input datafile copy RECID=4 STAMP=1050021557 file name=/data/app/oracle/oradata/oracle11/users01.dbf
Finished Duplicate Db at 2020-09-02 00:39:21
```



### 8.4 参考文档

- DG操作步骤.txt

```plsql
主库：db70 
ip：192.168.201.70
db_name：easdb
unique_name：db70
net service_name：db70
==================
辅库：db10 
ip：192.168.201.10
db_name：easdb
unique_name：db10
net service_name：db10
========================
2台主机分别修改hosts文件加入host解析
192.168.201.70	db70
192.168.21.10	db10
===========================
1，主库开启归档，强制日志force logging
--干净的关闭数据库
SQL> shutdown immediate
--以mount模式启动
SQL> startup mount
--切换到归档模式
SQL> alter database archivelog;
--开启强制日志
SQL> alter database force logging;
--打开数据库
SQL> alter database open;
--查看归档
SQL> archive log list;
--查看是否为强制日志
SQL> select force_logging from v$database;
===================================
2，主库添加standby redo log
--查看Redo和Standby Redo
SQL> select * from v$logfile;											
--仅仅显示Online Redo，不显示Standby Redo
SQL> select * from v$log;												
--新增一组大小为500M的Standby Redo，这里的group号不得与Online redo重复
SQL> alter database add standby logfile group 21 '/u01/app/oracle/oradata/easdb/standby21.log' size 500M;
SQL> alter database add standby logfile group 22 '/u01/app/oracle/oradata/easdb/standby22.log' size 500M;
SQL> alter database add standby logfile group 23 '/u01/app/oracle/oradata/easdb/standby23.log' size 500M;
SQL> alter database add standby logfile group 24 '/u01/app/oracle/oradata/easdb/standby24.log' size 500M;
=======================================================================
3，从主库创建pfile
SQL> create pfile from spfile;
创建pfile文件, 默认路径为$ORACLE_HOME/dbs（/u01/app/oracle/product/11.2.0/dbhome_1/dbs）
将主库的pfile复制到备库/u01/app/oracle/product/11.2.0/dbhome_1/dbs/下
cd /u01/app/oracle/product/11.2.0/dbhome_1/dbs/
scp initorcl.ora db12:/u01/app/oracle/product/11.2.0/dbhome_1/dbs/
oracle@db10's password: 
initeasdb.ora   100% 1014     1.0KB/s   00:00  
===============================
4，设置主库初始化参数编辑/u01/app/oracle/product/11.2.0/dbhome_1/dbs/initorcl.ora文件在末尾追加
*.db_unique_name='db70'
*.fal_server='db10'
*.log_archive_config='dg_config=(db70,db10)'
*.log_archive_dest_1='location=use_db_recovery_file_dest valid_for=(all_logfiles, all_roles) db_unique_name=db70'
*.log_archive_dest_2='service=db10 lgwr async valid_for=(online_logfile,primary_role) db_unique_name=db10'
*.log_archive_dest_state_1=ENABLE
*.log_archive_dest_state_2=ENABLE
*.standby_file_management='AUTO'
*.db_file_name_convert='/u01/app/oracle/oradata/easdb','/u01/app/oracle/oradata/easdb'
*.log_file_name_convert='/u01/app/oracle/oradata/easdb','/u01/app/oracle/oradata/easdb'
=============================================================
5,创建新的主库spfile文件，并重新启动主库
SQL> shutdown immediate
SQL> create spfile from pfile;
SQL> startup
======================
6,修改备库初始化参数,编辑/u01/app/oracle/product/11.2.0/dbhome_1/dbs/initorcl.ora文件在末尾追加
*.db_unique_name='db10'
*.fal_server='db70'
*.log_archive_config='dg_config=(db70,db10)'
*.log_archive_dest_1='location=use_db_recovery_file_dest valid_for=(all_logfiles, all_roles) db_unique_name=db10'
*.log_archive_dest_2='service=db70 lgwr async valid_for=(online_logfile,primary_role) db_unique_name=db70'
*.log_archive_dest_state_1=ENABLE
*.log_archive_dest_state_2=ENABLE
*.standby_file_management='AUTO'
*.db_file_name_convert='/u01/app/oracle/oradata/easdb','/u01/app/oracle/oradata/easdb'
*.log_file_name_convert='/u01/app/oracle/oradata/easdb','/u01/app/oracle/oradata/easdb'
==============================================================
7,复制主库的密码文件orapworcl到备库的/u01/app/oracle/product/11.2.0/dbhome_1/dbs/下
cd /u01/app/oracle/product/11.2.0/dbhome_1/dbs/
scp orapworcl db12:/u01/app/oracle/product/11.2.0/dbhome_1/dbs/
oracle@db10's password: 
orapweasdb                  100% 1536     1.5KB/s   00:00 
=====================================
8,创建备库相应的目录结构使用oracle用户创建以下目录，避免权限问题
mkdir -p /u01/app/oracle/oradata/easdb/
mkdir -p /u01/app/oracle/admin/easdb/adump/
mkdir -p /u01/app/oracle/fast_recovery_area/easdb/
9,配置主库和备库的监听
主库创建listener.ora
# listener.ora Network Configuration File: /u01/app/oracle/product/11.2.0/dbhome_1/network/admin/listener.ora
# Generated by Oracle configuration tools.

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = db70)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
SID_LIST_LISTENER =
  (SID_LIST = 
    (SID_DESC =
      (SID_NAME = PLSExtProc)
      (ORACLE_HOME = /u01/app/oracle/product/11.2.0/dbhome_1)
      (PROGRAM = extproc)
      )
    (SID_DESC = 
      (GLOBAL_DBNAME = easdb)
      (ORACLE_HOME = /u01/app/oracle/product/11.2.0/dbhome_1)
      (SID_NAME = easdb)
      )
   )
      
ADR_BASE_LISTENER = /u01/app/oracle
====================================
备库创建listener.ora
# listener.ora Network Configuration File: /u01/app/oracle/product/11.2.0/dbhome_1/network/admin/listener.ora
# Generated by Oracle configuration tools.

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = db10)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
SID_LIST_LISTENER =
  (SID_LIST = 
    (SID_DESC =
      (SID_NAME = PLSExtProc)
      (ORACLE_HOME = /u01/app/oracle/product/11.2.0/dbhome_1)
      (PROGRAM = extproc)
      )
    (SID_DESC = 
      (GLOBAL_DBNAME = easdb)
      (ORACLE_HOME = /u01/app/oracle/product/11.2.0/dbhome_1)
      (SID_NAME = easdb)
      )
   )
      
ADR_BASE_LISTENER = /u01/app/oracle
======================================
主库,备库创建tnsnames.ora，配置一样
# tnsnames.ora Network Configuration File: /u01/app/oracle/product/11.2.0/dbhome_1/network/admin/tnsnames.ora
# Generated by Oracle configuration tools.

DB70 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = db70)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = easdb)
    )
  )
DB10 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = db10)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = easdb)
    )
  )
=====================================================
10,创建备库的spfile文件，启动备库到nomount模式
SQL> shutdown immediate
SQL> create spfile from pfile;
SQL> startup nomount
===============================
11,主库备库重启监听
lsnrctl stop
lsnrctl start
===================
12,RMAN复制主库到备库
首先RMAN连接到目标数据库和辅助数据库
rman target sys/Kingdee1@db70 auxiliary sys/Kingdee1@db10

Recovery Manager: Release 11.2.0.4.0 - Production on Fri Mar 27 00:05:27 2020

Copyright (c) 1982, 2011, Oracle and/or its affiliates.  All rights reserved.

connected to target database: EASDB (DBID=1013944561)
connected to auxiliary database: EASDB (not mounted)

RMAN> 
使用RMAN的duplicate命令进行复制，两边目录结构相同，需要添加nofilenamecheck参数
RMAN> duplicate target database for standby from active database nofilenamecheck;
============================================================
13,复制成功后，备库自动被加载为mount模式，进入sqlplus查看
SQL> select status from v$instance;

STATUS
------------
MOUNTED
======================
14,在备库开启实时日志应用
SQL> alter database recover managed standby database using current logfile disconnect from session;

Database altered.
================
15,主备库角色状态查询
SQL> select switchover_status,database_role from v$database;
SWITCHOVER_STATUS    DATABASE_ROLE
-------------------- ----------------
SESSIONS ACTIVE      PRIMARY
--主库显示：TO STANDBY/PRIMARY，如果显示SESSION ACTIVE表示还有活动的会话
备库状态
SQL> select switchover_status,database_role from v$database;

SWITCHOVER_STATUS    DATABASE_ROLE
-------------------- ----------------
NOT ALLOWED	     PHYSICAL STANDBY
--备库显示：NOT ALLOWED/PHYSICAL STANDBY
======================================
16,测试DG在主库端切换归档
SQL> archive log list;
Database log mode	       Archive Mode
Automatic archival	       Enabled
Archive destination	       USE_DB_RECOVERY_FILE_DEST
Oldest online log sequence     80
Next log sequence to archive   82
Current log sequence	82
SQL> alter system switch logfile;
System altered.
SQL> SQL> archive log list;
Database log mode	       Archive Mode
Automatic archival	       Enabled
Archive destination	       USE_DB_RECOVERY_FILE_DEST
Oldest online log sequence     81
Next log sequence to archive   83
Current log sequence	83
===========================
备库上查看，日志的sequence号也跟着变了
SQL> archive log list;
Database log mode	       Archive Mode
Automatic archival	       Enabled
Archive destination	       USE_DB_RECOVERY_FILE_DEST
Oldest online log sequence     81
Next log sequence to archive   0
Current log sequence	83
====================================
17,查看备库启动的dg进程
SQL> select process,client_process,sequence#,status from v$managed_standby;

PROCESS   CLIENT_P  SEQUENCE# STATUS
--------- -------- ---------- ------------
ARCH	  ARCH		   82 CLOSING
ARCH	  ARCH		    0 CONNECTED         //归档进程
ARCH	  ARCH		    0 CONNECTED
ARCH	  ARCH		   81 CLOSING
MRP0	  N/A		   83 APPLYING_LOG    //日志应用进程
RFS	  UNKNOWN	    0 IDLE
RFS	  UNKNOWN	    0 IDLE
RFS	  ARCH		    0 IDLE
RFS	  LGWR		   83 IDLE                    //归档传输进程

9 rows selected.
==========================
18,在备库上查看数据库的保护模式
SQL> select database_role,protection_mode,protection_level,open_mode from v$database;

DATABASE_ROLE	 PROTECTION_MODE      PROTECTION_LEVEL	   OPEN_MODE
---------------- -------------------- -------------------- --------------------
PHYSICAL STANDBY MAXIMUM PERFORMANCE  MAXIMUM PERFORMANCE  MOUNTED
//最大性能模式max performance-默认
//最大可用性模式max availability
//最大保护模式max protection
=====================
19,查看dg日志
SQL> select * from v$dataguard_status;
=============================
20,以只读方式打开备库，并开启实时日志应用
SQL> shutdown immediate
ORA-01109: database not open


Database dismounted.
ORACLE instance shut down.
SQL> startup
ORACLE instance started.

Total System Global Area 2.7125E+10 bytes
Fixed Size		    2266104 bytes
Variable Size		 1.3422E+10 bytes
Database Buffers	 1.3690E+10 bytes
Redo Buffers		   10301440 bytes
Database mounted.
Database opened.
SQL> select database_role,protection_mode,protection_level,open_mode from v$database;

DATABASE_ROLE	 PROTECTION_MODE      PROTECTION_LEVEL	   OPEN_MODE
---------------- -------------------- -------------------- --------------------
PHYSICAL STANDBY MAXIMUM PERFORMANCE  MAXIMUM PERFORMANCE  READ ONLY

SQL> select process,client_process,sequence#,status from v$managed_standby;

PROCESS   CLIENT_P  SEQUENCE# STATUS
--------- -------- ---------- ------------
ARCH	  ARCH		    0 CONNECTED
ARCH	  ARCH		    0 CONNECTED
ARCH	  ARCH		    0 CONNECTED
ARCH	  ARCH		   83 CLOSING
RFS	  ARCH		    0 IDLE
RFS	  LGWR		   84 IDLE
RFS	  UNKNOWN	    0 IDLE

7 rows selected.

SQL> alter database recover managed standby database using current logfile disconnect from session;

Database altered.
=============================
21,验证数据同步
SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME,APPLIED,DELETED FROM V$ARCHIVED_LOG WHERE DELETED='NO' ORDER BY SEQUENCE#;
```

- DG主备切换操作

```plsql
主备切换： 
切换顺序，把主切换成从；再把从切换成主 
查看日志：
tail -100f /u01/app/oracle/diag/rdbms/db70/easdb/trace/alert_easdb.log
--原来的主库上切成备的操作： 
SQL> select database_role,switchover_status from v$database;
DATABASE_ROLE 		SWITCHOVER_STATUS 
---------------- ------------------------
PRIMARY 			SESSIONS ACTIVE 
SQL> alter database commit to switchover to physical standby with session shutdown; 
#SQL> shutdown immediate 
SQL> startup nomount 
SQL> alter database mount standby database; 
SQL> recover managed standby database disconnect from session; 
SQL> select database_role,switchover_status from v$database; 
DATABASE_ROLE 		SWITCHOVER_STATUS 
---------------- ------------------------
PHYSICAL STANDBY 	TO PRIMARY 

--原来的备库切成主库的操作： 
SQL> select database_role,switchover_status from v$database; 
DATABASE_ROLE 		SWITCHOVER_STATUS 
---------------- -------------------- 
PHYSICAL STANDBY 	TO PRIMARY 
SQL> alter database commit to switchover to primary with session shutdown; 


============================================================= 
--切的时候报了下面错误；
发现是上面的实验把备库open read only了，
所以提示需要介质恢复；那么（alter database close;）, 
再应用日志（recover managed standby database disconnect from session;），再来切换就可以了 
SQL> alter database commit to switchover to primary with session shutdown; 
alter database commit to switchover to primary with session shutdown 
* 
ERROR at line 1: ORA-16139: media recovery required 
============================================================= 
SQL> shutdown immediate 
SQL> startup 
SQL> select database_role,switchover_status from v$database; 
DATABASE_ROLE 		SWITCHOVER_STATUS 
---------------- -------------------- 
PRIMARY 			SESSIONS ACTIVE
```



### 8.5 Win配置步骤

```plsql
# 主库
lsnrctl status
sqlplus / as sysdba

----
## 检查强制、归档、闪回
select force_logging from v$database;

archive log list;
alter system set log_archive_dest_1='location=D:\app\Administrator\archivelog';

select flashback_on from v$database;
show parameter db_recovery_file_dest;
alter system set db_recovery_file_dest='D:\app\Administrator\fast_recovery_area';
alter system set db_recovery_file_dest_size='40G';

----
## 开启强制、归档、闪回
shutdown immediate;
startup mount;

alter database archivelog;
alter database flashback on;
alter database force logging;

alter database open;

----
## 添加standby
select group#,member from v$logfile;

alter database add standby logfile group 11 'd:\app\administrator\oradata\oracle11\redo11_stb01_log' size 50m;
alter database add standby logfile group 12 'd:\app\administrator\oradata\oracle11\redo12_stb02_log' size 50m;
alter database add standby logfile group 13 'd:\app\administrator\oradata\oracle11\redo13_stb03_log' size 50m;
alter database add standby logfile group 14 'd:\app\administrator\oradata\oracle11\redo14_stb04_log' size 50m;

select group#,archived,status from v$standby_log;


## 先pfile，在spfile
show parameter spfile;
create pfile from spfile;

##//Win系统复制“initoracle11.ora”到备库
##//D:\app\Administrator\product\11.2.0\dbhome_1\database\
##//编辑“initoracle11.ora”，末尾加入
​```config.ora
*.db_unique_name='db13'
*.fal_server='db14'
*.log_archive_config='dg_config=(db13,db14)'
*.log_archive_dest_1='location=use_db_recovery_file_dest valid_for=(all_logfiles, all_roles) db_unique_name=db13'
*.log_archive_dest_2='service=db14 lgwr async valid_for=(online_logfile,primary_role) db_unique_name=db14'
*.log_archive_dest_state_1=ENABLE
*.log_archive_dest_state_2=ENABLE
*.standby_file_management='AUTO'
*.db_file_name_convert='D:\app\Administrator\oradata\oracle11','D:\app\Administrator\oradata\oracle11'
*.log_file_name_convert='D:\app\Administrator\oradata\oracle11','D:\app\Administrator\oradata\oracle11'
​```

## 创建spfile从pfile
shutdown immediate;
create spfile from pfile;
startup;

## 复制密码文件到备库
##//D:\app\Administrator\product\11.2.0\dbhome_1\database\PWDoracle11.ora

## 配置listener.ora
##//注意先备份
​```config.ora
# listener.ora Network Configuration File: D:\app\Administrator\product\11.2.0\dbhome_1\network\admin\listener.ora
# Generated by Oracle configuration tools.

SID_LIST_LISTENER =
  (SID_LIST =
	(SID_DESC =
      (SID_NAME = CLRExtProc)
      (ORACLE_HOME = D:\app\Administrator\product\11.2.0\dbhome_1)
      (PROGRAM = extproc)
      (ENVS = "EXTPROC_DLLS=ONLY:D:\app\Administrator\product\11.2.0\dbhome_1\bin\oraclr11.dll")
    )
	(SID_DESC =
      (GLOBAL_DBNAME = oracle11)
      (ORACLE_HOME = D:\app\Administrator\product\11.2.0\dbhome_1)
      (SID_NAME = oracle11)
      (ENVS = "EXTPROC_DLLS=ONLY:D:\app\Administrator\product\11.2.0\dbhome_1\bin\oraclr11.dll")
    )
  )

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.103.13)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )

ADR_BASE_LISTENER = D:\app\Administrator
​```


## 配置tnsnames.ora
##//注意先备份
+++++++++++++++++config file start+++++++++++++++++++
# tnsnames.ora Network Configuration File: D:\app\Administrator\product\11.2.0\dbhome_1\NETWORK\ADMIN\tnsnames.ora
# Generated by Oracle configuration tools.

ORACLR_CONNECTION_DATA =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
    (CONNECT_DATA =
      (SID = CLRExtProc)
      (PRESENTATION = RO)
    )
  )

DB13 =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.103.13)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle11)
    )
  )
  
DB14 =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.103.14)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle11)
    )
  )
+++++++++++++++++config file end+++++++++++++++++++

## 重启监听服务
lsnrctl stop
lsnrctl start
lsnrctl status

=============================================
#备库
##创建文件夹
D:\app\Administrator\archivelog

lsnrctl status
sqlplus / as sysdba

## 先pfile，在spfile
修改主库复制过来的“initoracle11.ora”文件，在末尾追加
​```config.ora
*.db_unique_name='db14'
*.fal_server='db13'
*.log_archive_config='dg_config=(db13,db14)'
*.log_archive_dest_1='location=use_db_recovery_file_dest valid_for=(all_logfiles, all_roles) db_unique_name=db14'
*.log_archive_dest_2='service=db13 lgwr async valid_for=(online_logfile,primary_role) db_unique_name=db13'
*.log_archive_dest_state_1=ENABLE
*.log_archive_dest_state_2=ENABLE
*.standby_file_management='AUTO'
*.db_file_name_convert='D:\app\Administrator\oradata\oracle11','D:\app\Administrator\oradata\oracle11'
*.log_file_name_convert='D:\app\Administrator\oradata\oracle11','D:\app\Administrator\oradata\oracle11'
​```

## 创建spfile从pfile
shutdown immediate;
create spfile from pfile;
startup nomount;


## ## 配置listener.ora
##//注意先备份
​```config.ora
# listener.ora Network Configuration File: D:\app\Administrator\product\11.2.0\dbhome_1\network\admin\listener.ora
# Generated by Oracle configuration tools.

SID_LIST_LISTENER =
  (SID_LIST =
	(SID_DESC =
      (SID_NAME = CLRExtProc)
      (ORACLE_HOME = D:\app\Administrator\product\11.2.0\dbhome_1)
      (PROGRAM = extproc)
      (ENVS = "EXTPROC_DLLS=ONLY:D:\app\Administrator\product\11.2.0\dbhome_1\bin\oraclr11.dll")
    )
	(SID_DESC =
      (GLOBAL_DBNAME = oracle11)
      (ORACLE_HOME = D:\app\Administrator\product\11.2.0\dbhome_1)
      (SID_NAME = oracle11)
      (ENVS = "EXTPROC_DLLS=ONLY:D:\app\Administrator\product\11.2.0\dbhome_1\bin\oraclr11.dll")
    )
  )

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.103.14)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )

ADR_BASE_LISTENER = D:\app\Administrator
​```

## 配置tnsnames.ora
##//注意先备份
​```config.ora
# tnsnames.ora Network Configuration File: D:\app\Administrator\product\11.2.0\dbhome_1\NETWORK\ADMIN\tnsnames.ora
# Generated by Oracle configuration tools.

ORACLR_CONNECTION_DATA =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
    (CONNECT_DATA =
      (SID = CLRExtProc)
      (PRESENTATION = RO)
    )
  )

DB13 =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.103.13)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle11)
    )
  )
  
DB14 =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.103.14)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle11)
    )
  )
​```

## 重启监听服务
lsnrctl stop
lsnrctl start
lsnrctl status

## rman复制（主备都可执行）
### 登录
rman target sys/123456@db13 auxiliary sys/123456@db14
### 复制
duplicate target database for standby from active database nofilenamecheck;
### 开启同步
alter database recover managed standby database using current logfile disconnect from session;

## 检查备库模式
select status from v$instance;

## 关闭数据库
shutdown immediate;

## 打开数据库
alter database open;

## 开启闪回
alter database flashback on;
select flashback_on from v$database;


================================
# 验证
## 查看主备状态
select switchover_status,database_role from v$database;

## 查看主备归档序号
archive log list;
alter system switch logfile;  ##//主库执行
archive log list;

## 查看备库DG进程
select process,client_process,sequence#,status from v$managed_standby;

## 查看备库保护模式
select database_role,protection_mode,protection_level,open_mode from v$database;

## 验证同步
select sequence#, first_time, next_time,applied,deleted from v$archived_log where deleted='NO' order by sequence#;


============================
# 以下归档日志定时清除策略
# Windows Oracle 定时清理归档日志
[toc]

## 1. 创建文件夹
cd D:\app\Administrator\
mkdir clear_arch
cd .\clear_arch
echo '' >clear_arch.bat
echo '' >clear_arch.ora

## 2. 添加bat脚本，用于定时任务
D:\app\Administrator\clear_arch\clear_arch.bat
​```powershell
set y=%date:~0,4%
set m=%date:~5,2%
set d=%date:~8,2%

set /a th=%time:~0,2%
if %th% LSS 10 (set hh=0%th%) else (set hh=%th%)
set /a tm=%time:~3,2%
if %tm% LSS 10 (set mm=0%tm%) else (set mm=%tm%)
set /a ts=%time:~6,2%
if %ts% LSS 10 (set ss=0%ts%) else (set ss=%ts%)

set logname=%y%%m%%d%%hh%%mm%%ss%

rman target / msglog=D:\app\Administrator\clear_arch\%logname%.log cmdfile=D:\app\Administrator\clear_arch\clear_arch.ora
​```



## 3. 添加执行脚本，用于定时任务执行的脚本

D:\app\Administrator\clear_arch\clear_arch.ora
​```plsql
crosscheck archivelog all;
delete noprompt expired archivelog all;
delete noprompt archivelog all completed before 'sysdate - 7';
exit;
​```



## 4. Windows 定时任务

cmd 下 执行 taskschd.msc，打开定时任务管理器。

1.依次“任务计划程序(本地)>任务计划程序库>Microsoft”，右击“Microsoft”新建文件夹，命名为“oracle”

![image-20200921205612995](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200921205612995.png)

![image-20200921205858695](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200921205858695.png)



2.右击新文件夹“oracle”，创建基本任务，打开任务向导。输入“任务名”和“描述”下一步。

![image-20200921210054028](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200921210054028.png)

![image-20200921210144054](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200921210144054.png)



3.选择执行频率“每天”

![image-20200921210253217](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200921210253217.png)

4.设置开始执行时间：“4:00:00、每个1天发生一次”

![image-20200921210857947](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200921210857947.png)

5.启动程序

![image-20200921211127053](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200921211127053.png)

6.选择脚本

![image-20200921211231403](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200921211231403.png)

7.勾选“当点击‘完成’时，打开此属性对话框”

![image-20200921211307675](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200921211307675.png)

8.选择“不管用户是否登录都要运行”；勾选“不存储密码”；勾选“使用最高权限运行”

![image-20200921211419144](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200921211419144.png)

9.测试运行，检查任务

![image-20200921211620787](C:\Users\rockchou\AppData\Roaming\Typora\typora-user-images\image-20200921211620787.png)



结束。。
```



### 8.6 脚注说明

[^1]: [关于Oracle口令认证原理](https://blog.csdn.net/ifudon/article/details/7075042)
