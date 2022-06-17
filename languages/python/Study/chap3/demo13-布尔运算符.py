# 布尔运算符

"""
对应布尔之间的运算：and、or、not、in、not in

运算关系图表
- and：
True vs True => True
True vs False => False
False vs Tre => False
False vs False => False

- or
True vs True => True
True vs False => True
False vs Tre => True
False vs False => False

- not
True => False      如果运算为True，运算结果为False
False => True
"""
print('----------------and 并且---------------------')
a,b=1,2
print(a==1 and b==2)    # True      True vs True => True
print(a==1 and b<2)     # False     True vs False => False
print(a!=1 and b==2)    # False     False vs True => False
print(a!=1 and b!=2)    # False     False vs False => False


print('----------------or 或者---------------------')
a,b=1,2
print(a==1 or b==2)    # True      True vs True => True
print(a==1 or b<2)     # False     True vs False => True
print(a!=1 or b==2)    # False     False vs True => True
print(a!=1 or b!=2)    # False     False vs False => False


print('----------------not 取反---------------------')
f1=True
f2=False
print(not f1)
print(not f2)

print('----------------in 与 not in---------------------')
s='hellworld'
print('w' in s)
print('k' in s)
print('w' not in s)
print('k' not in s)