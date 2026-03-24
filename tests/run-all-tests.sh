#!/usr/bin/env bash
# Run all test suites

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOTAL_PASS=0
TOTAL_FAIL=0

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          cc-buddy Test Suite Runner                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Make all test scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# Run each test suite
test_suites=(
  "test-pre-tool-use.sh"
  "test-post-tool-use.sh"
  "test-plugins.sh"
  "test-integration.sh"
)

for suite in "${test_suites[@]}"; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Running: $suite"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  if bash "$SCRIPT_DIR/$suite"; then
    echo "✓ $suite PASSED"
  else
    echo "✗ $suite FAILED"
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
  fi
  echo ""
done

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Final Results                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ "$TOTAL_FAIL" -eq 0 ]; then
  echo "  🎉 All test suites PASSED!"
  echo ""
  exit 0
else
  echo "  ❌ $TOTAL_FAIL test suite(s) FAILED"
  echo ""
  exit 1
fi
