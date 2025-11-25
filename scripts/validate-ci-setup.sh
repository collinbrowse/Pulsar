#!/bin/bash

# CI Setup Validation Script for Pulsar
# Validates that all CI/CD components are properly configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track validation results
ERRORS=0
WARNINGS=0

echo -e "${BLUE}🔍 Validating CI/CD Setup for Pulsar${NC}"
echo ""

# Function to check file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ $2${NC}"
        return 0
    else
        echo -e "${RED}❌ $2 not found: $1${NC}"
        ((ERRORS++))
        return 1
    fi
}

# Function to check directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✅ $2${NC}"
        return 0
    else
        echo -e "${RED}❌ $2 not found: $1${NC}"
        ((ERRORS++))
        return 1
    fi
}

# Function to check file is executable
check_executable() {
    if [ -x "$1" ]; then
        echo -e "${GREEN}✅ $2 is executable${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $2 is not executable: $1${NC}"
        ((WARNINGS++))
        return 1
    fi
}

# Function to validate YAML syntax
validate_yaml() {
    if command -v yamllint &> /dev/null; then
        if yamllint "$1" &> /dev/null; then
            echo -e "${GREEN}✅ $2 YAML syntax valid${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  $2 YAML syntax issues (yamllint not installed or errors found)${NC}"
            ((WARNINGS++))
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  yamllint not installed, skipping YAML validation${NC}"
        return 0
    fi
}

echo -e "${BLUE}📁 Checking directory structure...${NC}"
check_dir "scripts" "Scripts directory"
check_dir ".github/workflows" "GitHub workflows directory"
check_dir "docs" "Documentation directory"
check_dir "Pulsar.xcodeproj/xcshareddata/xcschemes" "Shared schemes directory"
echo ""

echo -e "${BLUE}📄 Checking shared schemes...${NC}"
check_file "Pulsar.xcodeproj/xcshareddata/xcschemes/Pulsar.xcscheme" "Pulsar scheme"
check_file "Pulsar.xcodeproj/xcshareddata/xcschemes/PulsarTests.xcscheme" "PulsarTests scheme"
check_file "Pulsar.xcodeproj/xcshareddata/xcschemes/PulsarUITests.xcscheme" "PulsarUITests scheme"
echo ""

echo -e "${BLUE}📋 Checking test plans...${NC}"
check_file "PulsarTests/UnitTests.xctestplan" "UnitTests test plan"
check_file "PulsarUITests/UITests.xctestplan" "UITests test plan"
echo ""

echo -e "${BLUE}⚙️  Checking configuration files...${NC}"
check_file ".swiftlint.yml" "SwiftLint configuration"
check_file ".swiftformat" "SwiftFormat configuration"
check_file ".gitignore" ".gitignore file"
check_file "Dangerfile" "Dangerfile"
check_file "CHANGELOG.md" "CHANGELOG.md"
echo ""

echo -e "${BLUE}🔧 Checking scripts...${NC}"
check_file "scripts/run-lint.sh" "run-lint.sh script"
check_file "scripts/run-format.sh" "run-format.sh script"
check_file "scripts/run-format-fix.sh" "run-format-fix.sh script"
check_file "scripts/parse-coverage.sh" "parse-coverage.sh script"
check_file "scripts/generate-changelog.sh" "generate-changelog.sh script"
check_file "scripts/validate-ci-setup.sh" "validate-ci-setup.sh script"
echo ""

echo -e "${BLUE}📜 Checking scripts are executable...${NC}"
check_executable "scripts/run-lint.sh" "run-lint.sh"
check_executable "scripts/run-format.sh" "run-format.sh"
check_executable "scripts/run-format-fix.sh" "run-format-fix.sh"
check_executable "scripts/parse-coverage.sh" "parse-coverage.sh"
check_executable "scripts/generate-changelog.sh" "generate-changelog.sh"
check_executable "scripts/validate-ci-setup.sh" "validate-ci-setup.sh"
echo ""

echo -e "${BLUE}🚀 Checking GitHub Actions workflows...${NC}"
check_file ".github/workflows/ci.yml" "Main CI workflow"
check_file ".github/workflows/ci-lint.yml" "Linting workflow"
check_file ".github/workflows/ci-coverage.yml" "Coverage workflow"
check_file ".github/workflows/ci-danger.yml" "Danger workflow"
check_file ".github/workflows/nightly-ui-tests.yml" "Nightly UI tests workflow"
check_file ".github/workflows/ci-docs.yml" "Documentation workflow"
echo ""

echo -e "${BLUE}📚 Checking documentation files...${NC}"
check_file "docs/ci_overview.md" "CI overview documentation"
check_file "docs/style_guide.md" "Style guide documentation"
check_file "docs/testing.md" "Testing documentation"
check_file "docs/architecture.md" "Architecture documentation"
check_file "docs/deployment.md" "Deployment documentation"
check_file "docs/release_process.md" "Release process documentation"
check_file "docs/danger.md" "Danger documentation"
echo ""

echo -e "${BLUE}✅ Validating workflow YAML syntax...${NC}"
validate_yaml ".github/workflows/ci.yml" "Main CI workflow"
validate_yaml ".github/workflows/ci-lint.yml" "Linting workflow"
validate_yaml ".github/workflows/ci-coverage.yml" "Coverage workflow"
validate_yaml ".github/workflows/ci-danger.yml" "Danger workflow"
validate_yaml ".github/workflows/nightly-ui-tests.yml" "Nightly UI tests workflow"
validate_yaml ".github/workflows/ci-docs.yml" "Documentation workflow"
echo ""

# Summary
echo -e "${BLUE}📊 Validation Summary${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Validation completed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}❌ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi


