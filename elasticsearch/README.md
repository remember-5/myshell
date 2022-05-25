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