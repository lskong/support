# Linux Shell编程
[toc]


## 1. Shell介绍

### 1.1 为什么要学习Shell
- 安装操作系统: 1.手动安装 2.工具自动化安装[Kickstart Cobbler] 3.网络安装
- 系统优化：
  - 关闭Selinux，iptables,Firewalld。防火墙工作中必须开启的对外场景，内部的测试服务器无所谓。ssh优化、加大文件描述符、内核参数优化、yum源、安装常用的软件、ntp时间同步、字符集调整。
- 安装服务Nginx、Apache（yum install httpd）、php、MySQL、Keepalived、Zabbix
    Sersync、NFS、Fedis、Mongo、Memcached、KVM、Docker、K8S、ELK...使用脚本安装。
  4）修改配置文件，启动服务（systemctl start stop restart reload status）
    公司自主研发（使用Python开发的程序）
  5）日志监控、日志切割、脚本+定时任务（rsync+sersync、rsync+cron）、ELK
  6）日志统计，使用三剑客+命令做日志分析
  7）数据备份、数据库备份（存三份，服务器本地+机房备份+办公室备份）
  8）监控，Zabbix（常用）、Nagios（交换路由）、Cacti（最要，流量监控）
    脚本把数据统计出来，使用Zabbix进行监控

### 1.2 学习Shell所需的知识
  1）Xshell连接工具，CRT工具
  2）Linux常用的基础命令
  3）vim编辑器
  4）三剑客：grep，sed，awk
  
### 1.3 如何学好Shell编程
 环境变量、条件表达式、if判断、for循环、while循环、caes语句、数组、条件控制语句continue break exit
  1）掌握以上执行，能够读懂脚本
  2）针对脚本进行修改，添加各种语句判断等
  3）编程语言是相通的，即脚本相同可套用
  4）需要一本教材（老男孩Shell编程）
  5）特别详细的笔记，或者其他Shell书籍
  6）练习出题自己编写脚本，学完Shell编程，能解决企业中大部分脚本问题

### 1.4 Shell入门
  1）什么是Shell
    Shell是命令的解释器，负责翻译我们输入的命令，执行成功发回给用户
    面试题：Linux默认的Shell是什么（答：bash）
    交互式：用户输入命令，bash负责把我们的命令翻译成内核可识别的语言，返回结果到屏幕
    非交互式：不与用户进行交互，执行文本里的内容，执行到文件的末尾结束。
  2）什么是Shell脚本
    命令的集合，命令大礼包，很多可以执行的命令发在文本中称为Shell脚本，还包含条件表达式判断语句数组等
    语言种类：C C++ Python Java Perl go php

### 1.5 Shell脚本规范
  1）为自动化做准备
  2）必须放在统一的目录
  3）脚本必须以.sh结尾
  4）脚本开头有注释#!/bin/bash 必须是第一行，以外的都是注释
  5）脚本的注释信息 Author cut log count 代码块注释
        #!/bin/sh
        #Author rockchou
        #data count
        #QQ...
  6）建议注释使用英文
  7）成对的符合和语法一次书写完币
  8）脚本名称的命令，最好见名知其意

## 2. Shell环境变量
01.什么是环境变量
  x=1 y=x+1,这里的x和y是变量名称，等号后面的是赋值
  右边一堆内容，使用一个名称来代替为环境变量

02.环境变量分类
  1）全局变量（环境变量）
  2）局部变量（普通变量）
  3）安装生命周期划分：永久的、临时的
  4）永久的，需要自环境变量文件中配置/etc/profile永久生效
  5）临时的，命令行使用export声明的，临时变量，重启失效
    test=12234只对当前的bash生效    
    export test=12234 对当前所有bash生效
    写入/etc/profile针对所有用户和bash生效
  6）如何查看变量：env、set
  7）环境变量生效顺序
    /etc/profile开机所有用户加载此文件
    . ~/.bashrc
    .bash_profile
    .bashrc
    /etc/bashrc

03.Shell变量值的定义
    数值的定义：name_age=1234    必须连续的数字
    字符串的定义：name="oldboy"  字符串必须加双引号，却会解析变量；单引号所见即所得
    命令的定义：time=`date`      反引号解析命令
              time=$(date)     $()解析命令
注意：命令的定义是吧结果复制给了变量，如果变量改变结果，需再次赋值

[root@localhost scripts]# time=`date`
[root@localhost scripts]# date
Fri Apr 10 01:02:53 CST 2020
[root@localhost scripts]# echo $time
Fri Apr 10 01:02:52 CST 2020
[root@localhost scripts]# date
Fri Apr 10 01:03:10 CST 2020
[root@localhost scripts]# echo $time
Fri Apr 10 01:02:52 CST 2020
[root@localhost scripts]# time=`date`


