# ceph运维


## 1 scrub errors
Possible data damage: 1 pg inconsistent

- 分析

数据的不一致性（inconsistent）指对象的大小不正确、恢复结束后某副本出现了对象丢失的情况。数据的不一致性会导致清理失败（scrub error）。
ceph在存储的过程中，由于特殊原因，可能遇到对象信息大小和物理磁盘上实际大小数据不一致的情况，这也会导致清理失败。

```bash
# 查看详情
root@node01:~# ceph health detail
[ERR] OSD_SCRUB_ERRORS: 1 scrub errors
[ERR] PG_DAMAGED: Possible data damage: 1 pg inconsistent
    pg 8.3ff is active+clean+inconsistent, acting [0,28,11]


```


- 修复

```bash
# 尝试修复未果
root@node02:~# ceph pg repair 8.3ff
instructing pg 8.3ff on osd.0 to repair


# 查询pg主osd
root@node02:~# ceph pg 8.3ff query |grep primary
            "same_primary_since": 11513,
                "num_objects_missing_on_primary": 0,
            "up_primary": 0,
            "acting_primary": 0,
                "same_primary_since": 11513,
                    "num_objects_missing_on_primary": 0,
                "up_primary": 0,
                "acting_primary": 0,
                "same_primary_since": 11513,
                    "num_objects_missing_on_primary": 0,
                "up_primary": 0,
                "acting_primary": 0,


# 查找osd对应节点
root@node02:~# ceph osd find 0
{
    "osd": 0,
    "addrs": {
        "addrvec": [
            {
                "type": "v2",
                "addr": "10.1.0.13:6812",
                "nonce": 3788
            },
            {
                "type": "v1",
                "addr": "10.1.0.13:6815",
                "nonce": 3788
            }
        ]
    },
    "osd_fsid": "603f3c9a-e1f9-4a4a-8672-7827ed8a170e",
    "host": "node03",
    "crush_location": {
        "host": "node03",
        "root": "default"
    }
}


# 使用ceph -w查看，并重启osd.0
systemctl restart ceph-osd@0.service


2022-07-22T14:00:00.000122+0800 mon.node03 [ERR] overall HEALTH_ERR 109 large omap objects; 1 scrub errors; Possible data damage: 1 pg inconsistent; 485 pgs not deep-scrubbed in time; 167 pgs not scrubbed in time
2022-07-22T14:02:47.553439+0800 mon.node03 [INF] osd.0 failed (root=default,host=node03) (connection refused reported by osd.19)
2022-07-22T14:02:48.418776+0800 mon.node03 [WRN] Health check failed: 1 osds down (OSD_DOWN)
2022-07-22T14:02:50.437621+0800 mon.node03 [WRN] Health check update: 106 large omap objects (LARGE_OMAP_OBJECTS)
2022-07-22T14:02:50.437647+0800 mon.node03 [WRN] Health check failed: Reduced data availability: 8 pgs peering (PG_AVAILABILITY)
2022-07-22T14:02:50.437659+0800 mon.node03 [WRN] Health check failed: Degraded data redundancy: 3594508/1227119949 objects degraded (0.293%), 6 pgs degraded (PG_DEGRADED)
2022-07-22T14:02:50.437674+0800 mon.node03 [INF] Health check cleared: OSD_SCRUB_ERRORS (was: 1 scrub errors)
2022-07-22T14:02:50.437686+0800 mon.node03 [INF] Health check cleared: PG_DAMAGED (was: Possible data damage: 1 pg inconsistent)
2022-07-22T14:02:56.462601+0800 mon.node03 [WRN] Health check update: Degraded data redundancy: 31154074/1227119949 objects degraded (2.539%), 101 pgs degraded (PG_DEGRADED)
2022-07-22T14:02:56.462637+0800 mon.node03 [INF] Health check cleared: PG_AVAILABILITY (was: Reduced data availability: 8 pgs peering)
2022-07-22T14:02:58.549747+0800 mon.node03 [INF] Health check cleared: OSD_DOWN (was: 1 osds down)
2022-07-22T14:02:58.566442+0800 mon.node03 [INF] osd.0 [v2:10.1.0.13:6812/105618,v1:10.1.0.13:6815/105618] boot
2022-07-22T14:03:00.281851+0800 mon.node03 [WRN] Health check update: 101 large omap objects (LARGE_OMAP_OBJECTS)
2022-07-22T14:03:01.937313+0800 mon.node03 [WRN] Health check update: Degraded data redundancy: 18775702/1227119949 objects degraded (1.530%), 66 pgs degraded (PG_DEGRADED)
2022-07-22T14:03:03.990750+0800 mon.node03 [INF] Health check cleared: PG_DEGRADED (was: Degraded data redundancy: 18775702/1227119949 objects degraded (1.530%), 66 pgs degraded)
```