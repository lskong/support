#!/usr/bin/python
# -*- coding: UTF-8 -*-

#
# - 双分支结构
#
'''
如果...不满足...就...
如果中奖就领奖，没中奖就不领
如果是周末不上班，不是就上班

if 条件表达式:
    条件执行体1
else:
    条件执行体2
'''

num=int(input('请输入一个整数：'))

# 条件判断
if num%2==0:
    print(num,'是偶数')
else:
    print(num,'是奇数')
