# cc-buddy 插件开发指南

本文档介绍如何为 cc-buddy 开发自定义插件。

## 快速开始

### 1. 选择插件类型

- **PreToolUse 插件**: 在操作执行前进行检查和拦截
- **PostToolUse 插件**: 在操作执行后进行自动化处理

### 2. 创建插件脚本

在对应目录创建可执行的 bash 脚本：

```bash
# PreToolUse 插件
touch plugins/pre/my-plugin.sh
chmod +x plugins/pre/my-plugin.sh

# PostToolUse 插件
touch plugins/post/my-plugin.sh
chmod +x plugins/post/my-plugin.sh
```

### 3. 注册插件

编辑 `plugins/config.json`，添加插件配置：

```json
{
  "pre": [
    {
      "name": "my-plugin",
      "enabled": true,
      "matcher": "Bash|Edit|Write",
      "priority": 80,
      "script": "plugins/pre/my-plugin.sh",
      "description": "我的自定义插件"
    }
  ]
}
```

## PreToolUse 插件开发

### 接口规范

**输入环境变量**:
- `TOOL_NAME`: 工具名称 (Bash, Edit, Write, Read, etc.)
- `TOOL_INPUT`: 工具输入参数 (JSON 格式)

**输出格式** (JSON to stdout):
```json
{
  "action": "allow|block",
  "reason": "说明原因",
  "suggestion": "可选的建议"
}
```

**退出码**:
- `0`: 允许执行
- `1`: 阻止执行

### 示例：检查文件大小

```bash
#!/usr/bin/env bash
# 检查要编辑的文件是否过大

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

# 获取文件大小（字节）
FILE_SIZE=$(wc -c < "$FILE_PATH")
MAX_SIZE=$((10 * 1024 * 1024))  # 10MB

if [[ $FILE_SIZE -gt $MAX_SIZE ]]; then
  cat <<EOF
{
  "action": "block",
  "reason": "文件过大 ($(($FILE_SIZE / 1024 / 1024))MB)，可能导致性能问题",
  "suggestion": "建议分批处理或使用专门的大文件编辑工具"
}
EOF
  exit 1
fi

cat <<EOF
{
  "action": "allow",
  "reason": "文件大小正常"
}
EOF
exit 0
```

### 常用模式

#### 1. 命令检查

```bash
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')

if [[ "$TOOL_NAME" == "Bash" ]] && echo "$COMMAND" | grep -q "pattern"; then
  # 检测到特定模式
fi
```

#### 2. 文件路径检查

```bash
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .path // ""')

if [[ "$FILE_PATH" =~ \.env$ ]]; then
  # 检测到 .env 文件
fi
```

#### 3. 多条件判断

```bash
if [[ "$TOOL_NAME" == "Edit" ]] && [[ "$FILE_PATH" =~ \.ts$ ]]; then
  # TypeScript 文件编辑
fi
```

## PostToolUse 插件开发

### 接口规范

**输入环境变量**:
- `TOOL_NAME`: 工具名称
- `TOOL_INPUT`: 工具输入参数 (JSON)
- `TOOL_OUTPUT`: 工具输出结果 (JSON)

**输出格式** (JSON to stdout):
```json
{
  "success": true|false,
  "message": "处理结果说明",
  "modifications": ["修改的文件列表"]
}
```

**退出码**:
- `0`: 处理成功
- `1`: 处理失败（不影响主流程）

### 示例：自动添加版权声明

```bash
#!/usr/bin/env bash
# 自动为新创建的文件添加版权声明

set -euo pipefail

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

# 只处理新创建的文件
if [[ "$TOOL_NAME" != "Write" ]] || [[ -z "$FILE_PATH" ]]; then
  cat <<EOF
{
  "success": true,
  "message": "跳过"
}
EOF
  exit 0
fi

# 检查文件类型
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
  "message": "不支持的文件类型"
}
EOF
    exit 0
    ;;
esac

# 检查是否已有版权声明
if head -n 5 "$FILE_PATH" | grep -q "Copyright"; then
  cat <<EOF
{
  "success": true,
  "message": "文件已有版权声明"
}
EOF
  exit 0
fi

# 添加版权声明
YEAR=$(date +%Y)
COPYRIGHT="$COMMENT_START
 * Copyright (c) $YEAR Your Company
 * All rights reserved.
 $COMMENT_END"

# 在文件开头插入版权声明
echo "$COPYRIGHT" | cat - "$FILE_PATH" > temp && mv temp "$FILE_PATH"

cat <<EOF
{
  "success": true,
  "message": "✨ 已添加版权声明",
  "modifications": ["$FILE_PATH"]
}
EOF
exit 0
```

### 常用模式

#### 1. 文件类型判断

```bash
FILE_EXT="${FILE_PATH##*.}"

case "$FILE_EXT" in
  js|ts) echo "JavaScript/TypeScript" ;;
  py) echo "Python" ;;
  *) echo "Other" ;;
esac
```

#### 2. 工具可用性检查

```bash
if command -v prettier &> /dev/null; then
  prettier --write "$FILE_PATH"
else
  echo "Prettier not installed"
fi
```

#### 3. 静默执行外部命令

```bash
# 执行命令但不显示输出
npx prettier --write "$FILE_PATH" &> /dev/null || true
```

## 配置选项

### matcher

指定插件匹配的工具类型，支持正则表达式：

```json
{
  "matcher": "Bash",           // 只匹配 Bash
  "matcher": "Edit|Write",     // 匹配 Edit 或 Write
  "matcher": ".*"              // 匹配所有工具
}
```

常用工具类型：
- `Bash`: Shell 命令
- `Edit`: 编辑现有文件
- `Write`: 创建新文件
- `Read`: 读取文件
- `MultiEdit`: 批量编辑

