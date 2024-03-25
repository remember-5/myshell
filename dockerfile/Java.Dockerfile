# ---- Base Node ----
FROM maven:3.8.4-openjdk-17 AS build

# copy maven setting file
COPY settings.xml /usr/share/maven/conf/settings.xml

WORKDIR /tmp

# 预下载依赖
COPY pom.xml .
RUN mvn dependency:go-offline

# copy代码
COPY src src
RUN mvn clean package -DskipTests

# ---- Run ----
FROM openjdk:17-jdk AS run
WORKDIR /app
COPY --from=build /tmp/target/demo.jar /app/demo.jar

# 声明一个环境参数用来动态启用配置文件 默认dev
ENV ACTIVE=dev
# 暴露端口
EXPOSE 8080

CMD ["sh","-c","java -jar /app/demo.jar --spring.profiles.active=${ACTIVE}"]
