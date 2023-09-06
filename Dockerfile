FROM centos:7 AS base
WORKDIR /app
COPY run.sh .
CMD ["sh", "-c", "tail -f /dev/null"]
