#!/usr/bin/env bash
# Integration tests for the complete hook system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

export CLAUDE_PLUGIN_ROOT="$PROJECT_ROOT"

PASS=0
FAIL=0

pass() {
  echo "  ✓ PASS: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  ✗ FAIL: $1"
  FAIL=$((FAIL + 1))
}

echo ""
echo "=== Integration Tests ==="
echo ""

# Test 1: hooks.json structure
echo "Test 1: hooks.json structure validation"
if python3 -c "
import json
from pathlib import Path

data = json.loads(Path('$PROJECT_ROOT/hooks/hooks.json').read_text())
hooks = data['hooks']

# Check SessionStart
assert 'SessionStart' in hooks
assert len(hooks['SessionStart']) > 0

# Check PreToolUse
assert 'PreToolUse' in hooks
assert len(hooks['PreToolUse']) > 0
assert hooks['PreToolUse'][0]['matcher'] == 'Bash|Read|Edit|Write'

# Check PostToolUse
assert 'PostToolUse' in hooks
assert len(hooks['PostToolUse']) > 0
assert hooks['PostToolUse'][0]['matcher'] == 'Edit|Write'
" 2>/dev/null; then
  pass "hooks.json structure valid"
else
  fail "hooks.json structure invalid"
fi

# Test 2: Plugin config structure
echo ""
echo "Test 2: Plugin config validation"
if python3 -c "
import json
from pathlib import Path

config = json.loads(Path('$PROJECT_ROOT/plugins/config.json').read_text())

# Check pre plugins
assert 'pre' in config
assert len(config['pre']) >= 2
for plugin in config['pre']:
    assert 'name' in plugin
    assert 'enabled' in plugin
    assert 'matcher' in plugin
    assert 'priority' in plugin
    assert 'script' in plugin

# Check post plugins
assert 'post' in config
assert len(config['post']) >= 2
for plugin in config['post']:
    assert 'name' in plugin
    assert 'enabled' in plugin
    assert 'matcher' in plugin
    assert 'priority' in plugin
    assert 'script' in plugin
" 2>/dev/null; then
  pass "Plugin config structure valid"
else
  fail "Plugin config structure invalid"
fi

