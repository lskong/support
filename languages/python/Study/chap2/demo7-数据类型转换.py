# 数据类型转换

# 为什么需要数据类型转换？
# 将不同数据类型的数据拼接在一起

name = '张三'
age = 20
print(type(name), type(age))  # 说明name与age的数据类型不相同

# print('我叫' + name + '，今年' + age + '岁')   # + 连接符
# - 当将str类型与int类型进行连接时，会报错，如下age不能那个直接+
# - 解决方案，类型转换，如下
print('我叫' + name + '，今年' + str(age) + '岁')

# str() 将其他数据类型转换成字符串，也可以用引起转换，str(123) or '123'

# int() 将其他数据类型转成整数，int('123') or int(9.8)
# - 1.文字类和小数据类字符串，无法转成整数
# - 2.浮点数转化成整数，抹零取整

# float() 将其他数据类型转成浮点数，float('9.9') or float(9)
# - 1.文字类无法转成整数
# - 2.整数转成浮点数，末尾为.0

print('----------str()函数，将其他类型转成str类型')
a = 10
b = 198.8
c = False
print(type(a), type(b), type(c))
print(str(a), str(b), str(c), type(str(a)), type(str(b)), type(str(c)))

print('----------int()函数，将其他的类型转int类型')
s1 = '128'
f1 = 98.7
s2 = '76.77'
ff = True
s3 = 'hello'
print(type(s1), type(f1), type(s2), type(ff), type(s3))
print(int(s1), type(int(s1)))   # 将str转成int类型，字符串为数字串
print(int(f1), type(int(f1)))   # float转成int类型，截取整数部分，舍掉小数部分
# print(int(s2), type(int(s2)))   # 将str转成int类型，报错，因为字符串为小数串
print(int(ff), type(int(ff)))   # 将bool转成int类型，结果为1或0
# print(int(s3), type(int(s3)))   # 将str转成int类型时，字符串必须为数字串(整数)


print('----------float()函数，将其他的类型转float类型')
s1 = '128.98'
s2 = '76'
ff = True
s3 = 'hello'
i = 98
print(type(s1), type(s2), type(ff), type(s3))
print(float(s1), type(float(s1)))
print(float(s2), type(float(s2)))
print(float(ff), type(float(ff)))
# print(float(s3), type(float(s3)))  # 字符串中的数据如果是非数字串，则不允许转换
print(float(i), type(float(i)))
