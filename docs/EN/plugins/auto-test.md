# auto-test Plugin

## 📋 Plugin Information

- **Name**: auto-test
- **Type**: PostToolUse (Automation Optimization)
- **Priority**: 50 (Medium)
- **Status**: Disabled by Default

## 🎯 Feature Overview

The `auto-test` plugin automatically runs relevant test cases after Claude Code edits or creates code files,及时发现 code issues. Supports multiple testing frameworks and programming languages.

### Supported Testing Frameworks

| Language | Testing Framework | Detection Method | Run Command |
|----------|------------------|------------------|-------------|
| JavaScript/TypeScript | Jest, Mocha, Vitest | package.json | `npm test` |
| Python | pytest, unittest | pytest.ini, setup.py | `pytest` |
| Go | go test | go.mod | `go test ./...` |
| Rust | cargo test | Cargo.toml | `cargo test` |

## 🎬 Claude Code Usage Examples

### Example 1: Automatically Run JavaScript Tests

**User Input**:
```
Fix the bug in calculateTotal function
```

**Claude Code Executes**:
```javascript
// Edit file: src/utils/calculator.js
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

**Plugin Automatically Executes**:
```bash
$ npm test

PASS  src/utils/calculator.test.js
  ✓ calculates total correctly (3ms)
  ✓ handles empty array (1ms)
  ✓ handles negative prices (2ms)

Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
```

**Plugin Output**:
```
✅ Tests passed
```

---

### Example 2: Test Failure Prompt

**User Input**:
```
Update user validation logic
```

**Claude Code Executes**:
```javascript
// Edit file: src/auth/validator.js
function validateUser(user) {
  return user.age > 18; // Bug: Should be >= 18
}
```

**Plugin Automatically Executes**:
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

**Plugin Output**:
```
❌ Tests failed, please check the code

Failed tests:
- validates user age correctly

Suggestion: Check the logic of validateUser function
```

---

### Example 3: Automatically Run Python Tests

**User Input**:
```
Optimize data processing function
```

**Claude Code Executes**:
```python
# Edit file: src/processor.py
def process_data(data):
    return [item * 2 for item in data if item > 0]
```

**Plugin Automatically Executes**:
```bash
$ pytest

======================== test session starts ========================
collected 5 items

tests/test_processor.py .....                                  [100%]

========================= 5 passed in 0.12s =========================
```

**Plugin Output**:
```
✅ Tests passed
```

---

### Example 4: Automatically Run Go Tests

**User Input**:
```
Add a string processing function
```

**Claude Code Executes**:
```go
// Edit file: utils/strings.go
func Reverse(s string) string {
    runes := []rune(s)
    for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
        runes[i], runes[j] = runes[j], runes[i]
    }
    return string(runes)
}
```

**Plugin Automatically Executes**:
```bash
$ go test ./...

ok      myproject/utils    0.123s
```

**Plugin Output**:
```
✅ Tests passed
```

---

### Example 5: Test Command Not Found

**User Input**:
```
Create a new utility function
```

**Claude Code Executes**:
```javascript
// Create file: src/utils/helper.js
export function formatDate(date) {
  return date.toISOString();
}
```

**Plugin Execution Result**:
```
Test command not found, skipping tests

Hint: Please configure test script in package.json
```

---

### Example 6: Skip Non-Code Files

**User Input**:
```
Update README documentation
```

**Claude Code Executes**:
```
Edit file: README.md
```

**Plugin Execution Result**:
```
Non-code file, skipping tests
```

## 🔧 Trigger Conditions

### Scenarios That Trigger Testing

1. **When Editing Code Files**
   - Tool type: `Edit`
   - File extensions: `.js`, `.ts`, `.py`, `.go`, `.rs`

2. **When Creating Code Files**
   - Tool type: `Write`
   - File extension is in the supported list

3. **Project Has Test Configuration**
   - Node.js: `test` script exists in `package.json`
   - Python: `pytest.ini` or `setup.py` exists
   - Go: `go.mod` exists
   - Rust: `Cargo.toml` exists

### Scenarios That Won't Trigger

1. **Non-Code Files**
   - Document files (.md, .txt)
   - Configuration files (.json, .yaml)
   - Image files, etc.

2. **Missing Test Configuration**
   - Project doesn't have test command configured
   - Testing framework not installed

3. **Non-File Operations**
   - Bash command execution
   - Read operations

4. **Plugin Disabled**
   - Plugin is disabled by default

## 📝 Configuration Instructions

### Enable Plugin

Edit `plugins/config.json`:

```json
{
  "post": [
    {
      "name": "auto-test",
      "enabled": true,  // Change to true to enable
      "matcher": "Edit|Write",
      "priority": 50,
      "script": "plugins/post/auto-test.sh",
      "description": "Automatically run related tests"
    }
  ]
}
```

### Configure Test Commands

#### Node.js Project (package.json)
```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

