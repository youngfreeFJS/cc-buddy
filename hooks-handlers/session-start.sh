#!/usr/bin/env bash
# cc-buddy SessionStart hook.
# Injects additionalContext so Claude explains operations before executing them.

json_escape() {
  local value=$1
  local quote='"'
  value=${value//\\/\\\\}
  value=${value//$quote/\\$quote}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

# Read configuration from .claude/cc-buddy.json
CONFIG_FILE=".claude/cc-buddy.json"

if [ -f "$CONFIG_FILE" ]; then
  # Parse config using Python
  CONFIG_OUTPUT=$(python3 << 'PYEOF'
import json, sys

try:
    with open('.claude/cc-buddy.json') as f:
        config = json.load(f)
    
    # Merge user dangerous commands with defaults
    default_dangerous = ['rm -rf', 'DROP', 'DELETE FROM', 'TRUNCATE']
    user_dangerous = config.get('dangerousCommands', [])
    all_dangerous = list(dict.fromkeys(default_dangerous + user_dangerous))
    
    print(config.get('verbosity', 'normal'))
    print('|||'.join(config.get('skip', [])))
    print('|||'.join(config.get('skipPatterns', [])))
    print('|||'.join(all_dangerous))
except:
    print('normal')
    print('')
    print('')
    print('rm -rf|||DROP|||DELETE FROM|||TRUNCATE')
PYEOF
)
else
  # No config file, use defaults
  CONFIG_OUTPUT=$'normal\n\n\nrm -rf|||DROP|||DELETE FROM|||TRUNCATE'
fi

# Parse config output (4 lines: verbosity, skip, skipPatterns, dangerousCommands)
# Read line by line to preserve empty lines
line_num=0
while IFS= read -r line; do
  case $line_num in
    0) VERBOSITY="$line" ;;
    1) USER_SKIP="$line" ;;
    2) USER_SKIP_PATTERNS="$line" ;;
    3) USER_DANGEROUS="$line" ;;
  esac
  line_num=$((line_num + 1))
done <<< "$CONFIG_OUTPUT"

# Set defaults if empty
VERBOSITY="${VERBOSITY:-normal}"
USER_DANGEROUS="${USER_DANGEROUS:-rm -rf|||DROP|||DELETE FROM|||TRUNCATE}"

# Build skip list (append user skip to defaults)
DEFAULT_SKIP="ls, cd, cat, pwd, git status"
if [ -n "$USER_SKIP" ]; then
  SKIP_LIST="$DEFAULT_SKIP, ${USER_SKIP//|||/, }"
else
  SKIP_LIST="$DEFAULT_SKIP"
fi

# Build dangerous commands list
DANGEROUS_LIST="${USER_DANGEROUS//|||/, }"

# Generate prompt based on verbosity level
case "$VERBOSITY" in
  minimal)
    read -r -d '' ADDITIONAL_CONTEXT <<'PROMPT_EOF' || true
You have the cc-buddy plugin installed (minimal mode).

Only explain dangerous operations that could cause data loss or security issues.
For dangerous operations, use this format:
😇 your explanation here
⚠️ Risk: describe the risk

Dangerous operations include: DANGEROUS_PLACEHOLDER

For all other operations, skip the explanation and just run them.
PROMPT_EOF
    ADDITIONAL_CONTEXT="${ADDITIONAL_CONTEXT//DANGEROUS_PLACEHOLDER/$DANGEROUS_LIST}"
    ;;
    
  verbose)
    read -r -d '' ADDITIONAL_CONTEXT <<'PROMPT_EOF' || true
You have the cc-buddy plugin installed (verbose mode).

Before performing ANY operation, always output an explanation:
😇 your explanation here

For dangerous operations, add a risk warning:
⚠️ Risk: describe the risk

Dangerous operations include: DANGEROUS_PLACEHOLDER
PROMPT_EOF
    ADDITIONAL_CONTEXT="${ADDITIONAL_CONTEXT//DANGEROUS_PLACEHOLDER/$DANGEROUS_LIST}"
    ;;
    
  *)
    # normal (default)
    read -r -d '' ADDITIONAL_CONTEXT <<'PROMPT_EOF' || true
IMPORTANT: Write the 😇 explanation in the same language as the user's most recent message. If the user writes in English, explain in English. If the user writes in Chinese, explain in Chinese.

You have the cc-buddy plugin installed. Before performing any Bash, Edit, Write, or MultiEdit operation, you must first output a brief one-line explanation. Use this exact format:
😇 your explanation here

Explanation: 2-3 short clauses joined by commas, no period.
If the operation involves a tool or library, briefly mention what it does.
If the operation has risks or side effects, mention them.

Examples:
😇 Install axios, a Promise-based HTTP client for browsers and Node.js
😇 Remove border radius from avatar, switch to sharp corners to match the overall design language
😇 Recursively delete dist directory to clean up old build artifacts, this operation is irreversible

For trivially obvious commands SKIP_PLACEHOLDER skip the explanation and just run them.
For dangerous operations DANGEROUS_PLACEHOLDER, mention the risk.
Do not repeat the filename, command, or diff content, just the semantic intent. Do not skip this step.
PROMPT_EOF
    ADDITIONAL_CONTEXT="${ADDITIONAL_CONTEXT//SKIP_PLACEHOLDER/($SKIP_LIST)}"
    ADDITIONAL_CONTEXT="${ADDITIONAL_CONTEXT//DANGEROUS_PLACEHOLDER/($DANGEROUS_LIST)}"
    ;;
esac

cat <<JSONEOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$(json_escape "$ADDITIONAL_CONTEXT")"
  }
}
JSONEOF

exit 0
