#!/bin/bash

# 配置runner的环境变量
gitlab_register=""
gitlab_token=""
gitlab_tags=""

echo "====================设置代理===================="
cat >> ~/.bashrc << EOF
# 开启代理
function proxy_on(){
    #export ALL_PROXY=socks5://127.0.0.1:1080
    export http_proxy=http://10.4.15.113:29999
    export https_proxy=http://10.4.15.113:29999
    echo -e "已开启代理"
}
# 关闭代理
function proxy_off(){
    #unset ALL_PROXY
    unset http_proxy
    unset https_proxy
    echo -e "已关闭代理"
}
# 执行proxy_off，即默认关闭代理
proxy_off
EOF
source ~/.bashrc


echo "====================安装jdk===================="
wget http://10.4.15.114:9000/package/jdk-8u341-linux-x64.tar.gz
tar zxvf jdk-8u341-linux-x64.tar.gz
mv jdk1.8.0_341 /usr/local
## 创建profile.d下的文件
cat > /etc/profile.d/jdk.sh << 'EOF'
export JAVA_HOME=/usr/local/jdk1.8.0_341
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
EOF

echo "====================安装maven===================="
wget http://10.4.15.114:9000/package/apache-maven-3.8.6.tar.gz
tar zxvf apache-maven-3.8.6.tar.gz
mv apache-maven-3.8.6 /usr/local
cat > /etc/profile.d/maven.sh << 'EOF'
export MAVEN_HOME=/usr/local/apache-maven-3.8.6
export PATH=$MAVEN_HOME/bin:$PATH
EOF

echo "====================安装nodejs===================="
wget http://10.4.15.114:9000/package/node-v14.21.1-linux-x64.tar.gz
tar zxvf node-v14.21.1-linux-x64.tar.gz
mv node-v14.21.1-linux-x64 /usr/local
cat > /etc/profile.d/nodejs.sh << 'EOF'
export NODEJS_HOME=/usr/local/node-v14.21.1-linux-x64
export PATH=${NODEJS_HOME}/bin:${PATH}
EOF

# 并设置阿里云镜像
proxy_on
npm config set registry https://registry.npmmirror.com
npm i yarn pnpm rimraf -g
proxy_off

echo "====================安装git===================="
wget http://10.4.15.114:9000/package/git-2.31.1-1.WANdisco.1657096008.x86_64.rpm
rpm -Uvh --force --nodeps *.rpm

echo "====================安装gitlab-runner===================="
wget http://10.4.15.114:9000/package/gitlab-runner-linux-amd64
cp gitlab-runner-linux-amd64 /usr/local/bin/gitlab-runner
chmod +x /usr/local/bin/gitlab-runner
ln -s /usr/local/bin/gitlab-runner /usr/bin/gitlab-runner
mkdir -p /data/gitlab-runner
gitlab-runner install -n "gitlab-runner" --user=root --working-directory=/data/gitlab-runner
gitlab-runner start

# 获取需要安装的ip地址
function getIpAddr(){
	# 获取IP命令
	ipaddr=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
	array=(`echo $ipaddr | tr '\n' ' '` ) 	# IP地址分割，区分是否多网卡
	#array=(172.20.32.214 192.168.1.10);
	num=${#array[@]}  						#获取数组元素的个数
  echo "${num}"
  echo "${array[*]}"
	# 选择安装的IP地址
	if [ $num -eq 1 ]; then
		#echo "*单网卡"
		local_ip=${array[*]}
	elif [ $num -gt 1 ];then
		echo -e "\033[035m******************************\033[0m"
		echo -e "\033[036m*    请选择安装的IP地址		\033[0m"
    for key in ${!array[*]}
    do
      echo -e "\033[032m*  $key : ${array[$key]}		\033[0m"
    done
		echo -e "\033[035m******************************\033[0m"
		#选择需要安装的服务类型
		input=""
		while :
		do
			read -r -p "*请选择安装的IP地址(序号): " input
			if [ $input -gt $num ]; then
			  echo "请输入正确的ip序列号"
      else
        local_ip=${array[$input]}
        echo "选择网段 $input 的IP为：${local_ip}"
        break
      fi
		done
	else
		echo -e "\033[31m*未设置网卡IP，请检查服务器环境！ \033[0m"
		exit 1
	fi
}

# 校验IP地址合法性
function isValidIp() {
	local ip=$1
	local ret=1

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		ip=(${ip//\./ }) # 按.分割，转成数组，方便下面的判断
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		ret=$?
	fi
	return $ret
}

local_ip=''

getIpAddr	#自动获取IP
isValidIp ${local_ip}	# IP校验
if [ $? -ne 0 ]; then
	echo -e "\033[31m*自动获取的IP地址无效，请重试！ \033[0m"
	exit 1
fi
echo "*选择安装的IP地址为：${local_ip}"

gitlab_tags=$local_ip

sudo gitlab-runner register \
  --non-interactive \
  --url $gitlab_register \
  --registration-token $gitlab_token \
  --executor "shell" \
  --description "ideal-runner" \
  --maintenance-note "Free-form maintainer notes about this runner" \
  --tag-list "$gitlab_tags" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected"


echo "====================安装完成============================"

source /etc/profile

echo "**************java version******************"
java -version

echo "**************maven version******************"
mvn -v

echo "**************nodejs version******************"
node -v

echo "**************git version******************"
git --version

echo "**************gitlab-runner version******************"
gitlab-runner --version


