# cc-buddy Plugin Development Guide

This document introduces how to develop custom plugins for cc-buddy.

## Quick Start

### 1. Choose Plugin Type

- **PreToolUse Plugin**: Check and intercept before operation execution
- **PostToolUse Plugin**: Perform automated processing after operation execution

### 2. Create Plugin Script

Create executable bash scripts in corresponding directories:

```bash
# PreToolUse plugin
touch plugins/pre/my-plugin.sh
chmod +x plugins/pre/my-plugin.sh

# PostToolUse plugin
touch plugins/post/my-plugin.sh
chmod +x plugins/post/my-plugin.sh
```

### 3. Register Plugin

Edit `plugins/config.json`, add plugin configuration:

```json
{
  "pre": [
    {
      "name": "my-plugin",
      "enabled": true,
      "matcher": "Bash|Edit|Write",
      "priority": 80,
      "script": "plugins/pre/my-plugin.sh",
      "description": "My custom plugin"
    }
  ]
}
```

## PreToolUse Plugin Development

### Interface Specification

**Input Environment Variables**:
- `TOOL_NAME`: Tool name (Bash, Edit, Write, Read, etc.)
- `TOOL_INPUT`: Tool input parameters (JSON format)

**Output Format** (JSON to stdout):
```json
{
  "action": "allow|block",
  "reason": "Explanation of reason",
  "suggestion": "Optional suggestion"
}
```

**Exit Codes**:
- `0`: Allow execution
- `1`: Block execution

### Example: Check File Size

```bash
#!/usr/bin/env bash
# Check if the file to edit is too large

set -euo pipefail

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
  cat <<EOF
{
  "action": "allow",
  "reason": "No file to check"
}
EOF
  exit 0
fi

# Get file size (bytes)
FILE_SIZE=$(wc -c < "$FILE_PATH")
MAX_SIZE=$((10 * 1024 * 1024))  # 10MB

if [[ $FILE_SIZE -gt $MAX_SIZE ]]; then
  cat <<EOF
{
  "action": "block",
  "reason": "File too large ($(($FILE_SIZE / 1024 / 1024))MB), may cause performance issues",
  "suggestion": "建议分批处理或使用专门的大文件编辑工具"
}
EOF
  exit 1
fi

cat <<EOF
{
  "action": "allow",
  "reason": "File size is normal"
}
EOF
exit 0
```

### Common Patterns

#### 1. Command Check

```bash
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')

if [[ "$TOOL_NAME" == "Bash" ]] && echo "$COMMAND" | grep -q "pattern"; then
  # Specific pattern detected
fi
```

#### 2. File Path Check

```bash
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .path // ""')

if [[ "$FILE_PATH" =~ \.env$ ]]; then
  # .env file detected
fi
```

#### 3. Multi-condition Check

```bash
if [[ "$TOOL_NAME" == "Edit" ]] && [[ "$FILE_PATH" =~ \.ts$ ]]; then
  # TypeScript file editing
fi
```

## PostToolUse Plugin Development

### Interface Specification

**Input Environment Variables**:
- `TOOL_NAME`: Tool name
- `TOOL_INPUT`: Tool input parameters (JSON)
- `TOOL_OUTPUT`: Tool output result (JSON)

**Output Format** (JSON to stdout):
```json
{
  "success": true|false,
  "message": "Processing result explanation",
  "modifications": ["List of modified files"]
}
```

**Exit Codes**:
- `0`: Processing successful
- `1`: Processing failed (does not affect main flow)

### Example: Automatically Add Copyright Notice

