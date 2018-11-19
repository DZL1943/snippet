# LFS

[LFS-BOOK-7.7-systemd](https://linux.cn/lfs/LFS-BOOK-7.7-systemd/index.html)

## 动机和目的

- 了解 Linux 启动过程、liveCD 原理
- 了解进程、线程、协程原理，以及进程组、作业、会话、终端、daemon
- 了解系统调用、链接、加载、库、包、依赖关系
- 了解内核以外的一堆东西
- 了解 docker、container os 原理

## 原理

## 概述

1. 准备宿主系统，创建分区和目录，下载软件包，添加用户以及设置环境变量
2. 使用宿主系统工具链编译 binutils 第一遍
3. 编译gcc第一遍，使用刚才生成的链接器
4. 安装内核头文件（glibc需要）
5. 用 /tools 里面的交叉链接器和交叉编译器交叉编译自己（glibc）
6. libstdc++
7. binutils第二遍（这次不用宿主的）
8. gcc第二遍
9. 其它1.tcl/expect/dejagnu/check/ncurses/bash/bzip2/coreutils/diffutils/file/findutils/gawk/gettext/grep/gzip/m4/make/patch/perl/sed/tar/texinfo/util1.linux/xz)
10. chroot
11. 内核头文件
12. man-pages
13. glibc
14. 调整工具链，让新编译的程序链接到这些新的库上
15. 1.lib/file/binutils/gmp/mpfr/mpc/gcc/bzip2/pkg-config/ncurses/attr/acl/libcap/sed/shadow/psmisc/procps-ng/e2fsprogs/coreutils/iana-etc/m4/flex/1.ison/grep/readline/bash/bc/libtool/gdbm/expat/inetutils/perl/XML-Parser/autoconf/automake/diffutils/gawk/findutils/gettext/intltool/gperf/gro1.f/xz/grub/less/gzip/iproute2/kbd/kmod/libpipeline/make/patch/systemd/dbus/util-linux/man-db/tar/texinfo/vim
16. 基本系统配置（network udev symlinks clock console locale inputrc shells systemd）
17. fstab kernel grub
18. reboot

## 注意事项

- 环境变量
- 权限
- 报错和遗漏
- 前期不需要 fstab，但要保证 mount（甚至在chroot之前分区意义不大）
- 前期不需要 patch
- 为缩减时长可跳过测试（尤其是gcc）
- 建议跟踪记录每次编译后对文件系统的改动

## 预备知识

## 宿主机要求

```bash
# check hostreqs
cat > version-check.sh << "EOF"
#!/bin/bash
# Simple script to list version numbers of critical development tools
export LC_ALL=C
bash --version | head -n1 | cut -d" " -f2-4
echo "/bin/sh -> `readlink -f /bin/sh`"
echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
bison --version | head -n1
if [ -h /usr/bin/yacc ]; then
echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
elif [ -x /usr/bin/yacc ]; then
echo yacc is `/usr/bin/yacc --version | head -n1`
else
echo "yacc not found"
fi
bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-
echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
diff --version | head -n1
find --version | head -n1
gawk --version | head -n1
if [ -h /usr/bin/awk ]; then
echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
elif [ -x /usr/bin/awk ]; then
echo yacc is `/usr/bin/awk --version | head -n1`
else
echo "awk not found"
fi
gcc --version | head -n1
g++ --version | head -n1
ldd --version | head -n1 | cut -d" " -f2- # glibc version
grep --version | head -n1
gzip --version | head -n1
cat /proc/version
m4 --version | head -n1
make --version | head -n1
patch --version | head -n1
echo Perl `perl -V:version`
sed --version | head -n1
tar --version | head -n1
makeinfo --version | head -n1
xz --version | head -n1
echo 'main(){}' > dummy.c && g++ -o dummy dummy.c
if [ -x dummy ]
then echo "g++ compilation OK";
else echo "g++ compilation failed"; fi
rm -f dummy.c dummy
EOF
bash version-check.sh
```

- bash
- binutils
- bison
- bzip
- coreutils
- diffutils
- findutils
- gawk
- gcc  #检查 /usr/lib 或是 /usr/lib64 下是否存在 libgmp.la、libmpfr.la 和 libmpc.la。这三个文件应该要么都存在，要么都没有
- glibc
- grep
- gzip
- linux kernel
- m4
- make
- patch
- perl
- sed
- tar
- texinfo  # 这个需要手动装一下
- xz

## chapter 1-4

4～10G，共用 swap，不建议lvm。我这里直接添加一块新的盘

```bash
# parted
select /dev/sdb
mklabel msdos  # 实验环境下随意
mkpart primary 2048s 200m  # boot 需要设置标志吗？
mkpart extended 200m -1
mkpart logical 200m -1

mkfs -v -t ext2 /dev/sdb1
mkfs -v -t ext4 /dev/sdb5
export LFS=/mnt/lfs
mkdir -pv $LFS; mount -v -t ext4 /dev/sdb5 $LFS
mkdir -pv $LFS/boot; mount -v -t ext2 /dev/sdb1 $LFS/boot
# mkswap /dev/<xxx>; /sbin/swapon -v /dev/<xxx>
# fstab ?

# 软件包
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources

wget --input-file=https://linux.cn/lfs/LFS-BOOK-7.7-systemd/wget-list-LFS7.7-systemd-USTC --continue --directory-prefix=$LFS/sources
pushd $LFS/sources
md5sum -c md5sums
popd

mkdir -v $LFS/tools
ln -sv $LFS/tools /  # ?

groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
echo lfs|passwd lfs --stdin
chown -v lfs $LFS/tools
chown -v lfs $LFS/sources
su - lfs

cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF

source ~/.bash_profile
```

## ch05 - 构建临时文件系统

构建过程：

1. 源文件和补丁在$LFS/sources 目录，进入该目录
2. 解压软件包，进入解压后目录
3. 编译
4. 回到sources目录
5. 删除解压后的目录以及相关临时构建目录

