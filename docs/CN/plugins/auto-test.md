# auto-test 插件

## 📋 插件信息

- **名称**: auto-test
- **类型**: PostToolUse（自动化优化）
- **优先级**: 50（中）
- **状态**: 默认禁用

## 🎯 功能介绍

`auto-test` 插件会在 Claude Code 编辑或创建代码文件后，自动运行相关的测试用例，及时发现代码问题。支持多种测试框架和编程语言。

### 支持的测试框架

| 语言 | 测试框架 | 检测方式 | 运行命令 |
|------|---------|---------|---------|
| JavaScript/TypeScript | Jest, Mocha, Vitest | package.json | `npm test` |
| Python | pytest, unittest | pytest.ini, setup.py | `pytest` |
| Go | go test | go.mod | `go test ./...` |
| Rust | cargo test | Cargo.toml | `cargo test` |

## 🎬 Claude Code 使用示例

### 示例 1: 自动运行 JavaScript 测试

**用户输入**:
```
修复 calculateTotal 函数的 bug
```

**Claude Code 执行**:
```javascript
// 编辑文件: src/utils/calculator.js
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

**插件自动执行**:
```bash
$ npm test

PASS  src/utils/calculator.test.js
  ✓ calculates total correctly (3ms)
  ✓ handles empty array (1ms)
  ✓ handles negative prices (2ms)

Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
```

**插件输出**:
```
✅ 测试通过
```

---

### 示例 2: 测试失败提示

**用户输入**:
```
更新用户验证逻辑
```

**Claude Code 执行**:
```javascript
// 编辑文件: src/auth/validator.js
function validateUser(user) {
  return user.age > 18; // Bug: 应该是 >= 18
}
```

**插件自动执行**:
```bash
$ npm test

FAIL  src/auth/validator.test.js
  ✕ validates user age correctly (5ms)

  ● validates user age correctly

    expect(received).toBe(expected)

    Expected: true
    Received: false

Test Suites: 1 failed, 1 total
Tests:       1 failed, 3 total
```

**插件输出**:
```
❌ 测试失败，请检查代码

失败的测试:
- validates user age correctly

建议: 检查 validateUser 函数的逻辑
```

---

### 示例 3: 自动运行 Python 测试

**用户输入**:
```
优化数据处理函数
```

**Claude Code 执行**:
```python
# 编辑文件: src/processor.py
def process_data(data):
    return [item * 2 for item in data if item > 0]
```

**插件自动执行**:
```bash
$ pytest

======================== test session starts ========================
collected 5 items

tests/test_processor.py .....                                  [100%]

========================= 5 passed in 0.12s =========================
```

**插件输出**:
```
✅ 测试通过
```

---

### 示例 4: 自动运行 Go 测试

**用户输入**:
```
添加字符串处理函数
```

**Claude Code 执行**:
```go
// 编辑文件: utils/strings.go
func Reverse(s string) string {
    runes := []rune(s)
    for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
        runes[i], runes[j] = runes[j], runes[i]
    }
    return string(runes)
}
```

**插件自动执行**:
```bash
$ go test ./...

ok      myproject/utils    0.123s
```

**插件输出**:
```
✅ 测试通过
```

---

### 示例 5: 测试命令未找到

**用户输入**:
```
创建一个新的工具函数
```

**Claude Code 执行**:
```javascript
// 创建文件: src/utils/helper.js
export function formatDate(date) {
  return date.toISOString();
}
```

**插件执行结果**:
```
未找到测试命令，跳过测试

提示: 请在 package.json 中配置 test 脚本
```

---

### 示例 6: 非代码文件跳过

**用户输入**:
```
更新 README 文档
```

**Claude Code 执行**:
```
Edit file: README.md
```

**插件执行结果**:
```
非代码文件，跳过测试
```

## 🔧 触发条件

### 会触发测试的场景

1. **编辑代码文件时**
   - 工具类型: `Edit`
   - 文件扩展名: `.js`, `.ts`, `.py`, `.go`, `.rs`

2. **创建代码文件时**
   - 工具类型: `Write`
   - 文件扩展名在支持列表中

3. **项目有测试配置**
   - Node.js: `package.json` 中有 `test` 脚本
   - Python: 存在 `pytest.ini` 或 `setup.py`
   - Go: 存在 `go.mod`
   - Rust: 存在 `Cargo.toml`

### 不会触发的场景

1. **非代码文件**
   - 文档文件 (.md, .txt)
   - 配置文件 (.json, .yaml)
   - 图片文件等

2. **测试配置缺失**
   - 项目没有配置测试命令
   - 测试框架未安装

3. **非文件操作**
   - Bash 命令执行
   - Read 读取操作

4. **插件被禁用**
   - 默认状态下插件是禁用的

## 📝 配置说明

### 启用插件

编辑 `plugins/config.json`:

```json
{
  "post": [
    {
      "name": "auto-test",
      "enabled": true,  // 改为 true 启用
      "matcher": "Edit|Write",
      "priority": 50,
      "script": "plugins/post/auto-test.sh",
      "description": "自动运行相关测试"
    }
  ]
}
```

### 配置测试命令

#### Node.js 项目 (package.json)
```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

