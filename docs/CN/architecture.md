# cc-buddy 架构设计

## 概述

cc-buddy 采用三层防护架构，通过插件化系统提供灵活的扩展能力。

## 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      Claude Code                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    cc-buddy 三层防护                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Layer 1: SessionStart (解释和引导)                          │
│  ├─ 注入 additionalContext                                   │
│  ├─ 让 Claude 主动解释操作                                   │
│  └─ 提供风险等级提示                                         │
│                                                               │
│  Layer 2: PreToolUse (拦截和保护)                            │
│  ├─ 插件调度器 (pre-tool-use.sh)                            │
│  ├─ 危险命令检测                                             │
│  ├─ 敏感文件保护                                             │
│  └─ 可扩展插件系统                                           │
│                                                               │
│  Layer 3: PostToolUse (自动化测试和优化)                         │
│  ├─ 插件调度器 (post-tool-use.sh)                           │
│  ├─ 代码格式化                                               │
│  ├─ 自动测试                                                 │
│  └─ 可扩展插件系统                                           │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## 核心组件

### 1. Hook 调度器

#### SessionStart Handler
- **文件**: `hooks-handlers/session-start.sh`
- **功能**: 注入解释指令到 Claude 的上下文
- **触发时机**: 会话启动时
- **输出**: `additionalContext` JSON

#### PreToolUse Dispatcher
- **文件**: `hooks-handlers/pre-tool-use.sh`
- **功能**: 在工具执行前调度插件进行检查
- **触发时机**: Claude 准备执行工具前
- **输入**: 工具类型、参数等
- **输出**: `allow` / `block` + 原因

#### PostToolUse Dispatcher
- **文件**: `hooks-handlers/post-tool-use.sh`
- **功能**: 在工具执行后调度插件进行后处理
- **触发时机**: Claude 执行工具后
- **输入**: 工具类型、执行结果等
- **输出**: 后处理结果

### 2. 插件系统

#### 插件目录结构
```
plugins/
├── config.json              # 插件配置文件
├── pre/                     # PreToolUse 插件
│   ├── block-dangerous.sh   # 危险命令拦截
│   └── protect-secrets.sh   # 敏感文件保护
└── post/                    # PostToolUse 插件
    ├── auto-format.sh       # 自动格式化
    └── auto-test.sh         # 自动测试
```

#### 插件配置格式 (config.json)
```json
{
  "pre": [
    {
      "name": "block-dangerous",
      "enabled": true,
      "matcher": "Bash",
      "priority": 100,
      "script": "plugins/pre/block-dangerous.sh",
      "description": "阻止危险的 shell 命令"
    },
    {
      "name": "protect-secrets",
      "enabled": true,
      "matcher": "Read|Edit|Write",
      "priority": 90,
      "script": "plugins/pre/protect-secrets.sh",
      "description": "保护敏感文件不被访问"
    }
  ],
  "post": [
    {
      "name": "auto-format",
      "enabled": true,
      "matcher": "Edit|Write",
      "priority": 100,
      "script": "plugins/post/auto-format.sh",
      "description": "自动格式化代码"
    },
    {
      "name": "auto-test",
      "enabled": false,
      "matcher": "Edit|Write",
      "priority": 50,
      "script": "plugins/post/auto-test.sh",
      "description": "自动运行相关测试"
    }
  ]
}
```

### 3. 插件接口规范

#### PreToolUse 插件接口

**输入** (通过环境变量):
- `TOOL_NAME`: 工具名称 (Bash, Edit, Write, etc.)
- `TOOL_INPUT`: 工具输入参数 (JSON)

**输出** (JSON to stdout):
```json
{
  "action": "allow|block",
  "reason": "拦截原因或通过说明",
  "suggestion": "可选的替代方案"
}
```

**退出码**:
- `0`: 允许执行
- `1`: 阻止执行

#### PostToolUse 插件接口

**输入** (通过环境变量):
- `TOOL_NAME`: 工具名称
- `TOOL_INPUT`: 工具输入参数 (JSON)
- `TOOL_OUTPUT`: 工具输出结果 (JSON)

**输出** (JSON to stdout):
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

## 工作流程

### PreToolUse 流程

```
Claude 准备执行工具
    ↓
pre-tool-use.sh 调度器启动
    ↓
读取 plugins/config.json
    ↓
按 priority 排序启用的插件
    ↓
依次执行匹配的插件
    ↓
任一插件返回 block → 阻止执行
    ↓
所有插件返回 allow → 允许执行
```

