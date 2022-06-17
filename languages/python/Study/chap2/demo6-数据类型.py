# 数据类型

# 常用的数据类型
# 整数类型  int 520
# 浮点数类型 float   3.14159
# 布尔类型  bool    true,false
# 字符串类型 str     '人生苦短，我用python'

# =================
# 整数类型，英文integer，简写int，可以表示正数、负数和零
# 整数的不同进制表示方式
# 十进制，默认的进制
# 二进制，以0b开头
# 八进制，以0o开头
# 十六进制，以0x开头
n1 = 90
n2 = -76
n3 = 0
print(n1, type(n1))
print(n2, type(n2))
print(n3, type(n3))
print('十进制', 118)
print('二进制', 0b100010101)
print('八进制', 0o176)
print('十六进制', 0x1EAF)


# =====================
# 浮点数类型
# 浮点数整数部分和小数部分组成
# 浮点数存储不精准性：
# 使用浮点数进行计算时，可能会出现小数位不确定的情况
# 解决办法：导入decimal模块

f1 = 3.14159
print(f1, type(f1))

f2 = 1.1
f3 = 2.2
print(f2 + f3)  # 计算结果：3.3000000000000003


from decimal import Decimal
print(Decimal('1.1') + Decimal('2.2'))

# 并非所有的浮点数都是这中情况，如1.1+2.1
print(1.1 + 2.1)    # 计算结果：3.2



# ==================
# 布尔类型 boolean
# 用来表示真或假的值
# True表示真，False表示假
# 布尔值可以转化为整数
# True-->1
# False-->0
b1 = True
b2 = False
print(b1, type(b1))
print(b2, type(b2))


print(b1+1)       # 值为2 1+1
print(b2+1)       # 值为1 0+1


# =====================
# 字符串类型
# 字符串又被称为不可变的字符序列
# 可以使用单引号、双引号、三引号来定义
# 单引号和双引号定义的字符串必须在一行
# 三引号定义的字符串可以分布在连续的多行
str1 = '人生苦短，我用python'
str2 = "人生苦短，我用python"
str3 = """人生苦短,
我用python"""
str4 = '''人生苦短,
我用python'''

print(str1, type(str1))
print(str2, type(str2))
print(str3, type(str3))
print(str4, type(str4))