#### Python 项目 (pytest.ini)
```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
```

#### Go 项目
```bash
# 无需额外配置，go test 自动发现测试文件
```

#### Rust 项目
```bash
# 无需额外配置，cargo test 自动发现测试
```

### 自定义测试范围

#### 只运行相关测试

编辑 `plugins/post/auto-test.sh`，添加智能测试逻辑：

```bash
# 根据修改的文件运行相关测试
FILE_NAME=$(basename "$FILE_PATH" .js)
TEST_FILE="tests/${FILE_NAME}.test.js"

if [[ -f "$TEST_FILE" ]]; then
  npm test -- "$TEST_FILE"
else
  npm test
fi
```

#### 设置超时时间

```bash
# 添加超时控制
timeout 30s npm test || {
  echo "测试超时"
  exit 0
}
```

## 🎨 输出格式

### 测试通过

```json
{
  "success": true,
  "message": "✅ 测试通过",
  "modifications": []
}
```

### 测试失败

```json
{
  "success": false,
  "message": "❌ 测试失败，请检查代码",
  "modifications": []
}
```

### 跳过测试

```json
{
  "success": true,
  "message": "未找到测试命令，跳过测试",
  "modifications": []
}
```

## ⚠️ 注意事项

1. **性能影响**
   - 测试运行可能需要较长时间（几秒到几分钟）
   - 建议只在重要文件修改时启用
   - 可以配置只运行相关测试

2. **测试失败处理**
   - 测试失败不会阻止文件保存
   - 只是提供警告信息
   - 用户可以选择忽略或修复

3. **CI/CD 集成**
   - 本地测试是快速反馈
   - 完整测试应该在 CI/CD 中运行
   - 避免重复测试

4. **默认禁用原因**
   - 测试可能耗时较长
   - 不是所有项目都需要
   - 用户可以根据需要启用

## 💡 最佳实践

### 1. 编写快速的单元测试

```javascript
// ✅ 好的测试：快速、独立
test('adds two numbers', () => {
  expect(add(1, 2)).toBe(3);
});

// ❌ 避免：慢速、依赖外部服务
test('fetches user from API', async () => {
  const user = await fetch('https://api.example.com/user/1');
  expect(user.name).toBe('John');
});
```

### 2. 使用测试覆盖率

```json
{
  "scripts": {
    "test": "jest --coverage --coverageThreshold='{\"global\":{\"lines\":80}}'"
  }
}
```

### 3. 配置测试监视模式

```json
{
  "scripts": {
    "test:watch": "jest --watch --onlyChanged"
  }
}
```

### 4. 分离单元测试和集成测试

```json
{
  "scripts": {
    "test:unit": "jest --testPathPattern=unit",
    "test:integration": "jest --testPathPattern=integration",
    "test": "npm run test:unit"
  }
}
```

## 🔗 相关资源

- [架构设计文档](../architecture.md)
- [插件开发指南](../plugin-development.md)
- [测试用例](../../tests/test-plugins.sh)
- [Jest 官方文档](https://jestjs.io/)
- [pytest 官方文档](https://docs.pytest.org/)

## 📊 统计信息

- **支持语言数**: 4 种
- **支持测试框架**: 6+ 个
- **平均测试时间**: 1-30 秒
- **默认状态**: 禁用

## 🤝 贡献

如果你想添加新的测试框架支持，欢迎提交 PR。

## 🎓 使用建议

### 何时启用此插件

✅ **适合启用的场景**:
- TDD（测试驱动开发）项目
- 关键业务逻辑修改
- 重构代码时
- 团队要求高测试覆盖率

❌ **不适合启用的场景**:
- 快速原型开发
- 测试运行时间过长
- 频繁修改 UI 代码
- 探索性编程

### 渐进式启用

1. **第一阶段**: 禁用，手动运行测试
2. **第二阶段**: 只在关键文件启用
3. **第三阶段**: 配置只运行相关测试
4. **第四阶段**: 全局启用

### 与 CI/CD 配合

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: npm test
      - name: Upload coverage
        uses: codecov/codecov-action@v2
```
