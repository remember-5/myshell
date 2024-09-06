## 说明
https://docs.gitlab.com/runner/install/docker.html
https://docs.gitlab.com/runner/register/
https://docs.gitlab.com/runner/commands/index.html

```shell
docker exec -it gitlab-runner gitlab-runner register -n \
    --url https://gitlab.com \  ###注册gitlab地址
    --registration-token xxxxxx \  ###注册token
    --description "My Runner" \   ###描述
    --docker-image docker:26.0.0 \   ###docker版本，保持和运行的docker一致
    --executor docker \
    --docker-privileged \
    --docker-allowed-pull-policies if-not-present \  ###允许拉取方式
    --docker-pull-policy if-not-present \   ###拉取方式
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock \  ### 需要docker命令
    --docker-volumes /root/.m2:/root/.m2 \   ### maven 的缓存路径
    --docker-volumes /root/.npm:/root/.npm \   ### npm缓存路径
    --docker-volumes /root/.local:/root/.local   ### python缓存 需要用pip install --user 安装
    --docker-volumes /root/.gitlab-runner-cache:/cache   ### 产物缓存
```

卸载runner

```shell
gitlab-runner list
gitlab-runner unregister --url https://gitlab.org/ --token {TOKEN}
```


~~需要在`/srv/gitlab-runner/config/config.toml` 添加~~
```
[[runners]]
    [runners.docker]
        allowed_pull_policies = ["if-not-present"] #添加了这行
        pull_policy = ["if-not-present"]  #添加了这行
```


## gitlab-ci.yml



