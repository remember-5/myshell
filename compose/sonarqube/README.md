## 安装
安装前先执行以下4句话

```shell script
sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=65536
ulimit -n 65536
ulimit -u 4096
```


# 迁移

## 备份

```bash
# 暂停服务
docker compose down

# 先备份数据库，可以备份sql文件
# 自行操作



# 备份sonar文件
BACKUP_DIR=/data/sonarqube/backup
sudo cp -rp /var/lib/docker/volumes/sonarqube_conf/_data $BACKUP_DIR/conf
sudo cp -rp /var/lib/docker/volumes/sonarqube_extensions/_data $BACKUP_DIR/extensions
sudo cp -rp /var/lib/docker/volumes/sonarqube_data/_data $BACKUP_DIR/data
sudo cp -rp /var/lib/docker/volumes/sonarqube_logs/_data $BACKUP_DIR/logs

```


## 恢复

```bash
# 先只启动数据库服务
docker-compose up -d sonarqube-db
# 等待数据库初始化完成（约10-20秒）
docker-compose logs -f sonarqube-db
# 看到 "database system is ready to accept connections" 即可

# 先删除默认创建的空数据库
docker exec -it sonarqube-db psql -U sonarqube -d postgres -c "DROP DATABASE sonarqube;"
docker exec -it sonarqube-db psql -U sonarqube -d postgres -c "CREATE DATABASE sonarqube;"
# 再导入备份
docker exec -i sonarqube-db psql -U sonarqube -d sonarqube < /path/to/your/backup.sql


# 停止所有服务
docker-compose down
# 找到 Docker 卷的实际存储路径（通常在 /var/lib/docker/volumes/）
docker volume inspect <项目名>_sonarqube_data
docker volume inspect <项目名>_sonarqube_extensions
docker volume inspect <项目名>_sonarqube_conf
docker volume inspect <项目名>_sonarqube_logs
# 恢复数据到对应卷（假设你的备份在 /backup 目录）
# 替换 <项目名> 为你的实际项目名称
sudo cp -r /backup/sonarqube_data/* /var/lib/docker/volumes/<项目名>_sonarqube_data/_data/
sudo cp -r /backup/sonarqube_extensions/* /var/lib/docker/volumes/<项目名>_sonarqube_extensions/_data/
sudo cp -r /backup/sonarqube_conf/* /var/lib/docker/volumes/<项目名>_sonarqube_conf/_data/
sudo cp -r /backup/sonarqube_logs/* /var/lib/docker/volumes/<项目名>_sonarqube_logs/_data/


# 恢复权限

# 日志文件可以不要
sudo chown -R 1000:1000 /var/lib/docker/volumes/sonarqube_sonarqube_conf/_data
sudo chown -R 1000:1000 /var/lib/docker/volumes/sonarqube_sonarqube_data/_data
sudo chown -R 1000:1000 /var/lib/docker/volumes/sonarqube_sonarqube_extensions/_data

sysctl -w vm.max_map_count=262144
sysctl -w fs.file-max=65536
ulimit -n 65536
ulimit -u 4096



```