```bash
cd $LFS/sources
# binutils-1
version=2.25
tar -xjvf binutils-$version.tar.bz2
pushd binutils-$version
mkdir -pv ../binutils-build
pushd ../binutils-build
../binutils-$version/configure     \
    --prefix=/tools            \
    --with-sysroot=$LFS        \
    --with-lib-path=/tools/lib \
    --target=$LFS_TGT          \
    --disable-nls              \
    --disable-werror
make
case $(uname -m) in
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac
make install
popd
popd
rm -rf binutils-$version binutils-build
# -> bin（x86_64-lfs-linux-gnu-*）  lib（空的）  lib64（指向lib）  share  x86_64-lfs-linux-gnu/{bin,lib}
# gcc-1
version=4.9.2
tar -xjvf gcc-$version.tar.bz2
pushd gcc-$version
tar -xf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -xf ../gmp-6.0.0a.tar.xz
mv -v gmp-6.0.0 gmp
tar -xf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc
# 修改 GCC 默认的动态链接器为安装在 /tools 文件夹中的。从 GCC 的 include 搜索路径中移除 /usr/include
for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done
sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure
mkdir -v ../gcc-build
pushd ../gcc-build
../gcc-$version/configure                             \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libitm                               \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libcilkrts                           \
    --disable-libstdc++-v3                         \
    --enable-languages=c,c++
make && make install
popd
popd
rm -rf gcc-$version gcc-build
# - bin目录增加gcc文件
# - 增加空的include目录
# - lib目录增加gcc/x86_64-lfs-linux-gnu/4.9.2目录（主要是.h文件）
# - 增加libexec/gcc/x86_64-lfs-linux-gnu/4.9.2目录
# linux api header
version=3.19
tar -xf linux-$version.tar.xz
pushd linux-$version
make mrproper
make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include
popd
rm -rf linux-$version
# 显然在include目录增加了内核头文件
# glibc-1
version=2.21
tar -xf glibc-$version.tar.xz
pushd glibc-$version
if [ ! -r /usr/include/rpc/types.h ]; then
  su -c 'mkdir -pv /usr/include/rpc'
  su -c 'cp -v sunrpc/rpc/*.h /usr/include/rpc'
fi
sed -e '/ia32/s/^/1:/' \
    -e '/SSE2/s/^1://' \
    -i  sysdeps/i386/i686/multiarch/mempcpy_chk.S
mkdir -v ../glibc-build
pushd ../glibc-build
# 用 /tools 里面的交叉链接器和交叉编译器交叉编译自己
../glibc-$version/configure                             \
      --prefix=/tools                               \
      --host=$LFS_TGT                               \
      --build=$(../glibc-$version/scripts/config.guess) \
      --disable-profile                             \
      --enable-kernel=2.6.32                        \
      --with-headers=/tools/include                 \
      libc_cv_forced_unwind=yes                     \
      libc_cv_ctors_header=yes                      \
      libc_cv_c_cleanup=yes
make && make install
# check
echo 'main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'
# -> [Requesting program interpreter: /tools/lib/ld-linux.so.2]
rm -v dummy.c a.out
popd
popd
rm -rf glibc-$version glibc-build
# - bin目录增加了一些东西
# - 增加etc目录
# - lib目录增加了一些东西（主要是.so .a）
# - 增加sbin目录
# - 增加var目录
# libstdc++  从属于 gcc
version=4.9.2
tar -xjvf gcc-$version.tar.bz2
pushd gcc-$version
mkdir -pv ../gcc-build
pushd ../gcc-build
../gcc-$version/libstdc++-v3/configure \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-shared                \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/4.9.2
make && make install
popd
popd
rm -rf gcc-$version gcc-build

# binutils-2
version=2.25
tar -xjvf binutils-$version.tar.bz2
pushd binutils-$version
mkdir -pv ../binutils-build
pushd ../binutils-build
CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../binutils-$version/configure     \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot
make && make install
# 为下一章的“再调整”阶段准备链接器
make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin
popd
popd
rm -rf binutils-$version binutils-build

# gcc-2
version=4.9.2
tar -xjvf gcc-$version.tar.bz2
pushd gcc-$version
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

tar -xf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -xf ../gmp-6.0.0a.tar.xz
mv -v gmp-6.0.0 gmp
tar -xf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc

mkdir -pv ../gcc-build
pushd ../gcc-build
CC=$LFS_TGT-gcc                                    \
CXX=$LFS_TGT-g++                                   \
AR=$LFS_TGT-ar                                     \
RANLIB=$LFS_TGT-ranlib                             \
../gcc-$version/configure                             \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp
make && make install

ln -sv gcc /tools/bin/cc

echo 'main(){}' > dummy.c
cc dummy.c
readelf -l a.out | grep ': /tools'
# -> [Requesting program interpreter: /tools/lib/ld-linux.so.2]
rm -v dummy.c a.out
popd
popd
rm -rf gcc-$version gcc-build

# for test - Tcl, Expect, DejaGNU, Check
version=8.6.3
tar -xzvf tcl$version-src.tar.gz
pushd tcl$version
pushd unix
./configure --prefix=/tools
make
# TZ=UTC make test
make install
chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh
popd
popd
rm -rf tcl$version

version=5.45
tar -xzvf expect$version.tar.gz
pushd expect$version
cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include
make
make test
make SCRIPTS="" install
popd
rm -rf expect$version

version=1.5.2
tar -xzvf dejagnu-$version.tar.gz
pushd dejagnu-$version
./configure --prefix=/tools && make install && make check
popd
rm -rf dejagnu-$version

version=0.9.14
tar -xzvf check-$version.tar.gz
pushd check-$version
PKG_CONFIG= ./configure --prefix=/tools && make && make check; make install
popd
rm -rf check-$version

version=5.9
tar -xzvf ncurses-$version.tar.gz
pushd ncurses-$version
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
make && make install
popd
rm -rf ncurses-$version

version=4.3.30
tar -xzvf bash-$version.tar.gz
pushd bash-$version
./configure --prefix=/tools --without-bash-malloc
make && make tests; make install
ln -sv bash /tools/bin/sh
popd
rm -rf bash-$version

version=1.0.6
tar -xzvf bzip2-$version.tar.gz
pushd bzip2-$version
make && make PREFIX=/tools install
popd
rm -rf bzip2-$version

version=8.23
tar -xf coreutils-$version.tar.xz
pushd coreutils-$version
./configure --prefix=/tools --enable-install-program=hostname
make && make RUN_EXPENSIVE_TESTS=yes check; make install
popd
rm -rf coreutils-$version

version=3.3
tar -xf diffutils-$version.tar.xz
pushd diffutils-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf diffutils-$version

version=5.22
tar -xzvf file-$version.tar.gz
pushd file-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf file-$version

version=4.4.2
tar -xzvf findutils-$version.tar.gz
pushd findutils-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf findutils-$version

version=4.1.1
tar -xf gawk-$version.tar.xz
pushd gawk-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf gawk-$version

version=0.19.4
tar -xf gettext-$version.tar.xz
pushd gettext-$version
pushd gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared
make -C gnulib-lib
make -C intl pluralx.c
make -C src msgfmt
make -C src msgmerge
make -C src xgettext
cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin
popd
popd
rm -rf gettext-$version

version=2.21
tar -xf grep-$version.tar.xz
pushd grep-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf grep-$version

version=1.6
tar -xf gzip-$version.tar.xz
pushd gzip-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf gzip-$version

version=1.4.17
tar -xf m4-$version.tar.xz
pushd m4-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf m4-$version

version=4.1
tar -xjvf make-$version.tar.bz2
pushd make-$version
./configure --prefix=/tools --without-guile && make && make check; make install
popd
rm -rf make-$version

version=2.7.4
tar -xf patch-$version.tar.xz
pushd patch-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf patch-$version

version=5.20.2
tar -xjvf perl-$version.tar.bz2
pushd perl-$version
sh Configure -des -Dprefix=/tools -Dlibs=-lm
make
cp -v perl cpan/podlators/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/$version
cp -Rv lib/* /tools/lib/perl5/$version
popd
rm -rf perl-$version

version=4.2.2
tar -xjvf sed-$version.tar.bz2
pushd sed-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf sed-$version

version=1.28
tar -xf tar-$version.tar.xz
pushd tar-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf tar-$version

version=5.2
tar -xf texinfo-$version.tar.xz
pushd texinfo-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf texinfo-$version

version=2.26
tar -xf util-linux-$version.tar.xz
pushd util-linux-$version
./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            PKG_CONFIG=""
make && make install
popd
rm -rf util-linux-$version

version=5.2.0
tar -xf xz-$version.tar.xz
pushd xz-$version
./configure --prefix=/tools && make && make check; make install
popd
rm -rf xz-$version

# optional: clean. used: 1.5g
strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*
rm -rf /tools/{,share}/{info,man,doc}

chown -R root:root $LFS/tools
# bak? $LFS/tools
```

