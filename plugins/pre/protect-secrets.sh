#!/usr/bin/env bash
# cc-buddy PreToolUse plugin: protect-secrets
# Protects sensitive files from being read, edited, or written

set -euo pipefail

# Extract file path from tool input
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .path // ""')

# If no file path, allow
if [[ -z "$FILE_PATH" ]]; then
  cat <<EOF
{
  "action": "allow",
  "reason": "No file path specified"
}
EOF
  exit 0
fi

# Define sensitive file patterns
SENSITIVE_PATTERNS=(
  "\.env$"
  "\.env\."
  "secret"
  "password"
  "credentials"
  "\.pem$"
  "\.key$"
  "\.p12$"
  "\.pfx$"
  "id_rsa"
  "id_dsa"
  "id_ecdsa"
  "id_ed25519"
  "\.aws/credentials"
  "\.ssh/config"
  "\.netrc"
  "\.npmrc"
  "\.pypirc"
)

# Check if file matches sensitive patterns
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if echo "$FILE_PATH" | grep -qiE "$pattern"; then
    cat <<EOF
{
  "action": "block",
  "reason": "🔒 敏感文件保护: 该文件可能包含密钥、密码或其他敏感信息",
  "suggestion": "如果需要访问此文件，请手动操作。建议使用环境变量或密钥管理服务来管理敏感信息。"
}
EOF
    exit 1
  fi
done

# File is safe to access
cat <<EOF
{
  "action": "allow",
  "reason": "文件安全检查通过"
}
EOF
exit 0
