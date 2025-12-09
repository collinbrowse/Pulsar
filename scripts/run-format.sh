#!/bin/bash

# SwiftFormat check script for Pulsar
# This script checks if code is properly formatted without making changes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🎨 Checking code formatting with SwiftFormat..."

# Check if SwiftFormat is installed
if ! command -v swiftformat &> /dev/null; then
    echo -e "${RED}❌ SwiftFormat is not installed.${NC}"
    echo "Install it with: brew install swiftformat"
    exit 1
fi

# Run SwiftFormat in lint mode (no changes)
if swiftformat --lint .; then
    echo -e "${GREEN}✅ Code formatting is correct!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Code formatting issues found.${NC}"
    echo "Run './scripts/run-format-fix.sh' to auto-fix formatting issues."
    exit 1
fi