```text
# tree -pugsDhCaL 2 /mnt/lfs
/mnt/lfs
├── [drwxr-xr-x root     root     1.0K Nov 18 15:40]  boot
│   └── [drwx------ root     root      12K Nov 18 15:40]  lost+found
├── [drwx------ root     root      16K Nov 18 15:37]  lost+found
├── [drwxrwxrwt lfs      root     4.0K Nov 18 21:29]  sources
│   ├── [-rw-r--r-- root     root     378K May 19  2013]  acl-2.2.52.src.tar.gz
│   ├── [-rw-r--r-- root     root     336K May 19  2013]  attr-2.4.47.src.tar.gz
│   ├── [-rw-r--r-- root     root     1.2M Apr 25  2012]  autoconf-2.69.tar.xz
│   ├── [-rw-r--r-- root     root     1.4M Jan  6  2015]  automake-1.15.tar.xz
│   ├── [-rw-r--r-- root     root     7.6M Nov  7  2014]  bash-4.3.30.tar.gz
│   ├── [-rw-r--r-- root     root     8.7K Feb 20  2015]  bash-4.3.30-upstream_fixes-1.patch
│   ├── [-rw-r--r-- root     root     1.4K Feb 20  2015]  bc-1.06.95-memory_leak-1.patch
│   ├── [-rw-r--r-- root     root     283K Sep  5  2006]  bc-1.06.95.tar.bz2
│   ├── [-rw-r--r-- root     root      23M Dec 23  2014]  binutils-2.25.tar.bz2
│   ├── [-rw-r--r-- root     root     1.9M Jan 23  2015]  bison-3.0.4.tar.xz
│   ├── [-rw-r--r-- root     root     1.6K Feb 20  2015]  bzip2-1.0.6-install_docs-1.patch
│   ├── [-rw-r--r-- root     root     764K Sep 20  2010]  bzip2-1.0.6.tar.gz
│   ├── [-rw-r--r-- root     root     740K Jul 26  2014]  check-0.9.14.tar.gz
│   ├── [-rw-r--r-- root     root     139K Feb 20  2015]  coreutils-8.23-i18n-1.patch
│   ├── [-rw-r--r-- root     root     5.1M Jul 19  2014]  coreutils-8.23.tar.xz
│   ├── [-rw-r--r-- root     root     1.8M Feb  9  2015]  dbus-1.8.16.tar.gz
│   ├── [-rw-r--r-- root     root     583K Feb  4  2015]  dejagnu-1.5.2.tar.gz
│   ├── [-rw-r--r-- root     root     1.1M Mar 25  2013]  diffutils-3.3.tar.xz
│   ├── [-rw-r--r-- root     root     6.1M Aug 29  2014]  e2fsprogs-1.42.12.tar.gz
│   ├── [-rw-r--r-- root     root     549K Mar 25  2012]  expat-2.1.0.tar.gz
│   ├── [-rw-r--r-- root     root     614K Nov 10  2010]  expect5.45.tar.gz
│   ├── [-rw-r--r-- root     root     715K Feb 20  2015]  file-5.22.tar.gz
│   ├── [-rw-r--r-- root     root     2.0M Jun  6  2009]  findutils-4.4.2.tar.gz
│   ├── [-rw-r--r-- root     root     1.5M Mar 27  2014]  flex-2.5.39.tar.bz2
│   ├── [-rw-r--r-- root     root     2.1M Apr  9  2014]  gawk-4.1.1.tar.xz
│   ├── [-rw-r--r-- root     root      86M Oct 30  2014]  gcc-4.9.2.tar.bz2
│   ├── [-rw-r--r-- root     root     793K Dec 26  2013]  gdbm-1.11.tar.gz
│   ├── [-rw-r--r-- root     root     6.3M Dec 24  2014]  gettext-0.19.4.tar.xz
│   ├── [-rw-r--r-- root     root     2.7K Feb 20  2015]  glibc-2.21-fhs-1.patch
│   ├── [-rw-r--r-- root     root      12M Feb  6  2015]  glibc-2.21.tar.xz
│   ├── [-rw-r--r-- root     root     1.8M Mar 26  2014]  gmp-6.0.0a.tar.xz
│   ├── [-rw-r--r-- root     root     960K Feb  4  2009]  gperf-3.0.4.tar.gz
│   ├── [-rw-r--r-- root     root     1.2M Nov 24  2014]  grep-2.21.tar.xz
│   ├── [-rw-r--r-- root     root     4.0M Nov  4  2014]  groff-1.22.3.tar.gz
│   ├── [-rw-r--r-- root     root     5.5M Dec 25  2013]  grub-2.02~beta2.tar.xz
│   ├── [-rw-r--r-- root     root     708K Jun 10  2013]  gzip-1.6.tar.xz
│   ├── [-rw-r--r-- root     root     201K Dec 23  2014]  iana-etc-2.30.tar.bz2
│   ├── [-rw-r--r-- root     root     2.1M Jan 13  2014]  inetutils-1.9.2.tar.gz
│   ├── [-rw-r--r-- root     root     185K Feb 27  2012]  intltool-0.50.2.tar.gz
│   ├── [-rw-r--r-- root     root     444K Feb 11  2015]  iproute2-3.19.0.tar.xz
│   ├── [-rw-r--r-- root     root      12K Feb 20  2015]  kbd-2.0.2-backspace-1.patch
│   ├── [-rw-r--r-- root     root     2.1M Jul  8  2014]  kbd-2.0.2.tar.gz
│   ├── [-rw-r--r-- root     root     1.4M Nov 16  2014]  kmod-19.tar.xz
│   ├── [-rw-r--r-- root     root     304K Apr  5  2013]  less-458.tar.gz
│   ├── [-rw-r--r-- root     root      62K Jan  6  2014]  libcap-2.24.tar.xz
│   ├── [-rw-r--r-- root     root     786K Oct 26  2014]  libpipeline-1.4.0.tar.gz
│   ├── [-rw-r--r-- root     root     950K Feb 16  2015]  libtool-2.4.6.tar.xz
│   ├── [-rw-r--r-- root     root      78M Feb  9  2015]  linux-3.19.tar.xz
│   ├── [-rw-r--r-- root     root     1.1M Sep 22  2013]  m4-1.4.17.tar.xz
│   ├── [-rw-r--r-- root     root     1.3M Oct  6  2014]  make-4.1.tar.bz2
│   ├── [-rw-r--r-- root     root     1.4M Nov  8  2014]  man-db-2.7.1.tar.xz
│   ├── [-rw-r--r-- root     root     1.3M Feb  2  2015]  man-pages-3.79.tar.xz
│   ├── [-rw-r--r-- root     root     618K Jan 15  2014]  mpc-1.0.2.tar.gz
│   ├── [-rw-r--r-- root     root     1.0M Mar 14  2013]  mpfr-3.1.2.tar.xz
│   ├── [-rw-r--r-- root     root      38K Feb 20  2015]  mpfr-3.1.2-upstream_fixes-3.patch
│   ├── [-rw-r--r-- root     root     2.7M Apr  5  2011]  ncurses-5.9.tar.gz
│   ├── [-rw-r--r-- root     root     698K Feb  1  2015]  patch-2.7.4.tar.xz
│   ├── [-rw-r--r-- root     root      13M Feb 15  2015]  perl-5.20.2.tar.bz2
│   ├── [-rw-r--r-- root     root     1.8M Jan 24  2013]  pkg-config-0.28.tar.gz
│   ├── [-rw-r--r-- root     root     801K Sep 23  2014]  procps-ng-3.3.10.tar.xz
│   ├── [-rw-r--r-- root     root     447K Feb 16  2014]  psmisc-22.21.tar.gz
│   ├── [-rw-r--r-- root     root     2.4M Feb 26  2014]  readline-6.3.tar.gz
│   ├── [-rw-r--r-- root     root     5.2K Feb 20  2015]  readline-6.3-upstream_fixes-3.patch
│   ├── [-rw-r--r-- root     root     1.0M Dec 23  2012]  sed-4.2.2.tar.bz2
│   ├── [-rw-r--r-- root     root     1.5M May 10  2014]  shadow-4.2.1.tar.xz
│   ├── [-rw-r--r-- root     root     9.3K Feb 20  2015]  systemd-219-compat-1.patch
│   ├── [-rw-r--r-- root     root     3.8M Feb 17  2015]  systemd-219.tar.xz
│   ├── [-rw-r--r-- root     root     1.9M Jul 28  2014]  tar-1.28.tar.xz
│   ├── [-rw-r--r-- root     root     8.5M Nov 12  2014]  tcl8.6.3-src.tar.gz
│   ├── [-rw-r--r-- root     root     3.6M Sep 27  2013]  texinfo-5.2.tar.xz
│   ├── [-rw-r--r-- root     root     285K Jan 31  2015]  tzdata2015a.tar.gz
│   ├── [-rw-r--r-- root     root     3.7M Feb 19  2015]  util-linux-2.26.tar.xz
│   ├── [-rw-r--r-- root     root     9.4M Feb 20  2015]  vim-7.4.tar.bz2
│   ├── [-rw-r--r-- root     root     5.7K Nov 18  2016]  wget-list-LFS7.7-systemd-USTC
│   ├── [-rw-r--r-- root     root     232K Jan 12  2015]  XML-Parser-2.44.tar.gz
│   ├── [-rw-r--r-- root     root     984K Dec 22  2014]  xz-5.2.0.tar.xz
│   └── [-rw-r--r-- root     root     440K Apr 29  2013]  zlib-1.2.8.tar.xz
└── [drwxr-xr-x lfs      root     4.0K Nov 18 19:58]  tools
    ├── [drwxr-xr-x lfs      lfs       12K Nov 18 21:29]  bin
    ├── [drwxr-xr-x lfs      lfs      4.0K Nov 18 19:03]  etc
    ├── [drwxr-xr-x lfs      lfs      4.0K Nov 18 21:29]  include
    ├── [drwxr-xr-x lfs      lfs       12K Nov 18 21:29]  lib
    ├── [lrwxrwxrwx lfs      lfs         3 Nov 18 17:34]  lib64 -> lib
    ├── [drwxr-xr-x lfs      lfs      4.0K Nov 18 21:24]  libexec
    ├── [drwxr-xr-x lfs      lfs      4.0K Nov 18 20:17]  man
    ├── [drwxr-xr-x lfs      lfs      4.0K Nov 18 21:27]  sbin
    ├── [drwxr-xr-x lfs      lfs      4.0K Nov 18 21:27]  share
    ├── [drwxr-xr-x lfs      lfs      4.0K Nov 18 19:03]  var
    ├── [drwxr-xr-x lfs      lfs      4.0K Nov 18 19:17]  x86_64-lfs-linux-gnu
    └── [drwxr-xr-x lfs      lfs      4.0K Nov 18 19:23]  x86_64-unknown-linux-gnu

17 directories, 77 files
```

