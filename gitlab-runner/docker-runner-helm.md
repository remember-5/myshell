# 背景
开发提交代码到gitlab后，自动触发流水线打包，并部署发布到k8s

# 采用技术:
- gitlab（v17.5.1） 采用docker安装
- gitlab-runner（v17.5） 采用docker安装
- k8s(v1.20.4)

## gitlab安装
```yaml
version: '3.6'
services:
  gitlab:
    image: gitlab/gitlab-ce:17.4.2-ce.0
    container_name: gitlab
    restart: always
    hostname: 'gitlab.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        # Add any other gitlab.rb configuration here, each on its own line  
        # 这个是http的端口，还有https的端口，可以设置http_2_https  
        external_url 'https://gitlab.com:80'  
        # 自定义ssh端口  
        gitlab_rails['gitlab_shell_ssh_port'] = 22  
    ports:
      - '80:80'
      - '443:443'
      - '22:22'
    volumes:
      - './config:/etc/gitlab'
      - './logs:/var/log/gitlab'
      - './data:/var/opt/gitlab'
    shm_size: '256m'
```

## gitlab runner安装
```yaml
services:
  gitlab-runner:
    image: gitlab/gitlab-runner:v17.5.1
    container_name: gitlab-runner
    restart: always
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock' # 这个挂载是将宿主机上的docker socket挂载到了容器内，这样容器内执行的docker命令会被宿主机docker daemon最终执行。  
      - '/srv/gitlab-runner/config:/etc/gitlab-runner' # 这个挂载是将gitlab-runner的配置文件挂载到宿主机上，这样我们可以通过修改宿主机上的这个配置文件对gitlab-runner进行配置  
      - '/srv/gitlab-runner/cache:/cache' # 这个挂载是将gitlab-runner的缓存文件挂载到宿主机上，这样我们可以通过修改宿主机上的这个配置文件对gitlab-runner进行配置  
      - '/root/.m2:/root/.m2' # 这个挂载是将maven缓存挂载到宿主机上  
      - '/root/.npm:/root/.npm' # 这个挂载是将npm缓存挂载到宿主机上  
      - '/root/.local:/root/.local' # 这个挂载是将python缓存挂载到宿主机上
```
注册gitlab-runner
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

# CI/CD方案

远程k8s方案选择有三种，我的需求是能远程调用k8s, 能够填充yml的变量，能够动态编译yml的部份内容，如多ports
以下是这三个镜像的简要对比：

- `alpine/helm`：包含 Helm，一个 Kubernetes 的包管理工具，可以处理模板化的 Kubernetes 配置文件，支持变量填充和动态内容生成。对于你的需求来说，这是最佳选择。

- `bitnami/kubectl`：包含 `kubectl`，一个 Kubernetes 的命令行工具，用于管理 Kubernetes 集群。它可以远程调用 Kubernetes API，但不支持 Helm chart 或模板化的配置文件。

- `alpine/k8s`：这是一个基于 Alpine Linux 的轻量级 Docker 镜像，包含了 Kubernetes 的一些基础工具。具体包含哪些工具取决于镜像的构建方式，可能包含 `kubectl` 或其他 Kubernetes 工具。如果你需要使用 Helm，这个镜像可能无法满足你的需求，除非它也包含了 Helm。


GPT推荐使用 `alpine/helm` 镜像。这是因为 Helm 提供了强大的模板化功能，可以轻松地填充 YAML 文件中的变量，并动态编译部分内容，如多个端口。


总的来说，如果你的需求是远程调用 Kubernetes、填充 YAML 文件的变量，以及动态编译 YAML 文件的部分内容，那么 `alpine/helm` 镜像应该是最佳选择。

