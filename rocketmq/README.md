# 安装

```shell
# create folder
touch docker-compose.yml
mkdir -p ./namesrv/logs/rocketmqlogs
mkdir -p ./broker/{logs,store,conf}
mkdir -p ./proxy/{logs,conf}
```


dashboard已经很久没更新了，所以换了个镜像,
还有问题，待修复


# 参考
- 官方提供的docker-compose demo https://rocketmq.apache.org/zh/docs/quickStart/03quickstartWithDockercompose
- github rocketmq-docker https://github.com/apache/rocketmq-docker/tree/master/templates/docker-compose
- 权限控制 https://rocketmq.apache.org/zh/docs/bestPractice/03access
- acl文件 https://github.com/apache/rocketmq/blob/develop/distribution/conf/plain_acl.yml
- rocketmq-dashboard 自行搜索
- 参考文章 https://blog.csdn.net/Peng_Hong_fu/article/details/127769777
