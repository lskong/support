# 变量定义

# 定义一个变量name，把玛丽亚赋值给name
name='玛丽亚'
print(name)


# 变量由三部分组成
# 标识：表示对象所存储的内存地址，使用内置函数id(obj)来获取
# 类型：表示的是对象的数据类型，使用内置函数type(obj)来获取
# 值：表示对象所存储的具体数据，使用print(obj)可以将值进行打印输出

print('标识',id(name))
print('类型',type(name))
print('值',name)

# 当多次赋值之后，变量名会指向新的空间，原赋值就变成内存垃圾
name='陈老板'
print(name)