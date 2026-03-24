# RFC: cc-buddy 三层防护架构

## 中文版本

### Issue Title
```
[RFC] 为 cc-buddy 增加三层防护架构：全生命周期质量保障体系
```

### 提案概述

本提案建议为 cc-buddy 引入**三层防护架构**，通过扩展 Claude Code Hooks 的能力，在 AI 编程的全生命周期中提供安全保护和质量保障。

---

## 🎯 核心理念

### 三层防护架构

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
│  🎓 Layer 1: SessionStart (解释和引导)                       │
│  ├─ 让 AI 主动解释操作意图                                   │
│  ├─ 提供风险等级评估                                         │
│  └─ 引导用户理解 AI 行为                                     │
│                                                               │
│  🛡️ Layer 2: PreToolUse (拦截和保护)                        │
│  ├─ 危险命令检测与拦截                                       │
│  ├─ 敏感文件访问控制                                         │
│  ├─ 代码规范前置检查                                         │
│  └─ 质量门禁前置验证                                         │
│                                                               │
│  ✨ Layer 3: PostToolUse (自动化和优化)                      │
│  ├─ 代码自动格式化                                           │
│  ├─ 单元测试自动运行                                         │
│  ├─ 代码质量自动检查                                         │
│  └─ Git 操作自动化                                           │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 💡 核心价值主张

### 1. 全生命周期 Hook 能力扩展

**现状问题**：
- 当前 cc-buddy 仅使用 SessionStart hook
- 缺少对 AI 操作执行前后的干预能力
- 无法在关键节点进行质量把控

**解决方案**：
- ✅ **SessionStart**: 会话开始时的解释和引导
- ✅ **PreToolUse**: 工具执行前的拦截和保护
- ✅ **PostToolUse**: 工具执行后的自动化和优化

**价值**：
- 📈 覆盖 AI 编程的完整生命周期
- 🔒 在每个关键节点提供质量保障
- 🚀 最大化 Claude Code Hooks 的能力

---

### 2. QA 工程师视角：质量前置

**背景**：
作为一名 QA 工程师，我深知**质量前置**的重要性。传统的"开发完成 → QA 测试 → 发现问题 → 返工修复"的模式效率低下、成本高昂。

**痛点**：
- ❌ AI 可能生成不符合规范的代码
- ❌ AI 可能执行危险的系统命令
- ❌ AI 可能忽略单元测试和代码检查
- ❌ 问题发现太晚，修复成本高

**解决方案**：
通过 **PreToolUse** 和 **PostToolUse** hooks，将质量检查前置到研发阶段：

#### PreToolUse（质量门禁）
```
AI 准备执行操作
    ↓
PreToolUse 插件检查
    ├─ 代码规范检查
    ├─ 安全风险评估
    ├─ 测试覆盖率要求
    └─ 架构规范验证
    ↓
不符合要求 → 阻止执行 + 提供修改建议
符合要求 → 允许执行
```

#### PostToolUse（自动化保障）
```
AI 完成代码修改
    ↓
PostToolUse 插件自动执行
    ├─ 代码格式化（Prettier/Black）
    ├─ 单元测试运行（Jest/pytest）
    ├─ 静态代码分析（ESLint/SonarQube）
    ├─ 代码覆盖率检查
    └─ Git 提交规范检查
    ↓
问题立即暴露 → 及时修复
质量自动保障 → 减少返工
```

**价值**：
- ✅ **质量前置**：在代码生成阶段就保证质量
- ✅ **自动化**：无需人工干预，自动执行检查
- ✅ **快速反馈**：问题立即发现，立即修复
- ✅ **降低成本**：减少后期返工和修复成本

---

### 3. 安全性增强

**场景 1：防止危险命令执行**
```
用户: "清理一下系统日志"
AI: 准备执行 rm -rf /var/log/*

PreToolUse 插件拦截:
🔴 危险操作！检测到递归删除操作
   风险: 可能删除重要系统日志
   建议: 使用 logrotate 或指定具体文件
   
操作被阻止 ✅
```

