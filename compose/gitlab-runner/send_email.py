import os
import smtplib
from email.mime.text import MIMEText

# 读取环境变量中的 SMTP 配置
smtp_server = os.getenv('SMTP_HOST_ADDRESS')
smtp_port = os.getenv('SMTP_HOST_PORT')
smtp_user = os.getenv('SMTP_HOST_USER')
smtp_password = os.getenv('SMTP_HOST_PASSWORD')
# 从环境变量中读取收件人列表
recipients = os.getenv('EMAIL_RECIPIENTS').split(',')
project_name = os.environ['CI_PROJECT_NAME']
commit_message = os.environ['CI_COMMIT_MESSAGE']
pipeline_id = os.environ['CI_PIPELINE_ID']
project_id = os.environ['CI_PROJECT_ID']
job_id = os.environ['CI_JOB_ID']
job_url = os.environ['CI_JOB_URL']
docker_image = os.environ['DOCKER_IMAGE_NAME']
docker_tag = os.environ['DOCKER_IMAGE_TAG']

# 创建邮件标题和内容
subject = f"CI Job Notification for {project_name}, {docker_image}:{docker_tag}"
body = f"""
Hello,

This is a notification for a recently completed CI job.

Project: {project_name}
Project ID: {project_id}
Commit Message: {commit_message}
Pipeline ID: {pipeline_id}
Job ID: {job_id}
Job URL: {job_url}
Docker Image: {docker_image}
Docker Tag: {docker_tag}

Please check the CI server for more details.

Best,
Your CI System
"""

# 创建一个 MIMEText 对象
msg = MIMEText(body)
msg['Subject'] = subject
msg['From'] = smtp_user
msg['To'] = ', '.join(recipients)

# 连接 SMTP 服务器并发送邮件
with smtplib.SMTP_SSL(smtp_server, smtp_port) as server:
  server.login(smtp_user, smtp_password)
  server.send_message(msg, from_addr=smtp_user, to_addrs=recipients)
