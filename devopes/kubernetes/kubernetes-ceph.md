# kubernetes对接ceph存储

- 环境介绍
- Ceph存储部署<略>
- kubernetes部署
- kubernetes集成ceph rbd
- kubernetes集成cephfs


## 环境介绍
```shell
# ceph存储
ceph version 15.2.13
os ubuntu 18.04
##管理网
172.16.103.21 node01
172.16.103.22 node02
172.16.103.23 node03

##集群网
10.103.0.21 node01
10.103.0.22 node02
10.103.0.23 node03


# kubernetes
docker version 1
kubernetes version 1.19.4
os centos 8.2
##管理网
172.16.103.101 node01 master
172.16.103.102 node02 
172.16.103.103 node03
##集群网
10.103.0.101 node01
10.103.0.102 node02
10.103.0.103 node03
```

## Ceph存储部署<略>

## kubernetes部署

- 所有节点配置

```shell
# 关闭swap
swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab

# /etc/hosts
172.16.103.101 node01
172.16.103.102 node02
172.16.103.103 node03

# 配置内核参数
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# 关闭selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/seliunx/conf
setenforce 0
getenforce

# 关闭防火墙
systemctl stop firewalld.service
systemctl disable firewalld.service

# 免密设置，默认node01 master节点
ssh-keygen
ssh-copy-id node01
ssh-copy-id node02
ssh-copy-id node03
```


- 所有节点Docker部署

```shell
# 清理旧版本
yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

# yum工具
yum install -y yum-utils device-mapper-persistent-data lvm2 git

# 安装docker-ce源
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 指定版本安装docker-ce
yum list docker-ce --showduplicates | sort -r
yum install -y docker-ce-19.03.15 docker-ce-cli-19.03.15 containerd.io

## 配置镜像加速器
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://wc9koj0u.mirror.aliyuncs.com"]
}
EOF

# 启动docker
systemctl enable docker
systemctl start docker
systemctl status docker

# 卸载docker
yum remove docker-ce docker-ce-cli containerd.io
rm -rf /var/lib/docker
```


- 所有节点kubernetes部署

```shell
# k8s源,centos7和centos8相同
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

# 部署kubelet kubeadm kubectl
yum install -y --nogpgcheck kubelet-1.19.4 kubeadm-1.19.4  kubectl-1.19.4
##卸载 yum remove -y --nogpgcheck kubelet kubeadm kubectl

// 查看版本
kubectl version

// 启动服务
systemctl enable kubelet
systemctl start kubelet
```


- 初始化kubernetes集群