## ch06 - 安装基本的系统软件

```bash
# run with root?
mkdir -pv $LFS/{dev,proc,sys,run}

mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3

mount -v --bind /dev $LFS/dev
mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='\u:\w\$ '              \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h
# 从这里以后，就不再需要 LFS 变量了
# 注意 /tools/bin 放在了 PATH 变量的最后。意思是在每个软件的最后版本编译安装好后就不再使用临时工具了
# 本章从这以后的命令，以及后续章节里的命令都要在 chroot 环境下运行
mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -v  /usr/libexec
mkdir -pv /usr/{,local/}share/man/man{1..8}

case $(uname -m) in
 x86_64) ln -sv lib /lib64
         ln -sv lib /usr/lib64
         ln -sv lib /usr/local/lib64 ;;
esac

mkdir -v /var/{log,mail,spool}
ln -sv /run /var/run
ln -sv /run/lock /var/lock
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}

ln -sv /tools/bin/{bash,cat,echo,pwd,stty} /bin
ln -sv /tools/bin/perl /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib
sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la
ln -sv bash /bin/sh

ln -sv /proc/self/mounts /etc/mtab

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
systemd-bus-proxy:x:72:72:systemd Bus Proxy:/:/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/bin/false
systemd-network:x:76:76:systemd Network Management:/:/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
systemd-bus-proxy:x:72:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
nogroup:x:99:
users:x:999:
EOF

exec /tools/bin/bash --login +h

touch /var/log/{btmp,lastlog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

# ls -> bin  boot  dev  etc  home  lfs_tools.tar.gz  lib  lib64  lost+found  media  mnt  opt  proc  root  run  sbin  sources  srv  sys  tmp  tools  usr  var

cd /sources
pkg=linux-3.19
tar -xf $pkg.tar.xz
pushd $pkg
make mrproper
make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include
popd; rm -rf $pkg

pkg=man-pages-3.79
tar -xf $pkg.tar.xz
pushd $pkg
make install
popd; rm -rf $pkg

# glibc-2
pkg=glibc-2.21
tar -xf $pkg.tar.xz
pushd $pkg
patch -Np1 -i ../$pkg-fhs-1.patch
sed -e '/ia32/s/^/1:/' \
    -e '/SSE2/s/^1://' \
    -i  sysdeps/i386/i686/multiarch/mempcpy_chk.S
mkdir -pv ../$pkg-build
pushd ../$pkg-build
../$pkg/configure    \
    --prefix=/usr          \
    --disable-profile      \
    --enable-kernel=2.6.32 \
    --enable-obsolete-rpc
make
make check
touch /etc/ld.so.conf
make install
cp -v ../$pkg/nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
install -v -Dm644 ../$pkg/nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../$pkg/nscd/nscd.service /lib/systemd/system/nscd.service
mkdir -pv /usr/lib/locale
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
# make localedata/install-locales
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns myhostname
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../tzdata2015a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

tzselect
TZ='Asia/Shanghai'
ln -sfv /usr/share/zoneinfo/$TZ /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF
cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

popd
popd; rm -rf $pkg $pkg-build

# adjusting
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld

gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs

echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
grep -B1 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
rm -v dummy.c a.out dummy.log

pkg=zlib-1.2.8
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr && make && make check; make install
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
popd; rm -rf $pkg

pkg=file-5.22
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr && make && make check; make install
popd; rm -rf $pkg

# binutils-3
expect -c "spawn ls"
pkg=binutils-2.25
tar -xjvf $pkg.tar.bz2
pushd $pkg
mkdir -v ../$pkg-build
pushd ../$pkg-build
../$pkg/configure --prefix=/usr   \
                           --enable-shared \
                           --disable-werror
make tooldir=/usr
make -k check
make tooldir=/usr install
popd
popd; rm -rf $pkg $pkg-build

pkg=gmp-6.0.0
tar -xf ${pkg}a.tar.xz
pushd $pkg
./configure --prefix=/usr \
            --enable-cxx  \
            --docdir=/usr/share/doc/${pkg}a
make
make html
make check 2>&1 | tee gmp-check-log
awk '/tests passed/{total+=$2} ; END{print total}' gmp-check-log
make install
make install-html
popd; rm -rf $pkg

pkg=mpfr-3.1.2
tar -xf $pkg.tar.xz
pushd $pkg
patch -Np1 -i ../$pkg-upstream_fixes-3.patch
./configure --prefix=/usr        \
            --enable-thread-safe \
            --docdir=/usr/share/doc/$pkg
make
make html
make check
make install
make install-html
popd; rm -rf $pkg

pkg=mpc-1.0.2
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr --docdir=/usr/share/doc/$pkg
make
make html
make check
make install
make install-html
popd; rm -rf $pkg

# gcc-3
pkg=gcc-4.9.2
tar -xjvf $pkg.tar.bz2
pushd $pkg
mkdir -v ../$pkg-build
pushd ../$pkg-build
SED=sed                       \
../$pkg/configure        \
     --prefix=/usr            \
     --enable-languages=c,c++ \
     --disable-multilib       \
     --disable-bootstrap      \
     --with-system-zlib
make
ulimit -s 32768
make -k check
../$pkg/contrib/test_summary|grep -A7 Summ
make install

ln -sv ../usr/bin/cpp /lib
ln -sv gcc /usr/bin/cc
install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/4.9.2/liblto_plugin.so /usr/lib/bfd-plugins/

echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
grep -B4 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
rm -v dummy.c a.out dummy.log
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
popd
popd; rm -rf $pkg $pkg-build

pkg=bzip2-1.0.6
tar -xzvf $pkg.tar.gz
pushd $pkg
patch -Np1 -i ../$pkg-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat
popd; rm -rf $pkg

pkg=pkg-config-0.28
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr        \
            --with-internal-glib \
            --disable-host-tool  \
            --docdir=/usr/share/doc/$pkg
make && make check; make install
popd; rm -rf $pkg

pkg=ncurses-5.9
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --enable-pc-files       \
            --enable-widec
make && make install
mv -v /usr/lib/libncursesw.so.5* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
# for lib in ncurses form panel menu ; do
#     rm -vf                    /usr/lib/lib${lib}.so
#     echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
#     ln -sfv lib${lib}w.a      /usr/lib/lib${lib}.a
#     ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
# done

# ln -sfv libncurses++w.a /usr/lib/libncurses++.a

rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
ln -sfv libncursesw.a      /usr/lib/libcursesw.a
ln -sfv libncurses.a       /usr/lib/libcurses.a

mkdir -v       /usr/share/doc/$pkg
cp -v -R doc/* /usr/share/doc/$pkg

make distclean
./configure --prefix=/usr    \
            --with-shared    \
            --without-normal \
            --without-debug  \
            --without-cxx-binding
make sources libs
cp -av lib/lib*.so.5* /usr/lib
popd; rm -rf $pkg

pkg=attr-2.4.47
tar -xzvf $pkg.src.tar.gz
pushd $pkg
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i -e "/SUBDIRS/s|man2||" man/Makefile
./configure --prefix=/usr
make
make -j1 tests root-tests
make install install-dev install-lib
chmod -v 755 /usr/lib/libattr.so
mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
popd; rm -rf $pkg

pkg=acl-2.2.52
tar -xzvf $pkg.src.tar.gz
pushd $pkg
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test
sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" \
    libacl/__acl_to_any_text.c
./configure --prefix=/usr --libexecdir=/usr/lib
make
make install install-dev install-lib
chmod -v 755 /usr/lib/libacl.so
mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
popd; rm -rf $pkg

pkg=libcap-2.24
tar -xf $pkg.tar.xz
pushd $pkg
make
make RAISE_SETFCAP=no prefix=/usr install
chmod -v 755 /usr/lib/libcap.so
mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
popd; rm -rf $pkg

pkg=sed-4.2.2
tar -xjvf $pkg.tar.bz2
pushd $pkg
./configure --prefix=/usr --bindir=/bin --htmldir=/usr/share/doc/$pkg
make
make html
make check
make install
make -C doc install-html
popd; rm -rf $pkg

pkg=shadow-4.2.1
tar -xf $pkg.tar.xz
pushd $pkg
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs
sed -i 's/1000/999/' etc/useradd
./configure --sysconfdir=/etc --with-group-name-max-length=32
make && make install
mv -v /usr/bin/passwd /bin

pwconv
grpconv
sed -i 's/yes/no/' /etc/default/useradd
passwd root
popd; rm -rf $pkg

pkg=psmisc-22.21
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr && make && make install
mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin
popd; rm -rf $pkg

pkg=procps-ng-3.3.10
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/$pkg \
            --disable-static                         \
            --disable-kill
make
sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
make check
make install
mv -v /usr/bin/pidof /bin
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
popd; rm -rf $pkg

pkg=e2fsprogs-1.42.12
tar -xzvf $pkg.tar.gz
pushd $pkg
sed -e '/int.*old_desc_blocks/s/int/blk64_t/' \
    -e '/if (old_desc_blocks/s/super->s_first_meta_bg/desc_blocks/' \
    -i lib/ext2fs/closefs.c
mkdir -v build
pushd build
LIBS=-L/tools/lib                    \
CFLAGS=-I/tools/include              \
PKG_CONFIG_PATH=/tools/lib/pkgconfig \
../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make
ln -sfv /tools/lib/lib{blk,uu}id.so.1 lib
make LD_LIBRARY_PATH=/tools/lib check
make install
make install-libs
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
popd
popd; rm -rf $pkg

pkg=coreutils-8.23
tar -xf $pkg.tar.xz
pushd $pkg
patch -Np1 -i ../$pkg-i18n-1.patch 
touch Makefile.in
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
make
make NON_ROOT_USERNAME=nobody check-root
echo "dummy:x:1000:nobody" >> /etc/group
chown -Rv nobody .
su nobody -s /bin/bash \
          -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
sed -i '/dummy/d' /etc/group
make install
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
mv -v /usr/bin/{head,sleep,nice,test,[} /bin
popd; rm -rf $pkg

pkg=iana-etc-2.30
tar -xjvf $pkg.tar.bz2
pushd $pkg
make && make install
popd; rm -rf $pkg

pkg=m4-1.4.17
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr && make && make check; make install
popd; rm -rf $pkg

pkg=flex-2.5.39
tar -xjvf $pkg.tar.bz2
pushd $pkg
sed -i -e '/test-bison/d' tests/Makefile.in
./configure --prefix=/usr --docdir=/usr/share/doc/$pkg
make && make check; make install
ln -sv flex /usr/bin/lex
popd; rm -rf $pkg

pkg=bison-3.0.4
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr --docdir=/usr/share/doc/$pkg
make && make check; make install
popd; rm -rf $pkg

pkg=grep-2.21
tar -xf $pkg.tar.xz
pushd $pkg
sed -i -e '/tp++/a  if (ep <= tp) break;' src/kwset.c
./configure --prefix=/usr --bindir=/bin && make && make check; make install
popd; rm -rf $pkg

pkg=readline-6.3
tar -xzvf $pkg.tar.gz
pushd $pkg
patch -Np1 -i ../$pkg-upstream_fixes-3.patch
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr --docdir=/usr/share/doc/$pkg
make SHLIB_LIBS=-lncurses
make SHLIB_LIBS=-lncurses install

mv -v /usr/lib/lib{readline,history}.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/$pkg
popd; rm -rf $pkg

pkg=bash-4.3.30
tar -xzvf $pkg.tar.gz
pushd $pkg
patch -Np1 -i ../$pkg-upstream_fixes-1.patch
./configure --prefix=/usr                       \
            --bindir=/bin                       \
            --docdir=/usr/share/doc/$pkg \
            --without-bash-malloc               \
            --with-installed-readline
make
chown -Rv nobody .
su nobody -s /bin/bash -c "PATH=$PATH make tests"
make install
exec /bin/bash --login +h
popd; rm -rf $pkg

pkg=bc-1.06.95
tar -xjvf $pkg.tar.bz2
pushd $pkg
patch -Np1 -i ../$pkg-memory_leak-1.patch
./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info
make
echo "quit" | ./bc/bc -l Test/checklib.b
make install
popd; rm -rf $pkg

pkg=libtool-2.4.6
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr && make && make check; make install
popd; rm -rf $pkg


pkg=gdbm-1.11
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr --enable-libgdbm-compat
make && make check; make install
popd; rm -rf $pkg

pkg=expat-2.1.0
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr && make && make check; make install
install -v -dm755 /usr/share/doc/$pkg
install -v -m644 doc/*.{html,png,css} /usr/share/doc/$pkg
popd; rm -rf $pkg

pkg=inetutils-1.9.2
tar -xzvf $pkg.tar.gz
pushd $pkg
echo '#define PATH_PROCNET_DEV "/proc/net/dev"' >> ifconfig/system/linux.h 
./configure --prefix=/usr        \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-servers
make && make check; make install
mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin
popd; rm -rf $pkg

pkg=perl-5.20.2
tar -xjvf $pkg.tar.bz2
pushd $pkg
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib
make
make -k test
make install
unset BUILD_ZLIB BUILD_BZIP2
popd; rm -rf $pkg

pkg=XML-Parser-2.44
tar -xzvf $pkg.tar.gz
pushd $pkg
perl Makefile.PL
make && make test; make install
popd; rm -rf $pkg

pkg=autoconf-2.69
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr && make && make check; make install
popd; rm -rf $pkg

pkg=automake-1.15
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr --docdir=/usr/share/doc/$pkg
make
ed -i "s:./configure:LEXLIB=/usr/lib/libfl.a &:" t/lex-{clean,depend}-cxx.sh
make -j4 check
make install
popd; rm -rf $pkg

pkg=diffutils-3.3
tar -xf $pkg.tar.xz
pushd $pkg
sed -i 's:= @mkdir_p@:= /bin/mkdir -p:' po/Makefile.in.in
./configure --prefix=/usr && make && make check; make install
popd; rm -rf $pkg

pkg=gawk-4.1.1
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr && make && make check; make install
mkdir -v /usr/share/doc/$pkg
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/$pkg
popd; rm -rf $pkg

pkg=findutils-4.4.2
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr --localstatedir=/var/lib/locate
make && make check; make install
mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
popd; rm -rf $pkg

pkg=gettext-0.19.4
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr --docdir=/usr/share/doc/$pkg
make && make check; make install
popd; rm -rf $pkg

pkg=intltool-0.50.2
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr && make && make check; make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/$pkg/I18N-HOWTO
popd; rm -rf $pkg

pkg=gperf-3.0.4
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr --docdir=/usr/share/doc/$pkg
make && make check; make install
popd; rm -rf $pkg

pkg=groff-1.22.3
tar -xzvf $pkg.tar.gz
pushd $pkg
PAGE=<paper_size> ./configure --prefix=/usr
make && make install
popd; rm -rf $pkg

pkg=xz-5.2.0
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr --docdir=/usr/share/doc/$pkg
make && make check; make install
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
popd; rm -rf $pkg

pkg=grub-2.02~beta2
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-grub-emu-usb \
            --disable-efiemu       \
            --disable-werror
make && make install
popd; rm -rf $pkg

pkg=less-458
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr --sysconfdir=/etc
make && make install
popd; rm -rf $pkg

pkg=gzip-1.6
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr --bindir=/bin
make && make check; make install
mv -v /bin/{gzexe,uncompress,zcmp,zdiff,zegrep} /usr/bin
mv -v /bin/{zfgrep,zforce,zgrep,zless,zmore,znew} /usr/bin
popd; rm -rf $pkg

pkg=iproute2-3.19.0
tar -xf $pkg.tar.xz
pushd $pkg
sed -i '/^TARGETS/s@arpd@@g' misc/Makefile
sed -i /ARPD/d Makefile
sed -i 's/arpd.8//' man/man8/Makefile
make
make DOCDIR=/usr/share/doc/$pkg install
popd; rm -rf $pkg

pkg=kbd-2.0.2
tar -xzvf $pkg.tar.gz
pushd $pkg.tar.gz
patch -Np1 -i ../$pkg-backspace-1.patch
sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock
make && make check; make install
mkdir -v       /usr/share/doc/$pkg
cp -R -v docs/doc/* /usr/share/doc/$pkg
popd; rm -rf $pkg

pkg=kmod-19
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib
make && make check; make install
for target in depmod insmod lsmod modinfo modprobe rmmod; do
  ln -sv ../bin/kmod /sbin/$target
done

ln -sv kmod /bin/lsmod
popd; rm -rf $pkg

pkg=libpipeline-1.4.0
tar -xzvf $pkg.tar.gz
pushd $pkg
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr
make && make check; make install
popd; rm -rf $pkg

pkg=make-4.1
tar -xjvf $pkg.tar.bz2
pushd $pkg
./configure --prefix=/usr && make && make check; make install
popd; rm -rf $pkg

pkg=patch-2.7.4
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr && make && make check; make install
popd; rm -rf $pkg

pkg=systemd-219
tar -xf $pkg.tar.xz
pushd $pkg
cat > config.cache << "EOF"
KILL=/bin/kill
HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I/tools/include/blkid"
HAVE_LIBMOUNT=1
MOUNT_LIBS="-lmount"
MOUNT_CFLAGS="-I/tools/include/libmount"
cc_cv_CFLAGS__flto=no
EOF
sed -i "s:blkid/::" $(grep -rl "blkid/blkid.h")
patch -Np1 -i ../$pkg-compat-1.patch
sed -i "s:test/udev-test.pl ::g" Makefile.in
./configure --prefix=/usr                                           \
            --sysconfdir=/etc                                       \
            --localstatedir=/var                                    \
            --config-cache                                          \
            --with-rootprefix=                                      \
            --with-rootlibdir=/lib                                  \
            --enable-split-usr                                      \
            --disable-gudev                                         \
            --disable-firstboot                                     \
            --disable-ldconfig                                      \
            --disable-sysusers                                      \
            --without-python                                        \
            --docdir=/usr/share/doc/$pkg                    \
            --with-dbuspolicydir=/etc/dbus-1/system.d               \
            --with-dbussessionservicedir=/usr/share/dbus-1/services \
            --with-dbussystemservicedir=/usr/share/dbus-1/system-services
make LIBRARY_PATH=/tools/lib
make LD_LIBRARY_PATH=/tools/lib install
mv -v /usr/lib/libnss_{myhostname,mymachines,resolve}.so.2 /lib
rm -rfv /usr/lib/rpm
for tool in runlevel reboot shutdown poweroff halt telinit; do
     ln -sfv ../bin/systemctl /sbin/${tool}
done
ln -sfv ../lib/systemd/systemd /sbin/init
sed -i "s:0775 root lock:0755 root root:g" /usr/lib/tmpfiles.d/legacy.conf
sed -i "/pam.d/d" /usr/lib/tmpfiles.d/etc.conf
systemd-machine-id-setup
sed -i "s:minix:ext4:g" src/test/test-path-util.c
make LD_LIBRARY_PATH=/tools/lib -k check
popd; rm -rf $pkg

pkg=dbus-1.8.16
tar -xzvf $pkg.tar.gz
pushd $pkg
./configure --prefix=/usr                       \
            --sysconfdir=/etc                   \
            --localstatedir=/var                \
            --docdir=/usr/share/doc/$pkg \
            --with-console-auth-dir=/run/console
make && make install
mv -v /usr/lib/libdbus-1.so.* /lib
ln -sfv ../../lib/$（readlink /usr/lib/libdbus-1.so） /usr/lib/libdbus-1.so
ln -sfv /etc/machine-id /var/lib/dbus
popd; rm -rf $pkg

pkg=util-linux-2.26
tar -xf $pkg.tar.xz
pushd $pkg
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --docdir=/usr/share/doc/$pkg \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --without-python
make
chown -Rv nobody .
su nobody -s /bin/bash -c "PATH=$PATH make -k check"
make install
popd; rm -rf $pkg

pkg=man-db-2.7.1
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/$pkg \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap
make && make check; make install
sed -i "s:man root:root root:g" /usr/lib/tmpfiles.d/man-db.conf
popd; rm -rf $pkg

pkg=tar-1.28
tar -xf $pkg.tar.xz
pushd $pkg
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin
make && make check; make install
make -C doc install-html docdir=/usr/share/doc/$pkg
popd; rm -rf $pkg

pkg=texinfo-5.2
tar -xf $pkg.tar.xz
pushd $pkg
./configure --prefix=/usr && make && make check; make install
make TEXMF=/usr/share/texmf install-tex

pushd /usr/share/info
rm -v dir
for f in *
  do install-info $f dir 2>/dev/null
done
popd
popd; rm -rf $pkg

pkg=vim-7.4
tar -xjvf $pkg.tar.bz2
pushd $pkg
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr && make && make -j1 test; make install
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim74/doc /usr/share/doc/$pkg

cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

set nocompatible
set backspace=2
syntax on
if (&term == "iterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
popd; rm -rf $pkg

logout
chroot $LFS /tools/bin/env -i            \
    HOME=/root TERM=$TERM PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin   \
    /tools/bin/bash --login
# strip-debug
/tools/bin/find /{,usr/}{bin,lib,sbin} -type f \
    -exec /tools/bin/strip --strip-debug '{}' ';'

rm -rf /tmp/*
# chroot "$LFS" /usr/bin/env -i              \
#     HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
#     PATH=/bin:/usr/bin:/sbin:/usr/sbin     \
#     /bin/bash --login
# rm -rf /tools
```

## ch07 - 基本系统配置

### network

```bash
# static ip config
cat > /etc/systemd/network/10-static-eth0.network << "EOF"
[Match]
Name=eth0

[Network]
Address=192.168.0.2/24
Gateway=192.168.0.1
DNS=192.168.0.1
EOF

# dhcp config
cat > /etc/systemd/network/10-dhcp-eth0.network << "EOF"
[Match]
Name=eth0

[Network]
DHCP=yes
EOF

# /etc/resolve.conf
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

domain <Your Domain Name>
nameserver <IP address of your primary nameserver>
nameserver <IP address of your secondary nameserver>

# End /etc/resolv.conf
EOF
ln -sfv /run/systemd/resolve/resolv.conf /etc/resolv.conf

# hostname
echo "<lfs>" > /etc/hostname
# /etc/hosts
cat > /etc/hosts << "EOF"
# Begin /etc/hosts (no network card version)

127.0.0.1 <HOSTNAME.example.org> <HOSTNAME> localhost
::1       localhost

# End /etc/hosts (no network card version)
EOF
```

### udev

### symlinks

### clock

### console

### locale

### inputrc

### /etc/shells

### systemd-custom

## ch08 - boot

### fstab

### kernel

### grub

## theend

## reboot

## whatnow
