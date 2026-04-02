# 启动脚本
# /bin/bash -c "$(curl -fsSL http://10.4.15.114:9000/package/1go.sh)"
# 删除安装包
rm -rf jdk-8u341-linux-x64.tar.gz node-v14.21.1-linux-x64.tar.gz apache-maven-3.8.6.tar.gz gitlab-runner-linux-amd64 git-2.31.1-1.WANdisco.1657096008.x86_64.rpm
# 删除gitlab
gitlab-runner stop
rm -rf /etc/gitlab-runner/config.toml /usr/local/bin/gitlab-runner /usr/bin/gitlab-runner /data/gitlab-runner /etc/systemd/system/gitlab-runner.service
# 删除配置
rm -rf /etc/profile.d/maven.sh /etc/profile.d/nodejs.sh /etc/profile.d/maven.sh
rm -rf /usr/local/jdk1.8.0_341 /usr/local/apache-maven-3.8.6 /usr/local/node-v14.21.1-linux-x64
# .bashrc

source /etc/profile && source ~/.bashrc



# 校验
#- [x] java
#- [] maven
#- [x] nodejs
#- [x] git
#- [x] gitlab-runner
#- [x] ip
