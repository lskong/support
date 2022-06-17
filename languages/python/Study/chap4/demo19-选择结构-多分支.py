#!/usr/bin/python
# -*- coding: UTF-8 -*-


#
# 多分支结构
#
'''
成绩是在90分以上吗？ 不是
成绩是在80到90分之间吗？ 不是
成绩是在70到80分之间吗？ 不是
成绩是在60到70分之间吗？ 不是
成绩是60分以下吗？ 是

if 条件表达式:
    条件执行体1
elif 条件表达式2:
    条件执行体2
elif 条件表达式N:
    条件执行体N
[else:]
    条件执行体N+1

90-100  A
80-89   B
70-79   C
60-69   D
0-59    E
小于0，大于100，不是成绩单有效范围
'''


# 判断，写法一
score=int(input('请输入一个成绩：'))
if score>=90 and score<=100:
    print('A级')
elif score>=80 and score<=89:
    print('B级')
elif score>=70 and score<=79:
    print('C级')
elif score>=60 and score<=69:
    print('D级')
elif score>=0 and score<=59:
    print('E级')
else:
    print('对不起，成绩有误，不在成绩的有效范围')


# 判断，写法二
score=int(input('请输入一个成绩：'))
if 90<=score<=100:
    print('A级')
elif 80<=score<=89:
    print('B级')
elif 70<=score<=79:
    print('C级')
elif 60<=score<=69:
    print('D级')
elif 0<=score<=59:
    print('E级')
else:
    print('对不起，成绩有误，不在成绩的有效范围')