04.Shell特殊位置变量
  $0  代表了脚本的名称，如果全路径则脚本名称带全路径
      使用方法：给用户提示，如echo $"Usage: $0 {start|stop|restart}"
      只获取脚本名称：basename test.sh
  $n  脚本的第n个参数，0被脚本名称占用，所有从1开始 $1 $2...$9后面的参数需加{}

[root@localhost scripts]# cat test.sh
#!/bin/bash
#Author Rockchou
#Date 2020-04-10
echo $1 $2 $3 $3 $4 $5 $6 $7 $8 $9 $10 $11

[root@localhost scripts]# sh test.sh {1..11}
1 2 3 3 4 5 6 7 8 9 10 11

[root@localhost scripts]# sh test.sh {a..z}
a b c c d e f g h i a0 a1    //实际是$1+0和$1+1

[root@localhost scripts]# cat test.sh
#!/bin/bash
#Author Rockchou
#Date 2020-04-10
echo $1 $2 $3 $3 $4 $5 $6 $7 $8 $9 ${10} ${11}

[root@localhost scripts]# sh test.sh {a..z}
a b c c d e f g h i j k

  $#  获取脚本传参的总个数，控制脚本的传参

[root@localhost scripts]# cat test.sh
#!/bin/bash
#Author Rockchou
#Date 2020-04-10
[ $# -ne 2 ] && echo "Please input two parameter" && exit
name=$1
age=$2
echo $name $age

[root@localhost scripts]# sh test.sh oldboy
Please input two parameter

[root@localhost scripts]# sh test.sh oldboy 100
oldboy 100

[root@localhost scripts]# sh test.sh oldboy 100 str
Please input two parameter

  $*  获取脚本所有的参数，不加双引号与$@相同，加上双引号则把参数视为一个参数
  $@  获取脚本所有的参数，不加双引号与$*相同，加上双引号则把参数是为独立的参数
  $*和$@在脚本中相同，在循环内不同

[root@localhost scripts]# set -- "I am" rockchou techer
[root@localhost scripts]# echo $*
I am rockchou techer
[root@localhost scripts]# echo $@
I am rockchou techer
[root@localhost scripts]# echo "$*"
I am rockchou techer
[root@localhost scripts]# echo "$@"
I am rockchou techer
[root@localhost scripts]# for i in $*;do echo $i;done
I
am
rockchou
techer
[root@localhost scripts]# for i in $@;do echo $i;done
I
am
rockchou
techer
[root@localhost scripts]# for i in "$*";do echo $i;done
I am rockchou techer
[root@localhost scripts]# for i in "$@";do echo $i;done
I am
rockchou
techer
    
  $?  获取上一条命令的返回结果，0表示成功，非0表示失败
      可指定返回结果 [ $# -ne 2 ] && echo "pl inp two par" &&* exit 50

[root@localhost scripts]# echo $?
0
[root@localhost scripts]# ls xxxxx
ls: cannot access xxxxx: No such file or directory
[root@localhost scripts]# echo $?
2

[root@localhost scripts]# cat test.sh
#!/bin/bash
#Author Rockchou
#Date 2020-04-10
[ $# -ne 2 ] && echo "Please input two parameter" && exit 50
name=$1
age=$2
echo $name $age
[root@localhost scripts]# sh test.sh
Please input two parameter
[root@localhost scripts]# echo $?
50


  $$  获取脚本的PID
      echo $$ >/tmp/nginx_log.pid
      kill -9 `cat /tmp/nginx_log.pid`
  $!  获取上一个在后台运行脚本的PID，调试使用
  $_  获取命令行最后一个参数，相当于ESC.

05.脚本传参的三种方式
  1）第一种传参方式，赋值
  name=$1
  age=$2
  echo $name $age

  2）第二种传参方式，直接传参
  echo $1 $2

  3）第三种传参方式 （read）
  read -p "please input name :" name
  echo $name

题目：使用read传参的方式修改主机名称oldboy和IP地址10.0.0.100 sed
1.read -p "请输入要修改的主机名称" 变量名称
2.如何修改主机名
3.执行查看是否生效

第一个里程碑
#！/bin/sh
read -p "请输入要更改的主机名： " name

第二个里程碑
如何修改主机名称
hostnamectl set-hostname $name

第三个里程碑
如何修改IP地址
read -p "请输入要更改的IP地址主机位[10-254]:" IP
eth="/etc/sysconfig/network-scripts/ifcfg-eth0"
SIP=`cat $eth|grep IPADDR|awk -F. '{print $NF}'`
sed -i "s#$SIP#$IP#g" $eth

cat hostname.sh
#！/bin/sh
read -p "请输入要更改的主机名： " name
eth="/etc/sysconfig/network-scripts/ifcfg-eth0"
SIP=`cat $eth|grep IPADDR|awk -F. '{print $NF}'`
sed -i "s#$SIP#$IP#g" $eth

06.变量字符串
  1）字符串切片
    echo ${ts:0:4},从0开始取4个

[root@localhost ~]# echo $ts
I am rockchou teacher
[root@localhost ~]# echo ${ts:0:2}
I
[root@localhost ~]# echo ${ts:0:3}
I a
[root@localhost ~]# echo ${ts:0:1}
I
[root@localhost ~]# echo ${ts:5:8}
rockchou
  
  2）统计字符串长度

[root@localhost ~]# ts="I am rockchou teacher"
[root@localhost ~]# echo $ts
I am rockchou teacher
[root@localhost ~]# echo ${#ts}
21
[root@localhost ~]# echo $ts|wc -L
21
[root@localhost ~]# echo $ts|awk '{print length}'
21

  3）统计字符串中小于3个的字符

[root@localhost ~]# echo "I am rockchou teacher I am 18"|xargs -n1 |awk '{if(length<3)print}'
I
am
I
am
18

[root@localhost ~]# echo "I am rockchou teacher I am 18"|awk '{for(i=1;i<=NF;i++)if(length($i)<3)print $i}'
I
am
I
am
18

[root@localhost ~]# cat for.sh
#!/bin/sh
for i in I am rockchou teacher I am 18
do
  [ ${#i} -lt 3 ] && echo $i
done
[root@localhost ~]# sh for.sh
I
am
I
am
18
 
  4）字符串的删除和替换

删除
[root@localhost scripts]# url=www.sina.com.cn
[root@localhost scripts]# echo $url
www.sina.com.cn
[root@localhost scripts]# echo $url|sed 's#www.##g'
sina.com.cn
[root@localhost scripts]# echo ${url#*.}
sina.com.cn
[root@localhost scripts]# echo ${url#*.*.}
com.cn
[root@localhost scripts]# echo ${url#*.*.*.}
cn
[root@localhost scripts]# echo ${url##*.}
cn
#从前往后匹配删除  ##贪婪匹配

[root@localhost scripts]# echo ${url%.*}
www.sina.com
[root@localhost scripts]# echo ${url%%.*}
www
%从后往前匹配删除，%%贪念匹配

替换
[root@localhost scripts]# echo ${url/www/aaa}
aaa.sina.com.cn
[root@localhost scripts]# echo ${url//w/a}
aaa.sina.com.cn
[root@localhost scripts]# echo $url|sed 's#www#aaa#g'
aaa.sina.com.cn


三、Shell数值运算
01.expr 整数运算
    expr 1 + 1 
    expr 1 - 10
    expr 1 \* 10
    expr 1 / 10

02.$(()) 整数运算（效率最高）
    echo $((1+10))
    echo $((1-10))
    echo $((1*10))
    echo $((1/10))

03.$[] 整数运算
    echo $[1+10]
    echo $[1-10]
    echo $[1*10]
    echo $[1/10]

04.bc 整数运算 | 小数运算
    echo 10+10|bc
    echo 10+10.5|bc
    echo 10*10.5|bc

05.awk python 整数和小数运算
    awk 'BEGIN{print 1+1.5}'
    echo 10 20|awk '{print $1+$2}'

题：判断输入的数值是否输入的为整数

read -p "请输入第一个整数：" num1
expr 1 + $num1 >/dev/null 2>&1
[ $? -ne 0 ] && echo "请输入整数" exit 1

read -p "请输入第二个整数：" num2
expr 1 + $num2 >/dev/null 2>&1
[ $? -ne 0 ] && echo "请输入整数" exit 1

echo "$num1+$num2=$[$num1+$num2]"

题：做一个计算器，加减乘除用三种传参的方式完成
    输出结果：
    请输入第一个数值：10
    请输入第二个数值：20
    10+20=30

方法一
#!/bin/sh
echo -p "请输入两个数字：" num1 num2
echo "$num1+$num2=$[$num1+$num2]"
echo "$num1-$num2=$[$num1-$num2]"
echo "$num1*$num2=$[$num1*$num2]"
echo "$num1/$num2=$[$num1/$num2]"

方法二
#!/bin/sh
echo "$1+$2=$[$1+$2]"
echo "$1-$2=$[$1-$2]"
echo "$1*$2=$[$1*$2]"
echo "$1/$2=$[$1/$2]"


四、Shell条件表达式
01.文件测试
  test 相当于 [ ]
  -e    存在则为真
  -f    是否为存在文件    *****
  -d    是否为存在目录    *****
  -x    是否可执行
  -r    是否可以读
  -w    是否可写

[root@localhost ~]# [ -f /etc/hosts ] && echo OK || echo error
OK
[root@localhost ~]# [ -f /etc/hostss ] && echo OK || echo error
error
[root@localhost ~]# [ -d /etc/hosts ] && echo OK || echo error
error
[root@localhost ~]# [ -d /etc/ ] && echo OK || echo error
OK
[root@localhost ~]# ls -l
total 12
-rw-------. 1 root root 1612 Apr  9 09:41 anaconda-ks.cfg
-rw-r--r--. 1 root root   86 Apr 10 22:10 for.sh
-rw-r--r--. 1 root root  987 Apr  9 22:05 passwd
[root@localhost ~]# [ -x for.sh ] && echo OK || echo error
error
[root@localhost ~]# chmod +x for.sh
[root@localhost ~]# [ -x for.sh ] && echo OK || echo error
OK

案例：
[ -d /backup ] && echo OK || mkdir /backup
[ -f /etc/init.d/functions ] && /etc/init.d/functions

02.数值比较
  语法格式：[ 数值1 比较符 数值2 ]
  比较符,单括号[]
    -eq 等于      equal
    -ne 不等于     not equal
  -ge 大于等于   greater equal
    -le 小于等于   less equal
    -gt 大于      greater than
    -lt 小于      less than
  比较符，双括号[[]]
    = != < > <= >=

[root@localhost ~]# [ 10 -eq 20 ] && echo $? || echo $?
1
[root@localhost ~]# [ 10 -ne 20 ] && echo $? || echo $?
0
[root@localhost ~]# [ 10 -ge 20 ] && echo $? || echo $?
1
[root@localhost ~]# [ 10 -le 20 ] && echo $? || echo $?
0
[root@localhost ~]# [ 10 -gt 20 ] && echo $? || echo $?
1
[root@localhost ~]# [ 10 -le 20 ] && echo $? || echo $?
0
[root@localhost ~]# [ 10 -le 20 ];echo $?
0
[root@localhost ~]# [ 10 -ge 20 ];echo $?
1
[root@localhost ~]# [ 10 -ge 20 ] &&  ls ||  pwd
/root

题1：统计磁盘使用率，如果磁盘大于80%则发邮件报警，小于则提示OK
1）如何取出磁盘当前使用率
2）用数值表达式判断大小，如果大发邮件，如果小提示OK
3）测试脚本

#!/bin/sh
ur=`df -h|grep /$|awk '{print $(NF-1)}'
if [ ${ur%\%} -gt 80 ];then
    echo "磁盘使用率已超过80%,当前使用率$ur|"mail -s "磁盘使用率报警"
  else
    echo "磁盘使用率正常,当前使用率$ur|"mail -s "磁盘使用率信息"
fi

题2：统计内存使用率超过80%则发邮件报警，小于则提示OK

#!/bin/sh
ur=`free|awk 'NR=={print $3/$2*100}'
if [ ${ur%.*） -gt 80 ];then
    echo "内存使用率已超过80%,当前使用率$ur|"mail -s "内存使用率报警"
  else
    echo "内存使用率正常,当前使用率$ur|"mail -s "内存使用率信息"
fi

[ `free|awk 'NR=={print $3/$2*100]'|awk -F . '{print $1}' -gt 80 ] && echo mail || echo ok

题3：统计服务器负载，负载1分钟的值超过2则报警，小于则提示ok
1.查看cpu负责命令：uptime、w、top
2.压力测试命令：ab -n 20000 -c 2000 http://127.0.0.1/index.html

[root@lnmp01 ~]# uptime
18:28:44 up 2 days,  3:25,  2 users,  load average: 2.04, 1.94, 1.90
//load average: 2.04, 1.94, 1.90
//1分钟是2.04
//5分钟是1.94
//15分钟是1.90
[ `uptime|awk -F "[  ,.]+" '{print $11}'` -ge 2 ] && echo mail || echo ok
 
[root@lnmp01 ~]# w
18:38:42 up 2 days,  3:35,  2 users,  load average: 1.95, 1.87, 1.86
USER     TTY      FROM              LOGIN@   IDLE   JCPU   PCPU WHAT
oldboy   pts/0    172.16.1.1       18:28    0.00s  0.10s  0.03s sshd: oldboy [priv]
oldboy   pts/1    172.16.1.254     18:28    5:45   0.06s  0.04s sshd: oldboy [priv]
[ `w|awk -F "[ ,.]+" 'NR==1{print $11}'` -ge 2 ] && echo mail || echo ok

03.多整数比较
  -a 并且，在中括号内使用&&
  -o 或者，在中括号内使用||

[root@localhost ~]# [ 10 -ne 10 -a 10 -lt 100 ] && echo OK || echo error
error
[root@localhost ~]# [ 10 -ne 10 -o 10 -lt 100 ] && echo OK || echo error
OK

[root@localhost ~]# [[ 10 -ne 10 -o 10 -lt 100 ]] && echo OK || echo error
-bash: syntax error in conditional expression
-bash: syntax error near `-o'
[root@localhost ~]# [[ 10 -ne 10 && 10 -lt 100 ]] && echo OK || echo error
error
[root@localhost ~]# [[ 10 -ne 10 || 10 -lt 100 ]] && echo OK || echo error
OK

04.字符比较
  字符串比较需加双引号
  [ $USER = "root" ]
  [ $USER != "root" ]

  -z 字符串长度为0，则为真 
  -n 字符串长度不为0，则为真

[root@localhost ~]# AAA=""
[root@localhost ~]# [ -z $AAA ] && echo ok || echo error
ok
[root@localhost ~]# [ -n $AAA ] && echo ok || echo error
ok

[root@localhost ~]# AAA="drc"
[root@localhost ~]# [ -z $AAA ] && echo ok || echo error
error
[root@localhost ~]# [ -n $AAA ] && echo ok || echo error
ok

-z案例：

#!/bin/sh
read -p "请输入要更改的主机名：" name
[ -z $name ] echo "请输入主机名称：" && exit

案例：判断是否为整数
方法一：
expr 1 + 变量
[ $? -ne 0 ] && echo "请输入整数" && exit

方法二：
[[ $test =~ ^[0-9]+$ ]] &&echo ok || echo error

05.正则比对
  正则比对需使用[[]]
  [[ $USER =~ ^r ]]，其中~波浪线表示匹配意思

判断是否为整数
[root@localhost ~]# test=123op
[root@localhost ~]# [[ $test =~ ^[0-9]+$ ]] &&echo ok || echo error
error

[root@localhost ~]# test=123
[root@localhost ~]# [[ $test =~ ^[0-9]+$ ]] &&echo ok || echo error
ok

[root@localhost ~]# test=123.55
[root@localhost ~]# [[ $test =~ ^[0-9]+$ ]] &&echo ok || echo error
error
[root@localhost ~]# [[ ! $test =~ ^[0-9]+$ ]] &&echo ok || echo error
ok

案例：
使用三种传参方式比较两个数值的大小，大了提示大了，小了提示小了
要求数字加判断，且不能为空，不允许使用if

#!/bin/sh
#第一种
[ $1 -eq $2 ] && echo "$1=$2"
[ $1 -gt $2 ] && echo "$1>$2"
[ $1 -lt $2 ] && echo "$1<$2"

#第二种
n1=$1
n2=$2
[ $n1 -eq $n2 ] && echo "$n1=$n2"
[ $n1 -gt $n2 ] && echo "$n1>$n2"
[ $n1 -lt $n2 ] && echo "$n1<$n2"

#第三种
read -p "请输入两个整数：" $n1 $n2
[ $n1 -eq $n2 ] && echo "$n1=$n2"
[ $n1 -gt $n2 ] && echo "$n1>$n2"
[ $n1 -lt $n2 ] && echo "$n1<$n2"



五、Shell for循环
for循环格式
    for i in [取值列表] 数值，字符串，命令的结果``，序列 123456
    do
        echo $i
    done
--案例：测试1-255有多个IP地址在线（能ping通则在线） 

#!/bin/sh
for n in {1..254}
do
    ip=172.16.1.$n
    {        ##多线程ping
    ping -c2 $ip >/dev/null 2>&1
    [ $?  -eq 0 ] && echo $ip
    } &
done
wait
echo "在线取IP完成"

[root@lnmp01 scripts]# sh ping.sh
172.16.1.4
172.16.1.7
172.16.1.5
172.16.1.254
在线取IP完成

--案例：批量创建10个用户
    1.前缀oldboy1，oldboy2....
    2.输入用户处加判断是否为空
    3.创建用户个数，判断是否整数
    4.密码统一使用123456
    5.用户添加成功，则输出create is ok，失败提示error

#!/bin/sh
read -p "Please input user prefix: " pre
[ -z $pre ] && echo "Please input user prefix"
read -p "Please input user number: " num
[[ ! $num =~ ^[0-9]+$ ]] && echo "Please input number" && exit
for i in `seq $num `
do
    useradd $pre$i >/dev/null 2>&1
    [$? -eq 0 ] && echo "$pre$i create is ok" && echo "create is error"
    echo 123456|passwd --stdin $pre$1 >/dev/null 2>&1
done


六、Shell if判断
01.if判断格式
 1）单分支 
   if [ 你有钱 ]
    then
        echo "我嫁给你"
    fi
    
 2）双分支
    if [ 你有钱 ]
    then
        echo "我嫁给你"
    esle
        echo "不鸟你"
    fi

  3）多分支
    if [ 你有钱 ];then
        echo "我嫁给你"
    elif [ 你有房 ];then
        echo "我也嫁给你"
    elif [ 你活好 ];then
        echo "我倒贴你"
    eles        ##此处可以用elif结束
        echo "拜拜"
    fi
  
  总结：
  单分支：一个条件一个结果
  双分支：一个条件两个结果
  多分支：多个添加多个结果

--案例：判断输入的两个数字的大小

#!/bin/sh
read -p "Please input tow num :" num1 num2
if [ $num1 > $num2 ];then
    echo "$num1 > $num2"
elif [ $num1 < $num2 ];then
    echo "$num1 < $num2"
else
    echo "$num1 = $num2"
if

--案例：先输出一个随机数，read猜随机数，
如果你输入的小了则提示小了，大了提示大了，如果成功则提示猜对了

#!/bin/sh
ran=`echo $((RANDOM%100+1))`
while true
do
        let i++
read -p "Plesae input number: " num
if [ $num -gt $ran ];then
        echo "比随机数大了"
elif [ $num -lt $ran ];then
        echo "比随机数小了"
else
        echo "恭喜你答对了，总共猜了$i次"
        exit
fi
done

--案例：安装不同的centos版本，安装不同的yum源
    1.当前什么版本，如何取出来
    2.if判断，如果是6则安装6的域名源，7的安装7yum源，5的安装5yum源

#!/bin/sh
os=`cat /etc/redhat-release|awk '{print $(NF-1)}'`
    #[ "$os" == "xxx" ] && os="取centos6版本的命令"
if [ ${os%%.*} -eq 7 ];then
    which wget >/dev/null 2>&1
    [ $? -ne 0 ] && yum -y install wget
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.default
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
elif [ ${os%%.*} -eq 6 ];then
    which wget >/dev/null 2>&1
    [ $? -ne 0 ] && yum -y install wget
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.default
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
else
    which wget >/dev/null 2>&1
    [ $? -ne 0 ] && yum -y install wget
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.default
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
fi

02.菜单的使用方法

#!/bin/sh
echo -e "\t\t\t 1. PHP install 5.5"
echo -e "\t\t\t 2. PHP install 5.6"
echo -e "\t\t\t 3. PHP install 7.1"
echo -e "\t\t\t 4. PHP install 7.2"

cat <<EOF
            1. INSTALL PHP5.5
            2. INSTALL PHP5.6
            3. INSTALL PHP7.1
            4. INSTALL PHP7.2
EOF

--案例：安装不同版本的php 5.5 7.1 7.2

#!/bin/sh
cat <<EOF
            1. INSTALL PHP5.5
            1. INSTALL PHP5.6
            1. INSTALL PHP7.1
            1. INSTALL PHP7.2
EOF
read -p "请输入你要安装的版本序号：" $n
if [ $n -eq 1 ];then
    yum -y install php......
fi

七、Shell case语句
01.结构
    变量=名字，脚本的传参$1 $2
    case 变量 in
        模式1）
            命令大礼包
            ;;
        模式2）
            命令大礼包
            ;;
        模式3）
            命令大礼包
            ;;
        *)
        echo "没有匹配到"
    esac

#!/bin/sh
case $1 in
    Linux)
        echo "Linux is done..."
        ;;
    CentOS)
        echo "CentOS is done..."
        ;;
    *)
        echo "USAGE: [Linux|CentOS|MySQL]"
esac

--案例：批量删除用户（if判断也可以）
    1.删除用户的前缀 read -p "please input prefix: " pre
    2.删除用户的数量 read -p "please input number: " num
    3.判断是否删除 read -p "Are you sure del user? [y|yes|n|no]: " re

#!/bin/sh
read -p "please input prefix: " pre
read -p "please input number: " num
for i in `seq $num`
do
    echo $pre$i
done
read -p "Are you sure del user? [y|yes|n|no]: " re
for n in `seq $num`
do
    user=$pre$n
    case $re in
        y|yes)
            id $user >/dev/null 2>&1
            if [ $? -eq 0 ];then
                userdel -r $user >/dev/null 2>&1
                [ $? -eq 0 ] && echo "$user del is ok"
            else
                echo "id: $user: no such user"
            fi
            ;;
        n|no)
            echo "不删除，玩啥呢"
            exit
    esac
done

--案例：case要求使用菜单显示
    1.help帮助
    2.显示内存使用
    3.显示磁盘负责
    4.显示系统负责
    5.退出

#!/bin/sh
menu(){
cat <<EOF
    1.help帮助
    2.显示内存使用
    3.显示磁盘负责
    4.显示系统负责
    5.退出
EOF
}
menu
while true
do
    read -p "请输入要查看的系统编号" re
    case $re in
        1)
            clear
            menu
            ;;
        2)
            free
            ;;
        3)
            df -h
            ;;
        4)
            uptime
            ;;
        5)
            exit
            ;;
        *)
            echo "请输入要查看的系统编号"
    esac
