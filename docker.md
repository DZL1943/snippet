# docker

## 安装

```bash
function install_docker()
{
    yum -y remove docker*
    rm -rf /etc/yum.repos.d/docker*.repo
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum -y install docker-ce
    docker -v
}
```

## 架构

## 原理
### namespace

- PID
- Network
- UTS
- Mount
- IPC
- User

### cgroups

- cpu
- cpuacct
- cpuset
- memory
- devices
- freezer
- net_cls
- blkio
- perf_event
- net_prio
- hugetlb
- pids
- rdma

### UnionFS
### chroot


## CLI

## image
### dockerfile
### registry

## container

## network

## volume

## 生态
### Machine Compose Swarm
### kubernetes
