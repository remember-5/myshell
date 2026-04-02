## 镜像区别
拉取`RabbitMQ`镜像

镜像未配有控制台

`docker pull rabbitmq`

镜像配有控制台

`docker pull rabbitmq:management`

注意：rabbitmq是官方镜像，该镜像不带控制台。如果要安装带控制台的镜像，需要在拉取镜像时附带tag标签，例如：management。tag标签可以通过https://hub.docker.com/_/rabbitmq?tab=tags来查询。


## 安装服务
```shell
docker-compose up -d
```


## 管理RabbitMQ
```shell
docker stop rabbitmq
docker start rabbitmq
docker restart rabbitmq
```

## 控制台信息

启动容器后，可以浏览器中访问http://localhost:15672来查看控制台信息。 RabbitMQ默认的用户名：guest，密码：guest

## 安装插件

### 延迟队列


下载地址：https://www.rabbitmq.com/community-plugins.html

rabbitmq_delayed_message_exchange

添加到docker容器内
```shell
docker cp xxx.ez ID:/home
docker exec -it ID bash
cp /home/xxx.ez /plugins
rabbitmq-plugins enable rabbitmq_delayed_message_exchange
```




