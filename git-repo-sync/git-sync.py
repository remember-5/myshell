import os
import subprocess

# git仓库保存路径
file_path = "/home/sync-git/"

# 仓库信息
repo_list = [
    {
        # 仓库名
        "repo_name": "sync-git",
        # 需要同步的分支列表
        "branches": ["main", "dev"],
        # 公有仓库(源仓库)
        "public_repo": "https://gitlab.top/test/sync-git.git",
        # 私有仓库(从仓库)
        "private_repo": "https://gitlab.com/test/sync-git.git"
    },
]

# 证书信息(http方式，ssh方式请忽略), 格式 https://账户名:密码@域名
credential_list = [
    'https://admin:12345678@gitlab.com', # 仓库1证书信息
    'https://admin:12345678@gitlab.org' # 仓库2证书信息
]

def set_git_credentials():
    """
    设置 Git 凭证存储
    """
    credentials_file = os.path.expanduser("~/.git-credentials")
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

def check_and_clone():
    for repo in repo_list:
        # 检查仓库是否已经存在
        full_repo_path = os.path.join(file_path, repo["repo_name"])
        if not os.path.exists(full_repo_path):
            git_clone(repo)

def git_clone(repo):
    """
    克隆git仓库
    """
    os.chdir(file_path)
    for branch in repo["branches"]:
        if not branch_exists(repo, branch):
            print(f"The branch {branch} does not exist in the source repository")
            continue
        result = subprocess.run(["git", "clone", "-b", branch, repo["public_repo"]])
        if result.returncode != 0:
            print(f"克隆 {branch} 分支时发生错误.")
            return False
        print(f"{branch} 分支克隆成功:", repo["repo_name"])
    return True

def check_and_sync():
    """
    检测并同步任务
    """
    for repo in repo_list:
        full_repo_path = os.path.join(file_path, repo["repo_name"])
        os.chdir(full_repo_path)
        git_sync(repo)

def git_sync(repo):
    """
    同步git仓库
    """
    for branch in repo["branches"]:
        if not branch_exists(repo, branch):
            print(f"The branch {branch} does not exist in the source repository")
            continue
        subprocess.run(["git", "checkout", branch])
        result = subprocess.run(["git", "pull", "--rebase", "origin", branch])
        if result.returncode != 0:
            print(f"从源仓库拉取 {branch} 分支时发生错误.")

        # 切换到新拉取的分支,避免存在于分支同名的文件夹
        result = subprocess.run(["git", "checkout", branch, "--"])
        if result.returncode != 0:
            print(f"切换到 {branch} 分支时发生错误.")
            return

        # 将源仓库的内容推送到目标仓库
        result = subprocess.run(["git", "push", repo["private_repo"], branch])
        if result.returncode != 0:
            print(f"将内容推送到 {repo['private_repo']} 的 {branch} 分支时发生错误.")
            return

def branch_exists(repo, branch):
    """
    Check if the given branch exists in the remote repository
    """
    branches = subprocess.check_output(
        ["git", "ls-remote", "--heads", repo["public_repo"]]).decode('utf-8').split("\n")

    # check if the branch exists in the remote repository
    return any(b.endswith(f"/{branch}") for b in branches)

# 调用函数，预先配置ssh证书
if __name__ == "__main__":
    # set_git_credentials()
    check_and_clone()
    check_and_sync()
