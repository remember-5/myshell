# Introduction
gitlab-runner的安装、运行、卸载、配置等介绍

# 安装

## shell安装

```shell
# 下载gitlab-runner,根据实际情况下载
wget https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
cp gitlab-runner-linux-amd64 /usr/local/bin/gitlab-runner
chmod +x /usr/local/bin/gitlab-runner
ln -s /usr/local/bin/gitlab-runner /usr/bin/gitlab-runner
mkdir -p /data/gitlab-runner
gitlab-runner install -n "gitlab-runner" --user=root --working-directory=/data/gitlab-runner
gitlab-runner start
```

卸载runner
```shell
gitlab-runner list
gitlab-runner unregister --url https://gitlab.org/ --token {TOKEN}
```

## docker方式

参考`docker-compose.yml` 运行 `docker-compose up -d` 即可安装

## k8s方式

建议采用helm chats安装, 参考官方文档 https://artifacthub.io/packages/helm/gitlab/gitlab-runner


# Executor 选择
目前可选择的Executor如下：
- Shell：即是Runner直接在自己的Local环境执行CI Job，因此如果你的CI Job要执行各种指令，例如make、npm、composer⋯⋯，则需要事先确定在此Runner的Local环境是否已具备执行CI Job所需的一切相关程序和依赖。
- SSH：Runner会通过SSH连接上目标主机，并且在目标主机上执行CI Job。因此你要提供Runner足以SSH连接目标主机的账号密码或SSH Key，也要提供足够的用户权限。当然目标主机上也要事先处理好执行CI Job所需的一切相关程序和依赖。
- Parallels：每次要执行CI Job时，Runner会先通过Parallels建立一个干净的VM，然后通过SSH登录此VM并在其中执行CI Job。所以同样的用来建立VM的Image是先要准备好执行CI Job所需的一切相依程式与套件，这样Runner建立好的环境才能正确地执行CI Job。另外，当然架设Runner的主机上，记得要安装好Parallels。
- VirtualBox：同上，只是改成用VirtualBox建立干净的VM。同样架设Runner的主机上，记得要安装好VirtualBox。
- Docker：Runner会通过Docker建立干净的Container，并且在Container内执行CI Job。因此架设Runner的主机上，记得要安装好Docker，另外在规划CI Pipeline时也要记得先准备能顺利执行CI Job的各种Docker image。在CI Pipeline中采用Container已是十分普遍的做法，建议大家可以优先评估Docker executor是否适合你的工作场景。
- Docker Machine：延续上一个 Executor，此种 Executor 一样会通过 Container 来执行 CI Job，但差别在于这次你原本的 Runner 将不再是一般的工人了，它已经摇身一变成为工头，每当有工作（CI Job）分派下来，工头就会去自行招募工人（auto-scaling）来执行工作。因此倘若在短时间内有大量的工作需要执行，工头就会去招募大量的工人迅速地将工作们全部搞定。需要注意的是因为招募工人需要一些时间，故有时此种 Executor 在启动时会需要多花费一些时间。
- Kubernetes：延续前两个与 Container 相关的 Executor，这次直接进入超级工头 K8s 的世界。与前两种 Executor 类似，但这次 Runner 操控的不是小小的 Docker engine 了，而是改为操控 K8s。此种 Executor 让 Runner 可以透过 K8s API 控制分配给 Runner 使用的 K8s Cluster 相关资源。每当有 CI Job 指派给 Runner 时，Runner 就会透过 K8s 先建立一个干净的 Pod，接着在其中执行 CI Job。当然使用此种 Executor 依然记得先准备好能顺利执行 CI Job 的各种 Container image。
- Custom：如果上面这七种 Executor 都不能让你满意，那就只好请客官您自行动手啦！Custom Executor 即是 GitLab 提供给使用者自行定制 Executor 的管道。


## 该选择哪一种 Executor？
简单来说就是根据你的需要来选择 Executor！

如果你的团队已经很熟悉 Container 技术，不论是开发、测试及 Production 环境都已全面拥抱 Container，那当然选择 Docker executor 是再正常不过了。更不用说如果 Production 环境已经采用 K8s，那么 CI/CD Pipeline 想必也离不开 K8s 的魔掌，Runner 势必会选用 Kubernetes executor。（但还是别忘了凡事都有例外。）

假如只有开发环境拥抱 Container，但实际上测试机与 Production 环境还是采用实体服务器或 VM，这时你可能就会准备多个 Runner 并搭配多种 Executor。例如 Build、Unit Testing 或某些自动化测试的 CI Job 让 Docker executor 去处理；而像是 Performance testing 则用 VirtualBox executor 开一台干净的 VM 并部署程序来执行测试。

