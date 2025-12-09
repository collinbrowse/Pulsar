# CI/CD Overview

This document provides an overview of the CI/CD setup for the Pulsar iOS project.

## Project Configuration

### Workspace/Project
- **Project Name**: Pulsar.xcodeproj
- **Type**: Xcode Project (not a workspace)
- **Package Manager**: Swift Package Manager (SPM)

### Build Schemes

The project uses three shared schemes for CI/CD:

1. **Pulsar** - Main application scheme
   - Bundle ID: `com.collinbrowse.Pulsar`
   - Target: iOS 26.0+
   - Swift Version: 6.0

2. **PulsarTests** - Unit tests scheme
   - Bundle ID: `com.collinbrowse.PulsarTests`
   - Test Target: Pulsar
   - Code Coverage: Enabled

3. **PulsarUITests** - UI tests scheme
   - Bundle ID: `com.collinbrowse.PulsarUITests`
   - Test Target: Pulsar
   - Code Coverage: Enabled

### Shared Schemes

All schemes are shared in `Pulsar.xcodeproj/xcshareddata/xcschemes/` to ensure CI can access them:
- `Pulsar.xcscheme`
- `PulsarTests.xcscheme`
- `PulsarUITests.xcscheme`

## Test Targets

### Unit Tests (PulsarTests)
- **Location**: `PulsarTests/`
- **Framework**: Swift Testing + XCTest
- **Test Plan**: `PulsarTests/UnitTests.xctestplan`
- **Coverage**: Enabled by default

### UI Tests (PulsarUITests)
- **Location**: `PulsarUITests/`
- **Framework**: XCTest (XCUITest)
- **Test Plan**: `PulsarUITests/UITests.xctestplan`
- **Coverage**: Enabled by default

## CI Workflow Structure

### Main Workflow
- **File**: `.github/workflows/ci.yml`
- **Triggers**: Push to `main` and `milestone-*` branches, PRs to `main`
- **Jobs**:
  - `build-and-test`: Builds app and runs all tests
  - `lint`: Runs SwiftLint checks
  - `security`: Checks for hardcoded secrets

### Additional Workflows

1. **Linting Workflow** (`.github/workflows/ci-lint.yml`)
   - Runs on pull requests
   - SwiftLint and SwiftFormat checks

2. **Coverage Workflow** (`.github/workflows/ci-coverage.yml`)
   - Runs on pull requests
   - Enforces 80% coverage threshold

3. **Danger Workflow** (`.github/workflows/ci-danger.yml`)
   - Runs on pull requests
   - PR quality checks and automation

4. **Nightly UI Tests** (`.github/workflows/nightly-ui-tests.yml`)
   - Runs nightly via cron schedule
   - Full UI test suite execution

5. **Documentation Workflow** (`.github/workflows/ci-docs.yml`)
   - Runs on documentation changes
   - Validates markdown and generates docs

## Build Configuration

### Xcode Version
- **CI**: Latest available Xcode version (auto-detected)
- **Local Development**: Xcode 26.0+

### iOS Simulator
- **Device**: iPhone 16 Pro
- **OS Version**: iOS 26.0

### Build Settings
- **Code Signing**: Automatic (CI uses `CODE_SIGNING_ALLOWED=NO`)
- **Swift Version**: 6.0
- **Deployment Target**: iOS 26.0

## Test Execution

### Local Testing
```bash
# Run unit tests
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme PulsarTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' \
  -testPlan UnitTests

# Run UI tests
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme PulsarUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' \
  -testPlan UITests
```

### CI Testing
Tests are executed automatically via GitHub Actions using:
- Test plans for organized test execution
- Parallel test execution where supported
- Code coverage collection
- Test result bundle generation (.xcresult)

## Artifacts

CI workflows generate and upload the following artifacts:

1. **Test Results** (`.xcresult` bundles)
   - Unit test results
   - UI test results
   - Coverage data

2. **Build Logs**
   - Xcode build output
   - Test execution logs

3. **Coverage Reports**
   - JSON format for programmatic access
   - HTML format for human-readable reports

4. **Lint Reports**
   - SwiftLint violations
   - SwiftFormat check results

5. **UI Test Screenshots**
   - Screenshots captured during UI tests
   - Failure screenshots for debugging

## Branch Strategy

- **Main Branch**: `main` - Production-ready code
- **Feature Branches**: `milestone-*-*` - Feature development
- **CI Branch**: `ci/automation-setup` - CI/CD infrastructure

## Dependencies

### Swift Packages
- CoreGPX (GPX parsing)
- XMLCoder (XML parsing)
- FitDataProtocol (FIT file parsing)
- PostHog (Analytics)

### CI Tools
- SwiftLint (Code linting)
- SwiftFormat (Code formatting)
- Danger (PR automation)
- xcpretty (Build output formatting)

## Environment Variables

CI workflows use the following environment variables (configured in GitHub Secrets):
- `SUPABASE_URL` - Supabase backend URL
- `SUPABASE_ANON_KEY` - Supabase anonymous key
- `POSTHOG_API_KEY` - PostHog analytics key (optional)

## Coverage Threshold

- **Target**: 80% code coverage
- **Enforcement**: PRs fail if coverage drops below threshold
- **Baseline**: Coverage on `main` branch

## Related Documentation

- [Testing Guide](testing.md) - Detailed testing documentation
- [Style Guide](style_guide.md) - Code style and linting rules
- [Team Workflow](TEAM_WORKFLOW.md) - Development workflow
- [CI Setup Guide](README_CI_SETUP.md) - Complete CI setup instructions
