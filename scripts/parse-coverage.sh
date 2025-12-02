#!/bin/bash

# Coverage parsing script for Pulsar
# Extracts coverage percentage from xcresult bundle

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default threshold
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-80}

# Check if xcresult path is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: xcresult path required${NC}"
    echo "Usage: $0 <path-to-xcresult> [threshold]"
    exit 1
fi

XCRESULT_PATH="$1"

# Check if threshold is provided
if [ -n "$2" ]; then
    COVERAGE_THRESHOLD="$2"
fi

# Check if xcresult exists
if [ ! -d "$XCRESULT_PATH" ]; then
    echo -e "${RED}❌ Error: xcresult not found at $XCRESULT_PATH${NC}"
    exit 1
fi

echo "📊 Parsing coverage from $XCRESULT_PATH..."

# Extract coverage percentage using xccov
COVERAGE_PERCENTAGE=$(xcrun xccov view --report "$XCRESULT_PATH" 2>/dev/null | grep -E "^\s*[0-9]+\.[0-9]+%" | head -1 | awk '{print $1}' | sed 's/%//' || echo "0")

# If xccov fails, try alternative method
if [ -z "$COVERAGE_PERCENTAGE" ] || [ "$COVERAGE_PERCENTAGE" = "0" ]; then
    # Try JSON method
    COVERAGE_JSON=$(xcrun xccov view --report --json "$XCRESULT_PATH" 2>/dev/null || echo "{}")
    COVERAGE_PERCENTAGE=$(echo "$COVERAGE_JSON" | grep -o '"lineCoverage":[0-9.]*' | head -1 | cut -d':' -f2 | awk '{printf "%.2f", $1 * 100}')
fi

# Convert to integer for comparison
COVERAGE_INT=$(echo "$COVERAGE_PERCENTAGE" | cut -d'.' -f1)

echo "📈 Coverage: ${COVERAGE_PERCENTAGE}%"
echo "🎯 Threshold: ${COVERAGE_THRESHOLD}%"

# Check if coverage meets threshold
if [ "$COVERAGE_INT" -lt "$COVERAGE_THRESHOLD" ]; then
    echo -e "${RED}❌ Coverage (${COVERAGE_PERCENTAGE}%) is below threshold (${COVERAGE_THRESHOLD}%)${NC}"
    echo "COVERAGE_PERCENTAGE=${COVERAGE_PERCENTAGE}" >> $GITHUB_ENV
    echo "COVERAGE_PASSED=false" >> $GITHUB_ENV
    exit 1
else
    echo -e "${GREEN}✅ Coverage (${COVERAGE_PERCENTAGE}%) meets threshold (${COVERAGE_THRESHOLD}%)${NC}"
    echo "COVERAGE_PERCENTAGE=${COVERAGE_PERCENTAGE}" >> $GITHUB_ENV
    echo "COVERAGE_PASSED=true" >> $GITHUB_ENV
    exit 0
fi






