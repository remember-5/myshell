# AGENTS.md

本文件为 AI 模型提供在本仓库中编写 Docker 和 Docker Compose 配置的规范指导。

## 角色定义

你是一个 DevOps 基础设施助手，负责为用户提供基于 Docker 和 Docker Compose 的软件部署方案。所有输出的文档和注释使用**中文**。

## 目录与文件规范

### 目录结构

每个服务必须创建独立目录，目录名使用小写英文，与软件名称一致：

```
<service-name>/
├── docker-compose.yml        # 必须：主部署文件
├── README.md                 # 必须：中文说明文档
├── .env                      # 可选：环境变量（含敏感信息时使用）
├── config/                   # 可选：配置文件挂载目录
└── docker-compose-<变体>.yml  # 可选：替代部署方案（如 docker-compose-mysql.yml）
```

### 文件命名规则

- 主文件固定命名 `docker-compose.yml`
- 存在多种部署方案时，使用 `docker-compose-<变体描述>.yml` 命名（如 `docker-compose-mysql.yml`、`docker-compose-cluster.yml`）
- 配置文件放在 `config/` 目录下
- 数据持久化目录使用 `data/` 或 `./data`

## Docker Compose 编写规范

### 基本格式

使用**无版本声明**的现代格式（不写 `version: "3"` 等声明）：

```yaml
services:
  <service-name>:
    image: <image>:<明确版本号>
    container_name: <service-name>
    restart: always
    environment:
      - TZ=Asia/Shanghai
    ports:
      - "<宿主端口>:<容器端口>"
    volumes:
      - ./data:/var/lib/<service-path>
```

### 强制规则

| 规则 | 说明 |
|------|------|
| 明确镜像版本 | 禁止使用 `latest`，必须指定具体版本号如 `rabbitmq:4.0.5-management` |
| restart 策略 | 所有服务必须设置 `restart: always` |
| container_name | 必须显式设置，使用服务名称 |
| 时区设置 | 环境变量中必须包含 `TZ=Asia/Shanghai` |
| 数据持久化 | 所有有状态服务必须挂载数据卷，禁止数据仅存于容器内 |

### 卷挂载规范

使用相对路径挂载到当前服务目录下：

```yaml
volumes:
  - ./data:/var/lib/<xxx>         # 数据目录
  - ./config:/etc/<xxx>           # 配置文件
  - ./logs:/var/log/<xxx>         # 日志目录（如需要）
```

对于多容器共享的场景，使用命名卷并在文件底部声明：

```yaml
volumes:
  service_data:
  service_config:
```

### 网络配置

- 单容器服务：不需要额外网络配置，使用默认网络
- 多容器服务（如应用+数据库）：必须创建自定义网络

```yaml
networks:
  <service-name>-net:
    driver: bridge
```

### 环境变量

- 少量变量直接写在 `environment` 中
- 包含敏感信息（密码、密钥）时，使用 `.env` 文件配合 `env_file` 引用
- 环境变量使用列表格式 `- KEY=VALUE`

### 资源限制（可选）

对资源消耗较大的服务添加资源限制：

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 4G
    reservations:
      cpus: '2'
      memory: 2G
```

### 健康检查（可选）

对关键服务添加健康检查：

```yaml
healthcheck:
  test: ["CMD", "<check-command>"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s
```

### 服务依赖

多容器场景中使用 `depends_on` 声明启动顺序：

```yaml
depends_on:
  - db
```

### 代理配置

需要在注释中保留代理配置模板，方便中国网络环境使用：

```yaml
#      - http_proxy=http://127.0.0.1:1080
#      - https_proxy=http://127.0.0.1:1080
#      - no_proxy=localhost,127.0.0.1
```

## README.md 编写规范

每个服务目录下必须包含中文 README.md，结构如下：

```markdown
# <服务名称>

<一句话描述>

## 快速启动

docker-compose up -d

## 访问地址

- 管理界面: http://localhost:<port>
- 默认用户名: xxx
- 默认密码: xxx

## 配置说明

对 docker-compose.yml 中关键配置项的解释

## 常见问题（如有）

已知问题和解决方案
```

### README 要求

- 全文使用中文
- 包含默认访问地址和端口
- 如有默认账号密码必须标注
- 对非常规配置项进行说明
- 如涉及插件安装、数据迁移等操作，提供完整步骤

## 禁止事项

- **禁止**在 docker-compose.yml 中使用 `latest` 标签
- **禁止**有状态服务不挂载数据卷
- **禁止**在 YAML 文件中硬编码生产环境密码（使用 `.env` 文件或注释提示用户修改）
- **禁止**省略 `restart` 策略
- **禁止**省略 `container_name`
- **禁止**省略时区配置
- **禁止**使用英文编写文档和注释（代码关键字除外）