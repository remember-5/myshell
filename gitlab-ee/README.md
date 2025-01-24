# Introduction

https://docs.gitlab.com/ee/install/docker/installation.html#install-gitlab-by-using-docker-compose


原本镜像`ghcr.io/lakr233/gitlab-license-generator:main` 

用nju的镜像加速


```shell
docker run --rm -it \
  -v "./build:/license-generator/build" \
  -e LICENSE_NAME="Tim Cook" \
  -e LICENSE_COMPANY="Apple Computer, Inc." \
  -e LICENSE_EMAIL="tcook@apple.com" \
  -e LICENSE_PLAN="ultimate" \
  -e LICENSE_USER_COUNT="2147483647" \
  -e LICENSE_EXPIRE_YEAR="2500" \
  --entrypoint /bin/bash \
  ghcr.nju.edu.cn/lakr233/gitlab-license-generator:main \
  -c "chmod +x ./make.sh ./src/scan.features.rb && ./make.sh"

```

```shell
volumes:
- "./build/public.key:/opt/gitlab/embedded/service/gitlab-rails/.license_encryption_key.pub"

```