done

--案例：nginx启动脚本
    命令行方式启动nginx
    /application/nginx/sbin/nginx           启动命令
    /application/nginx/sbin/nginx -s stop   停止命令
    /application/nginx/sbin/nginx -s reload 重新加载命令
    
    重启
    /application/nginx/sbin/nginx -s stop
    sleep 2
    /application/nginx/sbin/nginx
    
    查看状态
    手动过滤出监听的端口和nginx的PID打印输出


--案例：jumpserver跳板机
    1.需要连接服务器的IP地址
        菜单
    2.需要和服务器直接做免密钥
    3.如何登陆服务器
    4.使用case语句控制

--案例：中午吃啥？随机生产中午要吃那一家

#!/bin/sh
read -p "请输入chi随机生成：" num
[[ $num == "chi" ]] && ran=`echo $((RANDOM%10+1))`
case $ran in
    1)
        echo "你要吃黄焖鸡米饭"
        ;;
    2)
        echo "你要吃包子"
        ;;
    3)
        echo "你要吃炒菜"
        ;;
    4)
        echo "你要吃豆浆"
        ;;
    5)
        echo "你要吃拉面"
        ;;
    6)
        echo "你要吃水饺"
        ;;
    7)
        echo "你要吃盖饭饭"
        ;;
    8)
        echo "你要撸串"
        ;;
    9)
        echo "你要吃沙县"
        ;;
    10)
        echo "不吃了"
