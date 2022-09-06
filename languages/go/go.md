# go

## go 环境配置

```bash
wget https://studygolang.com/dl/golang/go1.19.linux-amd64.tar.gz
tar xf go1.19.linux-amd64.tar.gz -C /usr/local/


cat >> /etc/profile << "EOF"
export GOROOT=/usr/local/go
export GOPATH=/opt/goProject 
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOROOT/bin
export PATH=$PATH:$GOPATH/bin
EOF

source /etc/profile
```