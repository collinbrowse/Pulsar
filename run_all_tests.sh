#!/usr/bin/env bash
# Run all Pulsar tests: unit (PulsarTests) + UI (PulsarUITests).
# Usage: ./run_all_tests.sh [destination]
# Default destination: platform=iOS Simulator,name=iPhone 17 Pro

set -e
DEST="${1:-platform=iOS Simulator,name=iPhone 17 Pro}"
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

echo "=== Running unit tests (PulsarTests) ==="
xcodebuild test -scheme Pulsar -destination "$DEST" -only-testing:PulsarTests CODE_SIGNING_ALLOWED=NO 2>&1 | tee /tmp/pulsar_unit.log | grep -E "Test (Suite|Case)|Executed|TEST |failure" || true

echo ""
echo "=== Running UI tests (PulsarUITests) ==="
xcodebuild test -scheme Pulsar -destination "$DEST" -only-testing:PulsarUITests CODE_SIGNING_ALLOWED=NO 2>&1 | tee /tmp/pulsar_ui.log | grep -E "Test (Suite|Case)|Executed|TEST |failure" || true

echo ""
echo "=== Summary ==="
grep "Executed" /tmp/pulsar_unit.log | tail -1
grep "Executed" /tmp/pulsar_ui.log | tail -1
grep "TEST SUCCEEDED\|TEST FAILED" /tmp/pulsar_unit.log /tmp/pulsar_ui.log || true