esac

八、Shell while循环
01.格式1
    while [ 条件表达式 ]
    do
    done

02.格式2
    while read line
    do
    done<[files]

--案例：读取文件内容创建用户和设置密码

cat user.txt
zhangsan test
lishi    12345
wangerma    43321

vim while.sh
#!/bin/sh
while read line
do
    user=`echo $line|awk '{print $1}'`
    pass=`echo $line|awk '{print $2}'`
    useradd $user
    echo $pass|passwd --stdin $user
done<user.txt


九、Shell内置命令
01.exit
    结束命令
02.continue
    继续执行(略过持续执行)
03.break
    跳出循环体，执行循环外的命令

--案例：假设已存在test5用户，现要在创建test1~10的用户，使用三个内存命令分别输出的结果

#!/bin/sh
for i in `seq 10`
do
    useradd test$i
    if [ $? -eq 0 ];then
        echo "Create $i Success"
    else
        exit
    fi
done
echo done......
//以上输出结果是创建了1~4的test用户，然后退出。


#!/bin/sh
for i in `seq 10`
do
    useradd test$i
    if [ $? -eq 0 ];then
        echo "Create $i Success"
    else
        break
    fi
done
echo done......
//以上输出结果是创建了1~4的test用户，并输出done......。

#!/bin/sh
for i in `seq 10`
do
    useradd test$i
    if [ $? -eq 0 ];then
        echo "Create $i Success"
    else
        continue
    fi
