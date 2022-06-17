# print 函数

# 可以输出数字
print(520)
print(13.14)

# 可输出字符串
print('helloworld')
print("helloworld")

# 含有运算符的表达式
print(1+5)

# 将数据输出到文件中  注意：1.指定路径要存在。2.使用file=对象
fp=open('/print.txt', 'a+')  # a+ 如果文件不存在则创建，存在则在内容之后追加
print('hello','world',file=fp)
fp.close()

# 不换行输入
print('hello','world','python')

