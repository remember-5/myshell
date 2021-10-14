# 安装

## 创建文件

```
sh init.sh ${IP地址}
```


## 安装redis集群
```
docker-compose up -d
```


## 配置集群
```
docker exec -it redis-6379 /bin/bash
redis-cli  -a 之前设置的密码 --cluster create 配置文件中的IP地址:6379 IP地址:6380 IP地址:6381 IP地址:6382 IP地址:6383 IP地址:6384   --cluster-replicas 1
```