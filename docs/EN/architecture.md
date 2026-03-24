# cc-buddy Architecture Design

## Overview

cc-buddy adopts a three-layer protection architecture, providing flexible extensibility through a plugin system.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Claude Code                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    cc-buddy Three-Layer Protection           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Layer 1: SessionStart (Explanation and Guidance)            │
│  ├─ Inject additionalContext                                  │
│  ├─ Enable Claude to proactively explain operations           │
│  └─ Provide risk level warnings                              │
│                                                               │
│  Layer 2: PreToolUse (Interception and Protection)           │
│  ├─ Plugin dispatcher (pre-tool-use.sh)                      │
│  ├─ Dangerous command detection                              │
│  ├─ Sensitive file protection                                │
│  └─ Extensible plugin system                                 │
│                                                               │
│  Layer 3: PostToolUse (Automated Testing and Optimization)   │
│  ├─ Plugin dispatcher (post-tool-use.sh)                     │
│  ├─ Code formatting                                          │
│  ├─ Automated testing                                        │
│  └─ Extensible plugin system                                 │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Hook Dispatcher

#### SessionStart Handler
- **File**: `hooks-handlers/session-start.sh`
- **Function**: Inject explanation instructions into Claude's context
- **Trigger**: When session starts
- **Output**: `additionalContext` JSON

#### PreToolUse Dispatcher
- **File**: `hooks-handlers/pre-tool-use.sh`
- **Function**: Schedule plugins for checks before tool execution
- **Trigger**: Before Claude prepares to execute a tool
- **Input**: Tool type, parameters, etc.
- **Output**: `allow` / `block` + reason

#### PostToolUse Dispatcher
- **File**: `hooks-handlers/post-tool-use.sh`
- **Function**: Schedule plugins for post-processing after tool execution
- **Trigger**: After Claude executes a tool
- **Input**: Tool type, execution result, etc.
- **Output**: Post-processing result

### 2. Plugin System

#### Plugin Directory Structure
```
plugins/
├── config.json              # Plugin configuration file
├── pre/                     # PreToolUse plugins
│   ├── block-dangerous.sh   # Dangerous command interception
│   └── protect-secrets.sh   # Sensitive file protection
└── post/                    # PostToolUse plugins
    ├── auto-format.sh       # Automatic formatting
    └── auto-test.sh         # Automated testing
```

#### Plugin Configuration Format (config.json)
```json
{
  "pre": [
    {
      "name": "block-dangerous",
      "enabled": true,
      "matcher": "Bash",
      "priority": 100,
      "script": "plugins/pre/block-dangerous.sh",
      "description": "Block dangerous shell commands"
    },
    {
      "name": "protect-secrets",
      "enabled": true,
      "matcher": "Read|Edit|Write",
      "priority": 90,
      "script": "plugins/pre/protect-secrets.sh",
      "description": "Protect sensitive files from access"
    }
  ],
  "post": [
    {
      "name": "auto-format",
      "enabled": true,
      "matcher": "Edit|Write",
      "priority": 100,
      "script": "plugins/post/auto-format.sh",
      "description": "Automatically format code"
    },
    {
      "name": "auto-test",
      "enabled": false,
      "matcher": "Edit|Write",
      "priority": 50,
      "script": "plugins/post/auto-test.sh",
      "description": "Automatically run related tests"
    }
  ]
}
```

### 3. Plugin Interface Specification

#### PreToolUse Plugin Interface

**Input** (via environment variables):
- `TOOL_NAME`: Tool name (Bash, Edit, Write, etc.)
- `TOOL_INPUT`: Tool input parameters (JSON)

**Output** (JSON to stdout):
```json
{
  "action": "allow|block",
  "reason": "Interception reason or approval explanation",
  "suggestion": "Optional alternative solution"
}
```

**Exit Codes**:
- `0`: Allow execution
- `1`: Block execution

#### PostToolUse Plugin Interface

**Input** (via environment variables):
- `TOOL_NAME`: Tool name
- `TOOL_INPUT`: Tool input parameters (JSON)
- `TOOL_OUTPUT`: Tool output result (JSON)

**Output** (JSON to stdout):
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

## Workflow

### PreToolUse Flow

```
Claude prepares to execute tool
    ↓
pre-tool-use.sh dispatcher starts
    ↓
Read plugins/config.json
    ↓
Sort enabled plugins by priority
    ↓
Execute matching plugins in sequence
    ↓
Any plugin returns block → Block execution
    ↓
All plugins return allow → Allow execution
```

