#!/bin/bash

# SwiftLint runner script for Pulsar
# This script runs SwiftLint with proper error handling and exit codes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Running SwiftLint..."

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo -e "${RED}❌ SwiftLint is not installed.${NC}"
    echo "Install it with: brew install swiftlint"
    exit 1
fi

# Run SwiftLint
if swiftlint lint --strict; then
    echo -e "${GREEN}✅ SwiftLint passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ SwiftLint found violations.${NC}"
    echo "Run 'swiftlint --fix' to auto-fix some issues."
    exit 1
fi
