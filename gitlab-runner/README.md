说明
```shell
docker exec -it gitlab-runner gitlab-runner register -n \
    --url https://gitlab.com \  ###注册gitlab地址
    --registration-token xxxxxx \  ###注册token
    --description My Runner \   ###描述
    --docker-image docker:26.0.0 \   ###docker版本，保持和运行的docker一致
    --executor docker \
    --docker-privileged \
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
    --docker-volumes /root/m2:/root/.m2

```
