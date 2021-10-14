for port in $(seq 6379 6384); do
mkdir -p ./node-${port}/conf
touch ./node-${port}/conf/redis.conf
cat <<EOF >./node-${port}/conf/redis.conf
# 指定端口
port ${port}
requirepass 1234
# 绑定地址
bind 0.0.0.0
# 关闭保护模式
protected-mode no
daemonize no
# 追加的方式记录所有写操作的命令到磁盘文件
appendonly yes
# 启用集群
cluster-enabled yes
# 集群配置文件
cluster-config-file nodes.conf
# 集群节点连接超时时间
cluster-node-timeout 5000
# 配置ip
cluster-announce-ip $1
cluster-announce-port ${port}
cluster-announce-bus-port 1${port}
EOF
done
