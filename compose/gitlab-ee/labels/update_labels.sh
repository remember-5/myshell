#!/usr/bin/env bash
set -euo pipefail

# GitLab 地址、Token、Group ID。
# Token 需要 api 权限；不要把真实 token 写进脚本或提交到仓库。
GITLAB_HOST="${GITLAB_HOST:-https://gitlab.com}"
GITLAB_TOKEN="${GITLAB_TOKEN:?Set GITLAB_TOKEN with api scope before running this script}"
GROUP_ID="${GROUP_ID:-1}"
LABELS_FILE="${LABELS_FILE:-$(dirname "$0")/labels.json}"

# 是否同步到 group 下所有已有项目。
# true: 创建/更新 group labels 后，再同步到每个已有项目的 project labels。
# false: 只创建/更新 group labels。
SYNC_PROJECT_LABELS="${SYNC_PROJECT_LABELS:-true}"

# 是否先删除已有 labels 再按 labels.json 重建。
# 默认 false，避免误删已经绑定到 issue/MR 上的 label。
# true: 删除当前 group 自有 labels，再按 labels.json 重建。
DELETE_EXISTING_LABELS="${DELETE_EXISTING_LABELS:-false}"

# 是否删除已有项目里的 project labels。
# 只有 SYNC_PROJECT_LABELS=true 时才会生效。
# true: 对 group 下每个已有项目，先删除项目自有 labels，再按 labels.json 重建。
DELETE_PROJECT_LABELS="${DELETE_PROJECT_LABELS:-false}"

# 删除 label 是破坏性操作，正式执行删除时必须设置为 yes。
# 示例：
#   DELETE_EXISTING_LABELS=true CONFIRM_DELETE_LABELS=yes GITLAB_TOKEN=xxx bash update_labels.sh
# DRY_RUN=true 时不会真实删除，不需要确认。
CONFIRM_DELETE_LABELS="${CONFIRM_DELETE_LABELS:-no}"

# true: 只打印将要执行的动作，不真正修改。
DRY_RUN="${DRY_RUN:-false}"

urlencode() {
  jq -nr --arg v "$1" '$v|@uri'
}

validate_labels_file() {
  if [[ ! -f "$LABELS_FILE" ]]; then
    echo "Labels file not found: $LABELS_FILE" >&2
    exit 1
  fi

  jq -e '
    type == "array"
    and all(.[]; (.name | type == "string" and length > 0)
      and (.color | type == "string" and test("^#[0-9A-Fa-f]{6}$"))
      and (.description | type == "string"))
  ' "$LABELS_FILE" >/dev/null
}

validate_delete_options() {
  if [[ "$DELETE_PROJECT_LABELS" == "true" && "$SYNC_PROJECT_LABELS" != "true" ]]; then
    echo "DELETE_PROJECT_LABELS=true requires SYNC_PROJECT_LABELS=true." >&2
    exit 1
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    return 0
  fi

  if [[ "$DELETE_EXISTING_LABELS" == "true" || "$DELETE_PROJECT_LABELS" == "true" ]]; then
    if [[ "$CONFIRM_DELETE_LABELS" != "yes" ]]; then
      echo "Refusing to delete labels without CONFIRM_DELETE_LABELS=yes." >&2
      echo "Deletion can remove labels from existing issues/MRs. Re-run with CONFIRM_DELETE_LABELS=yes if intended." >&2
      exit 1
    fi
  fi
}

read_label_field() {
  local label="$1"
  local field="$2"
  jq -r --arg field "$field" '.[$field]' <<< "$label"
}

api() {
  local method="$1"
  local path="$2"
  local data="${3:-}"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY_RUN] $method $path $data" >&2

    if [[ "$method" == "GET" && "$path" == *"/projects?"* ]]; then
      printf '[]'
      return 0
    fi

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

list_project_label_names() {
  local project_id="$1"
  local page result count
  page=1

  while true; do
    result="$(api GET "/projects/$project_id/labels?include_ancestor_groups=false&per_page=100&page=$page")"
    count="$(echo "$result" | jq 'length')"

    [[ "$count" -eq 0 ]] && break

    echo "$result" | jq -r '.[].name'
    page=$((page + 1))
  done
}

