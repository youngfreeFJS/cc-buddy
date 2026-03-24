#!/usr/bin/env bash
# cc-buddy PreToolUse hook dispatcher
# Executes enabled pre-plugins to validate operations before execution

set -euo pipefail

# Get plugin root directory
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
CONFIG_FILE="${PLUGIN_ROOT}/plugins/config.json"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract tool name from input
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.toolName // ""')

# Export environment variables for plugins
export TOOL_NAME
export TOOL_INPUT="$HOOK_INPUT"

# Function to check if tool matches matcher pattern
matches_tool() {
  local matcher=$1
  local tool=$2
  
  # Convert matcher to regex pattern
  local pattern=$(echo "$matcher" | sed 's/|/\\|/g')
  
  if echo "$tool" | grep -qE "^($pattern)$"; then
    return 0
  else
    return 1
  fi
}

# Function to execute a plugin
execute_plugin() {
  local plugin_script=$1
  local plugin_name=$2
  
  local script_path="${PLUGIN_ROOT}/${plugin_script}"
  
  if [[ ! -f "$script_path" ]]; then
    >&2 echo "Warning: Plugin script not found: $script_path"
    return 0
  fi
  
  if [[ ! -x "$script_path" ]]; then
    chmod +x "$script_path"
  fi
  
  # Execute plugin and capture output
  local plugin_output
  local plugin_exit_code
  
  plugin_output=$("$script_path" 2>&1) || plugin_exit_code=$?
  plugin_exit_code=${plugin_exit_code:-0}
  
  # Parse plugin response
  local action=$(echo "$plugin_output" | jq -r '.action // "allow"')
  local reason=$(echo "$plugin_output" | jq -r '.reason // ""')
  local suggestion=$(echo "$plugin_output" | jq -r '.suggestion // ""')
  
  if [[ "$action" == "block" ]] || [[ $plugin_exit_code -ne 0 ]]; then
    # Plugin blocked the operation
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "action": "block",
    "plugin": "$plugin_name",
    "reason": "$reason",
    "suggestion": "$suggestion"
  }
}
EOF
    exit 1
  fi
  
  return 0
}

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  >&2 echo "Warning: Plugin config not found: $CONFIG_FILE"
  # Allow by default if no config
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "action": "allow"
  }
}
EOF
  exit 0
fi

# Read and sort plugins by priority (descending)
PLUGINS=$(jq -r '.pre | sort_by(-.priority) | .[] | select(.enabled == true) | @json' "$CONFIG_FILE")

# Execute matching plugins
while IFS= read -r plugin_json; do
  if [[ -z "$plugin_json" ]]; then
    continue
  fi
  
  plugin_name=$(echo "$plugin_json" | jq -r '.name')
  plugin_matcher=$(echo "$plugin_json" | jq -r '.matcher')
  plugin_script=$(echo "$plugin_json" | jq -r '.script')
  
  # Check if tool matches this plugin's matcher
  if matches_tool "$plugin_matcher" "$TOOL_NAME"; then
    # Execute plugin
    execute_plugin "$plugin_script" "$plugin_name" || exit 1
  fi
done <<< "$PLUGINS"

# All plugins passed, allow operation
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "action": "allow"
  }
}
EOF

exit 0
