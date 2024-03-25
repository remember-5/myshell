# 使用官方的 nginx 镜像作为基础镜像
FROM nginx:latest

# 将当前目录下的所有文件复制到容器中的 /usr/share/nginx/html 目录下
COPY test.html /usr/share/nginx/html

# 如果有需要，你可以添加其他的 nginx 配置文件
# COPY nginx.conf /etc/nginx/nginx.conf

# 暴露容器的 80 端口
EXPOSE 80

# 启动 nginx 服务
CMD ["nginx", "-g", "daemon off;"]
