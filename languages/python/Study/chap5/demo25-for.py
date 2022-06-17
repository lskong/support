#!/usr/bin/python

for item in 'Python':
    print(item)
    
'''
P
y
t
h
o
n

# 第一次取出来来的是P，将P赋值给item，并打印输出
'''

for i in range(10):
    print(i)   
'''
0
1
2
3
4
5
6
7
8
9

# range() 产生一个整数序列，也是一个可迭代对象
'''



for _ in range(5):
    print('人生苦短，我用Python')
'''
人生苦短，我用Python
人生苦短，我用Python
人生苦短，我用Python
人生苦短，我用Python
人生苦短，我用Python

# 如果在循环体中不需要使用到自定义变量，可以将自定义变量写为“_"
'''


print('使用for循环，计算1到100之间的偶数和')
sum=0
for item in range(1,101):
    if item%2==0:
        sum+=item
print('1到100之间的偶数和为:',sum)



'''
输出100到999之间的水仙花数
  举例：153=3*3*3+5*5*5+1*1*1
'''
for item in range(100,1000):
    ones=item%10        # 个位，除10取余
    tens=item//10%10    # 十位，整除10，再除10取余
    hundreds=item//100  # 百位，整除100
    # print(hundreds,tens,ones)
    # 判断
    if ones**3+tens**3+hundreds**3==item:
        print(item)

'''
153
370
371
407
'''