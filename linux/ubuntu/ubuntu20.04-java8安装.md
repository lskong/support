# java8 安装

```bash
ls jdk-8u221-linux-x64.tar.gz

tar xf jdk-8u221-linux-x64.tar.gz -C /usr/local/

cat >> /etc/profile << "EOF"
JAVA_HOME=/usr/local/jdk1.8.0_221
JRE_HOME=/usr/local/jdk1.8.0_221/jre
CLASS_PATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib
PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin
EOF

source /etc/profile


[root@vdbench2 opt]# java -version
openjdk version "1.8.0_332"
OpenJDK Runtime Environment (build 1.8.0_332-b09)
OpenJDK 64-Bit Server VM (build 25.332-b09, mixed mode)

```