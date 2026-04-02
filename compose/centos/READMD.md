- docker-compose.yml 是直接运行centos


启动完后会直接关闭容器，因为没有阻塞控制台，添加以下参数来阻塞控制台
```yml
stdin_open: true # docker run -i
tty: true # docker run -t
```
