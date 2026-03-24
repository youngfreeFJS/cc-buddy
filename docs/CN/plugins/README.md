# cc-buddy 插件文档

本目录包含 cc-buddy 所有插件的详细使用文档。每个插件都有独立的文档，包含 Claude Code 使用示例、触发条件、配置说明等。

## 📚 插件列表

### PreToolUse 插件（拦截保护）

这些插件在 Claude Code 执行操作前进行检查，可以拦截危险或不当的操作。

#### 1. [block-dangerous](./block-dangerous.md) 🔴
- **优先级**: 100（最高）
- **状态**: 默认启用
- **功能**: 拦截可能对系统造成严重损害的危险 shell 命令
- **保护范围**:
  - 文件系统破坏（`rm -rf /`）
  - 磁盘操作（`dd`, `mkfs`）
  - 系统攻击（Fork bomb）
  - 远程脚本执行（`curl | sh`）
  - 危险权限操作（`sudo` + 危险命令）

#### 2. [protect-secrets](./protect-secrets.md) 🔒
- **优先级**: 90（高）
- **状态**: 默认启用
- **功能**: 保护敏感文件不被读取、编辑或写入
- **保护范围**:
  - 环境变量文件（`.env`）
  - 密钥和证书（`.pem`, `.key`）
  - SSH 密钥（`id_rsa`）
  - 云服务凭证（`.aws/credentials`）
  - 包含敏感关键词的文件

---

### PostToolUse 插件（自动化优化）

这些插件在 Claude Code 执行操作后自动运行，提供额外的优化和检查。

#### 3. [auto-format](./auto-format.md) ✨
- **优先级**: 100（最高）
- **状态**: 默认启用
- **功能**: 自动格式化代码，确保代码风格统一
- **支持语言**:
  - JavaScript/TypeScript（Prettier）
  - Python（Black）
  - Go（gofmt）
  - Rust（rustfmt）
  - CSS/HTML/JSON（Prettier）

#### 4. [auto-test](./auto-test.md) 🧪
- **优先级**: 50（中）
- **状态**: 默认禁用
- **功能**: 自动运行相关测试用例，及时发现代码问题
- **支持框架**:
  - Jest, Mocha, Vitest（JavaScript/TypeScript）
  - pytest, unittest（Python）
  - go test（Go）
  - cargo test（Rust）

---

## 🎯 快速导航

### 按使用场景

| 场景 | 推荐插件 | 说明 |
|------|---------|------|
| 执行系统命令 | [block-dangerous](./block-dangerous.md) | 防止危险命令执行 |
| 访问敏感文件 | [protect-secrets](./protect-secrets.md) | 保护密钥和凭证 |
| 编辑代码文件 | [auto-format](./auto-format.md) | 自动格式化代码 |
| 修改业务逻辑 | [auto-test](./auto-test.md) | 自动运行测试 |

### 按插件类型

| 类型 | 插件 | 执行时机 |
|------|------|---------|
| PreToolUse | [block-dangerous](./block-dangerous.md) | 执行前拦截 |
| PreToolUse | [protect-secrets](./protect-secrets.md) | 执行前拦截 |
| PostToolUse | [auto-format](./auto-format.md) | 执行后优化 |
| PostToolUse | [auto-test](./auto-test.md) | 执行后验证 |

### 按优先级

| 优先级 | 插件 | 说明 |
|--------|------|------|
| 100 | [block-dangerous](./block-dangerous.md) | 最高优先级，最先检查 |
| 100 | [auto-format](./auto-format.md) | 最高优先级，最先执行 |
| 90 | [protect-secrets](./protect-secrets.md) | 高优先级 |
| 50 | [auto-test](./auto-test.md) | 中优先级 |

---

## 📖 文档结构

每个插件文档都包含以下内容：

1. **📋 插件信息**
   - 名称、类型、优先级、状态

2. **🎯 功能介绍**
   - 插件的作用和保护/优化范围

3. **🎬 Claude Code 使用示例**
   - 真实的使用场景
   - 触发效果展示
   - 拦截/执行结果

4. **🔧 触发条件**
   - 会触发的场景
   - 不会触发的场景

5. **📝 配置说明**
   - 启用/禁用方法
   - 自定义配置
   - 依赖安装

6. **🎨 输出格式**
   - JSON 输出示例

7. **⚠️ 注意事项**
   - 使用限制
   - 性能影响
   - 常见问题

8. **💡 最佳实践**
   - 推荐用法
   - 配置建议

9. **🔗 相关资源**
   - 相关文档链接
   - 官方资源

---

## 🚀 快速开始

### 1. 查看插件配置

```bash
cat plugins/config.json
```

### 2. 启用/禁用插件

编辑 `plugins/config.json`，修改 `enabled` 字段：

```json
{
  "pre": [
    {
      "name": "block-dangerous",
      "enabled": true  // 改为 false 可禁用
    }
  ]
}
```

### 3. 测试插件

```bash
# 运行所有测试
bash tests/run-all-tests.sh

# 运行插件测试
bash tests/test-plugins.sh
```

---

## 🔧 开发新插件

如果你想开发自己的插件，请参考：

- [插件开发指南](../plugin-development.md)
- [架构设计文档](../architecture.md)
- [现有插件源码](../../plugins/)

---

## 📊 插件统计

| 指标 | 数值 |
|------|------|
| 总插件数 | 4 个 |
| PreToolUse 插件 | 2 个 |
| PostToolUse 插件 | 2 个 |
| 默认启用 | 3 个 |
| 默认禁用 | 1 个 |
| 支持语言 | 9+ 种 |
| 测试用例 | 54 个 |

---

## 🤝 贡献

欢迎贡献新的插件或改进现有插件！

1. Fork 项目
2. 创建插件分支
3. 编写插件代码和测试
4. 编写插件文档
5. 提交 Pull Request

---

## 📞 获取帮助

- [GitHub Issues](https://github.com/your-repo/cc-buddy/issues)
- [架构文档](../architecture.md)
- [实现总结](../IMPLEMENTATION_SUMMARY.md)

---

**最后更新**: 2026-03-24
