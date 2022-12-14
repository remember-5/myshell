# 官方支持图

https://www.elastic.co/cn/support/matrix
安装之前线查看系统版本和jdk版本

参数配置文档 https://www.elastic.co/guide/en/elasticsearch/reference/index.html

## 6.8.6安装

```shell
mkdir -p data config plugins
chmod 775 -R $(pwd)
cp elasticsearch.yml config
docker-compost up -d
```

## 7.17.3

目前没有挂在配置

```shell
mkdir -p elasticsearch-data elasticsearch-plugins
chmod -R 777 $(pwd)
docker-compose up -d
```