#### Python Project (pytest.ini)
```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
```

#### Go Project
```bash
# No additional configuration needed, go test automatically discovers test files
```

#### Rust Project
```bash
# No additional configuration needed, cargo test automatically discovers tests
```

### Customize Test Scope

#### Run Only Related Tests

Edit `plugins/post/auto-test.sh`, add intelligent test logic:

```bash
# Run related tests based on modified files
FILE_NAME=$(basename "$FILE_PATH" .js)
TEST_FILE="tests/${FILE_NAME}.test.js"

if [[ -f "$TEST_FILE" ]]; then
  npm test -- "$TEST_FILE"
else
  npm test
fi
```

#### Set Timeout

```bash
# Add timeout control
timeout 30s npm test || {
  echo "Test timeout"
  exit 0
}
```

## 🎨 Output Format

### Tests Passed

```json
{
  "success": true,
  "message": "✅ Tests passed",
  "modifications": []
}
```

### Tests Failed

```json
{
  "success": false,
  "message": "❌ Tests failed, please check the code",
  "modifications": []
}
```

### Skip Tests

```json
{
  "success": true,
  "message": "Test command not found, skipping tests",
  "modifications": []
}
```

## ⚠️ Important Notes

1. **Performance Impact**
   - Test runs may take a long time (seconds to minutes)
   -建议 only enabling when important files are modified
   - Can configure to run only related tests

2. **Test Failure Handling**
   - Test failures won't block file saving
   - Only provides warning information
   - Users can choose to ignore or fix

3. **CI/CD Integration**
   - Local testing is for quick feedback
   - Complete tests should run in CI/CD
   - Avoid duplicate testing

4. **Reason for Default Disabled**
   - Tests may take a long time
   - Not all projects need it
   - Users can enable as needed

## 💡 Best Practices

### 1. Write Fast Unit Tests

```javascript
// ✅ Good test: fast, independent
test('adds two numbers', () => {
  expect(add(1, 2)).toBe(3);
});

// ❌ Avoid: slow, depends on external services
test('fetches user from API', async () => {
  const user = await fetch('https://api.example.com/user/1');
  expect(user.name).toBe('John');
});
```

### 2. Use Test Coverage

```json
{
  "scripts": {
    "test": "jest --coverage --coverageThreshold='{\"global\":{\"lines\":80}}'"
  }
}
```

### 3. Configure Test Watch Mode

```json
{
  "scripts": {
    "test:watch": "jest --watch --onlyChanged"
  }
}
```

### 4. Separate Unit Tests and Integration Tests

```json
{
  "scripts": {
    "test:unit": "jest --testPathPattern=unit",
    "test:integration": "jest --testPathPattern=integration",
    "test": "npm run test:unit"
  }
}
```

## 🔗 Related Resources

- [Architecture Design Document](../architecture.md)
- [Plugin Development Guide](../plugin-development.md)
- [Test Cases](../../tests/test-plugins.sh)
- [Jest Official Documentation](https://jestjs.io/)
- [pytest Official Documentation](https://docs.pytest.org/)

## 📊 Statistics

- **Number of Supported Languages**: 4
- **Supported Testing Frameworks**: 6+
- **Average Test Time**: 1-30 seconds
- **Default Status**: Disabled

## 🤝 Contributing

If you want to add new testing framework support, you're welcome to submit a PR.

## 🎓 Usage Recommendations

### When to Enable This Plugin

✅ **Suitable for Enabling**:
- TDD (Test-Driven Development) projects
- Critical business logic modifications
- When refactoring code
- Teams requiring high test coverage

❌ **Not Suitable for Enabling**:
- Rapid prototyping
- Test runs take too long
- Frequent UI code modifications
- Exploratory programming

### Progressive Enablement

1. **Phase 1**: Disabled, manually run tests
2. **Phase 2**: Enable only for critical files
3. **Phase 3**: Configure to run only related tests
4. **Phase 4**: Enable globally

### Coordinate with CI/CD

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
