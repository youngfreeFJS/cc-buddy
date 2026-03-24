#!/usr/bin/env bash
# cc-buddy PostToolUse plugin: auto-test
# Automatically runs relevant tests after code changes

set -euo pipefail

# Extract file path from tool input
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .path // ""')

# If no file path, skip
if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
  cat <<EOF
{
  "success": true,
  "message": "无测试需要运行"
}
EOF
  exit 0
fi

# Get file extension
FILE_EXT="${FILE_PATH##*.}"

# Determine test command based on project type
run_tests() {
  local test_cmd=""
  
  # Check for package.json (Node.js project)
  if [[ -f "package.json" ]]; then
    if grep -q "\"test\":" package.json; then
      test_cmd="npm test"
    fi
  fi
  
  # Check for pytest (Python project)
  if [[ -f "pytest.ini" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
    if command -v pytest &> /dev/null; then
      test_cmd="pytest"
    fi
  fi
  
  # Check for Cargo.toml (Rust project)
  if [[ -f "Cargo.toml" ]]; then
    test_cmd="cargo test"
  fi
  
  # Check for go.mod (Go project)
  if [[ -f "go.mod" ]]; then
    test_cmd="go test ./..."
  fi
  
  # Run tests if command found
  if [[ -n "$test_cmd" ]]; then
    if $test_cmd &> /dev/null; then
      cat <<EOF
{
  "success": true,
  "message": "✅ 测试通过",
  "modifications": []
}
EOF
    else
      cat <<EOF
{
  "success": false,
  "message": "❌ 测试失败，请检查代码",
  "modifications": []
}
EOF
    fi
  else
    cat <<EOF
{
  "success": true,
  "message": "未找到测试命令，跳过测试",
  "modifications": []
}
EOF
  fi
}

# Only run tests for code files
case "$FILE_EXT" in
  js|jsx|ts|tsx|py|go|rs)
    run_tests
    ;;
  *)
    cat <<EOF
{
  "success": true,
  "message": "非代码文件，跳过测试"
}
EOF
    ;;
esac

exit 0
