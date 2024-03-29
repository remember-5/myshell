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
