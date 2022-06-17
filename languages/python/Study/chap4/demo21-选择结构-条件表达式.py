#!/usr/bin/python
# -*- coding: UTF-8 -*-


'''
从键盘输入两个整数，比较两个整数的大小
'''

num_a=int(input('请输入第一个整数：'))
num_b=int(input('请输入第二个整数：'))

# 正常写法
'''
if num_a>=num_b:
    print(num_a,'大于等于',num_b)
else:
    print(num_a,'小于',num_b)
'''

# 使用条件表达式进入比较
print( (num_a,'大于等于',num_b) if num_a>=num_b else (num_a,'小于',num_b))

print( str(num_a)+'大于等于'+str(num_b) if num_a>=num_b else str(num_a)+'小于'+str(num_b))

# 条件判断的结果为True，则执行左边的代码
# 条件判断的结果为False，则执行右边的代码