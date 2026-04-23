# PostgreSQL 生产模板

基于 `PostgreSQL 18.3-bookworm` 的单机生产模板，内置 `pgaudit` 审计扩展，并支持可选的 PgBouncer 连接池。

## 快速启动

首次使用前，先修改 `.env` 中的数据库名、管理员账号和强密码：

```shell
docker compose build
docker compose up -d
```

启用 PgBouncer：

```shell
docker compose --profile pool up -d
```

## 访问地址

- 数据库地址：`localhost:5432`
- PgBouncer 地址：`localhost:6432`
- 默认数据库：`.env` 中的 `POSTGRES_DB`
- 默认管理员：`.env` 中的 `POSTGRES_USER`
- 默认密码：`.env` 中的 `POSTGRES_PASSWORD`

## 配置说明

- `docker-compose.yml`：生产基线部署
- `docker-compose.yml` 中已内置 `PgBouncer`，默认不启动，使用 `--profile pool` 启用
- `Dockerfile`：构建时默认切换 Debian 与 PGDG 的 APT 源到阿里云镜像，并安装 `pgaudit`
- `config/postgresql.conf`：生产参数
- `config/pg_hba.conf`：认证与访问控制
- `initdb/01-init-extensions.sql`：初始化扩展

## 常见问题

如需重新加载镜像和配置，可执行：

```shell
docker compose up -d --build --force-recreate
```

如需改回官方源构建，可执行：

```shell
docker build \
  --build-arg DEBIAN_APT_MIRROR=http://deb.debian.org/debian \
  --build-arg DEBIAN_SECURITY_APT_MIRROR=http://deb.debian.org/debian-security \
  --build-arg PGDG_APT_MIRROR=http://apt.postgresql.org/pub/repos/apt \
  -t myshell/postgres-prod:18.3-bookworm .
```
