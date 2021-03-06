# ------------------------------------
# 说明，本脚本只支持centos7+ 并保证在有公网环境下使用
# 默认安装jdk等信息
# ------------------------------------

MY_PATH=$(pwd)
echo "$MY_PATH"

echo "====================更换yum===================="
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum makecache

# ------------------------------------

echo "====================停止firewall===================="
systemctl stop firewalld.service
systemctl disable firewalld.service

# ------------------------------------

echo "====================安装插件===================="
yum install net-tools lrzsz vim wget unzip tree -y

# ------------------------------------

echo "====================安装docker===================="
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
yum install -y docker-ce-20.10.16 docker-ce-cli-20.10.16 containerd.io

# 启动docker
systemctl start docker

# 配置文件
touch /etc/docker/daemon.json
>/etc/docker/daemon.json
echo "{\"registry-mirrors\": [\"https://hub-mirror.c.163.com\"]}" >>/etc/docker/daemon.json
systemctl daemon-reload
systemctl restart docker

# ------------------------------------

echo "====================安装docker-compose===================="
curl -L "https://github.com/docker/compose/releases/download/v2.6.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version

# ------------------------------------

echo "====================安装nginx===================="
mkdir -p /data/package && cd /data/package
# 安装插件
yum -y install make gcc gcc-c++ zlib zlib-devel libtool automake openssl openssl-devel pcre pcre-devel
wget https://nginx.org/download/nginx-1.22.0.tar.gz
tar zxvf nginx-1.22.0.tar.gz && cd nginx-1.22.0
./configure --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-stream
make && make install
# 查看nginx版本
/usr/local/nginx/sbin/nginx -v
mkdir -p /usr/local/nginx/conf/conf.d
rm -rf /usr/local/nginx/conf/nginx.conf
cp $MY_PATH/config/nginx/nginx.conf /usr/local/nginx/conf
cp $MY_PATH/config/nginx/default.conf /usr/local/nginx/conf/conf.d/
cp $MY_PATH/config/nginx/https.conf /usr/local/nginx/conf/conf.d/

# ------------------------------------

echo "====================安装jdk===================="
cd /data/package
wget https://d6.injdk.cn/oraclejdk/8/jdk-8u301-linux-x64.tar.gz
tar zxvf jdk-8u301-linux-x64.tar.gz
mv jdk1.8.0_301 /usr/local

## 创建profile.d下的文件
cp $MY_PATH/.env/jdk.sh /etc/profile.d
source /etc/profile
java -version

# ------------------------------------

echo "====================安装maven===================="
cd /data/package
wget https://dlcdn.apache.org/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz --no-check-certificate
tar zxvf apache-maven-3.8.6-bin.tar.gz
mv apache-maven-3.8.6 /usr/local
cp $MY_PATH/.env/maven.sh /etc/profile.d
source /etc/profile
mvn -v
/bin/cp -rf $MY_PATH/config/maven/settings.xml /usr/local/apache-maven-3.8.6/conf/

# ------------------------------------

echo "====================安装nodejs===================="
wget https://nodejs.org/dist/v14.19.3/node-v14.19.3-linux-x64.tar.gz
tar xvf node-v14.19.3-linux-x64.tar.gz
mv node-v14.19.3-linux-x64 /usr/local
cp $MY_PATH/.env/nodejs.sh /etc/profile.d
source /etc/profile
node -v

npm config set registry https://registry.npm.taobao.org
npm i yarn pnpm rimraf -g

# ------------------------------------

echo "====================安装gitlab-runner===================="
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
ln -s /usr/local/bin/gitlab-runner /usr/bin/gitlab-runner
gitlab-runner install -n "gitlab-runner" --user=root --working-directory=/data/gitlab-runner
gitlab-runner start

echo "====================全部安装完成===================="

# ------------------------------------
## 安装mysql
#mkdir -p /data/mysql/data /data/mysql/conf /data/mysql/logs
#cd "$MY_PATH/mysql" && docker-compose up -d
#
## 安装redis
#mkdir -p /data/redis/data /data/redis/logs
#cd "$MY_PATH/redis" && docker-compose up -d
#
## 安装rabbitmq
#mkdir -p /data/rabbitmq
#cd "$MY_PATH/rabbitmq" && docker-compose up -d
#
## 安装minio
#mkdir -p /data/minio/data /data/minio/config
#cd "$MY_PATH/minio" && docker-compose up -d
