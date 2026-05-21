#!/usr/bin/env bash
# dev_vcs_helper — 共用 git 工具函式
# 使用方式：source 此檔案後呼叫各函式

# 確認目前目錄（或指定路徑）是否為 git repo
# 用法：assert_git_repo [path]
assert_git_repo() {
  local path="${1:-.}"
  git -C "$path" rev-parse --git-dir > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "ERROR: '$path' 不是 git repository 或路徑不存在" >&2
    return 1
  fi
}

# 確認分支存在
# 用法：assert_branch_exists <branch> [path]
assert_branch_exists() {
  local branch="$1"
  local path="${2:-.}"
  git -C "$path" rev-parse --verify "$branch" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "ERROR: 分支 '$branch' 不存在" >&2
    return 1
  fi
}

# 確認 tag 存在
# 用法：assert_tag_exists <tag> [path]
assert_tag_exists() {
  local tag="$1"
  local path="${2:-.}"
  git -C "$path" rev-parse --verify "refs/tags/$tag" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "ERROR: tag '$tag' 不存在" >&2
    return 1
  fi
}

# 取得目前日期（YYYYMMDD）
get_date() {
  date +%Y%m%d
}

# 取得目前日期時間（YYYY-MM-DD HH:MM:SS）
get_datetime() {
  date '+%Y-%m-%d %H:%M:%S'
}