done
echo done......
//以上输出结果是创建了1~4和6~10的test用户，并且输出done......。

十、Shell 函数
01.函数的作用
  1）命令合集，完成特定功能的代码块
  2）在shell中定义函数可以使代码模块化，便于复制代码，加强可读性
  3）函数和变量类似，先定义才可以调用，如果定义不调用则不会被执行

02.如何定义和调用函数
  #方法一（常用）
    函数名(){ 
    command
    }

  #方法二
    function 函数名(){
    command
    }

  #方法三
    function 函数名 {  //此处有空格
    command
    }

    调用直输入：函数名

03.函数传参
    test(){ 
    command
    }
    test $1
    ##注明：函数内获取的参数与函数外不是一个体
--案例

1---------
cont01(){
num=10    //函数内的变量
for i in `seq 10`
total=$[$i + $sum]
done
    echo "计算结果是：$total"
}
cont01
//结果为：20

2-----------
cont01(){
for i in `seq 10`
total=$[$i + $sum]
done
    echo "计算结果是：$total"
}
cont01
num=10    //执行函数后，才执行，所有报错
//结果为：报错

cont01(){
for i in `seq 10`
total=$[$i + $sum]
done
    echo "计算结果是：$total"
}
num=10        //此处作为全局变量
cont01
//结果为：20

