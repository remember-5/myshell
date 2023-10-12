// 连接到 admin 数据库, 创建用户
db.getSiblingDB('admin').createUser({
    user: 'root',
    pwd: '123456',
    roles: [{ role: 'root', db: 'admin' }],
});
