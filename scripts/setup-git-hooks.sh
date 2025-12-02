#!/bin/bash

# Setup git hooks for Pulsar project
# This script installs the pre-commit hook for SwiftLint

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔧 Setting up git hooks for Pulsar..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
  echo -e "${RED}❌ Error: Not in a git repository${NC}"
  echo "Please run this script from the project root directory."
  exit 1
fi

# Check if pre-commit script exists
if [ ! -f "scripts/pre-commit" ]; then
  echo -e "${RED}❌ Error: scripts/pre-commit not found${NC}"
  echo "Make sure you're running this from the project root."
  exit 1
fi

# Create .git/hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
cp scripts/pre-commit .git/hooks/pre-commit

# Make it executable
chmod +x .git/hooks/pre-commit

echo -e "${GREEN}✅ Pre-commit hook installed successfully!${NC}"
echo ""
echo "The hook will now run SwiftLint on staged Swift files before each commit."
echo ""
echo "To test it, try:"
echo "  git add SomeFile.swift"
echo "  git commit -m 'test: verify hook works'"
echo ""





