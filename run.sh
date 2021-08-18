# ------------------------------------
# 说明，本脚本只支持centos7+ 并保证在有公网环境下使用
# 默认安装jdk等信息
# ------------------------------------

# 1. 更换yum
echo "更换yum"
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum makecache

# 2. 停止firewall
echo "停止firewall"
systemctl stop firewalld.service
systemctl disable firewalld.service 

# 3. 安装插件
echo "安装插件"
yum install net-tools lrzsz vim wget unzip -y

# 4. 安装docker
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
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# 安装docker，如果需要指定版本，请更改脚本
yum install -y docker-ce-20.10.6 docker-ce-cli-20.10.6 containerd.io

# 启动docker
systemctl start docker

# 配置文件
touch /etc/docker/daemon.json
# TODO 这个位置要修改
echo "{\"registry-mirrors\": [\"https://fgb5kwgr.mirror.aliyuncs.com\"]}" >> /etc/docker/daemon.json
systemctl daemon-reload
systemctl restart docker

# 安装docker-compose

# 5. 安装nginx
yum -y install make gcc gcc-c++ zlib zlib-devel libtool automake openssl openssl-devel pcre pcre-devel
wget https://nginx.org/download/nginx-1.20.1.tar.gz
tar zxvf nginx-1.20.1.tar.gz
./configure --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-pcre=/server/pcre-8.35 --with-stream
make && make install

# 6. 安装jdk





# 7. 安装nodejs

# 8. gitlab-runner
# 因为需要更新git
# 安装源
yum install -y http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm
# 安装git
yum install -y git
# 更新git
yum update git

# 9.安装mysql
./mysql/docker-compose up -d 
# 10.安装redis

# 11. 安装rabbitmq