```shell
# node01 master节点
kubeadm init \
	--apiserver-advertise-address=10.103.0.101 \
	--image-repository registry.aliyuncs.com/google_containers \
	--pod-network-cidr=10.244.0.0/16 \
	--service-cidr=10.96.0.0/12 \
  --v 5 \
  --ignore-preflight-errors=all
## 重置初始化: kubeadm reset -f


# 成功输出以下信息
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.103.0.101:6443 --token uyhrd2.i09k6dd6uxojgs17 \
    --discovery-token-ca-cert-hash sha256:6348c1d51a22df0de8b1bff646f9266868720bd4cb2cbefeef2387bb5840e3d1

# 使node01为设置为控制台
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# node02/03加入集群
kubeadm join 10.103.0.101:6443 --token uyhrd2.i09k6dd6uxojgs17 \
    --discovery-token-ca-cert-hash sha256:6348c1d51a22df0de8b1bff646f9266868720bd4cb2cbefeef2387bb5840e3d1

# 查看集群
[root@node01 ~]# kubectl get nodes
NAME     STATUS     ROLES    AGE    VERSION
node01   NotReady   master   12m    v1.19.4
node02   NotReady   <none>   108s   v1.19.4
node03   NotReady   <none>   75s    v1.19.4

# 查看服务
[root@node01 ~]# kubectl get all -A
NAMESPACE     NAME                                 READY   STATUS    RESTARTS   AGE
kube-system   pod/coredns-6d56c8448f-dhhx6         0/1     Pending   0          12m
kube-system   pod/coredns-6d56c8448f-sm9mp         0/1     Pending   0          12m
kube-system   pod/etcd-node01                      1/1     Running   0          12m
kube-system   pod/kube-apiserver-node01            1/1     Running   0          12m
kube-system   pod/kube-controller-manager-node01   1/1     Running   0          12m
kube-system   pod/kube-proxy-gl6ft                 1/1     Running   0          12m
kube-system   pod/kube-proxy-snbwp                 1/1     Running   0          2m20s
kube-system   pod/kube-proxy-zhqgb                 1/1     Running   0          107s
kube-system   pod/kube-scheduler-node01            1/1     Running   0          12m

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP                  13m
kube-system   service/kube-dns     ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   13m

NAMESPACE     NAME                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/kube-proxy   3         3         3       3            3           kubernetes.io/os=linux   13m

NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/coredns   0/2     2            0           13m

NAMESPACE     NAME                                 DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/coredns-6d56c8448f   2         2         0       12m


# 部署CNI网络组件
## flannel网络组件文件：https://github.com/coreos/flannel/blob/master/Documentation/kube-flannel.yml
[root@node01 ~]# mkdir kubernetes
[root@node01 ~]# cd kubernetes/
[root@node01 kubernetes]# kubectl apply -f kube-flannel.yml

# 多等一会，在来查看结果
[root@node01 kubernetes]# kubectl get pods --all-namespaces
NAMESPACE     NAME                             READY   STATUS    RESTARTS   AGE
kube-system   coredns-6d56c8448f-dhhx6         1/1     Running   0          39m
kube-system   coredns-6d56c8448f-sm9mp         1/1     Running   0          39m
kube-system   etcd-node01                      1/1     Running   0          40m
kube-system   kube-apiserver-node01            1/1     Running   0          40m
kube-system   kube-controller-manager-node01   1/1     Running   0          40m
kube-system   kube-flannel-ds-27gn2            1/1     Running   0          10m
kube-system   kube-flannel-ds-gbsc2            1/1     Running   0          10m
kube-system   kube-flannel-ds-vrhgl            1/1     Running   0          10m
kube-system   kube-proxy-gl6ft                 1/1     Running   0          39m
kube-system   kube-proxy-snbwp                 1/1     Running   0          29m
kube-system   kube-proxy-zhqgb                 1/1     Running   0          28m
kube-system   kube-scheduler-node01            1/1     Running   0          40m
[root@node01 ~]# kubectl get all -A

# 解除master不能运行pod
kubectl taint nodes --all node-role.kubernetes.io/master-
```




## kubernetes集成ceph rbd

- Ceph配置

```shell
# 创建rbd存储池
root@node01:~# ceph osd pool create kubernetes 128
root@node01:~# ceph osd pool application enable kubernetes rbd
root@node01:~# ceph osd lspools |grep kubernetes
10 kubernetes

# 创建独立用户,或使用admin用户，为方便后面的cephfs集成，这里使用admin用户
## root@node01:~# ceph auth get-or-create client.kubernetes mon 'profile rbd' osd 'profile rbd pool=kubernetes' mgr 'profile rbd pool=kubernetes'
## root@node01:~# ceph auth get client.kubernetes
## exported keyring for client.kubernetes
## [client.kubernetes]
## 	key = AQB2W0lijQKhNxAAuf17q3zMsuPmw1v2o10QPQ==
## 	caps mgr = "profile rbd pool=kubernetes"
## 	caps mon = "profile rbd"
## 	caps osd = "profile rbd pool=kubernetes"

# 查看用户密钥
root@node01:~# ceph auth get client.admin
exported keyring for client.admin
[client.admin]
	key = AQB2W0lijQKhNxAAuf17q3zMsuPmw1v2o10QPQ==
	caps mds = "allow *"
	caps mgr = "allow *"
	caps mon = "allow *"
	caps osd = "allow *"

# 查看集群ID
root@node01:~# ceph mon dump
dumped monmap epoch 4
epoch 4
fsid 57a3acaf-d8c5-42e2-b045-62706b8dbe33
last_changed 2022-04-03T16:32:40.896770+0800
created 2022-04-03T16:31:51.013497+0800
min_mon_release 15 (octopus)
0: [v2:10.103.0.23:3300/0,v1:10.103.0.23:6789/0] mon.node03
1: [v2:10.103.0.21:3300/0,v1:10.103.0.21:6789/0] mon.node01
2: [v2:10.103.0.22:3300/0,v1:10.103.0.22:6789/0] mon.node02
```

