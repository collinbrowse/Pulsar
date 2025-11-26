#!/bin/bash

# SwiftFormat auto-fix script for Pulsar
# This script automatically fixes code formatting issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🎨 Auto-fixing code formatting with SwiftFormat..."

# Check if SwiftFormat is installed
if ! command -v swiftformat &> /dev/null; then
    echo -e "${RED}❌ SwiftFormat is not installed.${NC}"
    echo "Install it with: brew install swiftformat"
    exit 1
fi

# Run SwiftFormat with auto-fix
swiftformat .

echo -e "${GREEN}✅ Code formatting fixed!${NC}"
echo "Please review the changes before committing."




