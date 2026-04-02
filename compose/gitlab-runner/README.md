# GitLab Runner

gitlab-runner 的安装、运行、卸载、配置等介绍

## 目录

- [安装方案对比](#安装方案对比)
- [Docker Socket vs Docker-in-Docker 架构详解](#docker-socket-vs-docker-in-docker-架构详解)
- [推荐安装方式：Docker Compose](#推荐安装方式docker-compose)
- [安装步骤](#安装步骤)
- [其他安装方式](#其他安装方式)
- [Executor 选择](#executor-选择)
- [.gitlab-ci.yml 最佳实践](#gitlab-ciyml-最佳实践)
- [关键配置要点](#关键配置要点)
- [安全建议](#安全建议)
- [FAQ](#faq)
- [Reference](#reference)

---

## 安装方案对比

| 方案 | 安全性 | 复杂度 | 推荐场景 |
|------|--------|--------|----------|
| **Docker Socket 挂载** | ⚠️ 中 | 低 | 内网/受信环境（推荐）|
| Docker-in-Docker (dind) | ⚠️ 中 | 中 | 需要隔离的 Docker 环境 |
| Kaniko | ✅ 高 | 低 | 仅需构建镜像，无需 docker 命令 |

**推荐：Docker Socket 挂载方案**（本目录的 `docker-compose.yml`），原因：
- 配置简单，兼容性好
- 支持完整的 docker 命令
- 适合大多数内网 CI/CD 场景

> 如对安全性有更高要求，请参考 `docker-compose-kaniko.yml` 和 [SECURITY.md](SECURITY.md)

---

## Docker Socket vs Docker-in-Docker 架构详解

### 架构示意图

**Docker Socket 挂载方式：**

```
┌─────────────────────────────────────────────────────────────┐
│                        宿主机                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                  Docker Daemon                       │    │
│  │   ┌─────────┐  ┌─────────┐  ┌─────────┐             │    │
│  │   │ Image A │  │ Image B │  │ Image C │  ...        │    │
│  │   └─────────┘  └─────────┘  └─────────┘             │    │
│  └─────────────────────▲───────────────────────────────┘    │
│                        │                                     │
│        /var/run/docker.sock                                  │
│                        │                                     │
│  ┌─────────────────────┴───────────────────────────────┐    │
│  │              GitLab Runner 容器                      │    │
│  │   ┌─────────────────────────────────────────────┐   │    │
│  │   │              CI Job 容器                     │   │    │
│  │   │   docker build / docker push                 │   │    │
│  │   │   (通过 socket 操作宿主机 Docker)            │   │    │
│  │   └─────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**Docker-in-Docker (dind) 方式：**

```
┌─────────────────────────────────────────────────────────────┐
│                        宿主机                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                 宿主机 Docker Daemon                 │    │
│  └─────────────────────────────────────────────────────┘    │
│                            │                                 │
│  ┌─────────────────────────┴───────────────────────────┐    │
│  │              GitLab Runner 容器                      │    │
│  │                                                      │    │
│  │  ┌────────────────────────────────────────────────┐ │    │
│  │  │          dind 容器 (docker:dind)               │ │    │
│  │  │  ┌──────────────────────────────────────────┐  │ │    │
│  │  │  │         独立 Docker Daemon                │  │ │    │
│  │  │  │  ┌─────────┐  ┌─────────┐                │  │ │    │
│  │  │  │  │ Image X │  │ Image Y │                │  │ │    │
│  │  │  │  └─────────┘  └─────────┘                │  │ │    │
│  │  │  └──────────────────▲───────────────────────┘  │ │    │
│  │  └─────────────────────│───────────────────────────┘ │    │
│  │                        │ tcp://docker:2376           │    │
│  │  ┌─────────────────────┴───────────────────────────┐ │    │
│  │  │              CI Job 容器                         │ │    │
│  │  │   docker build / docker push                     │ │    │
│  │  │   (通过 TCP 连接 dind 容器内的 Docker)           │ │    │
│  │  └─────────────────────────────────────────────────┘ │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### 核心差异对比

| 对比维度 | Docker Socket 挂载 | Docker-in-Docker (dind) |
|----------|-------------------|------------------------|
| **Docker Daemon** | 共享宿主机 Daemon | 每个 Job 独立 Daemon |
| **镜像存储位置** | 宿主机本地 | dind 容器内（临时） |
| **镜像缓存** | 天然共享，构建快 | 需额外配置持久化卷 |
| **隔离性** | 低（共享 Daemon） | 高（完全隔离） |
| **安全性** | 中（能控制宿主机 Docker） | 中（需 privileged 模式） |
| **性能** | 高（无嵌套开销） | 中（嵌套虚拟化开销） |
| **配置复杂度** | 低 | 中 |

### `.gitlab-ci.yml` 配置差异

**Docker Socket 方式：**

```yaml
# 无需额外配置，直接使用 docker 命令
build:
  stage: build
  image: docker:26.1.3
  script:
    - docker build -t myimage:latest .
    - docker push myimage:latest
```

**Docker-in-Docker 方式：**

```yaml
build:
  stage: build
  image: docker:26.1.3
  services:
    - docker:26.1.3-dind   # 启动 dind 服务容器
  variables:
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_CERTDIR: "/certs"
    DOCKER_CERT_PATH: "/certs/client"
    DOCKER_TLS_VERIFY: "1"
  script:
    - docker build -t myimage:latest .
    - docker push myimage:latest
```

### 安全风险对比

| 风险类型 | Docker Socket 挂载 | Docker-in-Docker |
|----------|-------------------|------------------|
| **容器逃逸** | 可通过 Docker API 操控宿主机所有容器 | 仅限 dind 容器内部 |
| **文件系统访问** | 可挂载宿主机任意目录 | 仅限 dind 容器文件系统 |
| **特权模式** | 不强制要求 | 必须使用 `privileged: true` |
| **内核访问** | 通过 Docker API 间接访问 | 特权容器可直接访问宿主机内核 |
| **多租户隔离** | 不适合（共享 Daemon） | 适合（每 Job 独立环境） |

### 选型建议

**选择 Docker-in-Docker 的场景：**
- 多租户环境，需要严格隔离不同项目/团队的构建
- 需要测试特定版本的 Docker
- 合规要求禁止共享 Docker Daemon
- CI Job 可能执行不受信任的代码

**选择 Docker Socket 挂载的场景：**
- 内网受信环境，团队成员可信
- 追求构建速度，需要利用镜像缓存
- 配置简单，快速上手
- 资源有限，避免 dind 额外开销

---

## 推荐安装方式：Docker Compose

参考 `docker-compose.yml`，核心配置说明：

```yaml
services:
  gitlab-runner:
    image: gitlab/gitlab-runner:v17.11.0
    container_name: gitlab-runner
    restart: always
    environment:
      - TZ=Asia/Shanghai
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
        reservations:
          cpus: '2'
          memory: 2G
    healthcheck:
      test: ["CMD", "gitlab-runner", "verify"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock'   # Docker Socket
      - '/srv/gitlab-runner/config:/etc/gitlab-runner' # Runner 配置
      - '/srv/gitlab-runner/cache:/cache'              # 产物缓存
      - '/root/.m2:/root/.m2'                          # Maven 缓存
      - '/root/.npm:/root/.npm'                        # npm 缓存
      - '/root/.local:/root/.local'                    # Python pip 缓存
      - '/root/.pnpm-store:/root/.pnpm-store'          # pnpm 缓存
```

---

## 安装步骤

### 1. 启动 Runner

```bash
docker compose up -d
```

### 2. 注册 Runner (Docker executor)

使用 `register.sh` 脚本（推荐）：

```bash
REGISTRATION_TOKEN=glrt-your-token GITLAB_URL=https://your-gitlab.com ./register.sh
```

或手动注册：

```bash
docker exec -it gitlab-runner gitlab-runner register \
    --non-interactive \
    --url https://your-gitlab.com \
    --token glrt-your-token \
    --description "Docker Runner" \
    --executor docker \
    --docker-privileged \
    --docker-image docker:26.0.0 \
    --docker-pull-policy if-not-present \
    --docker-allowed-pull-policies if-not-present \
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
    --docker-volumes /srv/gitlab-runner/cache:/cache \
    --docker-volumes /root/.m2:/root/.m2 \
    --docker-volumes /root/.npm:/root/.npm \
    --docker-volumes /root/.local:/root/.local \
    --docker-volumes /root/.pnpm-store:/root/.pnpm-store
```

### 3. 验证注册

```bash
docker exec -it gitlab-runner gitlab-runner list
```

> 如果是内网使用 Harbor，建议更改 `helper_image`，避免拉不到镜像而报错，参考 https://docs.gitlab.com/runner/configuration/advanced-configuration/

---

## 其他安装方式

### shell 安装

```bash
# 下载 gitlab-runner
wget https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
cp gitlab-runner-linux-amd64 /usr/local/bin/gitlab-runner
chmod +x /usr/local/bin/gitlab-runner
ln -s /usr/local/bin/gitlab-runner /usr/bin/gitlab-runner
mkdir -p /data/gitlab-runner
gitlab-runner install -n "gitlab-runner" --user=root --working-directory=/data/gitlab-runner
gitlab-runner start
```

卸载 Runner：
```bash
gitlab-runner list
gitlab-runner unregister --url https://gitlab.org/ --token {TOKEN}
```

### k8s 方式

建议采用 Helm Chart 安装，参考官方文档 https://artifacthub.io/packages/helm/gitlab/gitlab-runner

注意如果用 cache，就需要 PVC https://docs.gitlab.com/runner/executors/kubernetes/#volumes

---

## Executor 选择

| Executor | 特点 | 适用场景 |
|----------|------|----------|
| **Docker** | 通过 Docker Container 执行 CI Job | 已拥抱容器技术的团队（推荐）|
| Shell | 在 Runner 本地环境直接执行 | 简单场景，需预装依赖 |
| SSH | 通过 SSH 连接目标主机执行 | 需在特定主机执行的场景 |
| Kubernetes | 通过 K8s API 创建 Pod 执行 | K8s 生产环境 |
| Docker Machine | Docker executor + auto-scaling | 大量并发 CI Job |
| Parallels / VirtualBox | 通过 VM 执行 | 需要完整 VM 隔离 |
| Custom | 自行定制 | 以上都不满足时 |

### 该选择哪一种？

- 团队熟悉 Container → **Docker executor**
- 生产环境用 K8s → **Kubernetes executor**
- CI Job 大量并发 → **Docker Machine executor**（可 auto-scaling）
- 特定主机部署 → **SSH 或 Shell executor**

> Shell、SSH、VirtualBox、Parallels 这几种 Executor 无法享受 GitLab Runner 的 caching feature。

常见的多 Runner 组合：
1. **Docker executor** — 供一般的 CI Job 使用
2. **Docker Machine executor** — 供 CI Job 大爆发堵车时使用
3. **SSH 或 Shell executor** — 供 Production Deploy 或有较高安全性考量的场景

---

## .gitlab-ci.yml 最佳实践

本目录提供了三个开箱即用的 CI 模板，位于 `ci-templates/` 目录下：

| 模板文件 | 适用场景 |
|----------|----------|
| `ci-templates/base.gitlab-ci.yml` | 通用基础模板（含多环境部署） |
| `ci-templates/java-maven.gitlab-ci.yml` | Java Maven 项目 |
| `ci-templates/nodejs.gitlab-ci.yml` | Node.js 前端项目 |

使用方式：将模板文件复制到项目根目录并重命名为 `.gitlab-ci.yml`，根据实际需求修改。

### 基础模板结构

```yaml
# 默认镜像
default:
  image: docker:26.1.3
  tags:
    - docker

# 阶段定义
stages:
  - build
  - test
  - deploy

# 全局变量
variables:
  DOCKER_IMAGE_NAME: $CI_PROJECT_NAME
  REGISTRY_URL: registry.example.com

# 缓存配置
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
    - .m2/
```

### 构建 Docker 镜像

```yaml
build:
  stage: build
  image: docker:26.1.3
  variables:
    DOCKER_IMAGE_TAG: ${CI_COMMIT_SHORT_SHA}
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $CI_REGISTRY_IMAGE:$DOCKER_IMAGE_TAG .
    - docker push $CI_REGISTRY_IMAGE:$DOCKER_IMAGE_TAG
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### 多环境部署 (使用 YAML 锚点)

```yaml
# 定义锚点模板
.deploy_template: &deploy_template
  stage: deploy
  image:
    name: bitnami/kubectl:latest
    entrypoint: [""]
  script:
    - export KUBECONFIG=$(pwd)/deploy/kubeconfig.yaml
    - envsubst < deploy/deployment-template.yaml > deployment.yaml
    - kubectl config use-context $K8S_CONTEXT
    - kubectl apply -f deployment.yaml -n $K8S_NAMESPACE

# 测试环境
deploy_test:
  <<: *deploy_template
  variables:
    K8S_CONTEXT: test
    K8S_NAMESPACE: test
    DOCKER_IMAGE_TAG: ${CI_COMMIT_SHORT_SHA}
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"

# 生产环境
deploy_prod:
  <<: *deploy_template
  variables:
    K8S_CONTEXT: prod
    K8S_NAMESPACE: production
    DOCKER_IMAGE_TAG: ${CI_COMMIT_TAG}
  rules:
    - if: $CI_COMMIT_TAG
  when: manual
```

### 邮件通知（构建失败时）

```yaml
notify:
  stage: .post
  image: python:3.10-alpine
  script:
    - python deploy/send_email.py
  when: on_failure
  allow_failure: true
```

邮件发送脚本参考本目录 `send_email.py`。

---

## 关键配置要点

### 1. 镜像拉取策略

```yaml
--docker-pull-policy if-not-present
```

避免每次都拉取镜像，加快构建速度。

### 2. 缓存挂载

在注册时挂载缓存目录：
- `/root/.m2` — Maven 缓存
- `/root/.npm` — npm 缓存
- `/root/.local` — Python pip 缓存（需用 `pip install --user` 安装）
- `/root/.pnpm-store` — pnpm 缓存
- `/cache` — GitLab 产物缓存

使用方式（以 Maven 为例）：
```yaml
variables:
  MAVEN_OPTS: "-Dmaven.repo.local=/root/.m2/repository"
script:
  - mvn $MAVEN_OPTS clean package -DskipTests
```

### 3. 触发规则最佳实践

```yaml
rules:
  - if: $CI_COMMIT_BRANCH == "main"                       # 主分支
  - if: $CI_COMMIT_BRANCH == "develop"                    # 开发分支
  - if: $CI_COMMIT_TAG                                     # 标签触发
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"       # MR 触发
```

### 4. Artifacts 和 Cache 的区别

| | Artifacts | Cache |
|-|-----------|-------|
| 用途 | 阶段间传递产物 | 加速依赖下载 |
| 生命周期 | 随 pipeline | 跨 pipeline 持久 |
| 示例 | `target/*.jar`, `dist/` | `node_modules/`, `.m2/` |

---

## 安全建议

详细内容请参考 [SECURITY.md](SECURITY.md)。

核心建议：

1. **Kaniko 方案**：无需 Docker Socket，更安全（参考 `docker-compose-kaniko.yml`）
2. **限制 Runner 权限**：在 `config.toml` 中限制 `allowed_images`
3. **使用 protected runners**：只允许受保护分支使用
4. **定期更新**：保持 Runner 版本最新

```toml
# config.toml 安全配置示例
[[runners]]
  [runners.docker]
    privileged = false
    allowed_images = ["docker:*", "alpine:*", "node:*", "maven:*"]
    network_mode = "bridge"
```

---

## FAQ

### Shell Executor 拉代码报错

```bash
# 更新 git
yum install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm
yum install -y git
yum update git
```

### 注册失败

错误：`ERROR: Failed to load config stat /etc/gitlab-runner/config.toml: no such file or directory builds=0`

解决办法：
```bash
docker exec -it <容器id> /bin/bash
touch /etc/gitlab-runner/config.toml
```

---

## Reference

- https://docs.gitlab.com/runner/install/docker.html
- https://docs.gitlab.com/runner/register/
- https://docs.gitlab.com/runner/commands/index.html
- https://docs.gitlab.com/runner/configuration/advanced-configuration/
- [K8s 部署方案 (kubectl/Helm)](docker-runner-helm.md)
- [安全最佳实践](SECURITY.md)
- 快速开始极狐 GitLab 工作流 https://www.yuque.com/rangwu/gitlab/guqi8aud217uaab7
- YAML anchors https://support.atlassian.com/bitbucket-cloud/docs/yaml-anchors/
