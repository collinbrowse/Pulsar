#!/bin/bash

# Changelog generation script for Pulsar
# Generates CHANGELOG.md entries from git commits

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the last tag or use initial commit
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
LAST_COMMIT=$(git rev-parse HEAD)

if [ -z "$LAST_TAG" ]; then
    echo -e "${YELLOW}⚠️  No tags found. Using all commits.${NC}"
    RANGE="HEAD"
else
    RANGE="${LAST_TAG}..HEAD"
fi

echo "📝 Generating changelog from ${RANGE}..."

# Create temporary file for new entries
TEMP_FILE=$(mktemp)

# Categorize commits
FEATURES=()
FIXES=()
DOCS=()
STYLE=()
REFACTOR=()
PERF=()
TEST=()
CHORE=()

# Parse commits
git log --pretty=format:"%s|%b" ${RANGE} | while IFS='|' read -r subject body; do
    # Skip merge commits
    if [[ "$subject" =~ ^Merge ]]; then
        continue
    fi
    
    # Categorize by conventional commit type
    if [[ "$subject" =~ ^feat(\(.+\))?: ]]; then
        FEATURES+=("$subject")
    elif [[ "$subject" =~ ^fix(\(.+\))?: ]]; then
        FIXES+=("$subject")
    elif [[ "$subject" =~ ^docs(\(.+\))?: ]]; then
        DOCS+=("$subject")
    elif [[ "$subject" =~ ^style(\(.+\))?: ]]; then
        STYLE+=("$subject")
    elif [[ "$subject" =~ ^refactor(\(.+\))?: ]]; then
        REFACTOR+=("$subject")
    elif [[ "$subject" =~ ^perf(\(.+\))?: ]]; then
        PERF+=("$subject")
    elif [[ "$subject" =~ ^test(\(.+\))?: ]]; then
        TEST+=("$subject")
    elif [[ "$subject" =~ ^chore(\(.+\))?: ]]; then
        CHORE+=("$subject")
    fi
done

# Generate changelog entries
{
    echo "## [Unreleased]"
    echo ""
    
    if [ ${#FEATURES[@]} -gt 0 ]; then
        echo "### Added"
        for feature in "${FEATURES[@]}"; do
            # Remove type prefix
            CLEANED=$(echo "$feature" | sed -E 's/^feat(\(.+\))?: //')
            echo "- ${CLEANED}"
        done
        echo ""
    fi
    
    if [ ${#FIXES[@]} -gt 0 ]; then
        echo "### Fixed"
        for fix in "${FIXES[@]}"; do
            CLEANED=$(echo "$fix" | sed -E 's/^fix(\(.+\))?: //')
            echo "- ${CLEANED}"
        done
        echo ""
    fi
    
    if [ ${#REFACTOR[@]} -gt 0 ]; then
        echo "### Changed"
        for refactor in "${REFACTOR[@]}"; do
            CLEANED=$(echo "$refactor" | sed -E 's/^refactor(\(.+\))?: //')
            echo "- ${CLEANED}"
        done
        echo ""
    fi
    
    if [ ${#PERF[@]} -gt 0 ]; then
        echo "### Performance"
        for perf in "${PERF[@]}"; do
            CLEANED=$(echo "$perf" | sed -E 's/^perf(\(.+\))?: //')
            echo "- ${CLEANED}"
        done
        echo ""
    fi
    
    if [ ${#DOCS[@]} -gt 0 ] || [ ${#STYLE[@]} -gt 0 ] || [ ${#TEST[@]} -gt 0 ] || [ ${#CHORE[@]} -gt 0 ]; then
        echo "### Other"
        for doc in "${DOCS[@]}"; do
            CLEANED=$(echo "$doc" | sed -E 's/^docs(\(.+\))?: //')
            echo "- ${CLEANED}"
        done
        for style in "${STYLE[@]}"; do
            CLEANED=$(echo "$style" | sed -E 's/^style(\(.+\))?: //')
            echo "- ${CLEANED}"
        done
        for test in "${TEST[@]}"; do
            CLEANED=$(echo "$test" | sed -E 's/^test(\(.+\))?: //')
            echo "- ${CLEANED}"
        done
        for chore in "${CHORE[@]}"; do
            CLEANED=$(echo "$chore" | sed -E 's/^chore(\(.+\))?: //')
            echo "- ${CLEANED}"
        done
        echo ""
    fi
} > "$TEMP_FILE"

# Check if there are any changes
if [ -s "$TEMP_FILE" ]; then
    echo -e "${GREEN}✅ Generated changelog entries${NC}"
    echo ""
    echo "Preview:"
    cat "$TEMP_FILE"
    echo ""
    echo "To update CHANGELOG.md, prepend this content to the [Unreleased] section."
else
    echo -e "${YELLOW}⚠️  No changes found in range ${RANGE}${NC}"
fi

# Cleanup
rm "$TEMP_FILE"




