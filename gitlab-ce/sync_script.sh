#!/bin/bash

# Variables
# ssh server
SSH_SERVER="127.0.0.1"
# ssh port
SSH_PORT="22"
# ssh user
SSH_USER="root"
# ssh 密码 (选填) - 如果使用密码登录，请填写
SSH_PASSWORD=""
# ssh 证书路径 (选填) - 如果使用证书登录，请填写
SSH_CERT_PATH="/data/xxx.pem"
# ssh 证书密码 (选填) - 如果证书有密码，请填写
SSH_CERT_PASSWORD=""

# Source path
SOURCE_PATH="/backups/1737700056_2025_01_24_17.8.1-ee_gitlab_backup.tar"
# Download path
DOWNLOAD_PATH="/data"
# Log file
LOG_FILE="/data/sync.log"

# 确保日志文件可写
mkdir -p "$(dirname "${LOG_FILE}")"
touch "${LOG_FILE}"
chmod 644 "${LOG_FILE}"

# Function to test SSH 连接
test_ssh_connection() {
    if [ -n "${SSH_CERT_PATH}" ]; then
        # 使用 ssh 证书连接 (证书认证)
        echo "Using SSH certificate for authentication..." >> "${LOG_FILE}"
        ssh -i "${SSH_CERT_PATH}" -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=60" "${SSH_USER}@${SSH_SERVER}" exit
        return $?
    elif [ -n "${SSH_PASSWORD}" ]; then
        # 使用 ssh 密码连接 (密码认证)
        echo "Using SSH password for authentication..." >> "${LOG_FILE}"
        sshpass -p "${SSH_PASSWORD}" ssh -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=60" "${SSH_USER}@${SSH_SERVER}" exit
        return $?
    else
        echo "请提供 SSH 证书路径或密码" >> "${LOG_FILE}"
        exit 1
    fi
}

# Function to perform rsync
perform_rsync() {
    if [ -n "${SSH_CERT_PATH}" ]; then
        # 使用证书认证
        nohup rsync -avz --partial --progress --timeout=60 \
            -e "ssh -i ${SSH_CERT_PATH} -o StrictHostKeyChecking=no -o ServerAliveInterval=60" \
            "${SSH_USER}@${SSH_SERVER}:${SOURCE_PATH}" \
            "${DOWNLOAD_PATH}" >> "${LOG_FILE}" 2>&1 &
    elif [ -n "${SSH_PASSWORD}" ]; then
        # 使用密码认证
        nohup rsync -avz --partial --progress --timeout=60 \
            -e "sshpass -p ${SSH_PASSWORD} ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60" \
            "${SSH_USER}@${SSH_SERVER}:${SOURCE_PATH}" \
            "${DOWNLOAD_PATH}" >> "${LOG_FILE}" 2>&1 &
    else
        echo "无法执行 rsync：未提供 SSH 证书或密码" >> "${LOG_FILE}"
        exit 1
    fi

    RSYNC_PID=$!  # 获取 rsync 的进程 ID
    disown  # 确保脚本不会等待 rsync 完成
    echo "rsync started in the background with PID: ${RSYNC_PID}." >> "${LOG_FILE}"
}

# Test SSH connection
echo "Attempting SSH connection..." >> "${LOG_FILE}"
if test_ssh_connection; then
    echo "SSH connection successful. Starting rsync..." >> "${LOG_FILE}"

    # Perform rsync
    perform_rsync

    # 可选：监控 rsync 是否完成
    echo "Waiting for rsync to complete in the background..."
    wait ${RSYNC_PID}
    if [ $? -eq 0 ]; then
        echo "GitLab backup transfer completed successfully." >> "${LOG_FILE}"
    else
        echo "GitLab backup transfer failed. Check the log for details." >> "${LOG_FILE}"
    fi
else
    echo "SSH connection failed. Unable to proceed with rsync. See log for details." >> "${LOG_FILE}"
fi

echo "Migration process finished. Check ${LOG_FILE} for details."
