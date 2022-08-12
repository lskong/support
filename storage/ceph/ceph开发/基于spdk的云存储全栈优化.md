
- [基于spdk的云存储全栈优化解决方案1.0](#基于spdk的云存储全栈优化解决方案10)
  - [架构介绍和性能目标](#架构介绍和性能目标)
  - [全栈优化解决方案](#全栈优化解决方案)
    - [1. 集成SPDK Vhost, 数据通过共享内存方式传递](#1-集成spdk-vhost-数据通过共享内存方式传递)
    - [2. RDMA替换TCP](#2-rdma替换tcp)
    - [3. 后端持久化层](#3-后端持久化层)
  - [问题与疑惑：](#问题与疑惑)
    - [使用spdk vhost对vm io与docker io进行加速这方面有什么建议或者可参考的资料](#使用spdk-vhost对vm-io与docker-io进行加速这方面有什么建议或者可参考的资料)
    - [2020中国峰会系列四 | Time to change, SPDK VHOST替代演进方案](#2020中国峰会系列四--time-to-change-spdk-vhost替代演进方案)
    - [SPDK OCF融合高速盘与慢速盘](#spdk-ocf融合高速盘与慢速盘)
    - [使用FPGA进行EC计算](#使用fpga进行ec计算)
    - [ceph-spdk按照官方文档目前部署比较困难，团队对这块经验是空白的](#ceph-spdk按照官方文档目前部署比较困难团队对这块经验是空白的)
    - [英特尔®机架规模设计【Rack Scale Architecture】](#英特尔机架规模设计rack-scale-architecture)
    - [ceph结合Nvme OF的应用场景](#ceph结合nvme-of的应用场景)
    - [PMDK目前是在SPDK中有集成](#pmdk目前是在spdk中有集成)
  - [FPGA 部署在哪里？与 CPU 之间如何通信？](#fpga-部署在哪里与-cpu-之间如何通信)
    - [(1)指令通道](#1指令通道)
    - [(2)数据通道](#2数据通道)
    - [(3)通知通道](#3通知通道)
  - [目前FPGA行业面临的问题](#目前fpga行业面临的问题)


# 基于spdk的云存储全栈优化解决方案1.0

使命与愿景：让天下没有难存储的数据（划掉）

## 架构介绍和性能目标

通过ceph为公司其他产品及业务场景提供块存储服务，采用分布式架构， 通过多副本冗余保证数据持久性。当前的SSD盘， HDD盘虽然可靠性高，能够宕机快速迁移，但性能上没有优势, 我们希望为客户提供一款同时满足高可靠，高性能, 快速可靠，同时软件能充分发挥出硬件性能的存储产品。

## 全栈优化解决方案

### 1. 集成SPDK Vhost, 数据通过共享内存方式传递
场景: HPC, k8s/OpenStack， 超融合

结合SPDK Vhost优化IO接入层性能， 将虚机IO与docker io转发至后端ceph存储节点完成持久化

    • 采用轮询方式，guest向host提交IO没有额外中断开销
    • 运用SPDK良好的模块抽象层次，编写自定义的bdev完成ceph和Vhost的对接

### 2. RDMA替换TCP
场景: HPC, k8s/OpenStack， 超融合场景, 文件存储, 医学影像, 块存储

由于数据从用户态拷贝到内核态，收发包流程有上下文切换， 流式传输， TCP内核栈， 高时延，CPU开销大等缺点， 使用RDMA替换TCP

    • 计算节点到存储节点RDMA
    • 存储节点之间RDMA
    • RoCE v2（基于UDP/IP）

### 3. 后端持久化层
场景: HPC, k8s/OpenStack， 超融合场景, 文件存储, 医学影像, 块存储

    • 后端存储节点使用SPDK NVMe Driver提供更高的IO吞吐能力，增加存储节点的SSD密度

    • 大数据， iSCSI网关场景使用SPDK OCF融合高速盘与慢速盘，提高整体存储容量的情况下， 针对不同的场景使用对应的缓存模式， 可以为高速读写提供不俗的速度

    • 普通加密及高安全要求场景， 使用SPDK NVMe Opal library避免加密成为性能的瓶颈，盘本身可以几乎满速运行。盘上自带的专用加密芯片释放了CPU的计算资源

    • 以数据为中心的高性能及高安全场景，使用Optane-PMem， PMEM相当于spdk OCF与SPDK NVMe Opal这两个模块的结合，并且性能更高

    • 容量敏感场景， 取消三副本模式，使用FPGA进行EC计算， 避免EC计算成为性能的瓶颈，负载对于CPU完全透明，释放了CPU的计算资源

    • 下一步ceph将对Nvme of进行支持， 所以未来这个feature也将进入公司战略调研

## 问题与疑惑：

### 使用spdk vhost对vm io与docker io进行加速这方面有什么建议或者可参考的资料
![spdk-vhost-devices](/img/virtio-devices.png "Magic Gardens")
![spdk-vhost-impl](/img/virtio&vhost.png "Magic Gardens")

### 2020中国峰会系列四 | Time to change, SPDK VHOST替代演进方案
使用vfio-user替代spdk vhost方案，这个方案从架构设计上比spdk vhost要好，请问现在这个方案可以稳定商用了吗，这两个方案请问intel的老师们更推荐使用哪种

![spdk-vhost-evolution-in-future](/img/spdk-vhost-evolution-in-future.png "Magic Gardens")

### SPDK OCF融合高速盘与慢速盘
能否讲解一下基于SPDKOCF这个融合后挂载的设备特点

    1) NVme是不是运行在内核空间
    2) 作为core driver的慢存储设备是运行在用户态吗
    3) 实际运用中需要注意什么地方，可能会在什么地方产生瓶颈
        
下面是单独使用open-cas库的架构图，我们打算基于SPDK的基础上使用OCF， 所以希望能够深入了解一下
![SPDK OCF](/img/open-cas-cache.png "Magic Gardens")
![dpdk001](/img/dpdk001.png "Magic Gardens")
![dpdk003](/img/dpdk003.jpg "Magic Gardens")
![dpdk004](/img/dpdk004.jpg "Magic Gardens")

### 使用FPGA进行EC计算
这个场景目前有厂家在做吗， 有没有可参考的设计

### ceph-spdk按照官方文档目前部署比较困难，团队对这块经验是空白的
        
        ceph-spdk目前编译走通了，根据ceph的官方文档进行虚拟环境部署时无法成功部署, 虚拟环境命令如下：
            1) 初始化spdk 
                sudo ./script/setup.sh config
            2) 创建虚拟化环境
                sudo ../src/vstart.sh --debug --new -x --localhost --bluestore-spdk 1c58:0023
            3) 报错在osd block解码时出现解码错误

        ceph-spdk在正式环境下创建osd时缺少操作步骤，基于spdk设备的OSD没有创建成功

       1. 根据阅读ceph源码， 目前ceph在应用spdk方面， 是将其作为一个OSD进行挂载使用的，ceho没有将spdk作为一个高速缓存的场景，想确认一下我们的理解是不是有问题
       2. 有没有可供参考的ceph-spdk的部署文档或测试环境文档


### 英特尔®机架规模设计【Rack Scale Architecture】
这个方案请问应用在那些场景，解决那些问题，我们想了解一下

![Rack Scale Architecture](/img/Rack-Scale-Architecture.png "Magic Gardens")
![SMART-NICS](/img/SPDK-NvmeOF-SMART-NICS.png "Magic Gardens")
    
### ceph结合Nvme OF的应用场景
虽然目前看到厂家应用比较少，但我们觉得这项技术也是个趋势， 希望能给我们布道一下
    
### PMDK目前是在SPDK中有集成
SPDK中什么场景使用到PMDK，作为什么角色使用，希望能帮我们解惑

==================================================

## FPGA 部署在哪里？与 CPU 之间如何通信？
腾讯云的 FPGA 主要部署在数据中心的服务器中。腾讯云将 FPGA 芯片加上 DDR 内存、外围电路和散热片，设计成 PCIE 板卡。这种 FPGA 板卡被安装在服务器的主板上，用户通过网络远程访问服务器，开发调试 FPGA，并用其加速特定业务。

FPGA 与 CPU 之间是通过 PCIE 链路通信的。CPU 内部集成了 DDR 内存控制器和 PCIE 控制器。在 FPGA 芯片内部也用可编程逻辑资源实现了 PCIE 控制器、DDR 控制器和 DMA 控制器。一般通讯分三种情况：

### (1)指令通道

CPU 向 FPGA 芯片写入指令，读取状态。CPU 直接通过 PCIE 访问到 FPGA 芯片内挂载的存储器或内部总线。

### (2)数据通道

CPU 读写 FPGA 板卡上 DDR 的数据时，CPU 通过 PCIE 配置 FPGA 芯片内的 DMA 控制器，输入数据的源物理地址和目的物理地址。DMA 控制器控制 FPGA 卡上的 DDR 控制器和 PCIE 控制器，在 FPGA 卡上的 DDR 内存和 CPU 连接的 DDR 内存之间传输数据。

### (3)通知通道

FPGA 通过 PCIE 向 CPU 发送中断请求，CPU 收到中断请求后保存当前工作现场，然后转入中断处理程序执行，必要时会关闭中断执行中断处理程序。CPU 执行完中断处理程序后，会重新打开中断，然后重载到之前的工作现场继续执行。

## 目前FPGA行业面临的问题
在行业内，微软在数据中心使用 FPGA 架构，Amazon 也推出了 FPGA 的计算实例，那么是不是说明整个行业对 FPGA 的使用比较广泛呢？实际上，FPGA 是个硬件芯片，它本身不能直接使用，也缺乏类似操作系统这样的系统软件支持。长期以来，FPGA 行业在数据计算加速方向可以分为以下几个参与方：

芯片原厂：Xilinx 和 Altera（已被 Intel 收购）提供 FPGA 的芯片，直供或者给代理商分销。

IP提供商：提供各种功能的 IP，比如访问 DDR 内存的 IP，支持 PCIE 设备的 IP，图片编解码的 IP。一些共同的通用 IP 由芯片原厂提供。

集成商：集成商提供硬件和软件的支持。由于直接用户缺乏硬件设计和制造能力，往往希望集成商提供成熟完善的硬件，并完成IP的集成，提供驱动和使用方式，方便最终用户的使用。

用户：最终使用者。在数据中心领域，用户一般目的是希望使用 FPGA 对计算进行加速。

在 FPGA 行业，芯片原厂并不提供直接使用的硬件板卡，这个工作由集成商完成。由于硬件板卡使用量小和分担设计、生产成本，硬件板卡价格往往高于芯片价格，甚至达到十倍之多。

IP 提供商因为担心产权泄露，通常不会迅速提供可用的可执行文件（网表文件）给用户，而是需要签署一系列的协议和法律文件，甚至有的 IP 提供商根本不提供给用户测试的机会。这样就造成最终用户很难得到可用的硬件板卡，更难以及时获得使用最新工艺芯片的硬件板卡，造成用户无法快速对不同IP进行验证，从而挑选适合自身业务的IP。另外，FPGA 的开发使用硬件描述语言，缺乏软件领域非常广泛使用的框架概念，导致开发周期漫长。一般来说，FPGA 开发周期是软件开发的三倍左右。

综上所述的这些问题，决定了云对 FPGA 行业的颠覆和革命。
