#!/usr/bin/env bash
# cc-buddy PostToolUse hook dispatcher
# Executes enabled post-plugins to perform automation after tool execution

set -euo pipefail

# Get plugin root directory
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
CONFIG_FILE="${PLUGIN_ROOT}/plugins/config.json"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract tool information from input
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.toolName // ""')
TOOL_OUTPUT=$(echo "$HOOK_INPUT" | jq -r '.toolOutput // "{}"')

# Export environment variables for plugins
export TOOL_NAME
export TOOL_INPUT="$HOOK_INPUT"
export TOOL_OUTPUT

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
  local success=$(echo "$plugin_output" | jq -r '.success // true')
  local message=$(echo "$plugin_output" | jq -r '.message // ""')
  
  if [[ "$message" != "" ]]; then
    >&2 echo "[$plugin_name] $message"
  fi
  
  return 0
}

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  >&2 echo "Warning: Plugin config not found: $CONFIG_FILE"
  # Continue without plugins
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse"
  }
}
EOF
  exit 0
fi

# Read and sort plugins by priority (descending)
PLUGINS=$(jq -r '.post | sort_by(-.priority) | .[] | select(.enabled == true) | @json' "$CONFIG_FILE")

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
    # Execute plugin (errors don't stop the chain)
    execute_plugin "$plugin_script" "$plugin_name" || true
  fi
done <<< "$PLUGINS"

# Return success
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse"
  }
}
EOF

exit 0
