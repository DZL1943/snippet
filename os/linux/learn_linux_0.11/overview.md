# learn linux 0.11

- https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/old-versions/linux-0.11.tar.gz
- http://oldlinux.org/Linux.old/Linux-0.11/sources/system/linux-0.11.tar.Z
- http://oldlinux.org/download/clk011c-1.9.5.pdf
- https://kernelnewbies.org/LinuxVersions

## 源码结构
- boot  //后来演变成arch
- drivers  //v1.0加入
- fs
- include
- init
- ipc  //v1.0加入
- kernel
- lib
- mm
- net  //v1.0加入
- tools

## 引导过程

1. 引导扇区由BIOS加载到0x7c00
2. bootsect.S
3. setup.S
4. head.S
5. /init/main.c
