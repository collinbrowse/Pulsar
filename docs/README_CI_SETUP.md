# CI/CD Setup Guide

Complete guide to setting up and using the CI/CD automation for the Pulsar iOS project.

## Overview

Pulsar uses GitHub Actions for continuous integration and deployment. The CI/CD system includes:

- **Build & Test**: Automated builds and test execution
- **Linting**: Code quality checks (SwiftLint + SwiftFormat)
- **Coverage**: Code coverage enforcement (80% threshold)
- **Danger**: PR quality automation
- **Nightly Tests**: Scheduled UI test runs
- **Documentation**: Automated documentation validation

## Quick Start

### Prerequisites

- GitHub repository with Actions enabled
- Xcode project with shared schemes
- Test plans configured

### Initial Setup

1. **Verify Shared Schemes**
   ```bash
   ./scripts/validate-ci-setup.sh
   ```

2. **Test Locally**
   ```bash
   # Run linting
   ./scripts/run-lint.sh
   
   # Run formatting check
   ./scripts/run-format.sh
   
   # Run tests
   xcodebuild test -project Pulsar.xcodeproj -scheme PulsarTests
   ```

3. **Push to GitHub**
   ```bash
   git push origin ci/automation-setup
   ```

## Workflows

### Main CI Workflow (`.github/workflows/ci.yml`)

**Triggers**: Push to `main` and `milestone-*` branches, PRs to `main`

**Jobs**:
- `build-and-test`: Builds app and runs all tests
- `lint`: Runs SwiftLint checks
- `security`: Checks for hardcoded secrets

**Artifacts**:
- Test results (`.xcresult` bundles)
- Coverage reports (JSON and HTML)
- UI test screenshots
- Build logs

### Linting Workflow (`.github/workflows/ci-lint.yml`)

**Triggers**: Pull requests

**Checks**:
- SwiftLint validation
- SwiftFormat validation

**Artifacts**:
- Lint reports (JSON and text)

### Coverage Workflow (`.github/workflows/ci-coverage.yml`)

**Triggers**: Pull requests

**Enforcement**:
- 80% coverage threshold
- Compares with baseline from `main` branch
- Fails PR if coverage drops

**Artifacts**:
- Coverage reports (JSON and text)

### Danger Workflow (`.github/workflows/ci-danger.yml`)

**Triggers**: Pull requests

**Checks**:
- PR title format
- Changelog entries
- Documentation
- TODO/FIXME warnings
- File size limits
- Screenshot requirements

### Nightly UI Tests (`.github/workflows/nightly-ui-tests.yml`)

**Triggers**: 
- Scheduled (daily at 2 AM UTC)
- Manual (workflow_dispatch)

**Purpose**:
- Full UI test suite execution
- Regression detection
- Screenshot collection

**Artifacts**:
- Test results
- Coverage reports
- Screenshots

### Documentation Workflow (`.github/workflows/ci-docs.yml`)

**Triggers**: Changes to documentation files

**Checks**:
- Markdown syntax validation
- Internal link validation
- Documentation index generation

## Local Development

### Running Scripts

All scripts are in the `scripts/` directory:

```bash
# Git Hooks Setup (first time only)
./scripts/setup-git-hooks.sh   # Install pre-commit hook

# Linting
./scripts/run-lint.sh          # Check for linting errors
./scripts/lint-all-files.sh    # Check all files (one-time use)
./scripts/lint-all-files.sh --fix  # Auto-fix all files
swiftlint --fix                 # Auto-fix linting issues

# Formatting
./scripts/run-format.sh        # Check formatting
./scripts/run-format-fix.sh    # Auto-fix formatting

# Coverage
./scripts/parse-coverage.sh <xcresult-path> [threshold]

# Changelog
./scripts/generate-changelog.sh

# Validation
./scripts/validate-ci-setup.sh
```

### Pre-Commit Hook

**Setup** (one-time per developer):
```bash
./scripts/setup-git-hooks.sh
```

The pre-commit hook automatically:
- Runs SwiftLint on staged Swift files
- Blocks commit if violations found
- Auto-fixes issues where possible
- Re-stages auto-fixed files

**Usage**: Just commit normally - the hook runs automatically!

### Pre-Commit Checklist

Before committing:

- [ ] Pre-commit hook installed: `./scripts/setup-git-hooks.sh`
- [ ] Hook will run automatically on commit
- [ ] (Optional) Run tests: `xcodebuild test -project Pulsar.xcodeproj -scheme PulsarTests`
- [ ] Update CHANGELOG.md if needed
- [ ] Ensure PR title follows conventional commits format

## Configuration

### SwiftLint

Configuration: `.swiftlint.yml`

Key rules:
- File length: Warning at 500, error at 1000
- Function length: Warning at 50, error at 100
- Cyclomatic complexity: Warning at 10, error at 20

### SwiftFormat

Configuration: `.swiftformat`

Key settings:
- Indentation: Tabs (4 spaces)
- Line length: 120 characters
- Swift 6 concurrency enabled

### Coverage Threshold

Set in `.github/workflows/ci-coverage.yml`:
```yaml
env:
  COVERAGE_THRESHOLD: 80
```

## Troubleshooting

### CI Build Failures

1. **Check workflow logs** in GitHub Actions
2. **Run validation script** locally: `./scripts/validate-ci-setup.sh`
3. **Test locally** with same commands as CI

### Linting Failures

1. **Run locally**: `./scripts/run-lint.sh`
2. **Auto-fix**: `swiftlint --fix`
3. **Check reports** in workflow artifacts

### Coverage Failures

1. **Check coverage report** in workflow artifacts
2. **Run locally**: `./scripts/parse-coverage.sh <xcresult>`
3. **Add tests** for uncovered code

### Danger Failures

1. **Check Danger comments** on PR
2. **Fix issues** mentioned in comments
3. **Re-run workflow** if needed

## Best Practices

### PR Workflow

1. **Create feature branch**: `git checkout -b feature/my-feature`
2. **Make changes** and commit
3. **Run pre-commit checks** locally
4. **Push and create PR**
5. **Address CI feedback**
6. **Merge when all checks pass**

### Commit Messages

Follow conventional commits:
- `feat: add new feature`
- `fix: resolve bug`
- `docs: update documentation`
- `refactor: improve code structure`

### Test Coverage

- Aim for 80%+ coverage
- Write tests for new functionality
- Update tests when changing code
- Review coverage reports regularly

## One-Time Full Project Lint

If you're adding SwiftLint mid-development, check all files at once:

```bash
# Check all files for violations
./scripts/lint-all-files.sh

# Auto-fix all issues
./scripts/lint-all-files.sh --fix

# Review and commit fixes
git add .
git commit -m "style: fix SwiftLint violations"
```

## Related Documentation

- [CI Overview](ci_overview.md) - CI/CD configuration details
- [Style Guide](style_guide.md) - Code style rules
- [Testing Guide](testing.md) - Testing documentation
- [Team Workflow](TEAM_WORKFLOW.md) - Development workflow
- [Danger Guide](danger.md) - Danger automation rules


