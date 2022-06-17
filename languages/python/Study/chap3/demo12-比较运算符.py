# Python中的比较运算

"""
对变量或表达式的结果进行大小、真假等比较。
>,<,>=,<=,!=
==  对象value的比较
is,is not 对象的id比较
"""

a,b=10,20
print('a>b 吗？',a>b)  # False
print('a<b 吗？',a<b)  # True

print('a<=b 吗？',a<=b)  # True
print('a>=b 吗？',a>=b)  # False

print('a==b 吗？',a==b)  # False
print('a!=b 吗？',a!=b)  # True

''' 
一个 = 称为赋值运算符，两个 == 称为比较运算符
一个变量由三部分组成：标识，类型，值
== 比较的是值还是标识呢？ --> 值
比较对象的标识使用 is
'''

a=10
b=10
print(a==b)     # True，说明a与b的值相等
print(a is b)   # True，说明a与b的标识相等

# 以下代码没学过，后面在讲
list1=[11,22,33,44]
list2=[11,22,33,44]
print(list1==list2)     # True  -- value
print(list1 is list2)   # False -- id
print(id(list1))
print(id(list2))
print(a is not b)       # False a与吧的id是相等的
print(list1 is not list2)   # True