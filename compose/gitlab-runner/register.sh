#!/bin/bash
# GitLab Runner 自动注册脚本

set -e

# 配置变量（可通过环境变量覆盖）
GITLAB_URL="${GITLAB_URL:-http://172.43.87.10:8088}"
REGISTRATION_TOKEN="${REGISTRATION_TOKEN:-}"
RUNNER_NAME="${RUNNER_NAME:-My Runner}"
RUNNER_EXECUTOR="${RUNNER_EXECUTOR:-docker}"
DOCKER_IMAGE="${DOCKER_IMAGE:-docker:26.0.0}"
RUNNER_TAGS="${RUNNER_TAGS:-test,docker}"

# 检查必需的环境变量
if [ -z "$REGISTRATION_TOKEN" ]; then
    echo "错误: 请设置 REGISTRATION_TOKEN 环境变量"
    echo "用法: REGISTRATION_TOKEN=glrt-xxx ./register.sh"
    exit 1
fi

echo "开始注册 GitLab Runner..."
echo "GitLab URL: $GITLAB_URL"
echo "Runner 名称: $RUNNER_NAME"

# 执行注册
docker exec -it gitlab-runner gitlab-runner register \
    --non-interactive \
    --url "$GITLAB_URL" \
    --token "$REGISTRATION_TOKEN" \
    --description "$RUNNER_NAME" \
    --executor "$RUNNER_EXECUTOR" \
    --docker-privileged \
    --docker-image "$DOCKER_IMAGE" \
    --docker-allowed-pull-policies if-not-present \
    --docker-pull-policy if-not-present \
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
    --docker-volumes /srv/gitlab-runner/cache:/cache \
    --docker-volumes /root/.m2:/root/.m2 \
    --docker-volumes /root/.npm:/root/.npm \
    --docker-volumes /root/.local:/root/.local \
    --docker-volumes /root/.pnpm-store:/root/.pnpm-store \
    --tag-list "$RUNNER_TAGS"

echo "✅ GitLab Runner 注册成功！"
echo ""
echo "查看已注册的 runners:"
docker exec -it gitlab-runner gitlab-runner list