# 方案1:  kubectl
这种比较适合简单的项目，因为helm有学习成本
项目的跟路径新建一个模版  `deployment-template.yaml`
```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: my-namespace
spec:
  type: NodePort
  ports:
    - name: my-app
      port: 80 # 端口，dockerfile expose的端口  
      protocol: TCP # 网络协议类型  
      nodePort: 30080 # master 暴露端口  
  selector:
    app: my-app

---

apiVersion: apps/v1
kind: Deployment #对象类型  
metadata:
  name: my-app  #名称  
  namespace: my-namespace
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: nginx-text # docker镜像
          image: nginx:1.26.2-alpine # 镜像tag
          imagePullPolicy: Always # 拉取策率 
          ports:
            - name: http
              containerPort: 80 # 端口，dockerfile expose的端口  
              protocol: TCP
          resources: # 最大限制CPU，最大限制内存，最大限制GPU  
            requests:
              cpu: "1"
              memory: 300Mi
            limits:
              cpu: "1"
              memory: 300Mi
      imagePullSecrets:
        - name: swr-private # 镜像仓库的secret name
```

`gitlab-ci.yaml`文件中如下
```yaml
test_deploy:
  stage: deploy
  image:
    name: bitnami/kubectl:latest
    entrypoint: [""] # 这个必须要
  script:
    # 构建 k8s 可执行环境
    - echo "=============== deploy  ==============="
    # 这个要先配置kubeconfig.yaml，可选环境变量，或者项目文件路径
    - export KUBECONFIG=$(pwd)/deploy/kubeconfig.yaml
    # 使用内网，根据自身情况选择
    - kubectl config use-context internal
    # 删除之前先判断是否有服务运行
    - kubectl delete -f deployment-template.yaml
    # 新建服务
    - kubectl apply -f deployment-template.yaml -n my-namespace
  tags:
    - test
  
```


根据需求发展，可能需要传入yaml中一部分变量，需要用`envsubst`来实现，只需要更改yaml
```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: ${K8S_DEPLOYMENT_NAME}
  namespace: ${K8S_NAMESPACE}
  labels:
    app: ${K8S_DEPLOYMENT_NAME}
spec:
  type: NodePort
  ports:
    - name: ${K8S_DEPLOYMENT_NAME}
      targetPort: ${DOCKERFILE_PORT}
      port: ${DOCKERFILE_PORT} # 端口，dockerfile expose的端口  
      protocol: TCP # 网络协议类型  
      nodePort: ${K8S_PORT} # master 暴露端口  
  selector:
    app: ${K8S_DEPLOYMENT_NAME}

---

apiVersion: apps/v1
kind: Deployment #对象类型  
metadata:
  name: ${K8S_DEPLOYMENT_NAME} #名称  
  namespace: ${K8S_NAMESPACE}
spec:
  replicas: ${K8S_REPLICAS}   # 指定Pod副本数  
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: ${K8S_DEPLOYMENT_NAME}
  template:
    metadata:
      labels:
        app: ${K8S_DEPLOYMENT_NAME}
    spec:
      containers:
        - name: docker-${K8S_DEPLOYMENT_NAME} # 拼接docker-${K8S_DEPLOYMENT_NAME}  
          image: ${REG_URL}/${IMAGE_NAME}:${IMAGE_TAG} # 镜像${REG_URL}/${IMAGE_NAME}:${IMAGE_TAG}  
          imagePullPolicy: Always # 生产是IfNotPresent，测试是Always  
          ports:
            - name: http
              containerPort: ${DOCKERFILE_PORT} # 端口，dockerfile expose的端口  
              protocol: TCP
          resources: # 最大限制CPU，最大限制内存，最大限制GPU  
            requests:
              cpu: ${CONTAINER_CPU}
              memory: ${CONTAINER_MEM}
            limits:
              cpu: ${CONTAINER_CPU}
              memory: ${CONTAINER_MEM}
      imagePullSecrets:
        - name: swr-private # 镜像仓库的secret name
  
```

`gitlab-ci.yaml`中更改为