**场景 2：保护敏感文件**
```
用户: "查看一下配置文件"
AI: 准备读取 .env 文件

PreToolUse 插件拦截:
🔒 敏感文件保护！该文件包含密钥和密码
   建议: 手动查看或使用环境变量管理工具
   
操作被阻止 ✅
```

---

### 4. 开发效率提升

**场景 1：自动代码格式化**
```
AI 修改了 index.js
    ↓
PostToolUse 自动执行 Prettier
    ↓
代码自动格式化 ✅
无需手动运行格式化工具
```

**场景 2：自动运行测试**
```
AI 修改了业务逻辑代码
    ↓
PostToolUse 自动运行相关测试
    ↓
测试失败 → 立即提示 AI 修复
测试通过 → 继续下一步
```

**场景 3：自动 Git 操作**
```
AI 完成代码修改
    ↓
PostToolUse 自动执行
    ├─ git add 修改的文件
    ├─ 检查 commit message 规范
    └─ 提示是否需要 commit
```

---

### 5. 可扩展的插件生态

**插件化架构**：
```json
{
  "pre": [
    {
      "name": "block-dangerous",
      "enabled": true,
      "priority": 100,
      "description": "阻止危险命令"
    },
    {
      "name": "protect-secrets",
      "enabled": true,
      "priority": 90,
      "description": "保护敏感文件"
    },
    {
      "name": "tdd-guard",
      "enabled": false,
      "priority": 80,
      "description": "强制 TDD 流程"
    }
  ],
  "post": [
    {
      "name": "auto-format",
      "enabled": true,
      "priority": 100,
      "description": "自动格式化"
    },
    {
      "name": "auto-test",
      "enabled": false,
      "priority": 50,
      "description": "自动运行测试"
    }
  ]
}
```

**扩展能力**：
- ✅ 用户可以自定义插件
- ✅ 插件可以灵活启用/禁用
- ✅ 支持优先级控制
- ✅ 支持条件匹配（matcher）

---

### 6. 团队协作与规范落地

**场景：统一团队代码规范**
```
团队规范:
- 必须使用 TypeScript strict 模式
- 必须有单元测试
- 必须通过 ESLint 检查
- Commit message 必须符合规范

通过 PreToolUse 插件:
├─ 检查 TypeScript 配置
├─ 验证测试文件存在
├─ 运行 ESLint 检查
└─ 验证 commit message

不符合规范 → 阻止提交 + 提供修改建议
```

**价值**：
- ✅ 规范自动化落地，无需人工审查
- ✅ 新人快速适应团队规范
- ✅ 减少 Code Review 负担
- ✅ 提升团队整体代码质量

---

### 7. 企业级质量保障

**场景：符合企业安全合规要求**
```
企业要求:
- 禁止访问生产环境配置
- 禁止执行高危命令
- 所有代码必须通过安全扫描
- 必须记录操作审计日志

通过三层防护:
├─ PreToolUse: 拦截违规操作
├─ PostToolUse: 自动安全扫描
└─ 审计日志: 记录所有操作
```

**价值**：
- ✅ 满足企业安全合规要求
- ✅ 降低安全风险
- ✅ 提供完整的操作审计
- ✅ 支持大规模团队使用

---

## 📋 实施方案

### Phase 1: 核心架构 ✅
- [x] 设计三层防护架构
- [x] 实现 PreToolUse 调度器
- [x] 实现 PostToolUse 调度器
- [x] 设计插件配置系统

### Phase 2: 基础插件 ✅
- [x] block-dangerous（危险命令拦截）
- [x] protect-secrets（敏感文件保护）
- [x] auto-format（自动格式化）
- [x] auto-test（自动测试）

### Phase 3: 文档完善 ✅
- [x] 架构设计文档
- [x] 插件开发指南
- [x] 使用示例和最佳实践
- [x] 完整的测试套件

### Phase 4: 社区推广（待进行）
- [ ] 发布到 Claude Code 插件市场
- [ ] 编写博客文章和教程
- [ ] 收集用户反馈
- [ ] 持续迭代优化

---

## 🎨 内置插件展示

### PreToolUse 插件

