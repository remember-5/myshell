# 安装runner
docker compose up -d
# 注册runner
docker exec -it gitlab-runner gitlab-runner register -n \
    --url https://gitlab.remember5.top:8443 \
    --registration-token glrt-Sw7ih-8ZLVPnUynJmTrp \
    --description "aliyun cloud runner" \
    --docker-image docker:26.1.4 \
    --executor docker \
    --docker-privileged \
    --docker-allowed-pull-policies if-not-present \
    --docker-pull-policy if-not-present \
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
    --docker-volumes /srv/gitlab-runner/cache:/cache \
    --docker-volumes /root/.m2:/root/.m2 \
    --docker-volumes /root/.npm:/root/.npm \
    --docker-volumes /root/.local:/root/.local
