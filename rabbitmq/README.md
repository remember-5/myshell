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




