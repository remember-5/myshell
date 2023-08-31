FROM centos:centos7
WORKDIR /app
COPY run.sh .
RUN chmod +x run.sh && sh run.sh
