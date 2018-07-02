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

- container   Manage containers
- image       Manage images
- network     Manage networks
- node        Manage Swarm nodes
- plugin      Manage plugins
- secret      Manage Docker secrets
- service     Manage services
- stack       Manage Docker stacks
- swarm       Manage Swarm
- system      Manage Docker
- volume      Manage volumes

### docker daemon

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

## 生态
### Machine Compose Swarm
### kubernetes
### coreos
### rancher
