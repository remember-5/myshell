## Install

```shell
# 初始化config.yaml
docker run --entrypoint="" --rm -it docker.io/gitea/runner:latest gitea-runner generate-config > config.yaml
# 安装服务
docker compose up -d
```


## Uninstall

卸载 or 重新安装

```shell
docker compose down -v
rm -rf ./data 
```




## Cache

compose 已经把宿主机目录挂进容器了 `./data:/data`, 所以 config.yaml 里的 cache 路径建议写：
```yaml
cache:
    enabled: true
    dir: /data/cache
    host: "192.168.123.1"
    port: 8088 # 可以修改端口, compose需要一起修改
```