delete_group_label() {
  local name="$1"
  local group_enc label_enc
  group_enc="$(urlencode "$GROUP_ID")"
  label_enc="$(urlencode "$name")"

  echo "Delete group label: $name"
  api DELETE "/groups/$group_enc/labels/$label_enc" >/dev/null
}

delete_project_label() {
  local project_id="$1"
  local name="$2"
  local label_enc
  label_enc="$(urlencode "$name")"

  echo "  Delete project label: $name"
  api DELETE "/projects/$project_id/labels/$label_enc" >/dev/null
}

delete_existing_group_labels() {
  if [[ "$DELETE_EXISTING_LABELS" != "true" ]]; then
    return 0
  fi

  echo "== Delete existing group labels =="
  while read -r name; do
    [[ -z "$name" ]] && continue
    delete_group_label "$name"
  done < <(list_group_label_names)
}

delete_existing_project_labels() {
  local project_id="$1"

  if [[ "$DELETE_PROJECT_LABELS" != "true" ]]; then
    return 0
  fi

  echo "  Delete existing project labels"
  while read -r name; do
    [[ -z "$name" ]] && continue
    delete_project_label "$project_id" "$name"
  done < <(list_project_label_names "$project_id")
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

  if api GET "/groups/$group_enc/labels/$label_enc?include_ancestor_groups=false&include_descendant_groups=false&only_group_labels=true" >/dev/null 2>&1; then
    echo "Update group label: $name"
    api PUT "/groups/$group_enc/labels/$label_enc" "$(jq -n --arg color "$color" --arg desc "$desc" \
      '{color:$color,description:$desc}')" >/dev/null
  else
    echo "Create group label: $name"
    api POST "/groups/$group_enc/labels" "$payload" >/dev/null
  fi
}

upsert_project_label() {
  local project_id="$1"
  local name="$2"
  local color="$3"
  local desc="$4"

  local label_enc payload
  label_enc="$(urlencode "$name")"
  payload="$(jq -n --arg name "$name" --arg color "$color" --arg desc "$desc" \
    '{name:$name,color:$color,description:$desc}')"

  if api GET "/projects/$project_id/labels/$label_enc?include_ancestor_groups=false" >/dev/null 2>&1; then
    echo "  Update project label: $name"
    api PUT "/projects/$project_id/labels/$label_enc" "$(jq -n --arg color "$color" --arg desc "$desc" \
      '{color:$color,description:$desc}')" >/dev/null
  else
    echo "  Create project label: $name"
    api POST "/projects/$project_id/labels" "$payload" >/dev/null
  fi
}

list_project_ids() {
  local group_enc page result count
  group_enc="$(urlencode "$GROUP_ID")"
  page=1

  while true; do
    result="$(api GET "/groups/$group_enc/projects?include_subgroups=true&simple=true&per_page=100&page=$page")"
    count="$(echo "$result" | jq 'length')"

    [[ "$count" -eq 0 ]] && break

    echo "$result" | jq -r '.[].id'
    page=$((page + 1))
  done
}

validate_labels_file
validate_delete_options

delete_existing_group_labels

echo "== Upsert group labels =="
while read -r label; do
  name="$(read_label_field "$label" name)"
  color="$(read_label_field "$label" color)"
  desc="$(read_label_field "$label" description)"
  upsert_group_label "$name" "$color" "$desc"
done < <(jq -c '.[]' "$LABELS_FILE")

if [[ "$SYNC_PROJECT_LABELS" == "true" ]]; then
  echo "== Sync labels to existing projects =="
  while read -r project_id; do
    [[ -z "$project_id" ]] && continue
    echo "Project: $project_id"
    delete_existing_project_labels "$project_id"

    while read -r label; do
      name="$(read_label_field "$label" name)"
      color="$(read_label_field "$label" color)"
      desc="$(read_label_field "$label" description)"
      upsert_project_label "$project_id" "$name" "$color" "$desc"
    done < <(jq -c '.[]' "$LABELS_FILE")
  done < <(list_project_ids)
fi

echo "Done."
