# input() 函数的介绍
# - 作用：接收来自用户的输入
# - 返回值类型：输入值的类型为str
# - 值的存储：使用=对输入的值进行存储

# input()函数的基本使用
present=input('大圣想要什么礼物呢？')
print(present,type(present))

# 从键盘输入两个整数，计算两个整数的和
a=input('输入一个加数:')
b=input('输入另一个加数:')
print(a+b)

a=int(a)
b=int(b)
print(a+b)

a=int(input('输入一个加数:'))
b=int(input('输入另一个加数:'))
print(a+b)