- Ceph-csi配置

```shell
# 下载ceph-csi项目
[root@node01 kubernetes] wget https://github.com/ceph/ceph-csi/archive/refs/tags/v3.3.1.tar.gz
## 版本对应，请查看readme查询版本; k8s版本1.19.4对版本3.3.1版本
[root@node01 kubernetes] tar xf v3.3.1.tar.gz 

  
# 创建命名空间cepfs，可以使用default。
[root@node01 kubernetes]# kubectl create ns ceph
namespace/ceph created
[root@node01 kubernetes]# kubectl get ns ceph
NAME       STATUS   AGE
ceph   Active   5s


# 修改csi-config-map.yaml
[root@node01 kubernetes]# cd ceph-csi-3.3.1/deploy/rbd/kubernetes/
[root@node01 kubernetes]# ls
csi-config-map.yaml  csi-nodeplugin-psp.yaml   csi-provisioner-psp.yaml   csi-rbdplugin-provisioner.yaml
csidriver.yaml       csi-nodeplugin-rbac.yaml  csi-provisioner-rbac.yaml  csi-rbdplugin.yaml

[root@node01 kubernetes]# vim csi-config-map.yaml
---
apiVersion: v1
kind: ConfigMap
data:
  config.json: |-
    [
      {
        "clusterID": "57a3acaf-d8c5-42e2-b045-62706b8dbe33",
        "monitors": [
          "10.103.0.21:6789",
          "10.103.0.22:6789",
          "10.103.0.23:6789"
        ]
      }
    ]
metadata:
  name: ceph-csi-config

# 应用文件csi-config-map.yaml
[root@node01 kubernetes]# kubectl apply -f csi-config-map.yaml -n ceph
configmap/ceph-csi-config created

# 查看configmap
[root@node01 kubernetes]# kubectl get configmap -n ceph
NAME              DATA   AGE
ceph-csi-config   1      102s


# 创建csi-rbd-secret.yaml
[root@node01 kubernetes]# vim csi-rbd-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: csi-rbd-secret
  namespace: ceph
stringData:
  userID: admin
  userKey: AQB2W0lijQKhNxAAuf17q3zMsuPmw1v2o10QPQ==   #使用ceph配置用户的密钥替换

# 应用文件
[root@node01 kubernetes]# kubectl apply -f csi-rbd-secret.yaml -n ceph
secret/csi-rbd-secret created
[root@node01 kubernetes]# kubectl get secret -n ceph
NAME                  TYPE                                  DATA   AGE
csi-rbd-secret        Opaque                                2      2m32s
default-token-p84gf   kubernetes.io/service-account-token   3      5m5s

# 配置Ceph-csi插件
[root@node01 kubernetes]# vim csi-provisioner-rbac.yaml		# 修改namespace=ceph
[root@node01 kubernetes]# vim csi-nodeplugin-rbac.yaml		# 修改namespace=ceph

[root@node01 kubernetes]# kubectl apply -f csi-provisioner-rbac.yaml -n ceph
serviceaccount/rbd-csi-provisioner created
clusterrole.rbac.authorization.k8s.io/rbd-external-provisioner-runner created
clusterrolebinding.rbac.authorization.k8s.io/rbd-csi-provisioner-role created
role.rbac.authorization.k8s.io/rbd-external-provisioner-cfg created
rolebinding.rbac.authorization.k8s.io/rbd-csi-provisioner-role-cfg created

[root@node01 kubernetes]# kubectl apply -f csi-nodeplugin-rbac.yaml -n ceph
serviceaccount/rbd-csi-nodeplugin created
clusterrole.rbac.authorization.k8s.io/rbd-csi-nodeplugin created
clusterrolebinding.rbac.authorization.k8s.io/rbd-csi-nodeplugin created

[root@node01 kubernetes]# vim csi-rbdplugin.yaml 		# 注释所有kms项目
[root@node01 kubernetes]# vim csi-rbdplugin-provisioner.yaml	# 注释所有kms项目
[root@node01 kubernetes]# kubectl apply -f csi-rbdplugin.yaml -n ceph
daemonset.apps/csi-rbdplugin created
service/csi-metrics-rbdplugin created

[root@node01 kubernetes]# kubectl apply -f csi-rbdplugin-provisioner.yaml -n ceph
service/csi-rbdplugin-provisioner created
deployment.apps/csi-rbdplugin-provisioner created

# 查看结果，需要时间，多等待
[root@node01 kubernetes]# kubectl get pod -o wide -n ceph
NAME                                         READY   STATUS    RESTARTS   AGE     IP             NODE     NOMINATED NODE   READINESS GATES
csi-rbdplugin-5n85n                          3/3     Running   0          4h40m   10.103.0.102   node02   <none>           <none>
csi-rbdplugin-9vfrd                          3/3     Running   0          4h40m   10.103.0.103   node03   <none>           <none>
csi-rbdplugin-gfssx                          3/3     Running   0          4h40m   10.103.0.101   node01   <none>           <none>
csi-rbdplugin-provisioner-6bfcf6c8c4-9hc4x   7/7     Running   0          4h40m   10.244.0.4     node01   <none>           <none>
csi-rbdplugin-provisioner-6bfcf6c8c4-j25nm   7/7     Running   0          4h40m   10.244.1.6     node02   <none>           <none>
csi-rbdplugin-provisioner-6bfcf6c8c4-x2cfz   7/7     Running   0          4h40m   10.244.2.6     node03   <none>           <none>



# 创建csi-rbd-sc.yaml文件
[root@node01 kubernetes]# vim csi-rbd-sc.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-rbd-sc
provisioner: rbd.csi.ceph.com
parameters:
  clusterID: 57a3acaf-d8c5-42e2-b045-62706b8dbe33
  pool: kubernetes
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
  csi.storage.k8s.io/provisioner-secret-namespace: ceph
  csi.storage.k8s.io/controller-expand-secret-name: csi-rbd-secret
  csi.storage.k8s.io/controller-expand-secret-namespace: ceph
  csi.storage.k8s.io/node-stage-secret-name: csi-rbd-secret
  csi.storage.k8s.io/node-stage-secret-namespace: ceph
  csi.storage.k8s.io/fstype: ext4
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions:
   - discard

# 应用csi-rbd-sc.yaml文件，使用yaml文件创建StorageClass
[root@node01 kubernetes]# kubectl apply -f csi-rbd-sc.yaml -n ceph
storageclass.storage.k8s.io/csi-rbd-sc created
[root@node01 kubernetes]# kubectl get sc
NAME         PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc   rbd.csi.ceph.com   Delete          Immediate           false                  84s

# 在Master节点创建raw-block-pvc.yaml文件
[root@node01 kubernetes]# vim raw-block-pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: raw-block-pvc
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Block
  resources:
    requests:
      storage: 10Gi
  storageClassName: csi-rbd-sc

# 应用raw-block-pvc.yaml，使用yaml文件创建PVC
kubectl apply -f raw-block-pvc.yaml
[root@node01 kubernetes]# kubectl apply -f raw-block-pvc.yaml -n ceph
persistentvolumeclaim/raw-block-pvc created
[root@node01 kubernetes]# kubectl get pvc -n ceph
NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
raw-block-pvc   Bound    pvc-138448bb-6624-482a-b5aa-091ff5fd044c   10Gi       RWO            csi-rbd-sc     2m11s


# 创建pod，在Master节点创建raw-block-pod.yaml文件
[root@node01 kubernetes]# vim raw-block-pod.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-raw-block-volume
spec:
  containers:
  - name: fc-container
    image: fedora:26
    command: ["/bin/sh", "-c"]
    args: ["tail -f /dev/null"]
    volumeDevices:
    - name: data
      devicePath: /dev/xvda
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: raw-block-pvc

# 使用yaml文件创建Pod
[root@node01 kubernetes]# kubectl apply -f raw-block-pod.yaml -n ceph
pod/pod-with-raw-block-volume created

[root@node01 kubernetes]# kubectl get pod -n ceph
NAME                                         READY   STATUS    RESTARTS   AGE
...
pod-with-raw-block-volume                    1/1     Running   0          54s
```



