#!/usr/bin/python

    
# 要求计算0到4之间的累加和
sum=0
'''初始化变量为0'''
a=0
'''条件判断'''
while a<5:
    '''条件执行体'''
    sum+=a
    '''改变变量'''
    a+=1
print('和为', sum)

'''
a  a<5       sum   sum+=a
0  0<5 true   0     0+0
1  1<5 true   1     0+1
2  1<5 true   3     1+2
3  1<5 true   6     3+3
4  1<5 true   10    6+4
'''


# 要求计算1到100之间的偶数和
sum=0
a=1
while a<=100:
    if a%2==0:
    # if not bool(a%2):
        sum+=a
    a+=1
print('偶数和为', sum)