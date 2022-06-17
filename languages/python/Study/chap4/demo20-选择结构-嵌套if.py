#!/usr/bin/python
# -*- coding: UTF-8 -*-



#
# 嵌套if
#
'''
if 条件表达式1:
    if 内层条件表达式
        内层条件执行体1
    else:
        内层条件执行体2
else:
    条件执行体
'''

'''
会员
    >=200   8折
    >=100   9折
    <100    不打折

非会员
    >=200   9.5折
    <200    不打折
'''

# 示例
answer=input('您时会员吗？ y/n：')
money=float(input('请输入您的购物金额：'))
if answer=='y' :
    if money>=200:
        print('打8折，付款金额为:',money*0.8)
    elif money>=100:
        print('打9折，付款金额为:',money*0.9)
    else:
        print('不打折，付款金额为:',money)

else:
    if money>=200:
        print('打9.5折，付款金额为:',money*0.95)
    else:
        print('不打折，付款金额为:',money)