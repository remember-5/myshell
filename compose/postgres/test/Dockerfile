FROM postgres:18.3-bookworm

ARG DEBIAN_APT_MIRROR=http://mirrors.aliyun.com/debian
ARG DEBIAN_SECURITY_APT_MIRROR=http://mirrors.aliyun.com/debian-security
ARG PGDG_APT_MIRROR=http://mirrors.aliyun.com/postgresql/repos/apt

RUN set -eux; \
    sed -i "s|http://deb.debian.org/debian|${DEBIAN_APT_MIRROR}|g; s|http://deb.debian.org/debian-security|${DEBIAN_SECURITY_APT_MIRROR}|g" /etc/apt/sources.list.d/debian.sources; \
    sed -i "s|http://apt.postgresql.org/pub/repos/apt|${PGDG_APT_MIRROR}|g" /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        postgresql-18-pgaudit \
    && rm -rf /var/lib/apt/lists/*
