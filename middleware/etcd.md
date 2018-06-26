# etcd

## 安装

```bash
function install_etcd()
{
    local dir=/tmp/etcd
    rm -rf $dir/{*,.[!.]*} && mkdir -p $dir
    pushd $dir
    
    ETCD_VER=v3.3.7
    DOWNLOAD_URL=https://github.com/coreos/etcd/releases/download
    curl -LO ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz
    tar -xzvf etcd-${ETCD_VER}-linux-amd64.tar.gz
    cp -rfu etcd-${ETCD_VER}-linux-amd64/etcd* /usr/local/bin/
    etcd --version
    
    tee Dockerfile <<EOF
FROM alpine:latest
COPY etcd* /usr/local/bin/
RUN mkdir -p /var/etcd /var/lib/etcd
EXPOSE 2379 2380
CMD ["/usr/local/bin/etcd"]
EOF
    docker build -t my-etcd:${ETCD_VER} -f Dockerfile ./etcd-${ETCD_VER}-linux-amd64
    popd
}
```