```bash
#!/usr/bin/env bash
# Automatically add copyright notice to newly created files

set -euo pipefail

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

# Only process newly created files
if [[ "$TOOL_NAME" != "Write" ]] || [[ -z "$FILE_PATH" ]]; then
  cat <<EOF
{
  "success": true,
  "message": "Skipped"
}
EOF
  exit 0
fi

# Check file type
FILE_EXT="${FILE_PATH##*.}"

case "$FILE_EXT" in
  js|ts|jsx|tsx)
    COMMENT_START="/*"
    COMMENT_END="*/"
    ;;
  py)
    COMMENT_START="#"
    COMMENT_END=""
    ;;
  *)
    cat <<EOF
{
  "success": true,
  "message": "Unsupported file type"
}
EOF
    exit 0
    ;;
esac

# Check if copyright notice already exists
if head -n 5 "$FILE_PATH" | grep -q "Copyright"; then
  cat <<EOF
{
  "success": true,
  "message": "File already has copyright notice"
}
EOF
  exit 0
fi

# Add copyright notice
YEAR=$(date +%Y)
COPYRIGHT="$COMMENT_START
 * Copyright (c) $YEAR Your Company
 * All rights reserved.
 $COMMENT_END"

# Insert copyright notice at the beginning of the file
echo "$COPYRIGHT" | cat - "$FILE_PATH" > temp && mv temp "$FILE_PATH"

cat <<EOF
{
  "success": true,
  "message": "✨ Copyright notice added",
  "modifications": ["$FILE_PATH"]
}
EOF
exit 0
```

### Common Patterns

#### 1. File Type Detection

```bash
FILE_EXT="${FILE_PATH##*.}"

case "$FILE_EXT" in
  js|ts) echo "JavaScript/TypeScript" ;;
  py) echo "Python" ;;
  *) echo "Other" ;;
esac
```

#### 2. Tool Availability Check

```bash
if command -v prettier &> /dev/null; then
  prettier --write "$FILE_PATH"
else
  echo "Prettier not installed"
fi
```

#### 3. Silent Execution of External Commands

```bash
# Execute command without displaying output
npx prettier --write "$FILE_PATH" &> /dev/null || true
```

## Configuration Options

### matcher

Specify tool types the plugin matches, supports regular expressions:

```json
{
  "matcher": "Bash",           // Match Bash only
  "matcher": "Edit|Write",     // Match Edit or Write
  "matcher": ".*"              // Match all tools
}
```

Common tool types:
- `Bash`: Shell commands
- `Edit`: Edit existing files
- `Write`: Create new files
- `Read`: Read files
- `MultiEdit`: Batch editing

### priority

Plugin execution priority (higher numbers execute first):

```json
{
  "priority": 100  // High priority, execute first
  "priority": 50   // Medium priority
  "priority": 10   // Low priority, execute last
}
```

**Recommendations**:
- Security check plugins: 90-100
- Business rule plugins: 50-80
- Formatting plugins: 30-50
- Notification plugins: 10-20

### enabled

Enable or disable plugin:

```json
{
  "enabled": true   // Enable
  "enabled": false  // Disable
}
```

## Debugging Tips

### 1. View Environment Variables

```bash
#!/usr/bin/env bash
# Debug plugin

echo "TOOL_NAME: $TOOL_NAME" >&2
echo "TOOL_INPUT: $TOOL_INPUT" >&2
echo "TOOL_OUTPUT: $TOOL_OUTPUT" >&2
```

### 2. Log Recording

```bash
LOG_FILE="/tmp/cc-buddy-plugin.log"

echo "[$(date)] Plugin executed" >> "$LOG_FILE"
echo "TOOL_NAME: $TOOL_NAME" >> "$LOG_FILE"
```

### 3. Test Plugin

```bash
# Manually test PreToolUse plugin
export TOOL_NAME="Bash"
export TOOL_INPUT='{"command":"rm -rf /"}'
bash plugins/pre/block-dangerous.sh

# Manually test PostToolUse plugin
export TOOL_NAME="Edit"
export TOOL_INPUT='{"file_path":"test.js"}'
export TOOL_OUTPUT='{}'
bash plugins/post/auto-format.sh
```

## Best Practices

### 1. Error Handling

```bash
set -euo pipefail  # Exit immediately on error

# Use || true to avoid non-critical command failures
optional_command || true
```

