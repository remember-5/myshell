# 安装runner
docker compose up -d
# 注册runner
docker exec -it gitlab-runner gitlab-runner register -n \
    --url https://gitlab.com \
    --registration-token xxxxx \
    --description "My Runner" \
    --docker-image docker:26.0.0 \
    --executor docker \
    --docker-privileged \
    --docker-allowed-pull-policies if-not-present \
    --docker-pull-policy if-not-present \
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
    --docker-volumes /root/.m2:/root/.m2 \
    --docker-volumes /root/.npm:/root/.npm \
    --docker-volumes /root/.local:/root/.local \
    --docker-volumes /cache:/cache
