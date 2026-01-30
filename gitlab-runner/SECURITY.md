# GitLab Runner 安全最佳实践

## 当前方案的安全风险

### 🔴 高风险：Docker Socket 挂载

**问题：**
```yaml
volumes:
  - '/var/run/docker.sock:/var/run/docker.sock'
```

这种配置给予 Runner 容器完全的宿主机 Docker 访问权限，等同于 root 权限。

**风险：**
1. CI 任务中的恶意代码可以：
   - 启动特权容器
   - 访问宿主机文件系统
   - 操控其他容器
   - 读取敏感信息（环境变量、secrets）
2. 容器逃逸风险
3. 任何能提交代码触发 CI 的人都能控制宿主机

**攻击示例：**
```yaml
# 恶意的 .gitlab-ci.yml
malicious_job:
  script:
    - docker run -v /:/host alpine cat /host/etc/shadow
    - docker run --privileged alpine nsenter --target 1 --mount --uts --ipc --net --pid -- bash
```

### 🔴 高风险：特权模式

**问题：**
```bash
--docker-privileged
```

特权模式移除了容器的所有安全限制。

**风险：**
- 可以加载内核模块
- 可以访问所有设备
- 可以修改系统配置
- 容器逃逸更容易

## 安全替代方案

### 方案 1：使用 Kaniko（推荐）

Kaniko 可以在非特权容器中构建 Docker 镜像，无需 Docker daemon。

**优点：**
- ✅ 不需要 Docker Socket
- ✅ 不需要特权模式
- ✅ 更安全的隔离
- ✅ 支持缓存和多阶段构建

**配置：**
参考 `docker-compose-kaniko.yml`

**注册命令：**
```bash
docker exec -it gitlab-runner gitlab-runner register \
    --non-interactive \
    --url https://gitlab.com \
    --token glrt-xxx \
    --description "Kaniko Runner" \
    --executor docker \
    --docker-image alpine:latest \
    --docker-volumes /cache
```

**CI 配置示例：**
```yaml
build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:v1.23.0-debug
    entrypoint: [""]
  script:
    - mkdir -p /kaniko/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"auth\":\"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"}}}" > /kaniko/.docker/config.json
    - /kaniko/executor
      --context "${CI_PROJECT_DIR}"
      --dockerfile "${CI_PROJECT_DIR}/Dockerfile"
      --destination "${CI_REGISTRY_IMAGE}:${CI_COMMIT_TAG}"
      --cache=true
```

### 方案 2：Docker-in-Docker (dind)

使用独立的 Docker daemon 容器，而不是共享宿主机的 Docker。

**优点：**
- ✅ 隔离的 Docker 环境
- ✅ 不影响宿主机 Docker
- ✅ 可以使用 Docker 命令

**缺点：**
- ⚠️ 仍需要特权模式
- ⚠️ 性能开销较大
- ⚠️ 存储管理复杂

**配置示例：**
```yaml
# .gitlab-ci.yml
build:
  stage: build
  image: docker:26.0.0
  services:
    - docker:26.0.0-dind
  variables:
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_CERTDIR: "/certs"
    DOCKER_TLS_VERIFY: 1
    DOCKER_CERT_PATH: "$DOCKER_TLS_CERTDIR/client"
  script:
    - docker build -t myimage:latest .
    - docker push myimage:latest
```

### 方案 3：Buildah

另一个无守护进程的容器构建工具。

**优点：**
- ✅ 不需要 Docker daemon
- ✅ 可以在非特权模式运行
- ✅ OCI 标准兼容

**示例：**
```yaml
build:
  stage: build
  image: quay.io/buildah/stable:latest
  script:
    - buildah bud -t myimage:latest .
    - buildah push myimage:latest docker://registry.example.com/myimage:latest
```

## 其他安全建议

### 1. 限制 Runner 权限

```yaml
# config.toml
[[runners]]
  [runners.docker]
    # 禁用特权模式
    privileged = false

    # 限制可用的镜像
    allowed_images = ["docker:*", "alpine:*", "node:*"]

    # 禁用主机网络
    network_mode = "bridge"

    # 只读根文件系统
    # read_only = true
```

### 2. 使用专用的 Runner 用户

不要使用 root 用户运行 Runner。

### 3. 网络隔离

```yaml
services:
  gitlab-runner:
    networks:
      - runner-network

networks:
  runner-network:
    driver: bridge
    internal: true  # 禁止访问外部网络（可选）
```

### 4. 资源限制

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 4G
```

### 5. 定期更新

- 定期更新 GitLab Runner 版本
- 更新基础镜像
- 审查安全公告

### 6. 审计和监控

- 启用 Runner 日志
- 监控异常的 Docker 操作
- 定期审查 CI/CD 配置

### 7. 最小权限原则

- 只给 Runner 必需的权限
- 使用 GitLab 的 protected runners 功能
- 限制哪些项目可以使用特定的 Runner

## 迁移建议

如果当前使用 Docker Socket 方案：

1. **评估需求**：确认是否真的需要构建 Docker 镜像
2. **选择方案**：优先考虑 Kaniko
3. **测试环境**：先在测试环境验证新方案
4. **逐步迁移**：一个项目一个项目地迁移
5. **监控问题**：密切关注构建失败和性能问题

## 参考资料

- [GitLab Runner Security](https://docs.gitlab.com/runner/security/)
- [Kaniko Documentation](https://github.com/GoogleContainerTools/kaniko)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)