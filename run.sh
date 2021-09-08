# ------------------------------------
# 说明，本脚本只支持centos7+ 并保证在有公网环境下使用
# 默认安装jdk等信息
# ------------------------------------

MY_PATH=$(pwd)
echo "$MY_PATH"

# 更换yum
echo "更换yum"
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum makecache

# ------------------------------------

# 停止firewall
echo "停止firewall"
systemctl stop firewalld.service
systemctl disable firewalld.service

# ------------------------------------

# 安装插件
echo "安装插件"
yum install net-tools lrzsz vim wget unzip tree -y

# ------------------------------------
# 安装docker
echo "安装docker"

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
    http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 安装docker，如果需要指定版本，请更改脚本
yum install -y docker-ce-20.10.6 docker-ce-cli-20.10.6 containerd.io

# 启动docker
systemctl start docker

# 配置文件
touch /etc/docker/daemon.json
>/etc/docker/daemon.json
echo "{\"registry-mirrors\": [\"https://hub-mirror.c.163.com\",\"https://docker.mirrors.ustc.edu.cn\"]}" >>/etc/docker/daemon.json
systemctl daemon-reload
systemctl restart docker

# ------------------------------------

# 安装docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version

# ------------------------------------

mkdir -p /data/package
cd /data/package
# 安装nginx
# 安装插件
yum -y install make gcc gcc-c++ zlib zlib-devel libtool automake openssl openssl-devel pcre pcre-devel
wget https://nginx.org/download/nginx-1.20.1.tar.gz
tar zxvf nginx-1.20.1.tar.gz
cd nginx-1.20.1
./configure --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-stream
make && make install
# 查看nginx版本
/usr/local/nginx/sbin/nginx -v
# ------------------------------------

# 安装jdk
wget https://mirrors.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz
tar zxvf jdk-8u202-linux-x64.tar.gz
mv jdk1.8.0_202 /usr/local

## 创建profile.d下的文件
cp .env/jdk.sh /etc/profile.d
source /etc/profile
java -version

# 安装maven
wget https://mirror-hk.koddos.net/apache/maven/maven-3/3.8.2/binaries/apache-maven-3.8.2-bin.tar.gz
tar zxvf apache-maven-3.8.2-bin.tar.gz
mv apache-maven-3.8.2 /usr/local
cp .env/maven.sh /etc/profile.d
source /etc/profile
mvn -v
# ------------------------------------

# 安装nodejs

wget https://nodejs.org/dist/v14.17.5/node-v14.17.5-linux-x64.tar.xz
tar xvf node-v14.17.5-linux-x64.tar.xz
mv node-v14.17.5-linux-x64 /usr/local
cp .env/nodejs.sh /etc/profile.d
source /etc/profile
node -v

npm config set registry https://registry.npm.taobao.org
npm i yarn -g

# ------------------------------------

# gitlab-runner
# 更新git
yum install -y http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm
# 安装git
yum install -y git
# 更新git
yum update git
# 下载gitlab-runner
wget https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
cp gitlab-runner-linux-amd64 /usr/local/bin/gitlab-runner
chmod +x /usr/local/bin/gitlab-runner
gitlab-runner install -n "gitlab-runner" -u root
gitlab-runner start

# ------------------------------------
# 安装mysql
mkdir -p /data/mysql/data /data/mysql/conf /data/mysql/logs
cd "$MY_PATH/mysql" && docker-compose up -d

# 安装redis
mkdir -p /data/redis/data /data/redis/logs
cd "$MY_PATH/redis" && docker-compose up -d

# 安装rabbitmq
mkdir -p /data/rabbitmq
cd "$MY_PATH/rabbitmq" && docker-compose up -d

# 安装minio
mkdir -p /data/minio/data /data/minio/config
cd "$MY_PATH/minio" && docker-compose up -d
