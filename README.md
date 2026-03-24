<div align="center">
  <img src="https://gw.alipayobjects.com/zos/k/2n/centaur.svg" width="106" alt="cc-buddy" />
  <h1>cc-buddy 😇</h1>
  <p><em>Make every line of your cc building more fun and enlightening, commenting codes real-time before Claude Code executes them.</em></p>
</div>

<div align="center">
  <img src="https://gw.alipayobjects.com/zos/k/ut/buddy.gif" width="800" alt="cc-buddy demo" />
</div>

## Overview

cc-buddy 😇 provides a three-layer protection system for Claude Code, making AI-assisted development safer, smarter, and more automated.

### Three-Layer Architecture

1. **SessionStart** - Explanation and Guidance
   - Injects instructions so Claude explains operations before executing
   - Provides context about what each command does and why it matters
   - Skips trivial commands like `ls`, `cat`, `git status`

2. **PreToolUse** - Interception and Protection
   - Blocks dangerous commands that could damage your system
   - Protects sensitive files from unauthorized access
   - Extensible plugin system for custom safety rules

3. **PostToolUse** - Automation and Optimization
   - Automatically formats code after editing
   - Runs tests to catch issues early
   - Extensible plugin system for custom workflows

No external LLM is needed; Claude itself generates the explanations and the plugins handle the safety and automation.

## Installation

```bash
claude plugins marketplace add alibaba-flyai/cc-buddy
claude plugins install cc-buddy@flyai
```

Then open a new cc tab or shell to activate.

## Examples

### Layer 1: Explanation

**Bash**: explain before running a command

    > 帮我安装 axios

    😇 安装 axios，一个基于 Promise 的 HTTP 客户端，支持拦截器和自动 JSON 转换

    $ npm install axios

**Edit**: explain before showing the diff

    > Remove the avatar border radius

    😇 Remove border radius from avatar, switch to sharp corners to match the design language

    src/components/Avatar.tsx
    66 -     "borderRadius": 45,
    66 +     "borderRadius": 0,

### Layer 2: Protection

**Block dangerous commands**:

    > Delete all log files

    🔴 危险操作被拦截: Recursive deletion detected
    建议: 请明确指定要删除的目录，避免使用通配符

**Protect sensitive files**:

    > Read the .env file

    🔒 敏感文件保护: 该文件可能包含密钥、密码或其他敏感信息
    建议: 如果需要访问此文件，请手动操作

### Layer 3: Automation

**Auto-format after editing**:

    > Update the API handler

    [Edit completed]
    ✨ 已使用 Prettier 格式化文件

## How It Works

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
│  └─ 让 Claude 主动解释操作                                   │
│                                                               │
│  Layer 2: PreToolUse (拦截和保护)                            │
│  ├─ block-dangerous: 危险命令检测                            │
│  ├─ protect-secrets: 敏感文件保护                            │
│  └─ 可扩展插件系统                                           │
│                                                               │
│  Layer 3: PostToolUse (自动化和优化)                         │
│  ├─ auto-format: 代码格式化                                  │
│  ├─ auto-test: 自动测试 (可选)                               │
│  └─ 可扩展插件系统                                           │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Plugin System

cc-buddy uses a flexible plugin system that allows you to customize behavior:

### Built-in Plugins

**PreToolUse Plugins** (Protection):
- `block-dangerous` - Blocks dangerous shell commands
- `protect-secrets` - Protects sensitive files

**PostToolUse Plugins** (Automation):
- `auto-format` - Automatically formats code (Prettier, Black, gofmt, rustfmt)
- `auto-test` - Runs tests after code changes (disabled by default)

### Configuration

Edit `plugins/config.json` to enable/disable plugins or adjust priorities:

```json
{
  "pre": [
    {
      "name": "block-dangerous",
      "enabled": true,
      "matcher": "Bash",
      "priority": 100,
      "description": "阻止危险的 shell 命令"
    }
  ],
  "post": [
    {
      "name": "auto-format",
      "enabled": true,
      "matcher": "Edit|Write",
      "priority": 100,
      "description": "自动格式化代码"
    }
  ]
}
```

### Adding Custom Plugins

1. Create your plugin script in `plugins/pre/` or `plugins/post/`
2. Add configuration to `plugins/config.json`
3. Set `enabled: true` to activate

See [docs/architecture.md](docs/architecture.md) for detailed plugin development guide.

## Update

```bash
claude plugins marketplace update flyai
claude plugins update cc-buddy@flyai
```

Then open a new cc tab or shell to apply the update.

## Uninstall

```bash
claude plugins uninstall cc-buddy@flyai
claude plugins marketplace remove flyai
```

Then open a new cc tab or shell window.

## Development

```bash
git clone https://github.com/alibaba-flyai/cc-buddy.git
cd cc-buddy
```

To test changes, open a separate project (not cc-buddy itself) and pass the cloned directory:

```bash
git clone https://github.com/alibaba-flyai/cc-buddy.git
cd ~/your-other-project
claude --plugin-dir /path/to/cloned/cc-buddy
```

The `--plugin-dir` flag loads the plugin for this session only, without installing it globally. You must use a different project because the checked-in `.claude/settings.json` disables plugins inside cc-buddy to prevent self-explanation loops during development.

Main files:

```text
.claude-plugin/plugin.json           plugin manifest
.claude-plugin/marketplace.json      marketplace manifest
hooks/hooks.json                     hook declarations
hooks-handlers/
  ├── session-start.sh               SessionStart hook (explanation)
  ├── pre-tool-use.sh                PreToolUse dispatcher (protection)
  └── post-tool-use.sh               PostToolUse dispatcher (automation)
plugins/
  ├── config.json                    plugin configuration
  ├── pre/                           PreToolUse plugins
  │   ├── block-dangerous.sh         dangerous command blocker
  │   └── protect-secrets.sh         sensitive file protector
  └── post/                          PostToolUse plugins
      ├── auto-format.sh             code formatter
      └── auto-test.sh               test runner
docs/
  ├── architecture.md                architecture design
  └── hook-inspirations.md           hook use cases research
```

Run the test suite locally without installing the plugin:

```bash
bash test.sh
```
