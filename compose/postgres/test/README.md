# PostgreSQL 测试模板

基于 `PostgreSQL 18.3-bookworm` 的单机测试模板，保留 `pgaudit` 审计与 `pg_stat_statements` 统计能力，并支持可选的 PgBouncer。

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

- 数据库地址：`localhost:15432`
- PgBouncer 地址：`localhost:16432`
- 默认数据库：`.env` 中的 `POSTGRES_DB`
- 默认管理员：`.env` 中的 `POSTGRES_USER`
- 默认密码：`.env` 中的 `POSTGRES_PASSWORD`

## 配置说明

- `docker-compose.yml`：测试环境部署
- `docker-compose.yml` 中已内置 `PgBouncer`，默认不启动，使用 `--profile pool` 启用
- `Dockerfile`：安装 `pgaudit`
- `config/postgresql.conf`：测试参数
- `config/pg_hba.conf`：认证与访问控制
- `initdb/01-init-extensions.sql`：初始化扩展

## 常见问题

如需重置测试数据，可停止容器后清空 `data/` 目录再重启。
