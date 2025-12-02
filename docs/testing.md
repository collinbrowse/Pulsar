# Testing Guide

This document provides comprehensive information about testing in the Pulsar iOS project.

## Overview

Pulsar uses a combination of testing frameworks:
- **Swift Testing** - Modern unit testing framework (Swift 6+)
- **XCTest** - Traditional unit and UI testing framework

## Test Structure

### Unit Tests (PulsarTests)

**Location**: `PulsarTests/`

**Framework**: Swift Testing + XCTest

**Test Plan**: `PulsarTests/UnitTests.xctestplan`

**Test Files**:
- `ActivityTests.swift`
- `AppStateTests.swift`
- `AuthenticationFlowTests.swift`
- `AuthenticationServiceTests.swift`
- `EnvironmentTests.swift`
- `FeatureFlagsTests.swift`
- `ProfileEncodingTests.swift`
- `ProfileTests.swift`
- `SocialTests.swift`
- `SupabaseClientTests.swift`

### UI Tests (PulsarUITests)

**Location**: `PulsarUITests/`

**Framework**: XCTest (XCUITest)

**Test Plan**: `PulsarUITests/UITests.xctestplan`

**Test Files**:
- `Milestone2UITests.swift`
- `OnboardingUITests.swift`
- `PulsarUITests.swift`
- `PulsarUITestsLaunchTests.swift`
- `SignUpWithExistingAccountUITests.swift`
- `UITestHelpers.swift`

## Test Plans

Test plans provide organized test execution with configurable options.

### UnitTests.xctestplan

**Configuration**:
- **Parallelization**: Enabled (tests run in parallel)
- **Code Coverage**: Enabled (via scheme)
- **Diagnostics**: Available (Address Sanitizer, Thread Sanitizer)
- **Test Execution**: Random order

**Usage**:
```bash
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme PulsarTests \
  -testPlan UnitTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'
```

### UITests.xctestplan

**Configuration**:
- **Parallelization**: Disabled (UI tests run sequentially)
- **Code Coverage**: Enabled (via scheme)
- **Diagnostics**: Available
- **Test Execution**: Sequential

**Usage**:
```bash
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme PulsarUITests \
  -testPlan UITests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'
```

## Running Tests

### In Xcode

1. **Run All Tests**
   - Press `Cmd+U` or Product → Test
   - Select test plan from scheme menu

2. **Run Specific Tests**
   - Click diamond icon next to test function
   - Right-click test class → Run

3. **Run with Coverage**
   - Edit Scheme → Test → Options
   - Enable "Gather coverage data"

### Command Line

#### Unit Tests
```bash
# Run all unit tests
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme PulsarTests \
  -testPlan UnitTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' \
  -enableCodeCoverage YES

# Run specific test
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme PulsarTests \
  -testPlan UnitTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' \
  -only-testing:PulsarTests/ActivityTests/testActivityCreation
```

#### UI Tests
```bash
# Run all UI tests
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme PulsarUITests \
  -testPlan UITests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' \
  -enableCodeCoverage YES

# Run specific UI test
xcodebuild test \
  -project Pulsar.xcodeproj \
  -scheme PulsarUITests \
  -testPlan UITests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' \
  -only-testing:PulsarUITests/OnboardingUITests/testSignUpFlow
```

## Test Organization

### Unit Test Structure

#### Swift Testing Framework
```swift
import Testing
@testable import Pulsar

@Suite("ActivityService Tests")
struct ActivityServiceTests {
    @Test("Parse GPX file successfully")
    func testParseGPX() async throws {
        // Test implementation
    }
    
    @Test("Handle invalid file format")
    func testInvalidFileFormat() async throws {
        // Test implementation
    }
}
```

#### XCTest Framework
```swift
import XCTest
@testable import Pulsar

final class ActivityTests: XCTestCase {
    func testActivityCreation() {
        let activity = Activity(
            userId: "test-user",
            name: "Test Run",
            distance: 5.0
        )
        XCTAssertEqual(activity.name, "Test Run")
    }
}
```

