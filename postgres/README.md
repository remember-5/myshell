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

添加插件
```shell
psql
CREATE EXTENSION pgaudit;
\dx

                                  List of installed extensions
  Name   | Version |   Schema   |                         Description                          
---------+---------+------------+-------------------------------------------------------------
 pgaudit | 1.7     | public     | PostgreSQL Audit Extension
 plpgsql | 1.0     | pg_catalog | PL/pgSQL procedural language
(2 rows)
```

postgres配置文件

```toml
# 启用日志收集器
logging_collector = on
# 日志输出目标
log_destination = 'stderr'
# 日志目录（相对于数据目录）
log_directory = 'log'
# 日志文件名模式
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
# 或者更详细日志格式
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h,session=%c,xid=%x '
# 日志轮转（可选）
log_rotation_age = 1d
log_rotation_size = 10MB
# 最小日志级别
log_min_messages = info
# pgaudit 相关配置
shared_preload_libraries = 'pgaudit'
pgaudit.log = 'all'
pgaudit.log_level = 'log'
pgaudit.log_parameter = on
pgaudit.log_relation = on
```
