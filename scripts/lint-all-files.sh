#!/bin/bash

# One-time full project lint script for Pulsar
# Useful for mid-development adoption to check all files at once

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if --fix flag is provided
AUTO_FIX=false
if [ "$1" == "--fix" ]; then
  AUTO_FIX=true
fi

echo -e "${BLUE}🔍 Running SwiftLint on all Swift files in project...${NC}"
echo ""

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
  echo -e "${RED}❌ SwiftLint is not installed.${NC}"
  echo "Install it with: brew install swiftlint"
  exit 1
fi

# Count Swift files
SWIFT_FILES=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./DerivedData/*" -not -path "./Pods/*" | wc -l | tr -d ' ')
echo "📊 Found $SWIFT_FILES Swift files to check"
echo ""

if [ "$AUTO_FIX" = true ]; then
  echo -e "${YELLOW}🔧 Auto-fixing issues...${NC}"
  echo ""
  
  # Run SwiftLint with auto-fix (this fixes what it can)
  echo "Step 1: Running auto-fix..."
  swiftlint --fix . || true  # Don't fail if some issues can't be auto-fixed
  
  echo ""
  echo "Step 2: Checking remaining issues..."
  echo ""
  
  # Now check if there are still violations
  # Capture both output and exit code
  LINT_OUTPUT=$(swiftlint lint --strict . 2>&1)
  LINT_EXIT_CODE=$?
  
  # Display the output
  echo "$LINT_OUTPUT"
  
  if [ $LINT_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All issues fixed!${NC}"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Review changes: git diff"
    echo "   2. Stage fixes: git add ."
    echo "   3. Commit: git commit -m 'style: fix SwiftLint violations'"
    exit 0
  else
    echo ""
    echo -e "${YELLOW}⚠️  Some issues were auto-fixed, but some require manual attention.${NC}"
    echo ""
    echo "📋 Remaining issues that need manual fixes:"
    echo "   - Force unwrapping violations (use guard/if-let instead)"
    echo "   - Function body length (refactor into smaller functions)"
    echo "   - Identifier naming (rename functions/variables)"
    echo "   - TODO comments (resolve or remove)"
    echo "   - Cyclomatic complexity (refactor complex functions)"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Review auto-fixes: git diff"
    echo "   2. Manually fix remaining issues shown above"
    echo "   3. Run again: ./scripts/lint-all-files.sh"
    echo "   4. Stage and commit when all issues are resolved"
    exit 1
  fi
else
  echo -e "${BLUE}Running lint check (no auto-fix)...${NC}"
  echo ""
  
  # Run SwiftLint without auto-fix
  if swiftlint lint --strict .; then
    echo ""
    echo -e "${GREEN}✅ All files pass SwiftLint!${NC}"
    exit 0
  else
    echo ""
    echo -e "${RED}❌ SwiftLint found violations.${NC}"
    echo ""
    echo "💡 To auto-fix issues:"
    echo "   ./scripts/lint-all-files.sh --fix"
    echo ""
    echo "💡 Or fix manually:"
    echo "   swiftlint --fix"
    echo ""
    exit 1
  fi
fi

