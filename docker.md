# docker
https://github.com/moby/moby

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
    
    #https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file
    tee /etc/docker/daemon.json <<EOF
{
    "registry-mirrors": ["https://registry.docker-cn.com"]
}
EOF
}
```

## 架构
### docker CLI

- container
- image
- network
- node
- plugin
- secret
- service
- stack
- swarm
- system
- volume

### docker daemon

## 原理
### namespace

```
- Cgroup      CLONE_NEWCGROUP   Cgroup root directory (since Linux 4.6)
- IPC         CLONE_NEWIPC      System V IPC, POSIX message queues (since Linux 2.6.19)
- Network     CLONE_NEWNET      Network devices, stacks, ports, etc. (since Linux 2.6.24)
- Mount       CLONE_NEWNS       Mount points (since Linux 2.4.19)
- PID         CLONE_NEWPID      Process IDs (since Linux 2.6.24)
- User        CLONE_NEWUSER     User and group IDs (started in Linux 2.6.23 and completed in Linux 3.8)
- UTS         CLONE_NEWUTS      Hostname and NIS domain name (since Linux 2.6.19)

内核结构: nsproxy
```

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

## 生态
### Machine Compose Swarm
### kubernetes
### coreos
### rancher
