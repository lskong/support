# Windows Oracle 定时清理归档日志
[toc]

## 1. 创建文件夹
cd D:\app\Administrator\
mkdir clear_arch
type nul >clear_arch.bat
type nul >clear_arch.ora

## 2. 添加bat脚本，用于定时任务
D:\app\Administrator\clear_arch\clear_arch.bat
```powershell
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
```



## 3. 添加执行脚本，用于定时任务执行的脚本

D:\app\Administrator\clear_arch\clear_arch.ora
```plsql
crosscheck archivelog all;
delete noprompt expired archivelog all;
delete noprompt archivelog all completed before 'sysdate - 7';
exit;
```



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