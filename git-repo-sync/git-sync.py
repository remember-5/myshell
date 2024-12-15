import os
import json
import subprocess
import getpass
from typing import Optional


def load_config():
    """加载配置文件"""
    try:
        with open('repo_config.json', 'r', encoding='utf-8') as f:
            config = json.load(f)
        return config['file_path'], config['repositories']
    except Exception as e:
        raise Exception(f"加载配置文件失败: {str(e)}")


def run_command(args, errmsg):
    """执行命令并处理异常"""
    try:
        subprocess.run(args, check=True, capture_output=True, text=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"{errmsg}. 错误详情: {str(e)}")
        print(f"命令输出: {e.output}")
        return False


def get_ssh_password() -> Optional[str]:
    """获取 SSH 密钥密码，优先从环境变量获取"""
    ssh_pass = os.getenv('SSH_KEY_PASSWORD')
    if ssh_pass:
        return ssh_pass

    try:
        return getpass.getpass('请输入 SSH 密钥密码 (如果没有设置密码请直接回车): ')
    except Exception as e:
        print(f"获取密码输入失败: {str(e)}")
        return None


def check_ssh_key_encrypted() -> bool:
    """检查 SSH 密钥是否加密"""
    ssh_key_path = os.path.expanduser('~/.ssh/id_rsa')
    try:
        with open(ssh_key_path, 'r') as f:
            content = f.read()
            return 'ENCRYPTED' in content
    except Exception as e:
        print(f"检查 SSH 密钥加密状态失败: {str(e)}")
        return False


def add_ssh_key_with_password(password: str) -> bool:
    """使用密码添加 SSH 密钥"""
    try:
        process = subprocess.Popen(
            ['ssh-add'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        stdout, stderr = process.communicate(input=f"{password}\n")

        if process.returncode == 0:
            print("SSH 密钥添加成功")
            return True
        else:
            print(f"添加 SSH 密钥失败: {stderr}")
            return False
    except Exception as e:
        print(f"添加 SSH 密钥时发生错误: {str(e)}")
        return False

def setup_git_ssh():
    """设置 Git SSH 命令以自动接受新主机"""
    ssh_command = 'ssh -o StrictHostKeyChecking=no'
    os.environ['GIT_SSH_COMMAND'] = ssh_command


def setup_ssh_agent():
    """设置 SSH Agent 并添加密钥"""
    setup_git_ssh()
    try:
        # 启动 ssh-agent
        ssh_agent = subprocess.run(['ssh-agent', '-s'], capture_output=True, text=True)

        # 解析环境变量
        for line in ssh_agent.stdout.split('\n'):
            if 'SSH_AUTH_SOCK' in line:
                key, value = line.split(';')[0].split('=')
                os.environ['SSH_AUTH_SOCK'] = value
            elif 'SSH_AGENT_PID' in line:
                key, value = line.split(';')[0].split('=')
                os.environ['SSH_AGENT_PID'] = value

        # 检查密钥是否加密
        if check_ssh_key_encrypted():
            # 获取密码
            ssh_pass = get_ssh_password()
            if ssh_pass:
                return add_ssh_key_with_password(ssh_pass)
            else:
                print("未提供 SSH 密钥密码")
                return False
        else:
            # 无密码的密钥直接添加
            subprocess.run(['ssh-add'], check=True)
            print("SSH 密钥已添加（无密码）")
            return True

    except Exception as e:
        print(f"设置 SSH Agent 失败: {str(e)}")
        return False


def check_and_clone(file_path, repositories):
    """检查并克隆仓库"""
    for repo_item in repositories:
        full_repo_path = os.path.join(file_path, repo_item["name"])
        if not os.path.exists(full_repo_path):
            git_clone(file_path, repo_item)


def git_clone(file_path, repo_item):
    """克隆git仓库"""
    os.chdir(file_path)
    for branch in repo_item["branches"]:
        if not branch_exists(repo_item["public_repo"], branch):
            print(f"分支 {branch} 在源仓库中不存在")
            continue

        success = run_command(
            ["git", "clone", "-b", branch, repo_item["public_repo"]],
            f"克隆分支 {branch} 时发生错误"
        )
        if success:
            print(f"成功克隆 {repo_item['name']} 的 {branch} 分支")


def check_and_sync(file_path, repositories):
    """检测并同步任务"""
    for repo in repositories:
        full_repo_path = os.path.join(file_path, repo["name"])
        try:
            os.chdir(full_repo_path)
            git_sync(repo)
        except Exception as e:
            print(f"处理仓库 {repo['name']} 时发生错误: {str(e)}")


def git_sync(repo):
    """同步git仓库"""
    for branch in repo["branches"]:
        try:
            if not branch_exists(repo["public_repo"], branch):
                print(f"分支 {branch} 在源仓库中不存在")
                continue

            # 清理工作区
            run_command(["git", "reset", "--hard"], "重置工作区时发生错误")
            run_command(["git", "clean", "-fd"], "清理工作区时发生错误")

            # 切换并更新分支
            run_command(["git", "checkout", branch], f"切换到 {branch} 分支时发生错误")
            run_command(["git", "pull", "--rebase", "origin", branch], f"从源仓库拉取 {branch} 分支时发生错误")
            run_command(["git", "reset", "--hard", f"origin/{branch}"], f"重置到 origin/{branch} 时发生错误")

            # 强制推送到目标仓库
            run_command(
                ["git", "push", "-f", repo["private_repo"], branch],
                f"推送到目标仓库的 {branch} 分支时发生错误"
            )
            print(f"成功同步 {repo['name']} 的 {branch} 分支")

        except Exception as e:
            print(f"同步分支 {branch} 时发生错误: {str(e)}")
            continue


def branch_exists(repo_url, branch):
    """检查分支是否存在于远程仓库"""
    try:
        if 'git@' in repo_url:
            setup_ssh_agent()
        result = subprocess.run(
            ["git", "ls-remote", "--heads", repo_url],
            check=True,
            capture_output=True,
            text=True
        )
        branches = result.stdout.split("\n")
        return any(b.endswith(f"/{branch}") for b in branches)
    except subprocess.CalledProcessError as e:
        print(f"检查分支时发生错误: {str(e)}")
        return False


if __name__ == "__main__":
    try:
        # 加载配置并执行同步
        file_path, repositories = load_config()
        check_and_clone(file_path, repositories)
        check_and_sync(file_path, repositories)
    except Exception as e:
        print(f"程序执行出错: {str(e)}")
