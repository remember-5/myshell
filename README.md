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