又或者，你的公司有非常多项目正在同步进行中，同时需要执行的 CI Job 时多时少，那么可以 auto-scaling 的 Docker Machine executor 也许会是一个可以考虑的选择。事实上 gitlab.com 提供给大家免费使用的 Shared Runner，就有采用 Docker Machine executor。

再举例，假如有某个 CI Job 只能在某台主机上执行，也许是为了搭配实体服务器的某个硬件装置、也许是基于安全性或凭证的缘故，在这种情况下很可能你会用到 SSH executor，或甚至是在该主机上安装 Runner 并设置为 Shell executor，让特定的 CI Job 只能在该 Runner 主机上执行。

最后，也有可能你因为刚好身处在一个完全没有 Container 知识与技能的团队，所以才只好选择 Shell、SSH、VirtualBox 这些不需要碰到 Container 的 Executor。

【小提醒】由于 SSH、VirtualBox、Parallels 这三种 Executor，Runner 都是先连上别的主机或 VM 之后才执行 CI Job 的内容，因此都不能享受到 GitLab Runner 的 caching feature。

（官网文件也有特别提醒这件事。）

GitLab Runner 及 Executor 与 CI/CD Pipeline 的规划密切相关，在实务上我们经常会准备多种 Runner 因应不同的情境，也许是类似下面这样常态准备 3 台 Runner。

Docker executor｜供一般的 CI Job 使用。
Docker Machine executor｜供 CI Job 大爆发堵车时使用。
SSH 或 Shell executor｜供 Production Deploy 或某些有较高安全性考量


# 挂载文件

shell方式可以直接在注册时选择挂载路径

docker-compose中需要增加映射目录到宿主机才行

找到volumes配置，修改为如下，分别是挂载了宿主机的docker和配置Maven的缓存，提高效率,比如`MAVEN_OPTS: "-Dmaven.repo.local=/.m2"`
`mvn $MAVEN_OPTS clean package -Dmaven.test.skip=true`

docker注册gitlab,并挂载目录(shell方式请自行删除--docker关键字)
```shell    
docker exec -it gitlab-runner gitlab-runner register \
    --non-interactive \
    --url https://gitlab.com \
    --token glrt-xaxsxx \
    --description "runner server" \
    --executor docker \
    --docker-privileged \
    --docker-image docker:26.0.0 \
    --docker-allowed-pull-policies if-not-present \
    --docker-pull-policy if-not-present \
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
    --docker-volumes /srv/gitlab-runner/cache:/cache \
    --docker-volumes /root/.m2:/root/.m2 \
    --docker-volumes /root/.npm:/root/.npm \
    --docker-volumes /root/.local:/root/.local
```

实际的命令
```shell
docker exec -it gitlab-runner gitlab-runner register \
    --non-interactive \
    --url https://gitlab.com \  ###注册gitlab地址
    --token xxxxxx \  ###注册token
    --description "My Runner" \   ###描述
    --executor docker \
    --docker-privileged \
    --docker-image docker:26.0.0 \   ###docker版本，保持和运行的docker一致
    --docker-allowed-pull-policies if-not-present \  ###允许拉取方式
    --docker-pull-policy if-not-present \   ###拉取方式，防止Runner重复拉取镜像
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock \  ### 需要docker命令
    --docker-volumes /srv/gitlab-runner/cache:/cache \   ### 产物缓存
    --docker-volumes /root/.m2:/root/.m2 \   ### maven 的缓存路径
    --docker-volumes /root/.npm:/root/.npm \   ### npm缓存路径
    --docker-volumes /root/.local:/root/.local   ### python缓存 需要用pip install --user 安装
```

# Gitlab Runner 运行完成发送邮件通知

在gitlab-ci.yml中添加以下内容

```shell
image: docker:26.1.3

# 本次构建的阶段：build package
stages:
  - generate_changelog
  - build
  - notice
  
# 全局环境变量
variables:
  DOCKER_IMAGE_NAME: mp-weixin
  
test-notice:
  stage: notice
  image: python:3.10-alpine
  allow_failure: true
  variables:
    DOCKER_IMAGE_TAG: test
  script:
    - python3 deploy/send_email.py
```

# FAQ

## Shell Executor拉代码报错
```shell
# 更新git
#yum install -y http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm
yum install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm
# 安装git
yum install -y git
yum update git
```

## 注册失败
ERROR: Failed to load config stat /etc/gitlab-runner/config.toml: no such file or directory builds=0

解决办法：进入容器内部
```shell
docker exec -it 容器id /bin/bash 
touch /etc/gitlab-runner/config.toml
```


# Reference
- https://docs.gitlab.com/runner/install/docker.html
- https://docs.gitlab.com/runner/register/
- https://docs.gitlab.com/runner/commands/index.html
- 快速开始极狐GitLab工作流 https://www.yuque.com/rangwu/gitlab/guqi8aud217uaab7
