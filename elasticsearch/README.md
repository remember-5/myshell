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

安装前创建文件夹,赋权,添加默认的配置文件(方便后续修改)

```shell
mkdir -p {config,data,logs,plugins,certs,ingest-pipelines,dictionaries}
sudo chown -R 1000:1000 config data logs plugins certs ingest-pipelines dictionaries
cd config && echo "network.host: 0.0.0.0">>elasticsearch.yml
docker-compose up -d
```
开启认证 ,进入es安装目录下的config目录
`vim elasticsearch.yml`
```yaml
# 配置X-Pack
http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-headers: Authorization
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
```
重启elasticsearch 服务,执行设置用户名和密码的命令，分别需要设置elastic、kibana、logstash_system、beats_system
```shell
cd bin && ./elasticsearch-setup-passwords interactive
```
使用elastic登录即可