## kubernetes集成cephfs

延续rbd集成，cephfs csi插件配置与rbd基本一样，这里需要注意切换到deploy/cephfs/kubernetes目录，并注如下：

- namespace 保持ceph不变
- csi-config-map.yaml 不变


```shell
# 插件secret文件
[root@node01 kubernetes]# cd /root/kubernetes/ceph-csi-3.3.1/deploy/cephfs/kubernetes
[root@node01 kubernetes]# vim csi-cephfs-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: csi-cephfs-secret
  namespace: ceph
stringData:
  userID: admin
  userKey: AQB2W0lijQKhNxAAuf17q3zMsuPmw1v2o10QPQ==   #使用ceph配置用户的密钥替换
  adminID: admin              
  adminKey: AQB2W0lijQKhNxAAuf17q3zMsuPmw1v2o10QPQ==

[root@node01 kubernetes]# kubectl apply -f csi-cephfs-secret.yaml -n ceph
secret/csi-cephfs-secret created
[root@node01 kubernetes]# kubectl get secret -n ceph
NAME                              TYPE                                  DATA   AGE
csi-cephfs-secret                 Opaque                                2      6s
csi-rbd-secret                    Opaque                                2      20m
default-token-8qsp6               kubernetes.io/service-account-token   3      21m
rbd-csi-nodeplugin-token-4b7pl    kubernetes.io/service-account-token   3      18m
rbd-csi-provisioner-token-f4kv7   kubernetes.io/service-account-token   3      18m


# plugin
# 配置Ceph-csi插件
[root@node01 kubernetes]# vim csi-provisioner-rbac.yaml		# 修改namespace=ceph
[root@node01 kubernetes]# vim csi-nodeplugin-rbac.yaml		# 修改namespace=ceph
[root@node01 kubernetes]# kubectl apply -f csi-provisioner-rbac.yaml -n ceph
serviceaccount/cephfs-csi-provisioner created
clusterrole.rbac.authorization.k8s.io/cephfs-external-provisioner-runner created
clusterrolebinding.rbac.authorization.k8s.io/cephfs-csi-provisioner-role created
role.rbac.authorization.k8s.io/cephfs-external-provisioner-cfg created
rolebinding.rbac.authorization.k8s.io/cephfs-csi-provisioner-role-cfg created

[root@node01 kubernetes]# kubectl apply -f csi-nodeplugin-rbac.yaml -n ceph
serviceaccount/cephfs-csi-nodeplugin created
clusterrole.rbac.authorization.k8s.io/cephfs-csi-nodeplugin created
clusterrolebinding.rbac.authorization.k8s.io/cephfs-csi-nodeplugin created


[root@node01 kubernetes]# kubectl apply -f csi-cephfsplugin.yaml -n ceph
daemonset.apps/csi-cephfsplugin created
service/csi-metrics-cephfsplugin created

[root@node01 kubernetes]# kubectl apply -f csi-cephfsplugin-provisioner.yaml -n ceph
service/csi-cephfsplugin-provisioner created
deployment.apps/csi-cephfsplugin-provisioner created

[root@node01 kubernetes]# kubectl get pod -o wide -n ceph
NAME                                            READY   STATUS    RESTARTS   AGE   IP             NODE     NOMINATED NODE   READINESS GATES
csi-cephfsplugin-b7qwj                          3/3     Running   0          27s   10.103.0.101   node01   <none>           <none>
csi-cephfsplugin-lmhb5                          3/3     Running   0          27s   10.103.0.103   node03   <none>           <none>
csi-cephfsplugin-provisioner-5c799c7d88-4km62   6/6     Running   0          20s   10.244.2.10    node03   <none>           <none>
csi-cephfsplugin-provisioner-5c799c7d88-kc2hm   6/6     Running   0          20s   10.244.1.8     node02   <none>           <none>
csi-cephfsplugin-provisioner-5c799c7d88-qbn6t   6/6     Running   0          20s   10.244.0.6     node01   <none>           <none>
csi-cephfsplugin-tljhq                          3/3     Running   0          27s   10.103.0.102   node02   <none>           <none>
csi-rbdplugin-6rxwx                             3/3     Running   0          33m   10.103.0.103   node03   <none>           <none>
csi-rbdplugin-7xbrc                             3/3     Running   0          33m   10.103.0.102   node02   <none>           <none>
csi-rbdplugin-kxcbt                             3/3     Running   0          33m   10.103.0.101   node01   <none>           <none>
csi-rbdplugin-provisioner-6bfcf6c8c4-9h5g6      7/7     Running   0          33m   10.244.2.8     node03   <none>           <none>
csi-rbdplugin-provisioner-6bfcf6c8c4-ksm54      7/7     Running   0          33m   10.244.0.5     node01   <none>           <none>
csi-rbdplugin-provisioner-6bfcf6c8c4-zdpv5      7/7     Running   0          33m   10.244.1.7     node02   <none>           <none>
pod-with-raw-block-volume                       1/1     Running   0          26m   10.244.2.9     node03   <none>           <none>

# 创建sc
[root@node01 kubernetes]# vim csi-cephfs-sc.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-cephfs-sc
provisioner: cephfs.csi.ceph.com
parameters:
  clusterID: 57a3acaf-d8c5-42e2-b045-62706b8dbe33
  fsName: cephfs
  csi.storage.k8s.io/provisioner-secret-name: csi-cephfs-secret
  csi.storage.k8s.io/provisioner-secret-namespace: ceph 
  csi.storage.k8s.io/controller-expand-secret-name: csi-cephfs-secret
  csi.storage.k8s.io/controller-expand-secret-namespace: ceph
  csi.storage.k8s.io/node-stage-secret-name: csi-cephfs-secret
  csi.storage.k8s.io/node-stage-secret-namespace: ceph
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions:
  - discard
  
[root@node01 kubernetes]# kubectl apply -f csi-cephfs-sc.yaml -n ceph
storageclass.storage.k8s.io/csi-cephfs-sc created
[root@node01 kubernetes]# kubectl get sc
NAME            PROVISIONER           RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-cephfs-sc   cephfs.csi.ceph.com   Delete          Immediate           true                   5s
csi-rbd-sc      rbd.csi.ceph.com      Delete          Immediate           true                   29

# 在Master节点创建pvc
[root@node01 kubernetes]# vim raw-cephfs-pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: raw-cephfs-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: csi-cephfs-sc

[root@node01 kubernetes]# kubectl apply -f raw-cephfs-pvc.yaml -n ceph
persistentvolumeclaim/raw-cephfs-pvc created

[root@node01 kubernetes]# kubectl get pvc -n ceph
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    AGE
raw-block-pvc    Bound    pvc-8b5b1cdf-f8f1-4d15-a027-7553bba8844e   10Gi       RWO            csi-rbd-sc      64m
raw-cephfs-pvc   Bound    pvc-be89c669-7f02-453a-87d3-38506336f9f9   10Gi       RWO            csi-cephfs-sc   22s


# 创建pod
[root@node01 kubernetes]# vim raw-cephfs-pod.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-raw-cephfs-volume
spec:
  containers:
  - name: fc-container
    image: fedora:26
    command: ["/bin/sh", "-c"]
    args: ["tail -f /dev/null"]
    volumeMounts:
    - mountPath: "/mnt/cephfs"
      name: cephfs-data
      readOnly: false
  volumes:
  - name: cephfs-data
    persistentVolumeClaim:
      claimName: raw-cephfs-pvc

# 使用yaml文件创建Pod
[root@node01 kubernetes]# kubectl apply -f raw-cephfs-pod.yaml -n ceph
pod/pod-with-raw-cephfs-volume created
[root@node01 kubernetes]# kubectl get pod -o wide -n ceph
NAME                                            READY   STATUS    RESTARTS   AGE   IP             NODE     NOMINATED NODE   READINESS GATES
...
pod-with-raw-block-volume                       1/1     Running   0          77m   10.244.2.9     node03   <none>           <none>
pod-with-raw-cephfs-volume                      1/1     Running   0          37s   10.244.2.11    node03   <none>           <none>

# 进入容器
[root@node01 kubernetes]# kubectl exec -it pod-with-raw-cephfs-volume -n ceph sh
sh-4.4# df -h

# 其它主机挂载cephfs查看
root@node01:/mnt/cephfs/volumes# ls
csi  _csi:csi-vol-67b47984-bc24-11ec-ae51-eae9aafde247.meta
root@node01:/mnt/cephfs/volumes# tree
.
├── csi
│   └── csi-vol-67b47984-bc24-11ec-ae51-eae9aafde247
│       └── 7aa2d779-a735-4f91-83d3-376ad97b814c
│           └── test
└── _csi:csi-vol-67b47984-bc24-11ec-ae51-eae9aafde247.meta

```