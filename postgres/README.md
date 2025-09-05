# docker iamges
see https://registry.hub.docker.com/_/postgres


# command
```shell
docker-compose pull
docker-compose build 
```

# 安装插件

尽量选择debian版本，不要选择alpine

```shell
apt-get update
apt-get install curl git vim -y

# change mirror repository
bash <(curl -sSL https://linuxmirrors.cn/main.sh)

# install PGXN (PostgreSQL Extension Network)
apt install -y \
    build-essential \
    git \
    postgresql-server-dev-16 \
    python3 \
    python3-pip

# install pgvector  
pgxn install vector


# source make install pgvector
cd /tmp
git clone --branch v0.8.1 https://github.com/pgvector/pgvector.git
cd pgvector
make
make install # may need sudo
```
