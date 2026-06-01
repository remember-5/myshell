# GitLab Labels 脚本

用于批量维护 GitLab group labels。

这些脚本只操作 **group labels**，不再复制到 project 级别。  
GitLab 项目可以直接使用所属 group 的 labels，因此这样更简单，也更不容易产生同名标签漂移。

## 文件说明

- `labels.json`：标签定义
- `lib.sh`：公共函数
- `add_labels.sh`：新增或更新 `labels.json` 中的全部标签
- `delete_labels.sh`：删除标签
- `.env.example`：环境变量示例

## 快速开始

先复制配置文件：

```bash
cp .env.example .env
```

然后编辑 `.env`，至少填写：

- `GROUP_ID`
- `GITLAB_TOKEN`

## 新增或更新全部标签

```bash
bash add_labels.sh
```

脚本会读取 `labels.json`，对每个标签执行：

- 已存在则更新颜色和描述
- 不存在则创建

## 删除标签

默认删除 `labels.json` 中声明的全部标签：

```bash
CONFIRM_DELETE_LABELS=yes bash delete_labels.sh
```

如果要删除当前 group 下全部自有 labels：

```bash
DELETE_MODE=all CONFIRM_DELETE_LABELS=yes bash delete_labels.sh
```

## 预演模式

如果只想看将执行什么操作，不真正调用 GitLab API：

```bash
DRY_RUN=true bash add_labels.sh
```

```bash
DRY_RUN=true CONFIRM_DELETE_LABELS=yes bash delete_labels.sh
```

## 环境变量说明

- `GITLAB_HOST`：GitLab 地址，默认 `https://gitlab.com`
- `GROUP_ID`：目标 group ID
- `GITLAB_TOKEN`：具备 `api` 权限的 token
- `LABELS_FILE`：标签定义文件，默认 `./labels.json`
- `DRY_RUN`：是否只预演，`true` 或 `false`
- `CONFIRM_DELETE_LABELS`：删除确认，删除时必须为 `yes`
- `ENV_FILE`：可选，自定义 `.env` 文件路径
- `DELETE_MODE`：删除模式，`managed` 或 `all`

## 删除模式说明

- `managed`
  只删除 `labels.json` 中声明的标签
- `all`
  删除当前 group 下全部自有 labels

## 注意事项

- `.env` 不要提交到仓库
- 删除标签会影响已有 issue / merge request 上的标签展示
- 建议先用 `DRY_RUN=true` 预演，再执行真实操作
