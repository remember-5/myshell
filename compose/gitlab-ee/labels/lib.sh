#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"

# 显式传入的环境变量优先级应高于 .env 文件，因此先记录再恢复。
ENV_GITLAB_HOST="${GITLAB_HOST-}"
ENV_GITLAB_TOKEN="${GITLAB_TOKEN-}"
ENV_GROUP_ID="${GROUP_ID-}"
ENV_LABELS_FILE="${LABELS_FILE-}"
ENV_DRY_RUN="${DRY_RUN-}"
ENV_CONFIRM_DELETE_LABELS="${CONFIRM_DELETE_LABELS-}"
HAS_GITLAB_HOST="${GITLAB_HOST+x}"
HAS_GITLAB_TOKEN="${GITLAB_TOKEN+x}"
HAS_GROUP_ID="${GROUP_ID+x}"
HAS_LABELS_FILE="${LABELS_FILE+x}"
HAS_DRY_RUN="${DRY_RUN+x}"
HAS_CONFIRM_DELETE_LABELS="${CONFIRM_DELETE_LABELS+x}"

load_env_file() {
  if [[ ! -f "$ENV_FILE" ]]; then
    return 0
  fi

  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a

  if [[ -n "${HAS_GITLAB_HOST:-}" ]]; then
    GITLAB_HOST="$ENV_GITLAB_HOST"
  fi

  if [[ -n "${HAS_GITLAB_TOKEN:-}" ]]; then
    GITLAB_TOKEN="$ENV_GITLAB_TOKEN"
  fi

  if [[ -n "${HAS_GROUP_ID:-}" ]]; then
    GROUP_ID="$ENV_GROUP_ID"
  fi

  if [[ -n "${HAS_LABELS_FILE:-}" ]]; then
    LABELS_FILE="$ENV_LABELS_FILE"
  fi

  if [[ -n "${HAS_DRY_RUN:-}" ]]; then
    DRY_RUN="$ENV_DRY_RUN"
  fi

  if [[ -n "${HAS_CONFIRM_DELETE_LABELS:-}" ]]; then
    CONFIRM_DELETE_LABELS="$ENV_CONFIRM_DELETE_LABELS"
  fi
}

load_env_file

# GitLab 地址、Token、Group ID。
# Token 需要 api 权限；不要把真实 token 写进脚本或提交到仓库。
GITLAB_HOST="${GITLAB_HOST:-https://gitlab.com}"
GITLAB_TOKEN="${GITLAB_TOKEN:?运行前请设置 GITLAB_TOKEN，且需具备 api 权限}"
GROUP_ID="${GROUP_ID:-1}"
LABELS_FILE="${LABELS_FILE:-$SCRIPT_DIR/labels.json}"
DRY_RUN="${DRY_RUN:-false}"
CONFIRM_DELETE_LABELS="${CONFIRM_DELETE_LABELS:-no}"

urlencode() {
  jq -nr --arg v "$1" '$v|@uri'
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "缺少依赖命令: $cmd" >&2
    exit 1
  fi
}

validate_runtime() {
  require_command curl
  require_command jq
}

validate_labels_file() {
  if [[ ! -f "$LABELS_FILE" ]]; then
    echo "标签文件不存在: $LABELS_FILE" >&2
    exit 1
  fi

  jq -e '
    type == "array"
    and all(.[]; (.name | type == "string" and length > 0)
      and (.color | type == "string" and test("^#[0-9A-Fa-f]{6}$"))
      and (.description | type == "string"))
  ' "$LABELS_FILE" >/dev/null
}

validate_delete_confirmation() {
  if [[ "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  if [[ "$CONFIRM_DELETE_LABELS" != "yes" ]]; then
    echo "删除标签前必须显式设置 CONFIRM_DELETE_LABELS=yes。" >&2
    echo "删除会影响已有 issue / MR 上的标签展示，请确认后重试。" >&2
    exit 1
  fi
}

read_label_field() {
  local label="$1"
  local field="$2"
  jq -r --arg field "$field" '.[$field]' <<< "$label"
}

managed_label_names() {
  jq -r '.[].name' "$LABELS_FILE"
}

api() {
  local method="$1"
  local path="$2"
  local data="${3:-}"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY_RUN] $method $path $data" >&2

    if [[ "$method" == "GET" && "$path" == *"/labels?"* ]]; then
      printf '[]'
      return 0
    fi

    if [[ "$method" == "GET" ]]; then
      return 1
    fi

    return 0
  fi

  local response body code
  if [[ -n "$data" ]]; then
    response="$(
      curl -sS -w $'\n%{http_code}' \
        --request "$method" \
        --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --header "Content-Type: application/json" \
        --data "$data" \
        "$GITLAB_HOST/api/v4$path"
    )"
  else
    response="$(
      curl -sS -w $'\n%{http_code}' \
        --request "$method" \
        --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "$GITLAB_HOST/api/v4$path"
    )"
  fi

  code="${response##*$'\n'}"
  body="${response%$'\n'*}"
  printf '%s' "$body"

  if [[ "$code" -lt 200 || "$code" -ge 300 ]]; then
    return 1
  fi
}

group_label_exists() {
  local name="$1"
  local group_enc label_enc
  group_enc="$(urlencode "$GROUP_ID")"
  label_enc="$(urlencode "$name")"

  api GET "/groups/$group_enc/labels/$label_enc?include_ancestor_groups=false&include_descendant_groups=false&only_group_labels=true" >/dev/null 2>&1
}

list_group_label_names() {
  local group_enc page result count
  group_enc="$(urlencode "$GROUP_ID")"
  page=1

  while true; do
    result="$(api GET "/groups/$group_enc/labels?only_group_labels=true&include_ancestor_groups=false&include_descendant_groups=false&per_page=100&page=$page")"
    count="$(echo "$result" | jq 'length')"

    [[ "$count" -eq 0 ]] && break

    echo "$result" | jq -r '.[].name'
    page=$((page + 1))
  done
}

upsert_group_label() {
  local name="$1"
  local color="$2"
  local desc="$3"

  local group_enc label_enc payload
  group_enc="$(urlencode "$GROUP_ID")"
  label_enc="$(urlencode "$name")"
  payload="$(jq -n --arg name "$name" --arg color "$color" --arg desc "$desc" \
    '{name:$name,color:$color,description:$desc}')"

  if group_label_exists "$name"; then
    echo "更新 group label: $name"
    api PUT "/groups/$group_enc/labels/$label_enc" "$(jq -n --arg color "$color" --arg desc "$desc" \
      '{color:$color,description:$desc}')" >/dev/null
  else
    echo "创建 group label: $name"
    api POST "/groups/$group_enc/labels" "$payload" >/dev/null
  fi
}

delete_group_label() {
  local name="$1"
  local group_enc label_enc
  group_enc="$(urlencode "$GROUP_ID")"
  label_enc="$(urlencode "$name")"

  if ! group_label_exists "$name"; then
    return 0
  fi

  echo "删除 group label: $name"
  api DELETE "/groups/$group_enc/labels/$label_enc" >/dev/null
}
