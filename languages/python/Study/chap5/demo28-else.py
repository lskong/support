#!/usr/bin/python

'''
for else
'''
for item in range(3):
    pwd=input('请输入密码: ')
    if pwd=='8888':
        print('密码正确')
        break
    else:
        print('密码不正确')
else:
    print('对不起，输入三次密码均不正确')
    
    
'''
while else
'''

a=0
while a<3:
    pwd=input('请输入密码: ')
    if pwd=='8888':
        print('密码正确')
        break
    else:
        print('密码不正确')
    a+=1
else:
    print('对不起，输入三次密码均不正确')