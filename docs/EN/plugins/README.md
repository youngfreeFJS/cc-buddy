# cc-buddy Plugin Documentation

This directory contains detailed documentation for all cc-buddy plugins. Each plugin has its own documentation, including Claude Code usage examples, trigger conditions, configuration instructions, etc.

## 📚 Plugin List

### PreToolUse Plugins (Interception Protection)

These plugins perform checks before Claude Code executes operations and can intercept dangerous or inappropriate operations.

#### 1. [block-dangerous](./block-dangerous.md) 🔴
- **Priority**: 100 (Highest)
- **Status**: Enabled by Default
- **Function**: Intercept dangerous shell commands that could cause serious damage to the system
- **Protection Scope**:
  - File system destruction (`rm -rf /`)
  - Disk operations (`dd`, `mkfs`)
  - System attacks (Fork bomb)
  - Remote script execution (`curl | sh`)
  - Dangerous permission operations (`sudo` + dangerous commands)

#### 2. [protect-secrets](./protect-secrets.md) 🔒
- **Priority**: 90 (High)
- **Status**: Enabled by Default
- **Function**: Protect sensitive files from being read, edited, or written
- **Protection Scope**:
  - Environment variable files (`.env`)
  - Keys and certificates (`.pem`, `.key`)
  - SSH keys (`id_rsa`)
  - Cloud service credentials (`.aws/credentials`)
  - Files containing sensitive keywords

---

### PostToolUse Plugins (Automation Optimization)

These plugins automatically run after Claude Code executes operations, providing additional optimization and checks.

#### 3. [auto-format](./auto-format.md) ✨
- **Priority**: 100 (Highest)
- **Status**: Enabled by Default
- **Function**: Automatically format code to ensure consistent code style
- **Supported Languages**:
  - JavaScript/TypeScript (Prettier)
  - Python (Black)
  - Go (gofmt)
  - Rust (rustfmt)
  - CSS/HTML/JSON (Prettier)

#### 4. [auto-test](./auto-test.md) 🧪
- **Priority**: 50 (Medium)
- **Status**: Disabled by Default
- **Function**: Automatically run relevant test cases to及时发现 code issues
- **Supported Frameworks**:
  - Jest, Mocha, Vitest (JavaScript/TypeScript)
  - pytest, unittest (Python)
  - go test (Go)
  - cargo test (Rust)

---

## 🎯 Quick Navigation

### By Use Case

| Scenario | Recommended Plugin | Description |
|----------|-------------------|-------------|
| Execute system commands | [block-dangerous](./block-dangerous.md) | Prevent dangerous command execution |
| Access sensitive files | [protect-secrets](./protect-secrets.md) | Protect keys and credentials |
| Edit code files | [auto-format](./auto-format.md) | Automatically format code |
| Modify business logic | [auto-test](./auto-test.md) | Automatically run tests |

### By Plugin Type

| Type | Plugin | Execution Timing |
|------|--------|------------------|
| PreToolUse | [block-dangerous](./block-dangerous.md) | Intercept before execution |
| PreToolUse | [protect-secrets](./protect-secrets.md) | Intercept before execution |
| PostToolUse | [auto-format](./auto-format.md) | Optimize after execution |
| PostToolUse | [auto-test](./auto-test.md) | Verify after execution |

### By Priority

| Priority | Plugin | Description |
|----------|--------|-------------|
| 100 | [block-dangerous](./block-dangerous.md) | Highest priority, checked first |
| 100 | [auto-format](./auto-format.md) | Highest priority, executed first |
| 90 | [protect-secrets](./protect-secrets.md) | High priority |
| 50 | [auto-test](./auto-test.md) | Medium priority |

---

## 📖 Documentation Structure

Each plugin documentation contains the following content:

1. **📋 Plugin Information**
   - Name, type, priority, status

2. **🎯 Feature Overview**
   - Plugin function and protection/optimization scope

3. **🎬 Claude Code Usage Examples**
   - Real usage scenarios
   - Trigger effect demonstration
   - Interception/execution results

4. **🔧 Trigger Conditions**
   - Scenarios that trigger
   - Scenarios that won't trigger

5. **📝 Configuration Instructions**
   - Enable/disable methods
   - Custom configuration
   - Dependency installation

6. **🎨 Output Format**
   - JSON output examples

7. **⚠️ Important Notes**
   - Usage limitations
   - Performance impact
   - Common issues

8. **💡 Best Practices**
   - Recommended usage
   - Configuration suggestions

9. **🔗 Related Resources**
   - Related documentation links
   - Official resources

---

## 🚀 Quick Start

### 1. Check Plugin Configuration

```bash
cat plugins/config.json
```

### 2. Enable/Disable Plugins

Edit `plugins/config.json`, modify the `enabled` field:

```json
{
  "pre": [
    {
      "name": "block-dangerous",
      "enabled": true  // Change to false to disable
    }
  ]
}
```

### 3. Test Plugins

```bash
# Run all tests
bash tests/run-all-tests.sh

# Run plugin tests
bash tests/test-plugins.sh
```

---

## 🔧 Develop New Plugins

If you want to develop your own plugins, please refer to:

- [Plugin Development Guide](../plugin-development.md)
- [Architecture Design Document](../architecture.md)
- [Existing Plugin Source Code](../../plugins/)

---

## 📊 Plugin Statistics

| Metric | Value |
|--------|-------|
| Total Plugins | 4 |
| PreToolUse Plugins | 2 |
| PostToolUse Plugins | 2 |
| Enabled by Default | 3 |
| Disabled by Default | 1 |
| Supported Languages | 9+ |
| Test Cases | 54 |

---

## 🤝 Contributing

Welcome to contribute new plugins or improve existing plugins!

1. Fork the project
2. Create a plugin branch
3. Write plugin code and tests
4. Write plugin documentation
5. Submit a Pull Request

---

## 📞 Get Help

- [GitHub Issues](https://github.com/your-repo/cc-buddy/issues)
- [Architecture Documentation](../architecture.md)
- [Implementation Summary](../IMPLEMENTATION_SUMMARY.md)

---

**Last Updated**: 2026-03-24
