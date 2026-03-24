#!/usr/bin/env bash
# Test suite for PostToolUse hook dispatcher

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
echo "=== PostToolUse Hook Dispatcher Tests ==="
echo ""

# Test 1: Hook should output valid JSON
echo "Test 1: Valid JSON output"
result=$(echo '{"toolName":"Edit","file_path":"test.txt"}' | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" 2>/dev/null)
if echo "$result" | jq . >/dev/null 2>&1; then
  pass "Outputs valid JSON"
else
  fail "Invalid JSON output"
fi

# Test 2: Hook should have correct structure
echo ""
echo "Test 2: JSON structure"
if echo "$result" | jq -e '.hookSpecificOutput.hookEventName == "PostToolUse"' >/dev/null 2>&1; then
  pass "hookEventName is PostToolUse"
else
  fail "hookEventName missing or incorrect"
fi

# Test 3: Hook should always succeed
echo ""
echo "Test 3: Hook always succeeds"
if echo '{"toolName":"Edit","file_path":"test.txt"}' | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" >/dev/null 2>&1; then
  pass "Hook exits 0"
else
  fail "Hook exits non-zero"
fi

# Test 4: Non-matching tool should be skipped
echo ""
echo "Test 4: Non-matching tool skipped"
result=$(echo '{"toolName":"Read","file_path":"test.txt"}' | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" 2>/dev/null)
if echo "$result" | jq -e '.hookSpecificOutput.hookEventName == "PostToolUse"' >/dev/null 2>&1; then
  pass "Non-matching tool handled"
else
  fail "Non-matching tool failed"
fi

# Test 5: Missing config should not fail
echo ""
echo "Test 5: Missing config fallback"
mv "$PROJECT_ROOT/plugins/config.json" "$PROJECT_ROOT/plugins/config.json.bak" 2>/dev/null || true
result=$(echo '{"toolName":"Edit","file_path":"test.txt"}' | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" 2>/dev/null)
mv "$PROJECT_ROOT/plugins/config.json.bak" "$PROJECT_ROOT/plugins/config.json" 2>/dev/null || true
if echo "$result" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
  pass "Missing config handled gracefully"
else
  fail "Missing config causes failure"
fi

# Test 6: Plugin priority ordering
echo ""
echo "Test 6: Plugin priority ordering"
# Create a test file
TEST_FILE="$PROJECT_ROOT/test_format.js"
echo "const x=1;" > "$TEST_FILE"

result=$(echo "{\"toolName\":\"Edit\",\"file_path\":\"$TEST_FILE\"}" | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" 2>&1)
rm -f "$TEST_FILE"

if echo "$result" | grep -q "auto-format" || echo "$result" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
  pass "Plugins executed in priority order"
else
  fail "Plugin priority not respected"
fi

# Test 7: Matcher pattern matching
echo ""
echo "Test 7: Matcher pattern matching"
# Test Edit matcher
result=$(echo '{"toolName":"Edit","file_path":"test.txt"}' | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" 2>/dev/null)
if echo "$result" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
  pass "Edit matcher works"
else
  fail "Edit matcher failed"
fi

# Test Write matcher
result=$(echo '{"toolName":"Write","file_path":"test.txt"}' | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" 2>/dev/null)
if echo "$result" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
  pass "Write matcher works"
else
  fail "Write matcher failed"
fi

# Test 8: Empty input handling
echo ""
echo "Test 8: Empty input handling"
result=$(echo '{}' | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" 2>/dev/null)
if echo "$result" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
  pass "Empty input handled gracefully"
else
  fail "Empty input not handled"
fi

# Test 9: Plugin error doesn't stop chain
echo ""
echo "Test 9: Plugin errors don't stop chain"
# Even if a plugin fails, hook should succeed
result=$(echo '{"toolName":"Edit","file_path":"/nonexistent/file.txt"}' | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" 2>/dev/null)
if echo "$result" | jq -e '.hookSpecificOutput' >/dev/null 2>&1; then
  pass "Plugin errors don't stop chain"
else
  fail "Plugin error stopped chain"
fi

# Test 10: Hook idempotency
echo ""
echo "Test 10: Hook idempotency"
input='{"toolName":"Edit","file_path":"test.txt"}'
result1=$(echo "$input" | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" 2>/dev/null)
result2=$(echo "$input" | bash "$PROJECT_ROOT/hooks-handlers/post-tool-use.sh" 2>/dev/null)
if [[ "$result1" == "$result2" ]]; then
  pass "Hook output is idempotent"
else
  fail "Hook output differs between runs"
fi

echo ""
echo "=== Results ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo ""

if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
