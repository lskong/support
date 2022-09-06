# snmp_exporter


## generator

https://github.com/prometheus/snmp_exporter/tree/main/generator

```bash
# Debian-based distributions.
sudo apt-get install unzip build-essential libsnmp-dev p7zip-full # Debian-based distros
# Redhat-based distributions.
sudo yum install gcc gcc-g++ make net-snmp net-snmp-utils net-snmp-libs net-snmp-devel # RHEL-based distros

go get github.com/prometheus/snmp_exporter/generator
cd ${GOPATH-$HOME/go}/src/github.com/prometheus/snmp_exporter/generator
go build
make mibs


export MIBDIRS=mibs;
./generator generate
```

- generator.yml
最简单的模块只是一个名称和一组要遍历的 OID。

```yaml
modules:
  module_name:  # 模块名
    walk:       # 要遍历的 OID 列表
      - 1.3.6.1.2.1.2              # Same as "interfaces"
      - sysUpTime                  # Same as "1.3.6.1.2.1.1.3"
      - 1.3.6.1.2.1.31.1.1.1.6.40  # Instance of "ifHCInOctets" with index "40"
    version: 2  # 使用SNMP版本，默认v2
    max_repetitions: 25  # 请求对象个数，默认25
    retries: 3   # 重试次数，默认3
    timeout: 5s  # 请求超时，默认5s

    auth:      
      community: public     # 团体名，默认public

      # snmp v3版本配置
      username: user  # 用户名
      security_level: noAuthNoPriv  # 默认noAuthNoPriv，可以是noAuthNoPriv, authNoPriv, authPriv.                        
      password: pass  # 密码，如果 security_level 为 authNoPriv 或 authPriv，则为必需。
      auth_protocol: MD5  # 默认MD5, 可以是MD5, SHA, SHA224, SHA256, SHA384, or SHA512，如果 security_level 是 authNoPriv 或 authPriv 则使用。
      priv_protocol: DES  # 默认DES, 可以是 AES, AES192, or AES256, 如果是security_level是authPriv则使用
      priv_password: otherPass # 如果 security_level 为 authPriv，则为必需。
      context_name: context # 如果在设备上配置了上下文，则为必需。

    lookups:  # 可选的查找列表
              # keep_source_indexes 的默认值为 false

      # 如果表的索引是 bsnDot11EssIndex，那通常是该表的结果指标上的标签
      # 相反，使用索引查找 bsnDot11EssSsid 表条目并使用该值创建 bsnDot11EssSsid 标签。
      - source_indexes: [bsnDot11EssIndex]
        lookup: bsnDot11EssSsid
        drop_source_indexes: false  # 如果为真，则删除此查找的源索引标签。这样可以避免新索引唯一时标签混乱。

      # 也可以链接查找或使用多个标签来收集标签值。这可能有助于将多个索引标签解析为适当的人类可读标签。请注意这里的排序很重要。

      - source_indexes: [cbQosPolicyIndex, cbQosObjectsIndex]
        lookup: cbQosConfigIndex
      - source_indexes: [cbQosConfigIndex]
        lookup: cbQosCMName

     overrides: # 允许每个模块重写MIBs
       metricName:
         ignore: true # 从输出中删除指标
         regex_extracts:
           Temp: # 将创建一个新指标，并将其附加到 metricName 以成为 metricNameTemp
             - regex: '(.*)' # 正则表达式从返回的 SNMP walks 值中提取一个值
               value: '$1' # 结果将被解析为 float64, 默认$1.
           Status:
             - regex: '.*Example'
               value: '1' # 正则表达式匹配且值解析的第一个条目获胜
             - regex: '.*'
               value: '0'
         type: DisplayString # 覆盖度量类型，可能的类型有:
                             #   gauge:   一个带有 gauge 类型的整数
                             #   counter: 一个类型为 counter 的整数
                             #   OctetString: 位串，呈现为 0xff34
                             #   DateAndTime: RFC 2579 DateAndTime 字节序列。如果设备没有时区数据，则使用 UTC
                             #   DisplayString: ASCII 或 UTF-8 字符串.
                             #   PhysAddress48: 48 位 MAC 地址，呈现为 00:01:02:03:04:ff
                             #   Float: 一个 32 位浮点值，带有类型规
                             #   Double: 一个 64 位浮点值，类型为 Gauge
                             #   InetAddressIPv4: 一个 IPv4 地址
                             #   InetAddressIPv6: 一个 IPv6 地址
                             #   InetAddress: 根据 RFC 4001 的 InetAddress。必须以 InetAddressType 开头
                             #   InetAddressMissingSize: 一个 InetAddress 违反了 RFC 4001 第 4.1 节，因为索引中没有大小。必须以 InetAddressType 开头。
                             #   EnumAsInfo: 为其创建单个时间序列的枚举。适用于恒定值
                             #   EnumAsStateSet: 每个状态都有一个时间序列的枚举。适用于可变的低基数枚举
                             #   Bits: 一个 RFC 2578 BITS 构造，它产生一个每比特有一个时间序列的 StateSet

```

- generator.yml示例

```yaml
  huawei_ce:    # 华为CE系列交换机
    version: 2
    max_repetitions: 25
    retries: 3
    timeout: 60s
    auth:
      community: public123
    walk:
      - sysUpTime
      - sysName
      - sysDescr
      - interfaces
      - ifXTable
      # cpu
      - 1.3.6.1.4.1.2011.5.25.31.1.1.1.1.5.16842753
      # 内存
      - 1.3.6.1.4.1.2011.5.25.31.1.1.1.1.7.16842753
      # 温度
      - 1.3.6.1.4.1.2011.5.25.31.1.1.1.1.11.16842753
      # 接口流量in
      - 1.3.6.1.2.1.31.1.1.1.6
      # 接口流量out
      - 1.3.6.1.2.1.31.1.1.1.10
    lookups:
      - source_indexes: [ifIndex]
        lookup: ifAlias
      - source_indexes: [ifIndex]
        lookup: ifDescr
      - source_indexes: [ifIndex]
        lookup: ifName
```