### UI Test Structure
```swift
import XCTest

final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testSignUpFlow() {
        // UI test implementation
    }
}
```

## Code Coverage

### Requirements

- **Target**: 80% code coverage
- **Enforcement**: PRs fail if coverage drops below threshold
- **Baseline**: Coverage on `main` branch

### Viewing Coverage

#### In Xcode
1. Run tests with coverage enabled
2. Open Report Navigator (Cmd+9)
3. Select test run
4. View coverage in Coverage tab

#### Command Line
```bash
# Generate coverage report
xcrun xccov view --report --json TestResults.xcresult > coverage.json

# View coverage summary
xcrun xccov view --report TestResults.xcresult
```

### Coverage Reports

CI generates coverage reports in multiple formats:
- **JSON**: For programmatic access
- **HTML**: For human-readable reports
- **xcresult**: Xcode-compatible format

## Diagnostics

### Available Diagnostics

Test plans support the following diagnostics:

1. **Address Sanitizer**
   - Detects memory corruption
   - Enabled via scheme settings

2. **Thread Sanitizer**
   - Detects data races
   - Enabled via scheme settings

3. **Main Thread Checker**
   - Detects UI updates off main thread
   - Enabled by default in Debug

### Enabling Diagnostics

1. Edit Scheme (Product → Scheme → Edit Scheme)
2. Select Test action
3. Enable desired diagnostics
4. Run tests

## CI Integration

### Test Execution in CI

Tests run automatically in CI via GitHub Actions:

1. **Main CI Workflow** (`.github/workflows/ci.yml`)
   - Runs on push to `main` and `milestone-*` branches
   - Runs on pull requests
   - Executes both unit and UI tests

2. **Nightly UI Tests** (`.github/workflows/nightly-ui-tests.yml`)
   - Runs nightly via cron schedule
   - Full UI test suite execution

### Test Artifacts

CI uploads the following test artifacts:

1. **Test Results** (`.xcresult` bundles)
   - Complete test execution results
   - Coverage data
   - Test logs

2. **Screenshots** (UI tests)
   - Screenshots captured during UI tests
   - Failure screenshots for debugging

3. **Coverage Reports**
   - JSON format for programmatic access
   - HTML format for human-readable reports

## Best Practices

### Unit Testing

1. **Test Isolation**
   - Each test should be independent
   - Use `setUp()` and `tearDown()` for common setup

2. **Test Naming**
   - Use descriptive test names
   - Follow pattern: `test<What>_<Condition>_<ExpectedResult>`

3. **Async Testing**
   - Use `async throws` for async tests
   - Use `await` for async operations

4. **Mocking**
   - Mock external dependencies
   - Use protocol-based mocking

### UI Testing

1. **Test Stability**
   - Use explicit waits instead of fixed delays
   - Wait for UI elements to appear

2. **Test Helpers**
   - Create reusable helper functions
   - Use `UITestHelpers.swift` for common operations

3. **Test Data**
   - Use consistent test data
   - Clean up test data after tests

4. **Screenshots**
   - Capture screenshots for debugging
   - Use screenshots in test reports

## Troubleshooting

### Common Issues

#### Tests Fail in CI but Pass Locally
- Check simulator version matches CI
- Verify environment variables are set
- Check for timing issues (add explicit waits)

#### Coverage Not Generated
- Ensure `-enableCodeCoverage YES` is set
- Verify test plan includes coverage option
- Check scheme settings

#### UI Tests Timeout
- Increase timeout values
- Add explicit waits for UI elements
- Check for blocking operations

## Related Documentation

- [CI Overview](ci_overview.md) - CI/CD setup
- [Style Guide](style_guide.md) - Code style rules
- [Team Workflow](TEAM_WORKFLOW.md) - Development workflow






