#!/usr/bin/env bash
# cc-buddy PostToolUse plugin: auto-format
# Automatically formats code files after editing

set -euo pipefail

# Extract file path from tool input
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .path // ""')

# If no file path, skip
if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
  cat <<EOF
{
  "success": true,
  "message": "无需格式化"
}
EOF
  exit 0
fi

# Get file extension
FILE_EXT="${FILE_PATH##*.}"

# Format based on file type
case "$FILE_EXT" in
  js|jsx|ts|tsx|json|css|scss|html|vue)
    # Check if prettier is available
    if command -v npx &> /dev/null && npx prettier --version &> /dev/null; then
      npx prettier --write "$FILE_PATH" &> /dev/null || true
      cat <<EOF
{
  "success": true,
  "message": "✨ 已使用 Prettier 格式化文件",
  "modifications": ["$FILE_PATH"]
}
EOF
    else
      cat <<EOF
{
  "success": true,
  "message": "Prettier 未安装，跳过格式化"
}
EOF
    fi
    ;;
    
  py)
    # Check if black is available
    if command -v black &> /dev/null; then
      black "$FILE_PATH" &> /dev/null || true
      cat <<EOF
{
  "success": true,
  "message": "✨ 已使用 Black 格式化 Python 文件",
  "modifications": ["$FILE_PATH"]
}
EOF
    else
      cat <<EOF
{
  "success": true,
  "message": "Black 未安装，跳过格式化"
}
EOF
    fi
    ;;
    
  go)
    # Check if gofmt is available
    if command -v gofmt &> /dev/null; then
      gofmt -w "$FILE_PATH" &> /dev/null || true
      cat <<EOF
{
  "success": true,
  "message": "✨ 已使用 gofmt 格式化 Go 文件",
  "modifications": ["$FILE_PATH"]
}
EOF
    else
      cat <<EOF
{
  "success": true,
  "message": "gofmt 未安装，跳过格式化"
}
EOF
    fi
    ;;
    
  rs)
    # Check if rustfmt is available
    if command -v rustfmt &> /dev/null; then
      rustfmt "$FILE_PATH" &> /dev/null || true
      cat <<EOF
{
  "success": true,
  "message": "✨ 已使用 rustfmt 格式化 Rust 文件",
  "modifications": ["$FILE_PATH"]
}
EOF
    else
      cat <<EOF
{
  "success": true,
  "message": "rustfmt 未安装，跳过格式化"
}
EOF
    fi
    ;;
    
  *)
    cat <<EOF
{
  "success": true,
  "message": "不支持的文件类型，跳过格式化"
}
EOF
    ;;
esac

exit 0