### PostToolUse 流程

```
Claude 执行工具完成
    ↓
post-tool-use.sh 调度器启动
    ↓
读取 plugins/config.json
    ↓
按 priority 排序启用的插件
    ↓
依次执行匹配的插件
    ↓
收集所有插件的处理结果
    ↓
返回汇总信息
```

## 扩展性

### 添加新插件

1. 创建插件脚本文件
2. 在 `plugins/config.json` 中注册
3. 设置 `enabled: true` 启用

### 插件开发指南

#### PreToolUse 插件示例
```bash
#!/usr/bin/env bash
# 示例：检查命令是否包含危险操作

COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')

if [[ "$COMMAND" =~ rm.*-rf.*/$ ]]; then
  cat <<EOF
{
  "action": "block",
  "reason": "检测到危险的递归删除操作",
  "suggestion": "请明确指定要删除的目录，避免使用 / 作为目标"
}
EOF
  exit 1
fi

cat <<EOF
{
  "action": "allow",
  "reason": "命令安全"
}
EOF
exit 0
```

#### PostToolUse 插件示例
```bash
#!/usr/bin/env bash
# 示例：自动格式化修改的文件

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

if [[ "$FILE_PATH" =~ \.(js|ts|jsx|tsx)$ ]]; then
  npx prettier --write "$FILE_PATH" 2>/dev/null
  
  cat <<EOF
{
  "success": true,
  "message": "已使用 Prettier 格式化文件",
  "modifications": ["$FILE_PATH"]
}
EOF
  exit 0
fi

cat <<EOF
{
  "success": true,
  "message": "无需格式化"
}
EOF
exit 0
```

## 配置管理

### 全局配置
- 位置: `plugins/config.json`
- 作用: 管理所有插件的启用状态和优先级

### 用户自定义
用户可以通过修改 `config.json` 来：
- 启用/禁用插件
- 调整插件优先级
- 修改插件参数

### 项目级配置
可以在项目根目录创建 `.cc-buddy/config.json` 覆盖全局配置。

## 性能考虑

1. **插件优先级**: 高优先级插件先执行，可以提前拦截
2. **短路机制**: PreToolUse 插件一旦返回 block 立即停止
3. **并行执行**: PostToolUse 插件可以考虑并行执行（未来优化）
4. **缓存机制**: 可以缓存插件检查结果（未来优化）

## 安全性

1. **插件隔离**: 每个插件在独立进程中运行
2. **超时控制**: 插件执行有超时限制（默认 5 秒）
3. **权限控制**: 插件只能访问必要的环境变量
4. **审计日志**: 记录所有插件的执行结果（可选）

## 未来扩展

1. **插件市场**: 支持从远程仓库安装插件
2. **插件依赖**: 支持插件间的依赖关系
3. **插件配置 UI**: 提供图形化配置界面
4. **插件测试框架**: 提供插件单元测试工具
5. **性能监控**: 监控插件执行时间和资源消耗

## 示例场景

### 场景 1: 阻止危险命令
```
用户: 删除所有日志文件
Claude: 准备执行 rm -rf /var/log/*
    ↓
PreToolUse: block-dangerous 插件拦截
    ↓
返回: 阻止执行，提示风险和替代方案
```

### 场景 2: 自动格式化
```
用户: 修改 index.js
Claude: 执行 Edit 操作
    ↓
PostToolUse: auto-format 插件执行
    ↓
自动运行 prettier --write index.js
    ↓
返回: 文件已格式化
```

### 场景 3: 多插件协作
```
用户: 修改 API 代码
    ↓
PreToolUse: 
  - protect-secrets: 检查是否修改敏感配置 ✓
  - tdd-guard: 检查是否先写测试 ✓
    ↓
Claude: 执行修改
    ↓
PostToolUse:
  - auto-format: 格式化代码 ✓
  - auto-test: 运行单元测试 ✓
  - auto-stage: git add 文件 ✓
```

## 总结

这个架构设计提供了：
- ✅ 三层防护机制
- ✅ 灵活的插件系统
- ✅ 清晰的接口规范
- ✅ 良好的扩展性
- ✅ 合理的性能考虑
- ✅ 完善的安全机制

通过这个架构，cc-buddy 可以从一个简单的命令解释工具，进化为一个功能强大、可扩展的 AI 编程助手增强系统。
