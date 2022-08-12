# pve解决万兆网卡读不到问题

- 核心问题

网卡型号：Intel Corporation Ethernet 10G 2P X520 Adapter (rev 01)
网口使用了SFP+和intel兼容的两种不一样的模块，造成系统只读到Intel模块，SFP+未能支持报错。
目前已经换掉了SFP+模块，问题解决。

除此方法外，可能还有其它方法，使其兼容。


- 排查过程
```bash 
# 查看网卡型号，并且驱动正常
root@pve-node04:~# lspci |grep -i eth
18:00.0 Ethernet controller: Broadcom Inc. and subsidiaries NetXtreme BCM5720 2-port Gigabit Ethernet PCIe
18:00.1 Ethernet controller: Broadcom Inc. and subsidiaries NetXtreme BCM5720 2-port Gigabit Ethernet PCIe
19:00.0 Ethernet controller: Broadcom Inc. and subsidiaries NetXtreme BCM5720 2-port Gigabit Ethernet PCIe
19:00.1 Ethernet controller: Broadcom Inc. and subsidiaries NetXtreme BCM5720 2-port Gigabit Ethernet PCIe
5f:00.0 Ethernet controller: Intel Corporation Ethernet 10G 2P X520 Adapter (rev 01)
5f:00.1 Ethernet controller: Intel Corporation Ethernet 10G 2P X520 Adapter (rev 01)

# 查看网卡模块支持
root@pve-node04:~# sudo dmesg |grep eth
[    2.722149] wmi_bus wmi_bus-PNP0C14:00: WQBC data block query control method not found
[    2.748718] tg3 0000:18:00.0 eth0: Tigon3 [partno(BCM95720) rev 5720000] (PCI Express) MAC address 34:48:ed:f8:3d:5c
[    2.748721] tg3 0000:18:00.0 eth0: attached PHY is 5720C (10/100/1000Base-T Ethernet) (WireSpeed[1], EEE[1])
[    2.748723] tg3 0000:18:00.0 eth0: RXcsums[1] LinkChgREG[0] MIirq[0] ASF[1] TSOcap[1]
[    2.748724] tg3 0000:18:00.0 eth0: dma_rwctrl[00000001] dma_mask[64-bit]
[    2.778790] tg3 0000:18:00.1 eth1: Tigon3 [partno(BCM95720) rev 5720000] (PCI Express) MAC address 34:48:ed:f8:3d:5d
[    2.778799] tg3 0000:18:00.1 eth1: attached PHY is 5720C (10/100/1000Base-T Ethernet) (WireSpeed[1], EEE[1])
[    2.778805] tg3 0000:18:00.1 eth1: RXcsums[1] LinkChgREG[0] MIirq[0] ASF[1] TSOcap[1]
[    2.778810] tg3 0000:18:00.1 eth1: dma_rwctrl[00000001] dma_mask[64-bit]
[    2.799269] tg3 0000:19:00.0 eth2: Tigon3 [partno(BCM95720) rev 5720000] (PCI Express) MAC address 34:48:ed:f8:3d:5e
[    2.799274] tg3 0000:19:00.0 eth2: attached PHY is 5720C (10/100/1000Base-T Ethernet) (WireSpeed[1], EEE[1])
[    2.799277] tg3 0000:19:00.0 eth2: RXcsums[1] LinkChgREG[0] MIirq[0] ASF[1] TSOcap[1]
[    2.799280] tg3 0000:19:00.0 eth2: dma_rwctrl[00000001] dma_mask[64-bit]
[    2.818574] tg3 0000:19:00.1 eth3: Tigon3 [partno(BCM95720) rev 5720000] (PCI Express) MAC address 34:48:ed:f8:3d:5f
[    2.818584] tg3 0000:19:00.1 eth3: attached PHY is 5720C (10/100/1000Base-T Ethernet) (WireSpeed[1], EEE[1])
[    2.818590] tg3 0000:19:00.1 eth3: RXcsums[1] LinkChgREG[0] MIirq[0] ASF[1] TSOcap[1]
[    2.818595] tg3 0000:19:00.1 eth3: dma_rwctrl[00000001] dma_mask[64-bit]
[    2.823972] tg3 0000:19:00.1 eno4: renamed from eth3
[    2.862592] tg3 0000:18:00.1 eno2: renamed from eth1
[    2.906515] tg3 0000:19:00.0 eno3: renamed from eth2
[    2.943519] tg3 0000:18:00.0 eno1: renamed from eth0
[    3.023331] ixgbe 0000:5f:00.0 enp95s0f0: renamed from eth1          #只读到一块网卡
[    6.433177] No Local Variables are initialized for Method [_GHL]

# 根据上面模块名，查看网卡加载信息
root@pve-node04:~# sudo dmesg |grep ixgbe
[    2.725114] ixgbe: Intel(R) 10 Gigabit PCI Express Network Driver
[    2.725116] ixgbe: Copyright (c) 1999-2016 Intel Corporation.
[    2.917410] ixgbe 0000:5f:00.0: Multiqueue Enabled: Rx Queue count = 48, Tx Queue count = 48 XDP Queue count = 0
[    2.917703] ixgbe 0000:5f:00.0: 32.000 Gb/s available PCIe bandwidth (5.0 GT/s PCIe x8 link)
[    2.918029] ixgbe 0000:5f:00.0: MAC: 2, PHY: 20, SFP+: 5, PBA No: G73131-008
[    2.918031] ixgbe 0000:5f:00.0: b4:96:91:1e:f7:0c
[    2.994827] ixgbe 0000:5f:00.0: Intel(R) 10 Gigabit Network Connection
[    2.995271] libphy: ixgbe-mdio: probed
[    3.021043] ixgbe 0000:5f:00.1: failed to load because an unsupported SFP+ or QSFP module type was detected.     # 报错提示
[    3.021120] ixgbe 0000:5f:00.1: Reload the driver after installing a supported module.
[    3.023331] ixgbe 0000:5f:00.0 enp95s0f0: renamed from eth1

```


参考资料：
https://www.serveradminz.com/blog/unsupported-sfp-linux/