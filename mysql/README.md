# 忽略表名大小写
在`docker-compose.yaml`中添加，如果数据库已经存在db文件，需要删除所有的文件后，重新构建容器
```yaml
version: '3'
services:
  mysql:
    # 忽律表名大小写
    command: --lower-case-table-names=1
```
