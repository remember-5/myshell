# PostgreSQL 模板

面向个人快速复用的 PostgreSQL Docker Compose 模板，拆分为 `prod/` 和 `test/` 两套相对独立目录。每个目录都自带 `Dockerfile`、`docker-compose.yml`、`.env`、配置文件、初始化 SQL 和数据目录，进入子目录后可直接启动。

## 目录结构

```text
postgres/
├── prod/
│   ├── docker-compose.yml
│   ├── .env
│   ├── Dockerfile
│   ├── README.md
│   ├── config/
│   ├── initdb/
│   ├── data/
│   ├── logs/
│   └── backup/
└── test/
    ├── docker-compose.yml
    ├── .env
    ├── Dockerfile
    ├── README.md
    ├── config/
    ├── initdb/
    ├── data/
    ├── logs/
    └── backup/
```

## 快速启动

生产模板：

```shell
cd postgres/prod
docker compose build
docker compose up -d
```

测试模板：

```shell
cd postgres/test
docker compose build
docker compose up -d
```

启用 PgBouncer 时，在对应目录内执行：

```shell
docker compose --profile pool up -d
```

## 模板特点

- `prod/` 和 `test/` 各自自包含，方便直接拷贝走单独使用
- 两套模板都固定为 `PostgreSQL 18.3-bookworm`
- 两套模板都内置 `pgaudit` 与 `pg_stat_statements`
- 生产与测试使用不同容器名和默认端口，可同时运行
- 两套模板都使用单个 `docker-compose.yml`，默认只启动 PostgreSQL
- 测试环境默认 PgBouncer 端口为 `16432`，避免与生产冲突

## 说明

详细参数和使用方法请分别查看：

- [prod/README.md](/Users/wangjiahao/IdeaProjects/myshell/postgres/prod/README.md)
- [test/README.md](/Users/wangjiahao/IdeaProjects/myshell/postgres/test/README.md)
