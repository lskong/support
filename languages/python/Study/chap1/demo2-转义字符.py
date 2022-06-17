# 转义字符 "\"

# 使特殊符失去意义
print('hello\\world')
print('老师说：\'大家好\'')

# \n newline  换行
print('hello\nworld')

# \t tab 制表位
print('hello\tworld')       # 四个字符占用一个制表位，所以o后面是三个空格
print('helloooo\tworld')    # 而四个oooo刚好占位4个，\t会重新开辟制表位，所以o后面是4个空格

# \r renter 回首
print('hello\rworld')       # 回首就会覆盖之前的内容，所以只显示world

# \b backspace 退格
print('hello\bworld')       # 默认退一格，所以把o给退没了

# 原字符
print(r'hello\world')       # 不希望转义符起作用，在字符串前加上r或R
print(R'hello\world')       # 注意这里在最后一个字符不能是反斜杠
print(R'helloword\\')       # 但可以在最后一个字符在加反斜杠，则语法成立