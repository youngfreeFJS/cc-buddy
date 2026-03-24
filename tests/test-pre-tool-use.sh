#!/usr/bin/env bash
# Test suite for PreToolUse hook dispatcher

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
echo "=== PreToolUse Hook Dispatcher Tests ==="
echo ""

# Test 1: Hook should output valid JSON
echo "Test 1: Valid JSON output"
result=$(echo '{"toolName":"Bash","command":"ls"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null)
if echo "$result" | jq . >/dev/null 2>&1; then
  pass "Outputs valid JSON"
else
  fail "Invalid JSON output"
fi

# Test 2: Hook should have correct structure
echo ""
echo "Test 2: JSON structure"
if echo "$result" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' >/dev/null 2>&1; then
  pass "hookEventName is PreToolUse"
else
  fail "hookEventName missing or incorrect"
fi

# Test 3: Safe command should be allowed
echo ""
echo "Test 3: Safe command allowed"
result=$(echo '{"toolName":"Bash","command":"ls -la"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null)
action=$(echo "$result" | jq -r '.hookSpecificOutput.action // "allow"')
if [[ "$action" == "allow" ]]; then
  pass "Safe command allowed"
else
  fail "Safe command blocked: $action"
fi

# Test 4: Dangerous command should be blocked
echo ""
echo "Test 4: Dangerous command blocked"
result=$(echo '{"toolName":"Bash","command":"rm -rf /"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null || true)
action=$(echo "$result" | jq -r '.hookSpecificOutput.action // "allow"')
if [[ "$action" == "block" ]]; then
  pass "Dangerous command blocked"
else
  fail "Dangerous command not blocked"
fi

# Test 5: Block reason should be provided
echo ""
echo "Test 5: Block reason provided"
if echo "$result" | jq -e '.hookSpecificOutput.reason' >/dev/null 2>&1; then
  pass "Block reason provided"
else
  fail "Block reason missing"
fi

# Test 6: Sensitive file should be protected
echo ""
echo "Test 6: Sensitive file protected"
result=$(echo '{"toolName":"Read","file_path":".env"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null || true)
action=$(echo "$result" | jq -r '.hookSpecificOutput.action // "allow"')
if [[ "$action" == "block" ]]; then
  pass "Sensitive file protected"
else
  fail "Sensitive file not protected"
fi

# Test 7: Non-matching tool should be allowed
echo ""
echo "Test 7: Non-matching tool allowed"
result=$(echo '{"toolName":"MultiEdit"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null)
action=$(echo "$result" | jq -r '.hookSpecificOutput.action // "allow"')
if [[ "$action" == "allow" ]]; then
  pass "Non-matching tool allowed"
else
  fail "Non-matching tool blocked"
fi

# Test 8: Missing config should allow by default
echo ""
echo "Test 8: Missing config fallback"
mv "$PROJECT_ROOT/plugins/config.json" "$PROJECT_ROOT/plugins/config.json.bak" 2>/dev/null || true
result=$(echo '{"toolName":"Bash","command":"ls"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null)
mv "$PROJECT_ROOT/plugins/config.json.bak" "$PROJECT_ROOT/plugins/config.json" 2>/dev/null || true
action=$(echo "$result" | jq -r '.hookSpecificOutput.action // "allow"')
if [[ "$action" == "allow" ]]; then
  pass "Missing config allows by default"
else
  fail "Missing config blocks incorrectly"
fi

# Test 9: Plugin priority ordering
echo ""
echo "Test 9: Plugin priority ordering"
# High priority plugin should execute first
result=$(echo '{"toolName":"Bash","command":"rm -rf /"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null || true)
plugin=$(echo "$result" | jq -r '.hookSpecificOutput.plugin // ""')
if [[ "$plugin" == "block-dangerous" ]]; then
  pass "High priority plugin executed first"
else
  fail "Plugin priority not respected: $plugin"
fi

# Test 10: Matcher pattern matching
echo ""
echo "Test 10: Matcher pattern matching"
# Test Bash matcher
result=$(echo '{"toolName":"Bash","command":"echo test"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null)
if echo "$result" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
  pass "Bash matcher works"
else
  fail "Bash matcher failed"
fi

# Test Edit matcher
result=$(echo '{"toolName":"Edit","file_path":"test.txt"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null)
if echo "$result" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
  pass "Edit matcher works"
else
  fail "Edit matcher failed"
fi

# Test 11: Hook exit code
echo ""
echo "Test 11: Hook exit codes"
# Safe command should exit 0
if echo '{"toolName":"Bash","command":"ls"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" >/dev/null 2>&1; then
  pass "Safe command exits 0"
else
  fail "Safe command exits non-zero"
fi

# Dangerous command should exit 1
if ! echo '{"toolName":"Bash","command":"rm -rf /"}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" >/dev/null 2>&1; then
  pass "Dangerous command exits 1"
else
  fail "Dangerous command exits 0"
fi

# Test 12: Empty input handling
echo ""
echo "Test 12: Empty input handling"
result=$(echo '{}' | bash "$PROJECT_ROOT/hooks-handlers/pre-tool-use.sh" 2>/dev/null)
if echo "$result" | jq -e '.hookSpecificOutput.action == "allow"' >/dev/null 2>&1; then
  pass "Empty input handled gracefully"
else
  fail "Empty input not handled"
fi

echo ""
echo "=== Results ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo ""

if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