3------------
cont01(){
num=$1
for i in `seq $sum`
total=$[$i + $sum]
done
    echo "计算结果是：$total"
}
cont01 $1
cont01 $2
cont01 $3
#命令行执行：sh fun.sh 10 20 30
//结果为：20
//结果为：40
//结果为：60

4----------------
fun2(){
echo 100
return 1
}
result=`fun2`
echo "函数的状况码：$?"
echo "函数的返回的值：$result"
//函数的状况码：1
//函数的返回的值：100

5-------------
file=/etc/ttt
t_file(){
if [ -f $file ];then
    return 50
else
    return 100
}
t_file
[ $? -eq 50 ] && echo "$file is ok" || echo "$file is error"

6-----统计文件行数
#!/bin/sh
file=/etc/passwd
count(){
local i=0
while read line 
do
    let i++
done
}
count

十一、Shell 数组
01.数组的分类
  普通数组：只能使用整数作为数组索引
  关联数组：可以使用字符串作为数组索引

02.数组赋值方式
  1）针对每个索引进行赋值
    数组名[索引]=变量

[root@lnmp01 ~]# array[0]=linux
[root@lnmp01 ~]# array[1]=centos
[root@lnmp01 ~]# array[2]=redhat
[root@lnmp01 ~]# array[3]=ubantu
[root@lnmp01 ~]# echo ${array[0]}
linux
[root@lnmp01 ~]# echo ${array[1]}
centos
[root@lnmp01 ~]# echo ${array[3]}
ubantu
[root@lnmp01 ~]# echo ${array[*]}    //查看数组值
linux centos redhat ubantu
[root@lnmp01 ~]# echo ${array[@]}
linux centos redhat ubantu
[root@lnmp01 ~]# echo ${!array[@]}    //查看索引号
0 1 2 3
[root@lnmp01 ~]# declare -a
......
declare -a array='([0]="linux" [1]="centos" [2]="redhat" [3]="ubantu")'

  2）一次赋值多个
    数组名=（多个变量）