#### 1. block-dangerous
**功能**：拦截危险的 shell 命令

**保护范围**：
- `rm -rf /` - 删除根目录
- `:(){ :|:& };:` - Fork bomb
- `curl ... | sh` - 执行远程脚本
- `dd if=/dev/zero` - 覆盖磁盘
- `sudo` + 危险命令组合

#### 2. protect-secrets
**功能**：保护敏感文件不被访问

**保护范围**：
- `.env` 文件
- 密钥文件（`.pem`, `.key`）
- SSH 配置（`id_rsa`）
- 云服务凭证（`.aws/credentials`）

### PostToolUse 插件

#### 3. auto-format
**功能**：自动格式化代码

**支持语言**：
- JavaScript/TypeScript（Prettier）
- Python（Black）
- Go（gofmt）
- Rust（rustfmt）

#### 4. auto-test
**功能**：自动运行测试（默认禁用）

**支持框架**：
- Jest, Mocha（JavaScript/TypeScript）
- pytest（Python）
- go test（Go）
- cargo test（Rust）

---

## 📊 预期收益

### 对个人开发者
- ✅ 防止误操作导致数据丢失
- ✅ 自动保持代码风格一致
- ✅ 提升开发效率和代码质量

### 对 QA 工程师
- ✅ 质量前置，减少后期返工
- ✅ 自动化检查，降低人工成本
- ✅ 快速反馈，及时发现问题

### 对团队
- ✅ 统一代码规范
- ✅ 保护敏感信息
- ✅ 自动化质量检查
- ✅ 降低 Code Review 负担

### 对企业
- ✅ 符合安全合规要求
- ✅ 降低人为错误风险
- ✅ 提高代码质量
- ✅ 支持大规模团队使用

---

## 🤔 讨论点

### 1. 架构设计
- ✅ 三层防护的划分是否合理？
- ✅ 插件化系统的设计是否满足扩展需求？
- ✅ 性能开销是否可接受？

### 2. 插件生态
- 📝 是否需要建立插件市场？
- 📝 如何鼓励社区贡献插件？
- 📝 插件质量如何保证？

### 3. 用户体验
- 📝 默认启用哪些插件？
- 📝 如何平衡安全性和便利性？
- 📝 错误提示是否足够友好？

### 4. 企业应用
- 📝 是否需要企业版功能？
- 📝 如何支持私有插件？
- 📝 审计日志如何实现？

---

## 📚 相关资源

- 架构设计文档: `docs/CN/architecture.md`
- 插件开发指南: `docs/CN/plugin-development.md`
- 实现总结: `docs/CN/IMPLEMENTATION_SUMMARY.md`
- Hook 应用案例: `docs/CN/hook-inspirations.md`

---

## 🎯 总结

cc-buddy 三层防护架构通过扩展 Claude Code Hooks 的能力，在 AI 编程的全生命周期中提供：

1. **🎓 解释和引导**（SessionStart）- 让用户理解 AI 行为
2. **🛡️ 拦截和保护**（PreToolUse）- 在执行前保障安全和质量
3. **✨ 自动化和优化**（PostToolUse）- 在执行后自动提升质量

这不仅是一个技术升级，更是一个**质量理念的转变**：从"事后检查"到"事前预防"，从"人工保障"到"自动化保障"。

作为 QA 工程师，我相信这个架构能够真正实现**质量前置**，让 AI 编程更安全、更高效、更可靠。

---

## English Version

### Issue Title
```
[RFC] Add Three-Layer Protection Architecture to cc-buddy: Full Lifecycle Quality Assurance System
```

### Proposal Overview

This proposal suggests introducing a **Three-Layer Protection Architecture** to cc-buddy, providing security protection and quality assurance throughout the AI programming lifecycle by extending Claude Code Hooks capabilities.

---

## 🎯 Core Concept

