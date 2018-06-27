parted /dev/sdb mklabel msdos
parted /dev/sdb mkpart primary 2048s 15g
mkfs -v -t ext4 /dev/sdb1
# mkswap /dev/sdb2

export LFS=/mnt/lfs
mkdir -pv $LFS
mount -v -t ext4 /dev/sdb1 $LFS
# /sbin/swapon -v /dev/sdb2

mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
wget --input-file=https://linux.cn/lfs/LFS-BOOK-7.7-systemd/wget-list-LFS7.7-systemd-USTC --continue --directory-prefix=$LFS/sources 

pushd $LFS/sources
curl -LO https://linux.cn/lfs/LFS-BOOK-7.7-systemd/md5sums
md5sums -c md5sums
popd

mkdir -pv $LFS/tools
ln -sv $LFS/tools /  #?
chmod a+rw -R /tools

groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
echo '123456' | passwd --stdin lfs
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
