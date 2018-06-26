```bash

function install_basic_pkgs()
{
    for pkg in epel-release vim fish tmux git python-pip python-devel '@Development Tools'; do yum -y install $pkg; done
}

function config_repo()
{}
```