### Three-Layer Protection Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Claude Code                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              cc-buddy Three-Layer Protection                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  🎓 Layer 1: SessionStart (Explanation & Guidance)           │
│  ├─ AI actively explains operation intent                    │
│  ├─ Provides risk level assessment                           │
│  └─ Guides users to understand AI behavior                   │
│                                                               │
│  🛡️ Layer 2: PreToolUse (Interception & Protection)         │
│  ├─ Dangerous command detection & blocking                   │
│  ├─ Sensitive file access control                            │
│  ├─ Code standard pre-check                                  │
│  └─ Quality gate pre-validation                              │
│                                                               │
│  ✨ Layer 3: PostToolUse (Automation & Optimization)         │
│  ├─ Automatic code formatting                                │
│  ├─ Automatic unit test execution                            │
│  ├─ Automatic code quality check                             │
│  └─ Git operation automation                                 │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 💡 Core Value Propositions

### 1. Full Lifecycle Hook Capability Extension

**Current Problem**:
- cc-buddy currently only uses SessionStart hook
- Lacks intervention capability before and after AI operations
- Cannot perform quality control at critical points

**Solution**:
- ✅ **SessionStart**: Explanation and guidance at session start
- ✅ **PreToolUse**: Interception and protection before tool execution
- ✅ **PostToolUse**: Automation and optimization after tool execution

**Value**:
- 📈 Covers the complete AI programming lifecycle
- 🔒 Provides quality assurance at every critical point
- 🚀 Maximizes Claude Code Hooks capabilities

---

### 2. QA Engineer Perspective: Shift-Left Quality

**Background**:
As a QA engineer, I deeply understand the importance of **shift-left quality**. The traditional "Development → QA Testing → Find Issues → Rework" model is inefficient and costly.

**Pain Points**:
- ❌ AI may generate non-compliant code
- ❌ AI may execute dangerous system commands
- ❌ AI may skip unit tests and code checks
- ❌ Issues discovered too late, high fix cost

**Solution**:
Through **PreToolUse** and **PostToolUse** hooks, shift quality checks to the development stage:

#### PreToolUse (Quality Gate)
```
AI prepares to execute operation
    ↓
PreToolUse plugin checks
    ├─ Code standard check
    ├─ Security risk assessment
    ├─ Test coverage requirement
    └─ Architecture standard validation
    ↓
Non-compliant → Block execution + Provide suggestions
Compliant → Allow execution
```

#### PostToolUse (Automated Assurance)
```
AI completes code modification
    ↓
PostToolUse plugin auto-executes
    ├─ Code formatting (Prettier/Black)
    ├─ Unit test execution (Jest/pytest)
    ├─ Static code analysis (ESLint/SonarQube)
    ├─ Code coverage check
    └─ Git commit standard check
    ↓
Issues immediately exposed → Timely fix
Quality automatically assured → Reduce rework
```

**Value**:
- ✅ **Shift-Left Quality**: Ensure quality at code generation stage
- ✅ **Automation**: No manual intervention, automatic checks
- ✅ **Fast Feedback**: Issues found and fixed immediately
- ✅ **Cost Reduction**: Reduce later rework and fix costs

---

### 3. Enhanced Security

**Scenario 1: Prevent Dangerous Command Execution**
```
User: "Clean up system logs"
AI: Preparing to execute rm -rf /var/log/*

PreToolUse plugin intercepts:
🔴 Dangerous Operation! Recursive deletion detected
   Risk: May delete important system logs
   Suggestion: Use logrotate or specify exact files
   
Operation blocked ✅
```

**Scenario 2: Protect Sensitive Files**
```
User: "Check the configuration file"
AI: Preparing to read .env file

PreToolUse plugin intercepts:
🔒 Sensitive File Protection! File contains keys and passwords
   Suggestion: View manually or use environment variable tools
   
Operation blocked ✅
```

---

### 4. Development Efficiency Improvement

**Scenario 1: Automatic Code Formatting**
```
AI modified index.js
    ↓
PostToolUse auto-executes Prettier
    ↓
Code automatically formatted ✅
No need to manually run formatting tools
```

**Scenario 2: Automatic Test Execution**
```
AI modified business logic code
    ↓
PostToolUse auto-runs related tests
    ↓
Test fails → Immediately prompt AI to fix
Test passes → Continue to next step
```

---

### 5. Extensible Plugin Ecosystem

