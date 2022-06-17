#!/usr/bin/python

"""
1. range() 函数的使用
2. while循环
3. for-in循环
4. break、continue与else语句
5. 嵌套循环
"""


# 内置函数range()
'''
range()函数
- 用于生成一个整数系列
- 创建range对象的三种方式
    - range(stop)， 创建一个(0,stop)之间的整数序列，步长为1
    - range(start,stop)， 创建一个(start,stop)之间的整数序列，步长为1
    - range(start,stop,step)，创建一个(start,stop)之间的整数序列，步长为step
- 返回值是一个迭代器对象
- range类型的有点: 不管range对象表示的整数系列有多长，所有range对象占用的内存空间都是相同的
  因为仅仅需要存储start,stop,step，只有当用到rang对象时，才回去计算序列中的相关元素
- in与not in判断整数序列中是否存在指定的整数
'''


# 循环结构
'''
- 反复做同一件事情的情况，称为循环
- 循环的分类：while  for -in
- 语法结构
    while 条件表达式:
        条件执行体(循环体)
        
- 选择结构的if与循环结构while的区别
  - if 是判断一次，条件为true执行一行
  - while是判断N+1次，条件为true执行N次
'''


# while循环的执行流程
'''
- 四步循环法
  - 初始化变量
  - 条件判断
  - 条件执行体
  - 改变变量
  总结：初始化的变量与条件判断的变量与改变的变量为同一个
'''


# for-in循环
'''
for-in循环
  - in 表达从(字符串、系列等)中依次取值，又称为遍历
  - for-in遍历的对象必须可迭代对象
  
for-in语法
  for 自定义的变量 in 可迭代对象:
      循环体
      
循环体内不需要访问自定义变量，可以将自定义变量替代为下划线
'''


# 流程控制语句break
'''
break语句，用于结束循环结构，通常与分支结构if一起使用
'''

# 流程控制语句continue
'''
continue语句，用于结束当前循环，进入一次循环，通常与分支结构if一起使用
'''


# else语句
'''
与else配合使用的有三种情况：
if else         if条件表达式不成立则执行else
while else      没有碰到break时执行else
for else        没有碰到break时执行else
'''

# 嵌套循环
'''
循环结构中又嵌套了另一个完整的循环结构，其中内层循环做为外层循环的循环执行体
'''

# 二重循环中的break和continue
'''
二重循环中break和continue只对本层循环影响，不影响外层循环
'''