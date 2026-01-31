#!/bin/bash

# 设置统计的时间范围和Git存储库路径
FROM_DATE="2023-08-01"
TO_DATE="2023-09-31"
REPO_PATH="/path/repository"

# 获取所有提交者的列表
AUTHORS=$(git -C $REPO_PATH log --pretty="%aN" --after="$FROM_DATE" --before="$TO_DATE" | sort | uniq)

# 遍历每个提交者，统计提交次数和代码行数
for AUTHOR in $AUTHORS; do
  COMMITS=$(git -C $REPO_PATH log --author="$AUTHOR" --after="$FROM_DATE" --before="$TO_DATE" --oneline | wc -l)
  LINES=$(git -C $REPO_PATH log --author="$AUTHOR" --after="$FROM_DATE" --before="$TO_DATE" --numstat | awk 'NF {print $1+$2}' | awk '{s+=$1} END {print s}')
  echo "Author: $AUTHOR"
  echo "Commits: $COMMITS"
  echo "Lines of code: $LINES"
  echo
done