```yaml
test_deploy:
  stage: deploy
  image:
    name: bitnami/kubectl:latest
    entrypoint: [""] # 必须要这段，否则报错找不到kubectl
  variables:
    IMAGE_NAME: 'nginx' # 镜像名称
    IMAGE_TAG: '1.26.2-alpine'
    DOCKERFILE_PORT: 80 # dockerfile 中暴露的端口
    K8S_PORT: 30080 # k8s 中暴露的端口
    K8S_NAMESPACE: 'my-namespace'  # k8s 命名空间
    K8S_DEPLOYMENT_NAME: 'my-app'  # 项目在 k8s 中部署的名称
    K8S_REPLICAS: 1 # k8s 部署的副本数
    REG_URL: 'registry-harbor:5000' # harbor 镜像仓库
    REG_USERNAME: 'admin' # harbor 账号
    REG_PASSWORD: 'admin123456' # harbor 密码
  script:
    # 配置k8s上下文环境变量
    - export KUBECONFIG=$(pwd)/deploy/kubeconfig.yaml
    # 查看所有的环境变量
    - printenv
    # !!!重点是这一步!!! 会通过环境变量填充模版(包含系统、gitlab-runner等环境变量)
    - envsubst < deployment-template.yaml > deployment.yaml
    # 查看生成的
    - cat deployment.yaml
    # 使用内网环境
    - kubectl config use-context internal
    # 检查服务是否存在
    - DEPLOYMENT_EXISTS=$(kubectl get deployments -n my-namespace | grep my-app || true)
    # 如果服务存在，删除服务
    - if [ -n "$DEPLOYMENT_EXISTS" ]; then kubectl delete -f deployment.yaml -n my-namespace; fi
    # 应用新的部署配置
    - kubectl apply -f deployment.yaml -n my-namespace
tags:
  - test
```

# 方案2: helm
在项目路径下创建charts目录以及文件，如下所示
```
  ├── charts
  │   └── app
  │       ├── Chart.yaml
  │       ├── templates
  │       └── values.yaml
```

`Chart.yaml`
```yaml
apiVersion: v2
name: my-app
description: A Helm chart for my application
version: 1.0.0
```
变量文件 `values.yaml`
```yaml
k8s:
  namespace: my-namespace
  deploymentName: my-app
  replicas: 1
  image:
    name: registry-harbor:5000/library/nginx
    tag: 1.26.2-alpine
  container:
    cpu: 300m
    mem: 300Mi
  ports:
    - name: http
      port: 80 # dockerfile暴露的端口  
      targetPort: 80 # svc service暴露的端口  
      nodePort: 30080 # master暴露端口  
    - name: https
      port: 443
      targetPort: 443
      nodePort: 30443
  imagePullSecrets: swr-private
```

`deployment.yaml`

```yaml
# deployment.yaml  
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.k8s.deploymentName }}
  namespace: {{ .Values.k8s.namespace }}
spec:
  replicas: {{ .Values.k8s.replicas }}
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: {{ .Values.k8s.deploymentName }}
  template:
    metadata:
      labels:
        app: {{ .Values.k8s.deploymentName }}
    spec:
      containers:
        - name: {{ .Values.k8s.deploymentName }}
          image: {{ .Values.k8s.image.name }}:{{ .Values.k8s.image.tag }}
          imagePullPolicy: Always
          ports:
            {{- range .Values.k8s.ports }}
            - name: {{ .name }}
              containerPort: {{ .port }}
              protocol: TCP
            {{- end }}
          resources:
            requests:
              cpu: {{ .Values.k8s.container.cpu }}
              memory: {{ .Values.k8s.container.mem }}
            limits:
              cpu: {{ .Values.k8s.container.cpu }}
              memory: {{ .Values.k8s.container.mem }}
      imagePullSecrets:
        - name: {{ .Values.k8s.imagePullSecrets }}
```

`service.yaml`
```yaml
# service.yaml  
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.k8s.deploymentName }}
  namespace: {{ .Values.k8s.namespace }}
  labels:
    app: {{ .Values.k8s.deploymentName }}
spec:
  type: NodePort
  ports:
    {{- range .Values.k8s.ports }}
    - name: {{ .name }}
      port: {{ .port }}
      protocol: TCP
      targetPort: {{ .targetPort }}
      nodePort: {{ .nodePort }}
    {{- end }}
  selector:
    app: {{ .Values.k8s.deploymentName }}
```

