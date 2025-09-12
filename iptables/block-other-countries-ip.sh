
#!/bin/bash
# Allow-Only-China-IPs
# 基于原脚本修改，实现只允许中国IP访问

Green="\033[32m"
Red="\033[31m"
Font="\033[0m"

# root权限检查
root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}Error:This script must be run as root!${Font}" 1>&2
        exit 1
    fi
}

# 检查系统版本
check_release(){
    if [ -f /etc/redhat-release ]; then
        release="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    fi
}

# 检查ipset是否安装
check_ipset(){
    if [ -f /sbin/ipset ]; then
        echo -e "${Green}检测到ipset已存在，并跳过安装步骤！${Font}"
    elif [ "${release}" == "centos" ]; then
        yum -y install ipset
    else
        apt-get -y install ipset
    fi
}

# 启用中国IP白名单
enable_china_whitelist(){
    check_ipset
    
    echo -e "${Green}正在下载中国IP数据...${Font}"
    wget -P /tmp http://www.ipdeny.com/ipblocks/data/countries/cn.zone 2> /dev/null
    
    # 检查下载是否成功
    if [ -f "/tmp/cn.zone" ]; then
        echo -e "${Green}中国IP数据下载成功！${Font}"
    else
        echo -e "${Red}下载失败，请检查网络连接！${Font}"
        exit 1
    fi
    
    # 创建中国IP集合
    ipset -N china-ips hash:net
    for i in $(cat /tmp/cn.zone); do 
        ipset -A china-ips $i
    done
    rm -f /tmp/cn.zone
    
    echo -e "${Green}中国IP规则添加成功！${Font}"
    
    # 备份当前规则
    echo -e "${Green}备份当前防火墙规则...${Font}"
    iptables-save > /tmp/iptables_backup_$(date +%Y%m%d_%H%M%S)
    
    # 设置白名单规则
    echo -e "${Green}配置防火墙白名单规则...${Font}"
    
    # 允许已建立的连接和本地回环
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    
    # 允许SSH连接（防止被锁在外面）
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # 允许中国IP访问GitLab端口
    iptables -A INPUT -p tcp -m set --match-set china-ips src --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp -m set --match-set china-ips src --dport 443 -j ACCEPT
    
    # 拒绝其他所有IP
    iptables -A INPUT -p tcp --dport 80 -j DROP
    iptables -A INPUT -p tcp --dport 443 -j DROP
    
    echo -e "${Green}中国IP白名单配置成功！${Font}"
    echo -e "${Green}现在只有中国IP可以访问您的GitLab服务！${Font}"
}

# 禁用白名单
disable_china_whitelist(){
    echo -e "${Green}正在移除中国IP白名单...${Font}"
    
    # 删除相关规则
    iptables -D INPUT -p tcp -m set --match-set china-ips src --dport 80 -j ACCEPT 2>/dev/null
    iptables -D INPUT -p tcp -m set --match-set china-ips src --dport 443 -j ACCEPT 2>/dev/null
    iptables -D INPUT -p tcp --dport 80 -j DROP 2>/dev/null
    iptables -D INPUT -p tcp --dport 443 -j DROP 2>/dev/null
    
    # 删除ipset集合
    ipset destroy china-ips 2>/dev/null
    
    echo -e "${Green}中国IP白名单已移除！${Font}"
}

# 查看当前规则
show_rules(){
    echo -e "${Green}当前防火墙规则：${Font}"
    iptables -L -n | grep -E "(china-ips|80|443)"
    echo -e "${Green}当前IPset集合：${Font}"
    ipset list
}

# 主菜单
main(){
    root_need
    check_release
    clear
    echo -e "———————————————————————————————————————"
    echo -e "${Green}GitLab 中国IP白名单管理工具${Font}"
    echo -e "${Green}1、启用中国IP白名单${Font}"
    echo -e "${Green}2、禁用中国IP白名单${Font}"
    echo -e "${Green}3、查看当前规则${Font}"
    echo -e "${Green}4、退出${Font}"
    echo -e "———————————————————————————————————————"
    read -p "请输入数字 [1-4]:" num
    case "$num" in
        1)
            enable_china_whitelist
            ;;
        2)
            disable_china_whitelist
            ;;
        3)
            show_rules
            ;;
        4)
            echo -e "${Green}退出程序${Font}"
            exit 0
            ;;
        *)
            clear
            echo -e "${Red}请输入正确数字 [1-4]${Font}"
            sleep 2s
            main
            ;;
    esac
}

main