# Test 3: All plugin scripts exist and are executable
echo ""
echo "Test 3: Plugin scripts existence and permissions"
all_exist=true
for script in "$PROJECT_ROOT"/plugins/pre/*.sh "$PROJECT_ROOT"/plugins/post/*.sh; do
  if [[ ! -f "$script" ]]; then
    fail "Plugin script not found: $script"
    all_exist=false
  elif [[ ! -x "$script" ]]; then
    fail "Plugin script not executable: $script"
    all_exist=false
  fi
done
if $all_exist; then
  pass "All plugin scripts exist and are executable"
fi

# Test 4: Hook dispatchers exist and are executable
echo ""
echo "Test 4: Hook dispatchers existence"
for dispatcher in pre-tool-use.sh post-tool-use.sh; do
  if [[ ! -f "$PROJECT_ROOT/hooks-handlers/$dispatcher" ]]; then
    fail "Dispatcher not found: $dispatcher"
  elif [[ ! -x "$PROJECT_ROOT/hooks-handlers/$dispatcher" ]]; then
    fail "Dispatcher not executable: $dispatcher"
  else
    pass "Dispatcher $dispatcher exists and is executable"
  fi
done

# Test 5: End-to-end dangerous command blocking
echo ""
echo "Test 5: E2E dangerous command blocking"
result=$(echo '{"toolName":"Bash","command":"rm -rf /"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null || true)
if echo "$result" | jq -e '.hookSpecificOutput.action == "block"' >/dev/null 2>&1; then
  pass "E2E dangerous command blocked"
else
  fail "E2E dangerous command not blocked"
fi

# Test 6: End-to-end sensitive file protection
echo ""
echo "Test 6: E2E sensitive file protection"
result=$(echo '{"toolName":"Read","file_path":".env"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null || true)
if echo "$result" | jq -e '.hookSpecificOutput.action == "block"' >/dev/null 2>&1; then
  pass "E2E sensitive file protected"
else
  fail "E2E sensitive file not protected"
fi

# Test 7: End-to-end safe operation allowed
echo ""
echo "Test 7: E2E safe operation allowed"
result=$(echo '{"toolName":"Bash","command":"ls -la"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null)
if echo "$result" | jq -e '.hookSpecificOutput.action == "allow"' >/dev/null 2>&1; then
  pass "E2E safe operation allowed"
else
  fail "E2E safe operation blocked"
fi

# Test 8: End-to-end PostToolUse execution
echo ""
echo "Test 8: E2E PostToolUse execution"
TEST_FILE="$PROJECT_ROOT/test_integration.js"
echo "const x=1;" > "$TEST_FILE"
result=$(echo "{\"toolName\":\"Edit\",\"file_path\":\"$TEST_FILE\"}" | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" 2>&1)
rm -f "$TEST_FILE"
if echo "$result" | jq -e '.hookSpecificOutput.hookEventName == "PostToolUse"' >/dev/null 2>&1; then
  pass "E2E PostToolUse executed"
else
  fail "E2E PostToolUse failed"
fi

# Test 9: Plugin priority ordering
echo ""
echo "Test 9: Plugin priority ordering"
priorities=$(python3 -c "
import json
from pathlib import Path

config = json.loads(Path('$PROJECT_ROOT/plugins/config.json').read_text())
pre_priorities = [p['priority'] for p in config['pre'] if p['enabled']]
post_priorities = [p['priority'] for p in config['post'] if p['enabled']]

# Check if priorities are in descending order after sorting
assert pre_priorities == sorted(pre_priorities, reverse=True)
assert post_priorities == sorted(post_priorities, reverse=True)
print('OK')
" 2>/dev/null)
if [[ "$priorities" == "OK" ]]; then
  pass "Plugin priorities properly ordered"
else
  fail "Plugin priorities not properly ordered"
fi

# Test 10: All hooks use CLAUDE_PLUGIN_ROOT
echo ""
echo "Test 10: CLAUDE_PLUGIN_ROOT usage"
if python3 -c "
import json
from pathlib import Path

data = json.loads(Path('$PROJECT_ROOT/hooks/hooks.json').read_text())
for hook_type in ['SessionStart', 'PreToolUse', 'PostToolUse']:
    for hook_group in data['hooks'][hook_type]:
        for hook in hook_group['hooks']:
            assert '\${CLAUDE_PLUGIN_ROOT}' in hook['command']
" 2>/dev/null; then
  pass "All hooks use CLAUDE_PLUGIN_ROOT"
else
  fail "Some hooks don't use CLAUDE_PLUGIN_ROOT"
fi

# Test 11: Timeout configuration
echo ""
echo "Test 11: Timeout configuration"
if python3 -c "
import json
from pathlib import Path

data = json.loads(Path('$PROJECT_ROOT/hooks/hooks.json').read_text())
for hook_type in ['SessionStart', 'PreToolUse', 'PostToolUse']:
    for hook_group in data['hooks'][hook_type]:
        for hook in hook_group['hooks']:
            assert hook.get('timeout', 0) > 0
" 2>/dev/null; then
  pass "All hooks have timeout configured"
else
  fail "Some hooks missing timeout"
fi

# Test 12: Documentation files exist
echo ""
echo "Test 12: Documentation completeness"
docs_exist=true
for doc in architecture.md hook-inspirations.md plugin-development.md IMPLEMENTATION_SUMMARY.md; do
  if [[ ! -f "$PROJECT_ROOT/docs/$doc" ]]; then
    fail "Documentation missing: $doc"
    docs_exist=false
  fi
done
if $docs_exist; then
  pass "All documentation files exist"
fi

echo ""
echo "=== Results ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo ""

if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