### PostToolUse Flow

```
Claude completes tool execution
    ↓
post-tool-use.sh dispatcher starts
    ↓
Read plugins/config.json
    ↓
Sort enabled plugins by priority
    ↓
Execute matching plugins in sequence
    ↓
Collect processing results from all plugins
    ↓
Return summary information
```

## Extensibility

### Adding New Plugins

1. Create plugin script file
2. Register in `plugins/config.json`
3. Set `enabled: true` to enable

### Plugin Development Guide

#### PreToolUse Plugin Example
```bash
#!/usr/bin/env bash
# Example: Check if command contains dangerous operations

COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')

if [[ "$COMMAND" =~ rm.*-rf.*/$ ]]; then
  cat <<EOF
{
  "action": "block",
  "reason": "Detected dangerous recursive deletion operation",
  "suggestion": "Please specify the directory to delete explicitly, avoid using / as target"
}
EOF
  exit 1
fi

cat <<EOF
{
  "action": "allow",
  "reason": "Command is safe"
}
EOF
exit 0
```

#### PostToolUse Plugin Example
```bash
#!/usr/bin/env bash
# Example: Automatically format modified files

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

if [[ "$FILE_PATH" =~ \.(js|ts|jsx|tsx)$ ]]; then
  npx prettier --write "$FILE_PATH" 2>/dev/null
  
  cat <<EOF
{
  "success": true,
  "message": "File formatted with Prettier",
  "modifications": ["$FILE_PATH"]
}
EOF
  exit 0
fi

cat <<EOF
{
  "success": true,
  "message": "No formatting needed"
}
EOF
exit 0
```

## Configuration Management

### Global Configuration
- Location: `plugins/config.json`
- Purpose: Manage enabled status and priority of all plugins

### User Customization
Users can modify `config.json` to:
- Enable/disable plugins
- Adjust plugin priority
- Modify plugin parameters

### Project-level Configuration
Create `.cc-buddy/config.json` in project root directory to override global configuration.

## Performance Considerations

1. **Plugin Priority**: High-priority plugins execute first, enabling early interception
2. **Short-circuit Mechanism**: PreToolUse plugins stop immediately once any returns block
3. **Parallel Execution**: PostToolUse plugins can consider parallel execution (future optimization)
4. **Caching Mechanism**: Can cache plugin check results (future optimization)

## Security

1. **Plugin Isolation**: Each plugin runs in an independent process
2. **Timeout Control**: Plugin execution has timeout limit (default 5 seconds)
3. **Permission Control**: Plugins can only access necessary environment variables
4. **Audit Logging**: Record execution results of all plugins (optional)

## Future Extensions

1. **Plugin Marketplace**: Support installing plugins from remote repositories
2. **Plugin Dependencies**: Support dependencies between plugins
3. **Plugin Configuration UI**: Provide graphical configuration interface
4. **Plugin Testing Framework**: Provide plugin unit testing tools
5. **Performance Monitoring**: Monitor plugin execution time and resource consumption

## Example Scenarios

### Scenario 1: Block Dangerous Commands
```
User: Delete all log files
Claude: Preparing to execute rm -rf /var/log/*
    ↓
PreToolUse: block-dangerous plugin intercepts
    ↓
Return: Block execution, warn of risks and provide alternatives
```

### Scenario 2: Automatic Formatting
```
User: Modify index.js
Claude: Execute Edit operation
    ↓
PostToolUse: auto-format plugin executes
    ↓
Automatically run prettier --write index.js
    ↓
Return: File formatted
```

### Scenario 3: Multi-plugin Collaboration
```
User: Modify API code
    ↓
PreToolUse: 
  - protect-secrets: Check if modifying sensitive config ✓
  - tdd-guard: Check if tests written first ✓
    ↓
Claude: Execute modification
    ↓
PostToolUse:
  - auto-format: Format code ✓
  - auto-test: Run unit tests ✓
  - auto-stage: git add files ✓
```

## Summary

This architecture design provides:
- ✅ Three-layer protection mechanism
- ✅ Flexible plugin system
- ✅ Clear interface specification
- ✅ Good extensibility
- ✅ Reasonable performance considerations
- ✅ Comprehensive security mechanism

Through this architecture, cc-buddy can evolve from a simple command explanation tool into a powerful, extensible AI programming assistant enhancement system.