### 2. JSON Parsing

```bash
# Use jq to parse JSON
VALUE=$(echo "$TOOL_INPUT" | jq -r '.key // "default"')

# Check if jq is available
if ! command -v jq &> /dev/null; then
  echo '{"action":"allow","reason":"jq not available"}' 
  exit 0
fi
```

### 3. Performance Optimization

```bash
# Avoid repeated operations
if [[ -f "$CACHE_FILE" ]]; then
  cat "$CACHE_FILE"
  exit 0
fi

# Limit execution time
timeout 3s expensive_command || echo "Timeout"
```

### 4. User Friendliness

```bash
# Provide clear error messages
cat <<EOF
{
  "action": "block",
  "reason": "🔴 Specific error reason",
  "suggestion": "Suggested solution"
}
EOF
```

## Plugin Example Library

### Check Git Branch

```bash
#!/usr/bin/env bash
# Block direct modifications on main branch

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
  cat <<EOF
{
  "action": "block",
  "reason": "🚫 Direct modification on $CURRENT_BRANCH branch is prohibited",
  "suggestion": "Please create a new branch for development"
}
EOF
  exit 1
fi

cat <<EOF
{
  "action": "allow",
  "reason": "Current branch: $CURRENT_BRANCH"
}
EOF
exit 0
```

### Automatic Git Commit

```bash
#!/usr/bin/env bash
# Automatically add modified files to Git

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

if [[ -z "$FILE_PATH" ]]; then
  cat <<EOF
{
  "success": true,
  "message": "No files to commit"
}
EOF
  exit 0
fi

# Check if in a Git repository
if ! git rev-parse --git-dir &> /dev/null; then
  cat <<EOF
{
  "success": true,
  "message": "Not in a Git repository"
}
EOF
  exit 0
fi

# Add to staging area
git add "$FILE_PATH" &> /dev/null

cat <<EOF
{
  "success": true,
  "message": "✅ Added to Git staging area",
  "modifications": ["$FILE_PATH"]
}
EOF
exit 0
```

### Code Complexity Check

```bash
#!/usr/bin/env bash
# Check code complexity

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

if [[ ! "$FILE_PATH" =~ \.(js|ts)$ ]]; then
  cat <<EOF
{
  "action": "allow",
  "reason": "Not a JS/TS file"
}
EOF
  exit 0
fi

# Simple complexity check: count nesting levels
MAX_NESTING=4
CURRENT_NESTING=$(grep -o '{' "$FILE_PATH" | wc -l)

if [[ $CURRENT_NESTING -gt $MAX_NESTING ]]; then
  cat <<EOF
{
  "action": "block",
  "reason": "⚠️ Code nesting level too deep ($CURRENT_NESTING levels)",
  "suggestion": "建议重构代码，降低复杂度"
}
EOF
  exit 1
fi

cat <<EOF
{
  "action": "allow",
  "reason": "Code complexity is normal"
}
EOF
exit 0
```

## Troubleshooting

### Plugin Not Executing

1. Check if `enabled` is `true`
2. Check if `matcher` matches tool type
3. Check if script has execute permission: `chmod +x plugin.sh`
4. Check if script path is correct

### Plugin Errors

1. Check error logs: `stderr` output
2. Manually test plugin script
3. Check if JSON format is correct
4. Ensure all dependency tools are installed

### Performance Issues

1. Check plugin execution time
2. Add timeout limits
3. Use caching to avoid repeated calculations
4. Lower plugin priority

## Contributing Plugins

If you develop useful plugins, you are welcome to contribute them to cc-buddy:

1. Fork the repository
2. Add plugins to `plugins/` directory
3. Update `plugins/config.json`
4. Add documentation and tests
5. Submit Pull Request

## Reference Resources

- [Architecture Design Document](architecture.md)
- [Hook Application Cases](hook-inspirations.md)
- [Claude Code Hooks Official Documentation](https://code.claude.com/docs/en/hooks-guide)
