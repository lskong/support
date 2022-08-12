# ceph_osd延时运维

- 查看时延高的osd
在集群没有压力时，osd写入时延高

```bash
root@node02:~# ceph osd perf
osd  commit_latency(ms)  apply_latency(ms)
 44                   0                  0
 43                   0                  0
 42                   0                  0
 41                   0                  0
 40                   0                  0
 39                   0                  0
 38                   1                  1
 37                   0                  0
 36                   1                  1
 15                   2                  2
 14                   0                  0
 13                   0                  0
 12                   0                  0
 11                   0                  0
 10                   1                  1
  9                   1                  1
  8                   0                  0
  7                   0                  0
  6                   0                  0
  1                   0                  0
  0                   0                  0
  2                   0                  0
  3                   1                  1
  4                   1                  1
  5                   0                  0
 16                   0                  0
 17                 120                120
 18                   0                  0
 19                 125                125
 20                   0                  0
 21                   0                  0
 22                   0                  0
 23                   0                  0
 24                   0                  0
 25                   0                  0
 26                   0                  0
 27                   1                  1
 28                   0                  0
 29                   0                  0
 30                   1                  1
 31                   0                  0
 32                   0                  0
 33                   0                  0
 34                   0                  0
 35                   0                  0
```

- 查看对应磁盘的时延

```bash
root@node02:~# iostat -x 1 /dev/sdg
Linux 4.12.14-520-zxcloud (node02) 	06/30/2022 	_x86_64_	(64 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           1.80    0.00    0.76    0.41    0.00   97.02

Device            r/s     w/s     rkB/s     wkB/s   rrqm/s   wrqm/s  %rrqm  %wrqm r_await w_await aqu-sz rareq-sz wareq-sz  svctm  %util
sdg              0.03   60.50      1.06  15241.96     0.00    60.48   0.61  49.99    9.40  142.10   8.71    38.21   251.93   5.80  35.13

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.27    0.00    0.13    0.22    0.00   99.39

Device            r/s     w/s     rkB/s     wkB/s   rrqm/s   wrqm/s  %rrqm  %wrqm r_await w_await aqu-sz rareq-sz wareq-sz  svctm  %util
sdg              0.00  167.00      0.00  42084.00     0.00   168.00   0.00  50.15    0.00  168.05  26.62     0.00   252.00   5.99 100.00

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.25    0.00    0.16    0.22    0.00   99.37

Device            r/s     w/s     rkB/s     wkB/s   rrqm/s   wrqm/s  %rrqm  %wrqm r_await w_await aqu-sz rareq-sz wareq-sz  svctm  %util
sdg              0.00  149.00      0.00  37548.00     0.00   149.00   0.00  50.00    0.00  160.48  27.49     0.00   252.00   6.71 100.00


# w_await 时延
```

- 检查磁盘状态

```bash


```