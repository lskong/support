#!/usr/bin/python3

# range()函数的三种创建方式

'''
第一种，只有一个参数
'''
r=range(10)         #[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]，默认从0开始，默认相差1称为步长
print(r)    # range(0,10)
print(list(r))  # 用于查看range对象中的整数序列


'''
第二种，给两个参数
'''
r2=range(1,10)      #指定了起始值，从1开始到10结束（不含10）,默认步长为1
print(r2)       
print(list(r2))     #[1, 2, 3, 4, 5, 6, 7, 8, 9]


'''
第三种，给三个参数
'''
r3=range(1,10,2)      #指定了起始值，从1开始到10结束（不含10）,步长为2
print(r3)       
print(list(r3))     # [1, 3, 5, 7, 9]



'''
判断指定的整数，在序列中是否存在 in, not in
'''
print(10 in r3)     # False ,10不在当前的r3这个整数序列中
print(3 in r3)      # True, 3在当前的r3系列中

print(10 not in r3) # True
print(3 not in r3)  # False

print(range(1,20,1))    # [1..19]
print(range(1,101,1))   # [1..100]