`gitlab-ci.yaml`

```yaml
test_deploy:
  stage: deploy
  image:
    name: alpine/helm:3.16
    entrypoint: [""] # 必须要这段，否则报错
  variables:
    DOCKER_IMAGE_TAG: 'test'
  script:
    # 配置环境变量
    - export KUBECONFIG=$(pwd)/deploy/kubeconfig.yaml
    # 如果是dev这种不会变docker tag的情况，需要判断服务是否存在，删除后新建
    - >
      if helm list -n my-namespace --kube-context internal | grep my-app > /dev/null; then
        echo "Release my-app exists, deleting..."
        helm uninstall my-app -n my-namespace --kube-context internal
      fi
    # 启动服务
    - helm upgrade --install my-app --kube-context internal ./charts/app
  tags:
    - test
```


还可以用`--set命令更改helm中的变量` values.yaml变量优先级是最低的，优先`--set`
```yaml
test_deploy:
  stage: deploy
  image:
    name: alpine/helm:3.16
    entrypoint: [""] # 必须要这段，否则报错  
  variables:
    REG_URL: 'registry-harbor:5000' # harbor 镜像仓库  
    REG_USERNAME: 'admin' # harbor 账号  
    REG_PASSWORD: 'admin123456' # harbor 密码  
    # docker 配置  
    DOCKER_IMAGE_NAME: 'nginx' # 镜像名称  
    DOCKER_IMAGE_TAG: '1.26.2-alpine' # 镜像版本  
    # k8s 配置  
    K8S_NAMESPACE: 'my-namespace'  # k8s 命名空间  
    K8S_DEPLOYMENT_NAME: 'my-app'  # 项目在 k8s 中部署的名称  
    K8S_REPLICAS: 1 # k8s 部署的副本数  
    K8S_CONTAINER_CPU: '1' # 容器 cpu 核数 100m 1 4 7
    K8S_CONTAINER_MEM: '300Mi' # 容器内存 100Mi, 0.1Gi  1024Mi
    K8S_IMAGE_PULL_SECRETS: 'swr-private'
    # port=dockerfile的暴露端口, targetPort=svc service的暴露端口, nodePort=master的暴露端口  
    K8S_PORT: k8s.ports[0].name=http,k8s.ports[0].port=80,k8s.ports[0].targetPort=80,k8s.ports[0].nodePort=30085,k8s.ports[1].name=https,k8s.ports[1].port=443,k8s.ports[1].targetPort=443,k8s.ports[1].nodePort=30086
  script:
    - export KUBECONFIG=$(pwd)/deploy/kubeconfig.yaml # 配置环境变量  
    - >
      if helm list -n $K8S_NAMESPACE --kube-context internal | grep $K8S_DEPLOYMENT_NAME > /dev/null; then
        echo "Release $K8S_DEPLOYMENT_NAME exists, deleting..."
        helm uninstall $K8S_DEPLOYMENT_NAME -n $K8S_NAMESPACE --kube-context internal
      fi
    - helm upgrade --install -n $K8S_NAMESPACE $K8S_DEPLOYMENT_NAME ./charts/app --kube-context internal
      --set k8s.namespace=$K8S_NAMESPACE
      --set k8s.deploymentName=$K8S_DEPLOYMENT_NAME
      --set k8s.replicas=$K8S_REPLICAS
      --set k8s.image.name=$REG_URL/$DOCKER_IMAGE_NAME
      --set k8s.image.tag=$DOCKER_IMAGE_TAG
      --set k8s.container.cpu=$K8S_CONTAINER_CPU
      --set k8s.container.mem=$K8S_CONTAINER_MEM
      --set k8s.imagePullSecrets=$K8S_IMAGE_PULL_SECRETS
      --set $K8S_PORT
  tags:
    - test
  
```
