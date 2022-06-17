#!/usr/bin/python

'''
要求输出1到50之间所有5的倍数，5 10 15 20 ...

5的倍数的共同点是：和5的余数为0的都是5的倍数
5的倍数的不同点：和5的余数不为0的都不是5的倍数

要求使用continue实现
'''

for item in range(1,51):
    if item%5==0:
        print(item)

print('--------使用continue---------------')
for item in range(1,51):
    if item%5!=0:
        continue
    print(item)