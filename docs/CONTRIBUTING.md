# Contributing to cc-buddy

Thank you for your interest in contributing to cc-buddy! This guide will help you understand how to develop, debug, and test the plugin.

## Table of Contents

- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [How to Debug](#how-to-debug)
- [How to Test](#how-to-test)
- [Configuration System](#configuration-system)
- [Common Issues](#common-issues)
- [Submitting Changes](#submitting-changes)

---

## Development Setup

### Prerequisites

- **Claude Code CLI** installed and configured
- **Bash** (macOS/Linux) or compatible shell
- **Python 3** for testing and config parsing
- **Git** for version control

### Clone and Setup

```bash
git clone https://github.com/alibaba-flyai/cc-buddy.git
cd cc-buddy
```

### Local Testing Without Installation

To test your changes without installing the plugin globally:

```bash
# In a different project directory (not cc-buddy itself)
cd ~/your-test-project
claude --plugin-dir /path/to/cloned/cc-buddy
```

**Important**: Do not test inside the cc-buddy directory itself. The `.claude/settings.json` disables plugins to prevent self-explanation loops during development.

---

## Project Structure

```
cc-buddy/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest (name, version, description)
│   └── marketplace.json         # Marketplace manifest (distribution info)
├── hooks/
│   └── hooks.json               # Hook declarations (SessionStart)
├── hooks-handlers/
│   └── session-start.sh         # Main hook logic (generates additionalContext)
├── .claude/
│   ├── rules/
│   │   └── shell.md             # Shell command guidelines
│   └── skills/
│       └── plugin-change-checklist/
│           └── SKILL.md         # Release checklist
├── test.sh                      # Comprehensive test suite (46 tests)
├── README.md                    # User-facing documentation
└── docs/
    └── CONTRIBUTING.md          # This file
```

### Key Files

**hooks-handlers/session-start.sh**
- Core logic of the plugin
- Reads `.claude/cc-buddy.json` config file
- Generates `additionalContext` prompt based on verbosity level
- Uses `json_escape()` function to safely embed prompt in JSON output

**test.sh**
- 46 automated tests covering:
  - JSON output validation
  - Configuration file parsing
  - Verbosity modes (minimal/normal/verbose)
  - User customization (skip lists, dangerous commands)
  - Manifest integrity
  - Hook idempotency

---

## How to Debug

### 1. Test Hook Output Directly

Run the hook script and inspect its JSON output:

```bash
bash hooks-handlers/session-start.sh
```

**Expected output**: Single-line JSON with `hookSpecificOutput.additionalContext`

```json
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"IMPORTANT: Write the 😇 explanation..."}}
```

### 2. Validate JSON Structure

Pipe the output to Python to check for parsing errors:

```bash
bash hooks-handlers/session-start.sh | python3 -c "import sys, json; data=json.load(sys.stdin); print('✓ Valid JSON'); print('Context length:', len(data['hookSpecificOutput']['additionalContext']))"
```

### 3. Test Configuration Loading

Create a test config file and verify it's parsed correctly:

```bash
mkdir -p .claude
cat > .claude/cc-buddy.json << 'EOF'
{
  "verbosity": "minimal",
  "skip": ["npm install"],
  "dangerousCommands": ["test-danger"]
}
EOF

bash hooks-handlers/session-start.sh | python3 -c "
import sys, json
data = json.load(sys.stdin)
ctx = data['hookSpecificOutput']['additionalContext']
print('✓ minimal mode' if 'minimal mode' in ctx else '✗ FAIL')
print('✓ npm install' if 'npm install' in ctx else '✗ FAIL')
print('✓ test-danger' if 'test-danger' in ctx else '✗ FAIL')
"
```

### 4. Debug Python Config Parser

Test the Python config parsing logic in isolation:

```bash
python3 << 'PYEOF'
import json

with open('.claude/cc-buddy.json') as f:
    config = json.load(f)

print("Config:", config)
print("Verbosity:", config.get('verbosity', 'normal'))
print("Skip:", config.get('skip', []))
print("Dangerous:", config.get('dangerousCommands', []))

# Test merge logic
default_dangerous = ['rm -rf', 'DROP', 'DELETE FROM', 'TRUNCATE']
user_dangerous = config.get('dangerousCommands', [])
all_dangerous = list(dict.fromkeys(default_dangerous + user_dangerous))
print("Merged dangerous:", all_dangerous)
PYEOF
```

### 5. Test in Real Claude Code Session

```bash
# In your test project
claude --plugin-dir /path/to/cc-buddy

# Then in Claude Code, try:
# "帮我安装 axios"
# "删除 dist 目录"
```

Watch for the 😇 explanation before each operation.

### 6. Check Hook Registration

Verify the hook is properly registered:

```bash
cat hooks/hooks.json
```

Should contain:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks-handlers/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

---

## How to Test

### Run Full Test Suite

```bash
bash test.sh
```

**Expected output**: `通过: 46  失败: 0`

### Test Categories

The test suite covers:

1. **JSON Output Validation** (3 tests)
   - Single-line JSON output
   - No unescaped newlines in string values
   - Valid JSON structure

2. **Manifest Integrity** (5 tests)
   - Version consistency between plugin.json and marketplace.json
   - Required fields present
   - Semver format validation

3. **Hook Behavior** (8 tests)
   - Idempotency (same output on repeated runs)
   - No stderr output
   - Correct hookEventName
   - Non-empty additionalContext

4. **Configuration System** (10 tests)
   - Config file absent → use defaults
   - Config file malformed → fallback to defaults
   - Config file valid → load user settings
   - Verbosity modes (minimal/normal/verbose)
   - User skip list appending
   - Dangerous commands merging

5. **Content Validation** (8 tests)
   - Skip rules contain default commands
   - Format rules present
   - Emoji format instruction (😇)
   - Dangerous commands list

6. **Edge Cases** (12 tests)
   - JSON escape handling
   - Context length limits
   - Plugin name consistency
   - CLAUDE_PLUGIN_ROOT variable usage

### Run Specific Test Categories

To debug a specific test, extract the relevant section from `test.sh`:

```bash
# Example: Test only configuration loading
bash -c '
result=$(bash hooks-handlers/session-start.sh 2>/dev/null)

mkdir -p .claude
cat > .claude/cc-buddy.json << "EOF"
{
  "verbosity": "minimal"
}
EOF

if python3 -c "
import subprocess, json
result = subprocess.run([\"bash\", \"hooks-handlers/session-start.sh\"], capture_output=True, text=True)
data = json.loads(result.stdout)
ctx = data[\"hookSpecificOutput\"][\"additionalContext\"]
assert \"minimal mode\" in ctx
"; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
fi

rm -rf .claude
'
```

### Manual Testing Checklist

Before submitting a PR, manually verify:

1. **Default behavior** (no config file)
   ```bash
   rm -rf .claude
   bash hooks-handlers/session-start.sh | python3 -c "import sys,json; print(json.load(sys.stdin)['hookSpecificOutput']['additionalContext'][:200])"
   ```

2. **Minimal mode**
   ```bash
   mkdir -p .claude
   echo '{"verbosity":"minimal"}' > .claude/cc-buddy.json
   bash hooks-handlers/session-start.sh | grep "minimal mode"
   ```

3. **Verbose mode**
   ```bash
   echo '{"verbosity":"verbose"}' > .claude/cc-buddy.json
   bash hooks-handlers/session-start.sh | grep "verbose mode"
   ```

4. **Custom skip list**
   ```bash
   echo '{"skip":["npm install","docker ps"]}' > .claude/cc-buddy.json
   bash hooks-handlers/session-start.sh | grep "npm install"
   ```

5. **Custom dangerous commands**
   ```bash
   echo '{"dangerousCommands":["rm -rf","custom-danger"]}' > .claude/cc-buddy.json
   bash hooks-handlers/session-start.sh | grep "custom-danger"
   ```

---

## Configuration System

### How Configuration Works

1. **Config File Location**: `.claude/cc-buddy.json` in project root
2. **Parser**: Python 3 embedded in `session-start.sh`
3. **Merge Strategy**: User settings append to defaults (not replace)

### Configuration Flow

```
session-start.sh
    │
    ├─▶ Check if .claude/cc-buddy.json exists
    │
    ├─▶ If exists: Parse with Python
    │   │
    │   ├─▶ Read verbosity (default: "normal")
    │   ├─▶ Read skip list (append to defaults)
    │   ├─▶ Read skipPatterns (regex, future use)
    │   └─▶ Read dangerousCommands (merge with defaults)
    │
    ├─▶ If not exists or parse fails: Use defaults
    │
    └─▶ Generate prompt based on verbosity level
        │
        ├─▶ minimal: Only explain dangerous ops
        ├─▶ normal: Skip trivial commands (ls, cd, etc.)
        └─▶ verbose: Explain everything
```

### Default Values

```bash
# Default skip list
DEFAULT_SKIP="ls, cd, cat, pwd, git status"

# Default dangerous commands
DEFAULT_DANGEROUS=["rm -rf", "DROP", "DELETE FROM", "TRUNCATE"]

# Default verbosity
VERBOSITY="normal"
```

### Debugging Config Parsing

If config isn't loading correctly:

1. **Check file syntax**:
   ```bash
   python3 -m json.tool .claude/cc-buddy.json
   ```

2. **Test Python parser directly**:
   ```bash
   python3 << 'EOF'
   import json
   with open('.claude/cc-buddy.json') as f:
       config = json.load(f)
   print(config)
   EOF
   ```

3. **Check bash variable assignment**:
   ```bash
   bash -x hooks-handlers/session-start.sh 2>&1 | grep VERBOSITY
   ```

---

## Common Issues

### Issue 1: Config Changes Not Taking Effect

**Symptom**: Modified `.claude/cc-buddy.json` but behavior unchanged

**Solution**:
1. Restart Claude Code window
2. Verify config file syntax: `python3 -m json.tool .claude/cc-buddy.json`
3. Check if file is in correct location (project root, not plugin directory)

### Issue 2: Test Failures After Modifying session-start.sh

**Symptom**: `bash test.sh` shows failures

**Debug steps**:
1. Run hook directly: `bash hooks-handlers/session-start.sh`
2. Check JSON validity: `bash hooks-handlers/session-start.sh | python3 -c "import sys,json; json.load(sys.stdin)"`
3. Look for stderr output: `bash hooks-handlers/session-start.sh 2>&1 | grep -v "^{"`

**Common causes**:
- Unescaped quotes in prompt text
- Missing `json_escape()` call
- Bash syntax errors in heredoc

### Issue 3: Python Config Parser Fails Silently

**Symptom**: Config file exists but defaults are used

**Debug**:
```bash
# Test Python code in isolation
python3 << 'EOF'
import json
try:
    with open('.claude/cc-buddy.json') as f:
        config = json.load(f)
    print("✓ Config loaded:", config)
except Exception as e:
    print("✗ Error:", e)
EOF
```

**Common causes**:
- Invalid JSON syntax (trailing commas, missing quotes)
- File encoding issues (use UTF-8)
- File permissions

### Issue 4: Hook Not Firing in Claude Code

**Symptom**: No 😇 explanations appear

**Checklist**:
1. Verify plugin is installed: `claude plugins list`
2. Check hook registration: `cat hooks/hooks.json`
3. Test hook manually: `bash hooks-handlers/session-start.sh`
4. Restart Claude Code window
5. Check if `.claude/settings.json` disables plugins

---

## Submitting Changes

### Before Submitting a PR

1. **Run full test suite**:
   ```bash
   bash test.sh
   ```
   All 46 tests must pass.

2. **Validate plugin manifest**:
   ```bash
   claude plugins validate .
   ```

3. **Test hook output**:
   ```bash
   bash hooks-handlers/session-start.sh | python3 -c "import sys,json; json.load(sys.stdin)"
   ```

4. **Manual testing**:
   - Test in a real project with `--plugin-dir`
   - Try all three verbosity modes
   - Test with and without config file

5. **Update version** (if behavior changed):
   - Bump version in `.claude-plugin/plugin.json`
   - Bump version in `.claude-plugin/marketplace.json`
   - Follow semver: `MAJOR.MINOR.PATCH`

6. **Update documentation**:
   - Update README.md if user-facing behavior changed
   - Add test cases for new features
   - Update this CONTRIBUTING.md if dev workflow changed

### PR Checklist

- [ ] All tests pass (`bash test.sh`)
- [ ] Plugin validates (`claude plugins validate .`)
- [ ] Hook output is valid JSON
- [ ] Manually tested in real project
- [ ] Version bumped (if needed)
- [ ] README updated (if needed)
- [ ] No external dependencies added
- [ ] Code follows existing style

### Release Process

1. Merge PR to main branch
2. Tag release: `git tag v2.1.0 && git push --tags`
3. Users update with:
   ```bash
   claude plugins marketplace update flyai
   claude plugins update cc-buddy@flyai
   ```

---

## Additional Resources

- **Plugin Development**: [Claude Code Plugin Docs](https://docs.anthropic.com/claude/docs/claude-code-plugins)
- **Hook System**: See `hooks/hooks.json` for SessionStart hook structure
- **Testing Philosophy**: All tests use real hook output, no shadow functions
- **Skill System**: See `.claude/skills/plugin-change-checklist/SKILL.md`

---

## Questions?

If you encounter issues not covered here:

1. Check existing issues: https://github.com/alibaba-flyai/cc-buddy/issues
2. Run debug commands from this guide
3. Open a new issue with:
   - Output of `bash hooks-handlers/session-start.sh`
   - Output of `bash test.sh`
   - Your `.claude/cc-buddy.json` (if using)
   - Claude Code version

Happy contributing! 😇
