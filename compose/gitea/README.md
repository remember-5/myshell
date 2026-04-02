# 官网
https://docs.gitea.com/zh-cn/installation/install-with-docker


# 配置认证源

## gitlab
add source: `site administration` -> `Identity & Access` -> `Authentication Source` -> `Add Authentication Source`

Gitlab管理员创建OAUTH2的应用，


回调信息:
AUTH_URL = https://your-gitlab-domain.com/oauth/authorize
TOKEN_URL = https://your-gitlab-domain.com/oauth/token
PROFILE_URL = https://your-gitlab-domain.com/api/v4/user