array=([0]=linux [1]=centos [2]=redhat [3]=ubantu)

工作中定义：
array=(linux centos redhat ubantu)

03.查看赋值结果
  declare -a

04.取消赋值
    unset 数组名
--案例：

#!/bin/sh
ip=(
172.16.1.2
172.16.1.3
172.16.1.4
172.16.1.5
)
for i in ${ip{*}}
do
    ping -c2 -w1 $i >/dev/null 2>&1
    [ $? -eq 0 ] && echo "ping $i is ok"
done

05.关联数组
  declare -A 数组名 //声明是一个关联数组
  declare -A //查看关联数组
  注意：awk里面不需要声明关联数组

[root@lnmp01 ~]# declare -A array
[root@lnmp01 ~]# array=([index]=linux [index1]=cenots [index2]=redhat [index3]=ubantu)
[root@lnmp01 ~]# echo ${array[*]}
cenots redhat ubantu linux
[root@lnmp01 ~]# echo ${!array[*]}
index1 index2 index3 index
[root@lnmp01 ~]# declare -a
......
declare -A array='([index1]="cenots" [index2]="redhat" [index3]="ubantu" [index]="linux" )'


--案例：统计文件相同字符个数

cat sex.txt
m
m
f
f
m
x

vim rarray.sh
#!/bin/sh
declare -A array
while read line
do
    let array[$line]++
done<sex.txt
for i in ${!array[*]}
do
    echo "$i 出现了 ${array[$i]} 次"
done


十二、Shell 脚本与脚本的调用
脚本1
cat /server/scripts/scritp1.sh

#!/bin/sh
count01(){
for i in `seq 10`
do
    total=$[$i+$num]
done
    echo "计算结果是：$total"
}
num=10
count01

脚本2,套用脚本1
cat /server/scripts/scritp2.sh

#!/bin/sh
. /server/scripts/scritp1.sh >/dev/null 2>&1
echo "我调用脚本1的count01结果为：`count01`"
echo "我调用脚本1的num结果为：$num"