### priority

插件执行优先级（数字越大越先执行）：

```json
{
  "priority": 100  // 高优先级，先执行
  "priority": 50   // 中优先级
  "priority": 10   // 低优先级，后执行
}
```

**建议**：
- 安全检查插件：90-100
- 业务规则插件：50-80
- 格式化插件：30-50
- 通知插件：10-20

### enabled

启用或禁用插件：

```json
{
  "enabled": true   // 启用
  "enabled": false  // 禁用
}
```

## 调试技巧

### 1. 查看环境变量

```bash
#!/usr/bin/env bash
# 调试插件

echo "TOOL_NAME: $TOOL_NAME" >&2
echo "TOOL_INPUT: $TOOL_INPUT" >&2
echo "TOOL_OUTPUT: $TOOL_OUTPUT" >&2
```

### 2. 记录日志

```bash
LOG_FILE="/tmp/cc-buddy-plugin.log"

echo "[$(date)] Plugin executed" >> "$LOG_FILE"
echo "TOOL_NAME: $TOOL_NAME" >> "$LOG_FILE"
```

### 3. 测试插件

```bash
# 手动测试 PreToolUse 插件
export TOOL_NAME="Bash"
export TOOL_INPUT='{"command":"rm -rf /"}'
bash plugins/pre/block-dangerous.sh

# 手动测试 PostToolUse 插件
export TOOL_NAME="Edit"
export TOOL_INPUT='{"file_path":"test.js"}'
export TOOL_OUTPUT='{}'
bash plugins/post/auto-format.sh
```

## 最佳实践

### 1. 错误处理

```bash
set -euo pipefail  # 遇到错误立即退出

# 使用 || true 避免非关键命令失败
optional_command || true
```

### 2. JSON 解析

```bash
# 使用 jq 解析 JSON
VALUE=$(echo "$TOOL_INPUT" | jq -r '.key // "default"')

# 检查 jq 是否可用
if ! command -v jq &> /dev/null; then
  echo '{"action":"allow","reason":"jq not available"}' 
  exit 0
fi
```

### 3. 性能优化

```bash
# 避免重复操作
if [[ -f "$CACHE_FILE" ]]; then
  cat "$CACHE_FILE"
  exit 0
fi

# 限制执行时间
timeout 3s expensive_command || echo "Timeout"
```

### 4. 用户友好

```bash
# 提供清晰的错误信息
cat <<EOF
{
  "action": "block",
  "reason": "🔴 具体的错误原因",
  "suggestion": "建议的解决方案"
}
EOF
```

## 插件示例库

### 检查 Git 分支

```bash
#!/usr/bin/env bash
# 阻止在 main 分支上直接修改

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
  cat <<EOF
{
  "action": "block",
  "reason": "🚫 禁止在 $CURRENT_BRANCH 分支上直接修改",
  "suggestion": "请创建新分支进行开发"
}
EOF
  exit 1
fi

cat <<EOF
{
  "action": "allow",
  "reason": "当前分支: $CURRENT_BRANCH"
}
EOF
exit 0
```

### 自动 Git Commit

```bash
#!/usr/bin/env bash
# 自动将修改的文件添加到 Git

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

if [[ -z "$FILE_PATH" ]]; then
  cat <<EOF
{
  "success": true,
  "message": "无文件需要提交"
}
EOF
  exit 0
fi

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir &> /dev/null; then
  cat <<EOF
{
  "success": true,
  "message": "不在 Git 仓库中"
}
EOF
  exit 0
fi

# 添加到暂存区
git add "$FILE_PATH" &> /dev/null

cat <<EOF
{
  "success": true,
  "message": "✅ 已添加到 Git 暂存区",
  "modifications": ["$FILE_PATH"]
}
EOF
exit 0
```

### 代码复杂度检查

```bash
#!/usr/bin/env bash
# 检查代码复杂度

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

if [[ ! "$FILE_PATH" =~ \.(js|ts)$ ]]; then
  cat <<EOF
{
  "action": "allow",
  "reason": "非 JS/TS 文件"
}
EOF
  exit 0
fi

# 简单的复杂度检查：统计嵌套层级
MAX_NESTING=4
CURRENT_NESTING=$(grep -o '{' "$FILE_PATH" | wc -l)

if [[ $CURRENT_NESTING -gt $MAX_NESTING ]]; then
  cat <<EOF
{
  "action": "block",
  "reason": "⚠️ 代码嵌套层级过深 ($CURRENT_NESTING 层)",
  "suggestion": "建议重构代码，降低复杂度"
}
EOF
  exit 1
fi

cat <<EOF
{
  "action": "allow",
  "reason": "代码复杂度正常"
}
EOF
exit 0
```

## 故障排查

### 插件不执行

1. 检查 `enabled` 是否为 `true`
2. 检查 `matcher` 是否匹配工具类型
3. 检查脚本是否有执行权限：`chmod +x plugin.sh`
4. 检查脚本路径是否正确

### 插件报错

1. 查看错误日志：`stderr` 输出
2. 手动测试插件脚本
3. 检查 JSON 格式是否正确
4. 确保所有依赖工具已安装

### 性能问题

1. 检查插件执行时间
2. 添加超时限制
3. 使用缓存避免重复计算
4. 降低插件优先级

## 贡献插件

如果你开发了有用的插件，欢迎贡献到 cc-buddy：

1. Fork 仓库
2. 添加插件到 `plugins/` 目录
3. 更新 `plugins/config.json`
4. 添加文档和测试
5. 提交 Pull Request

## 参考资源

- [架构设计文档](architecture.md)
- [Hook 应用案例](hook-inspirations.md)
- [Claude Code Hooks 官方文档](https://code.claude.com/docs/en/hooks-guide)
