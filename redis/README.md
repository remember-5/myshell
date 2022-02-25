## 单机结构
mkdir -p /data/redis/conf /data/redis/data /data/redis/logs
参考 `docker-compose.yml`

参数配置：
1.修改保护模式protected-mode yes 默认为yes 可以跳过这一步
Redis protected-mode属性解读
设置外部网络连接redis服务，设置说明如下：
a.关闭protected-mode模式，此时外部网络可以直接访问
b.开启protected-mode保护模式，需配置bind ip 和设置访问密码 redis3.2版本后新增protected-mode配置，默认是yes，即开启。

2.把bind 127.0.0.1 注释掉 #bind 127.0.0.1, 这样所有的ip都可以访问了
3.设置密码（根据自己的需要）
设置永久密码的方法
找到requirepass foobared 把foobared改为自己的登陆密码 这里我设置为123456
requirepass 123456

设置临时密码的方法

在连接上redis后,config set设置临时密码,redis重启后,设置的密码就失效了

## 单机集群

参考machine-cluster下的  `docker-compose.yml`

