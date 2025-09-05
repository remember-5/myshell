# 说明
日常的shell、docker文件的记录，有部分下载地址是官网下载，如遇到下载困难，请另行更换下载资源

不定期维护。

# Docker compose convertion k8s yaml

使用工具 [Kompose](https://github.com/kubernetes/kompose)

kubernetes文档 https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/translate-compose-kubernetes/

# docker教程
https://yeasy.gitbook.io/

# docker 镜像源
https://github.com/cmliu/CF-Workers-docker.io
https://dockerx.org/about/
https://mirror.kentxxq.com/image


```json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.xuanyuan.me",
    "https://docker-registry.nmqu.com",
    "https://docker.1ms.run",
    "https://docker.apiba.cn",
    "https://docker.cattt.net",
    "https://docker.etcd.fun",
    "https://dockerpull.pw",
    "https://hub.amingg.com",
    "https://hub.mirrorify.net",
    "https://image.cloudlayer.icu",
    "https://2a6bf1988cb6428c877f723ec7530dbc.mirror.swr.myhuaweicloud.com",
    "https://proxy.vvvv.ee",
    "https://docker.kejilion.pro",
    "https://dockerproxy.net",
    "https://hub2.nat.tf"
  ]
}


```


# TODO
- [x] docker-file 操作和说明
- [x] 挂载脚本 [mount-disk.sh](mount-disk.sh)
- [x] 代码统计脚本 [statistics-code.sh](statistics-code.sh)

## maven阿里云镜像
```xml
<mirror>
    <id>aliyunmaven</id>
    <mirrorOf>*</mirrorOf>
    <name>阿里云公共仓库</name>
    <url>https://maven.aliyun.com/repository/public</url>
</mirror>
```

## maven 163镜像
```xml
<mirror>
  <id>nexus-163</id>
  <mirrorOf>*</mirrorOf>
  <name>Nexus 163</name>
  <url>http://mirrors.163.com/maven/repository/maven-public/</url>
</mirror>
```

# 运行增加参数
`docker build -t --no-cache --build-arg http_proxy=http://127.0.0.1:1080 --build-arg https_proxy=http://127.0.0.1:1080 .`

`docker-compose up -d --build -e http_proxy=http://127.0.0.1:1080 -e https_proxy=http://127.0.0.1:1080 --no-cache`


# docker-compose 配合 docker 

```dockerfile
# 构建容器
FROM node:18.20.4-alpine as build
WORKDIR /app

# 定义我们将在构建阶段使用的参数
ARG ENV_ARG

# 设置环境变量
ENV BUILD_ENV=$ENV_ARG

COPY package.json .
RUN npm install --registry https://registry.npmmirror.com
COPY . /app
RUN npm run build:${BUILD_ENV}

# 生产容器
FROM nginx:1.27.1-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY deploy/nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```


```yaml
services:
  my-page:
    build:
      context: .
      args:
        - http_proxy=${http_proxy}
        - https_proxy=${https_proxy}
        - ENV_ARG=${ENV_ARG}  # 这里可以设置为 'prod', 'dev' 等值
    image: my-page:latest
    ports:
      - 8080:80
```


# 配置 HTTP/HTTPS 网络代理

使用Docker的过程中，因为网络原因，通常需要使用 HTTP/HTTPS 代理来加速镜像拉取、构建和使用。下面是常见的三种场景。

## 为 dockerd 设置网络代理

"docker pull" 命令是由 dockerd 守护进程执行。而 dockerd 守护进程是由 systemd 管理。因此，如果需要在执行 "docker pull" 命令时使用 HTTP/HTTPS 代理，需要通过 systemd 配置。

- 为 dockerd 创建配置文件夹。
```
sudo mkdir -p /etc/systemd/system/docker.service.d
```

- 为 dockerd 创建 HTTP/HTTPS 网络代理的配置文件，文件路径是 /etc/systemd/system/docker.service.d/http-proxy.conf 。并在该文件中添加相关环境变量。
```
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080/"
Environment="HTTPS_PROXY=http://proxy.example.com:8080/"
Environment="NO_PROXY=localhost,127.0.0.1,.example.com"
```

- 刷新配置并重启 docker 服务。
```
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 为 docker 容器设置网络代理

在容器运行阶段，如果需要使用 HTTP/HTTPS 代理，可以通过更改 docker 客户端配置，或者指定环境变量的方式。

- 更改 docker 客户端配置：创建或更改 ~/.docker/config.json，并在该文件中添加相关配置。
```
{
 "proxies":
 {
   "default":
   {
     "httpProxy": "http://proxy.example.com:8080/",
     "httpsProxy": "http://proxy.example.com:8080/",
     "noProxy": "localhost,127.0.0.1,.example.com"
   }
 }
}
```

- 指定环境变量：运行 "docker run" 命令时，指定相关环境变量。

| 环境变量 |  docker run 示例 |
| -------- | ---------------- |
| HTTP_PROXY | --env HTTP_PROXY="http://proxy.example.com:8080/" |
| HTTPS_PROXY | --env HTTPS_PROXY="http://proxy.example.com:8080/" |
| NO_PROXY | --env NO_PROXY="localhost,127.0.0.1,.example.com" |

## 为 docker build 过程设置网络代理

在容器构建阶段，如果需要使用 HTTP/HTTPS 代理，可以通过指定 "docker build" 的环境变量，或者在 Dockerfile 中指定环境变量的方式。

- 使用 "--build-arg" 指定 "docker build" 的相关环境变量
```
docker build \
    --build-arg "HTTP_PROXY=http://proxy.example.com:8080/" \
    --build-arg "HTTPS_PROXY=http://proxy.example.com:8080/" \
    --build-arg "NO_PROXY=localhost,127.0.0.1,.example.com" .
```

- 在 Dockerfile 中指定相关环境变量

| 环境变量 | Dockerfile 示例 |
| -------- | ---------------- |
| HTTP_PROXY | ENV HTTP_PROXY="http://proxy.example.com:8080/" |
| HTTPS_PROXY | ENV HTTPS_PROXY="http://proxy.example.com:8080/" |
| NO_PROXY | ENV NO_PROXY="localhost,127.0.0.1,.example.com" |

# FAQ

## ARM下dockerfile中的mkdir不可用
```dockerfile
# 贝尔实验室 Spring 官方推荐镜像 JDK下载地址 https://bell-sw.com/pages/downloads/
FROM bellsoft/liberica-openjdk-debian:17.0.11-cds

# 这个mkdir无法运行
# RUN mkdir -p /app/server

# 建议使用WORKDIR,这样会自动创建
WORKDIR /app/server

ENV SERVER_PORT=8080 LANG=C.UTF-8 LC_ALL=C.UTF-8 JAVA_OPTS="" TZ=Asia/Shanghai

EXPOSE ${SERVER_PORT}

```


