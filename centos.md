# centos7常用命令

## 更换yum源
```shell
# 备份原repo
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
# 下载阿里云的仓库
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# epel(RHEL 7)
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
yum makecache
```

## 关闭防火墙
```shell
systemctl stop firewalld
systemctl disable firewalld
```

## yum常用插件
```shell
yum install net-tools lrzsz vim wget unzip tree git -y
```
## 安装docker
```shell
# 卸载原有docker
yum remove docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-engine

# 安装docker插件
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

# 设置docker仓库
sudo yum-config-manager \
    --add-repo \
    https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

sudo sed -i 's/download.docker.com/mirrors.aliyun.com\/docker-ce/g' /etc/yum.repos.d/docker-ce.repo

# 安装docker，如果需要指定版本，请更改脚本
yum install -y docker-ce-${DOCKER_VERSION} docker-ce-cli-${DOCKER_VERSION} containerd.io docker-buildx-plugin docker-compose-plugin

# 启动docker
systemctl start docker
systemctl enable docker

# 配置文件
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "https://fgb5kwgr.mirror.aliyuncs.com",
    "https://registry.docker-cn.com"
  ]
}
EOF
systemctl daemon-reload
systemctl restart docker
```

## docker-compose安装
```shell
curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

## nginx安装
```shell
yum -y install make gcc gcc-c++ zlib zlib-devel libtool automake openssl openssl-devel pcre pcre-devel
wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar zxvf nginx-${NGINX_VERSION}.tar.gz && cd nginx-${NGINX_VERSION}
./configure --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-stream
make && make install
# 查看nginx版本
/usr/local/nginx/sbin/nginx -v
```

## 安装jdk
```shell
wget https://d6.injdk.cn/oraclejdk/8/jdk-8u341-linux-x64.tar.gz
tar zxvf jdk-8u341-linux-x64.tar.gz
mv jdk1.8.0_341 /usr/local
## 创建profile.d下的文件
cat > /etc/profile.d/jdk.sh << 'EOF'
export JAVA_HOME=/usr/local/jdk1.8.0_341
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
EOF
```

## 安装maven
```shell
wget https://dlcdn.apache.org/maven/maven-3/3.9.2/binaries/apache-maven-3.9.2-bin.tar.gz --no-check-certificate
tar zxvf apache-maven-3.9.2-bin.tar.gz
mv apache-maven-3.9.2 /usr/local
cat > /etc/profile.d/maven.sh << 'EOF'
export MAVEN_HOME=/usr/local/apache-maven-3.9.2
export PATH=${MAVEN_HOME}/bin:${PATH}
EOF
```

## 安装nodejs
```shell
wget https://nodejs.org/dist/v14.21.2/node-${NODE_JS_VERSION}-linux-x64.tar.gz
tar zxvf node-${NODE_JS_VERSION}-linux-x64.tar.gz
mv node-${NODE_JS_VERSION}-linux-x64 /usr/local
cat > /etc/profile.d/nodejs.sh << 'EOF'
export NODEJS_HOME=/usr/local/node-${NODE_JS_VERSION}-linux-x64
export PATH=${NODEJS_HOME}/bin:${PATH}
EOF
# 更改为npm mirror
npm config set registry https://registry.npmmirror.com
npm i yarn pnpm rimraf -g
```

## gitlab-runner安装
```shell
# 更新git
#yum install -y http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm
yum install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm
# 安装git
yum install -y git
# 更新git
yum update git
# 下载gitlab-runner
wget https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
cp gitlab-runner-linux-amd64 /usr/local/bin/gitlab-runner
chmod +x /usr/local/bin/gitlab-runner
ln -s /usr/local/bin/gitlab-runner /usr/bin/gitlab-runner
mkdir -p /data/gitlab-runner
gitlab-runner install -n "gitlab-runner" --user=root --working-directory=/data/gitlab-runner
gitlab-runner start
```
