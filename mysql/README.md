# 忽略表名大小写
在`docker-compose.yaml`中添加，如果数据库已经存在db文件，需要删除所有的文件后，重新构建容器
```yaml
version: '3'
services:
  mysql:
    # 忽律表名大小写
    command: --lower-case-table-names=1
```

# 安装审计插件Percona

mysql = v8.4


```shell
# docke安装的mysql，按照官方文档中，可以直接给so文件，找到对应mysql版本的插件。
# 下载链接 https://docs.percona.com/percona-server/8.4/binary-tarball-install.html
# 对应版本 https://docs.percona.com/percona-server/8.4/binary-tarball-names.html

wget https://downloads.percona.com/downloads/Percona-Server-8.4/Percona-Server-8.4.5-5/binary/tarball/Percona-Server-8.4.5-5-Linux.x86_64.glibc2.34-minimal.tar.gz

tar -xvf Percona-Server-8.4.5-5-Linux.x86_64.glibc2.34-minimal.tar.gz

# 确保组件文件在正确的位置
cp Percona-Server-8.4.5-5-Linux.x86_64.glibc2.34-minimal/lib/plugin/component_audit_api_message_emit.so /usr/lib/mysql/plugins
cp Percona-Server-8.4.5-5-Linux.x86_64.glibc2.34-minimal/lib/plugin/component_audit_log_filter.so /usr/lib/mysql/plugins

# 设置正确权限
chmod 644 /usr/lib/mysql/plugin/component_audit_api_message_emit.so
chmod 644 /usr/lib/mysql/plugin/component_audit_log_filter.so


# 创建审计配置文件
cat > /etc/mysql/conf.d/audit.cnf << 'EOF'
[mysqld]
# 启用审计组件
audit_log_format=JSON
audit_log_policy=ALL
audit_log_file=/var/lib/mysql/audit.log
audit_log_rotate_on_size=1073741824
audit_log_rotations=8
audit_log_buffer_size=16777216
EOF

# 创建审计日志文件并设置权限
touch /var/lib/mysql/audit.log
chown mysql:mysql /var/lib/mysql/audit.log
chmod 640 /var/lib/mysql/audit.log

##  重新安装（按正确顺序）
INSTALL COMPONENT 'file://component_audit_api_message_emit';
INSTALL COMPONENT 'file://component_audit_log_filter';


# 执行sql

cat Percona-Server-8.4.5-5-Linux.x86_64.glibc2.34-minimal/share/audit_log_filter_linux_install.sql


# 


```


```sql
-- 检查表是否存在
SHOW TABLES FROM mysql LIKE 'audit_log%';
-- 查看表结构（确认已正确创建）
DESCRIBE mysql.audit_log_filter;
DESCRIBE mysql.audit_log_user;


-- 安装审计组件（如果尚未安装）
INSTALL COMPONENT 'file://component_audit_log_filter';
INSTALL COMPONENT 'file://component_audit_api_message_emit';

-- 确认组件已安装
SELECT component_urn FROM mysql.component WHERE component_urn LIKE '%audit%';


-- 创建一个捕获所有事件的审计过滤器
INSERT INTO mysql.audit_log_filter (NAME, FILTER)
VALUES ('log_all', '{"filter": {"log": true}}');

-- 确认过滤器已创建
SELECT * FROM mysql.audit_log_filter;


-- 为所有现有用户分配审计过滤器
INSERT INTO mysql.audit_log_user (USERNAME, USERHOST, FILTERNAME)
SELECT
    user,
    host,
    'log_all'
FROM
    mysql.user
WHERE
    user NOT IN ('mysql.session', 'mysql.sys', 'debian-sys-maint');

-- 确认分配成功
SELECT * FROM mysql.audit_log_user;


-- 启用审计日志
SET GLOBAL audit_log_filter.disable = OFF;

-- 刷新权限使更改生效
FLUSH PRIVILEGES;

-- 确认审计已启用
SHOW VARIABLES LIKE 'audit_log_filter.disable';

     
-- 执行一些测试操作
CREATE DATABASE IF NOT EXISTS test_audit;
USE test_audit;
CREATE TABLE test_table (id INT, name VARCHAR(50));
INSERT INTO test_table VALUES (1, 'test');
SELECT * FROM test_table;
DROP TABLE test_table;
DROP DATABASE test_audit;

-- 创建存储过程，为新用户自动分配审计
DELIMITER //
CREATE PROCEDURE audit_new_user()
BEGIN
INSERT INTO mysql.audit_log_user (USERNAME, USERHOST, FILTERNAME)
SELECT
    user,
    host,
    'log_all'
FROM
    mysql.user u
        LEFT JOIN
        
    mysql.audit_log_user a ON u.user = a.USER AND u.host = a.HOST
WHERE
    a.USER IS NULL
  AND
    u.user NOT IN ('mysql.session', 'mysql.sys', 'debian-sys-maint');
END //
DELIMITER ;

-- 创建事件，定期为新用户分配审计
CREATE EVENT IF NOT EXISTS audit_new_users_event
ON SCHEDULE EVERY 1 HOUR
DO CALL audit_new_user();


     
```


!!!安装完记得重启!!!


日志`/var/lib/mysql/audit_filter.log`
