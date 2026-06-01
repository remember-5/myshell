#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

# 删除模式：
# managed: 只删除 labels.json 中声明的标签
# all: 删除当前 group 下全部自有 labels
DELETE_MODE="${DELETE_MODE:-managed}"

validate_runtime
validate_delete_confirmation

case "$DELETE_MODE" in
  managed)
    validate_labels_file
    echo "== 删除 labels.json 中声明的 group labels =="
    while read -r name; do
      [[ -z "$name" ]] && continue
      delete_group_label "$name"
    done < <(managed_label_names)
    ;;
  all)
    echo "== 删除当前 group 下全部自有 labels =="
    while read -r name; do
      [[ -z "$name" ]] && continue
      delete_group_label "$name"
    done < <(list_group_label_names)
    ;;
  *)
    echo "不支持的 DELETE_MODE: $DELETE_MODE" >&2
    echo "可选值: managed, all" >&2
    exit 1
    ;;
esac

echo "完成。"
