#!/usr/bin/env bash
# cc-buddy PreToolUse plugin: block-dangerous
# Blocks dangerous shell commands that could cause system damage

set -euo pipefail

# Extract command from tool input
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')

# If not a Bash command, allow
if [[ "$TOOL_NAME" != "Bash" ]] || [[ -z "$COMMAND" ]]; then
  cat <<EOF
{
  "action": "allow",
  "reason": "Not a bash command"
}
EOF
  exit 0
fi

# Define dangerous patterns
declare -A DANGEROUS_PATTERNS=(
  ["rm -rf /"]="Recursive deletion of root directory"
  ["rm -rf ~"]="Recursive deletion of home directory"
  ["rm -rf /*"]="Recursive deletion of root filesystem"
  ["dd if=/dev/zero of=/dev/"]="Overwriting disk device"
  ["mkfs"]="Formatting filesystem"
  ["> /dev/sd"]="Writing to disk device"
  [":(){ :|:& };:"]="Fork bomb attack"
  ["curl.*|.*sh"]="Executing remote script"
  ["wget.*|.*sh"]="Executing remote script"
  ["chmod -R 777 /"]="Dangerous permission change on root"
  ["chown -R"]="Recursive ownership change"
)

# Check for dangerous patterns
for pattern in "${!DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    reason="${DANGEROUS_PATTERNS[$pattern]}"
    
    cat <<EOF
{
  "action": "block",
  "reason": "🔴 危险操作被拦截: $reason",
  "suggestion": "请仔细检查命令，确保不会造成系统损坏。如果确实需要执行，请手动运行。"
}
EOF
    exit 1
  fi
done

# Check for sudo with dangerous commands
if echo "$COMMAND" | grep -qE "^sudo.*(rm|dd|mkfs|chmod|chown)"; then
  cat <<EOF
{
  "action": "block",
  "reason": "🟡 检测到 sudo 与潜在危险命令组合",
  "suggestion": "使用 sudo 执行系统命令需要格外小心，建议手动执行并确认操作。"
}
EOF
  exit 1
fi

# Command is safe
cat <<EOF
{
  "action": "allow",
  "reason": "命令安全检查通过"
}
EOF
exit 0
