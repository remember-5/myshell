# MySQL

基于 `mysql:8.4.4` 的单机 MySQL 部署，包含社区版可落地的审计替代方案与生产级 `binlog` 配置。

## 快速启动

1. 修改当前目录下的 `.env`，把 `MYSQL_ROOT_PASSWORD` 改成强密码。
2. 首次部署前建议先创建目录：

```bash
mkdir -p data logs
```

3. 启动服务：

```bash
docker compose up -d
```

## 访问地址

- MySQL 地址：`127.0.0.1:3306`
- root 用户：`root`
- root 密码：`.env` 中的 `MYSQL_ROOT_PASSWORD`

## 配置说明

- `docker-compose.yml`
  - 使用 `mysql:8.4.4`
  - root 密码通过 `.env` 注入，不再硬编码在 Compose 文件中
  - 挂载 `./config:/etc/mysql/conf.d`
  - 挂载 `./data:/var/lib/mysql`
  - 挂载 `./logs:/logs`
- `config/`
  - `10-base.cnf`：基础参数、字符集、连接数、`performance_schema`
  - `20-innodb.cnf`：InnoDB 与内存相关参数
  - `30-logging.cnf`：错误日志、慢查询日志、默认关闭的 `general_log`
  - `40-binlog.cnf`：`binlog` 与保留周期
  - MySQL 官方主配置会自动加载 `/etc/mysql/conf.d/*.cnf`，不需要手工在主配置里再写导入

## 审计说明

当前镜像是 Oracle MySQL 社区版，不能直接使用官方 `audit_log` 按用户策略审计能力。当前目录采用的是社区版可用方案：

- `general_log`
  - 记录连接、断开和收到的每条 SQL
  - 默认关闭，按需临时开启
  - 日志文件：`./logs/mysql-general.log`
- `slow_query_log`
  - 记录慢 SQL
  - 日志文件：`./logs/mysql-slow.log`
- `binlog`
  - 记录数据变更类事件，不记录普通 `SELECT`
  - 日志文件：`./logs/mysql-bin.*`

排障时临时开启：

```sql
SET GLOBAL general_log = 'ON';
```

排障结束后关闭：

```sql
SET GLOBAL general_log = 'OFF';
```

## 每个用户的操作记录怎么查

社区版没有“按用户绑定审计策略”的官方插件，但在你临时开启 `general_log` 后，所有连接和 SQL 都会被记下来。实际排查时，通常按连接信息和线程号关联用户操作。

常用方式：

```bash
grep 'Connect' logs/mysql-general.log
grep 'Query' logs/mysql-general.log
```

如果你需要更严格的“按用户过滤、策略化审计、合规留痕、防篡改”能力，建议直接改用 MySQL Enterprise Audit，而不是继续在当前社区版镜像里混装第三方审计组件。

## 常见问题

### 1. `lower_case_table_names = 1` 没生效

这个参数只适合在初始化数据目录之前确定。如果 `./data` 里已经有旧数据，需要先停容器并清空数据目录后重建。

### 2. 为什么 `binlog` 不能代替完整审计

`binlog` 主要记录数据变更事件，适合复制、恢复和变更追踪；普通查询语句，例如 `SELECT`，不会像 `general_log` 那样完整记录。

### 3. 为什么不继续使用 README 里原来的 Percona 审计组件方案

你当前运行的是 Oracle 官方 `mysql:8.4.4` 镜像，不是 Percona Server。把 Percona 的审计组件二进制直接塞进 Oracle MySQL 容器，兼容性和可维护性都没有保障，不适合作为生产方案。
