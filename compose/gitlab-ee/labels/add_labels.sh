#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib.sh"

validate_runtime
validate_labels_file

echo "== 新增或更新 group labels =="
while read -r label; do
  name="$(read_label_field "$label" name)"
  color="$(read_label_field "$label" color)"
  desc="$(read_label_field "$label" description)"
  upsert_group_label "$name" "$color" "$desc"
done < <(jq -c '.[]' "$LABELS_FILE")

echo "完成。"