**Plugin Architecture**:
```json
{
  "pre": [
    {
      "name": "block-dangerous",
      "enabled": true,
      "priority": 100,
      "description": "Block dangerous commands"
    },
    {
      "name": "protect-secrets",
      "enabled": true,
      "priority": 90,
      "description": "Protect sensitive files"
    }
  ],
  "post": [
    {
      "name": "auto-format",
      "enabled": true,
      "priority": 100,
      "description": "Auto format code"
    },
    {
      "name": "auto-test",
      "enabled": false,
      "priority": 50,
      "description": "Auto run tests"
    }
  ]
}
```

**Extension Capabilities**:
- ✅ Users can create custom plugins
- ✅ Plugins can be flexibly enabled/disabled
- ✅ Supports priority control
- ✅ Supports conditional matching (matcher)

---

## 📋 Implementation Plan

### Phase 1: Core Architecture ✅
- [x] Design three-layer protection architecture
- [x] Implement PreToolUse dispatcher
- [x] Implement PostToolUse dispatcher
- [x] Design plugin configuration system

### Phase 2: Basic Plugins ✅
- [x] block-dangerous (Dangerous command blocker)
- [x] protect-secrets (Secrets protection)
- [x] auto-format (Auto formatting)
- [x] auto-test (Auto testing)

### Phase 3: Documentation ✅
- [x] Architecture design document
- [x] Plugin development guide
- [x] Usage examples and best practices
- [x] Complete test suite

### Phase 4: Community Promotion (Pending)
- [ ] Publish to Claude Code plugin marketplace
- [ ] Write blog posts and tutorials
- [ ] Collect user feedback
- [ ] Continuous iteration and optimization

---

## 📊 Expected Benefits

### For Individual Developers
- ✅ Prevent data loss from misoperations
- ✅ Automatically maintain consistent code style
- ✅ Improve development efficiency and code quality

### For QA Engineers
- ✅ Shift-left quality, reduce later rework
- ✅ Automated checks, reduce manual costs
- ✅ Fast feedback, timely issue discovery

### For Teams
- ✅ Unified code standards
- ✅ Protect sensitive information
- ✅ Automated quality checks
- ✅ Reduce Code Review burden

### For Enterprises
- ✅ Meet security compliance requirements
- ✅ Reduce human error risks
- ✅ Improve code quality
- ✅ Support large-scale team usage

---

## 🤔 Discussion Points

### 1. Architecture Design
- ✅ Is the three-layer division reasonable?
- ✅ Does the plugin system design meet extension needs?
- ✅ Is the performance overhead acceptable?

### 2. Plugin Ecosystem
- 📝 Do we need a plugin marketplace?
- 📝 How to encourage community plugin contributions?
- 📝 How to ensure plugin quality?

### 3. User Experience
- 📝 Which plugins should be enabled by default?
- 📝 How to balance security and convenience?
- 📝 Are error messages user-friendly enough?

### 4. Enterprise Application
- 📝 Do we need enterprise edition features?
- 📝 How to support private plugins?
- 📝 How to implement audit logs?

---

## 📚 Related Resources

- Architecture Design: `docs/EN/architecture.md`
- Plugin Development Guide: `docs/EN/plugin-development.md`
- Implementation Summary: `docs/EN/IMPLEMENTATION_SUMMARY.md`
- Hook Inspiration Cases: `docs/EN/hook-inspirations.md`

---

## 🎯 Summary

The cc-buddy Three-Layer Protection Architecture extends Claude Code Hooks capabilities to provide throughout the AI programming lifecycle:

1. **🎓 Explanation & Guidance** (SessionStart) - Help users understand AI behavior
2. **🛡️ Interception & Protection** (PreToolUse) - Ensure safety and quality before execution
3. **✨ Automation & Optimization** (PostToolUse) - Automatically improve quality after execution

This is not just a technical upgrade, but a **shift in quality philosophy**: from "post-check" to "pre-prevention", from "manual assurance" to "automated assurance".

As a QA engineer, I believe this architecture can truly achieve **shift-left quality**, making AI programming safer, more efficient, and more reliable.
