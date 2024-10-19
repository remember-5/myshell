import os
import subprocess

# 仅支持linux系统


# 文件路径
file_path = "/home/sync-git/"

# 仓库信息
repo_list = [
    {
        # 仓库名
        "repo_name": "sync-git",
        # 默认分支
        "default_branch": "main",
        # 公有仓库(源仓库)
        "public_repo": "https://gitlab.top/test/sync-git.git",
        # 私有仓库(从仓库)
        "private_repo": "https://gitlab.com/test/sync-git.git"
    }
]

# 证书信息, 格式 https://账户名:密码@域名
credential_list = [
    'https://admin:12345678@gitlab.com', # 仓库1证书信息
    'https://admin:12345678@gitlab.org' # 仓库2证书信息
]


def set_git_credentials():
    """
    设置 Git 凭证存储
    """
    credentials_file = os.path.expanduser("~/.git-credentials")
     # 检查文件是否存在，如果不存在则创建
    if not os.path.exists(credentials_file):
        # 设置 Git 凭证为store
        subprocess.run(["git", "config", "--global", "credential.helper", "store"])
        try:
            with open(credentials_file, 'w') as file:
                for credential in credential_list:
                    file.write(f"{credential}\n")
            print(f"凭证已更新到 {credentials_file}")
        except IOError:
            print("IO Error occurred when writing to the file.")

def git_clone(repo):
    """
    克隆git仓库
    """
    result = subprocess.run(["git", "clone", "-b", repo["default_branch"], repo["public_repo"]])
    if result.returncode != 0:
        print("Error occurred while cloning the repository.")
    print("Repository cloned successfully.", repo["repo_name"])
    return result.returncode == 0

def git_sync(repo):
    """
    同步git仓库
    """
    result = subprocess.run(["git", "pull", "origin", repo["default_branch"]])
    if result.returncode != 0:
        print(f"Error occurred while pulling the {repo['default_branch']} branch of repository.")
        return
    result = subprocess.run(["git", "push", repo["private_repo"], repo["default_branch"]])
    if result.returncode != 0:
        print(f"Error occurred while pushing to the {repo['private_repo']} repository.")
        return

def sync():
    """
    同步任务
    """
    for repo in repo_list:
        # 检查仓库是否已经存在
        full_repo_path = os.path.join(file_path, repo["repo_name"])
        if not os.path.exists(full_repo_path):
            cloned = git_clone(repo)
            if not cloned:
                continue
        os.chdir(full_repo_path)
        git_sync(repo)

# 调用函数
if __name__ == "__main__":
    set_git_credentials()
    sync()
