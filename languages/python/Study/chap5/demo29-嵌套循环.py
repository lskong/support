#!/usr/bin/python

'''
打印一个三行四列的矩形
'''
for i in range(1,4):
    for j in range(1,5):
        print('*',end='\t')     #不换行，输入
    print()             # 打行
    
    

'''
打印一个9行直角三角形
'''
print('---------while---------')
a=1
while a<=9:
    for i in range(1,a+1):
        print('*',end='\t')
    print()
    a+=1
    
print('---------for---------')
for i in range(1,10):
    for j in range(1,i+1):
        print('*',end='\t')
    print()
    
    
'''
打印99乘法表
'''
print('------打印99乘法表---------')
for i in range(1,10):
    for j in range(1,i+1):
        print(i,'*',j,'=',i*j,end='\t')
    print()