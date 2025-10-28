# UI Testing Guide

## Overview

This guide covers UI testing for the Pulsar iOS app. We use **XCTest** and **XCUITest** to verify end-to-end user flows without manual testing after each code change.

## Test Organization

### Test Suites

- **`Milestone2UITests.swift`**: Comprehensive acceptance tests for Milestone 2 (Auth & Profiles)
- **`OnboardingUITests.swift`**: Detailed tests for individual onboarding components
- **`UITestHelpers.swift`**: Reusable utilities and test helpers

### Test Coverage

#### Milestone 2 Acceptance Criteria

Each milestone has a dedicated test file (`Milestone{N}UITests`) that verifies all acceptance criteria:

- ✅ M2.1: Welcome screen displays with sign in and sign up options
- ✅ M2.2: Sign up form validates email format
- ✅ M2.3: Password validation (minimum 8 characters)
- ✅ M2.4: Username validation (3-30 characters, alphanumeric + underscore/hyphen)
- ✅ M2.5: Profile creation form displays all fields
- ✅ M2.6: Optional profile fields can be skipped
- ✅ M2.7: Navigation flow works correctly
- ✅ M2.8: Keyboard dismisses properly
- ✅ M2.9: Form state preservation
- ✅ M2.10: Accessibility support

## Running UI Tests

### From Xcode

1. Open `Pulsar.xcodeproj`
2. Select a simulator (iOS 26.0+)
3. Press `Cmd + U` to run all tests, or
4. Press `Cmd + Ctrl + U` to run tests for the current file
5. Click the ◇ icon next to any test to run individually

### From Command Line

```bash
# Build for testing
xcodebuild -project Pulsar.xcodeproj \
  -scheme Pulsar \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build-for-testing

# Run all UI tests
xcodebuild -project Pulsar.xcodeproj \
  -scheme Pulsar \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test-without-building \
  -only-testing:PulsarUITests

# Run a specific test suite
xcodebuild -project Pulsar.xcodeproj \
  -scheme Pulsar \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test-without-building \
  -only-testing:PulsarUITests/Milestone2UITests

# Run a specific test
xcodebuild -project Pulsar.xcodeproj \
  -scheme Pulsar \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test-without-building \
  -only-testing:PulsarUITests/Milestone2UITests/testM2_1_WelcomeScreenDisplays
```

### In CI/CD (GitHub Actions)

UI tests run automatically on every pull request. See `.github/workflows/ci.yml` for configuration.

## Writing New UI Tests

### Test Naming Convention

- **Milestone Acceptance Tests**: `testM{milestone}_{criterion}_{description}`
  - Example: `testM2_1_WelcomeScreenDisplays`
- **Component Tests**: `test{Component}_{behavior}`
  - Example: `testSignUpValidationErrors`
- **Performance Tests**: `test{Feature}Performance`
  - Example: `testAppLaunchPerformance`

### Accessibility Identifiers

All interactive UI elements have accessibility identifiers for testing:

```swift
Button("Sign Up") {
    // button content
}
.accessibilityIdentifier("Sign Up")
```

#### Existing Identifiers

**Welcome Screen:**
- `"Sign Up"` - Create account button
- `"Sign In"` - Sign in button

**Sign Up Form:**
- `"Username"` - Username text field
- `"Full Name"` - Full name text field
- `"Email"` - Email text field
- `"Password"` - Password secure field
- `"Confirm Password"` - Confirm password secure field
- `"Create Account"` - Submit button

**Sign In Form:**
- `"Email"` - Email text field
- `"Password"` - Password secure field
- `"Sign In"` - Submit button

**Profile Creation:**
- `"Full Name"` - Full name text field
- `"Complete Profile"` - Submit button

### Test Helpers

Use the helpers in `UITestHelpers.swift` for common operations:

```swift
// Clear text from a field
app.clearText(in: textField)

// Type text (clearing first)
app.typeText(in: textField, text: "new value")

// Wait for an element
app.waitForElement(button, timeout: 5)

// Dismiss keyboard
app.dismissKeyboard()

// Generate test user data
let user = TestUser.generateUnique()
let validUser = TestUser.validTest

// Perform complete flows
performSignUp(in: app, user: user)
performSignIn(in: app, email: "test@example.com", password: "password")
completeProfileCreation(in: app, username: "testuser", fullName: "Test User")

// Capture screenshots for debugging
takeScreenshot(named: "Error State")
```

### Test Structure

Follow this pattern for new tests:

```swift
func testFeatureDescription() throws {
    XCTContext.runActivity(named: "Descriptive Activity Name") { _ in
        // Arrange
        let user = TestUser.generateUnique()
        
        // Act
        app.buttons["Sign Up"].tap()
        performSignUp(in: app, user: user)
        
        // Assert
        XCTAssertTrue(app.staticTexts["Welcome"].exists)
        
        // Capture state for debugging
        takeScreenshot(named: "Success State")
    }
}
```

### Performance Tests

Measure critical user flows:

```swift
func testFeaturePerformance() throws {
    measure {
        // Action to measure
        app.buttons["Sign Up"].tap()
        _ = app.staticTexts["Create Account"].waitForExistence(timeout: 2)
        app.navigationBars.buttons.firstMatch.tap()
    }
}
```

## Prerequisites for End-to-End Tests

Some tests require backend configuration to run successfully:

### 1. Disable Email Confirmation (Development Only)

For signup tests to pass:

1. Open Supabase Dashboard: https://supabase.com/dashboard/project/{your-project}/settings/auth
2. Go to **Authentication → Settings**
3. Toggle **OFF** "Enable email confirmations"
4. Save changes

**Note**: Re-enable this for production!

### 2. Test User Setup

For sign-in tests, you may need pre-existing test accounts:

```swift
// In your test setup
override func setUpWithError() throws {
    continueAfterFailure = false
    
    app = XCUIApplication()
    app.launchArguments = ["--uitesting"]
    
    // Optional: Create test user if needed
    // (Implementation depends on your backend setup)
    
    app.launch()
}
```

### 3. Network Simulation

To test error handling:

```swift
// TODO: Implement network conditioning
// - Airplane mode simulation
// - Slow network simulation
// - Server error simulation
```

## Debugging Failed Tests

### View Test Results

1. Open the **Test Navigator** (`Cmd + 6`)
2. Click on a failed test
3. View the error message and stack trace
4. Check attached screenshots

### Run Tests in Debug Mode

1. Add a breakpoint in your test
2. Right-click the test → **Debug "testName"**
3. Step through the test execution

### Enable Console Output

Add this to see all console logs during tests:

```swift
override func setUpWithError() throws {
    continueAfterFailure = false
    
    app = XCUIApplication()
    app.launchArguments = ["--uitesting", "--verbose-logging"]
    app.launch()
}
```

### Common Issues

#### "Element not found"
- **Cause**: Element hasn't loaded yet
- **Fix**: Use `waitForExistence(timeout:)` instead of asserting directly

```swift
// Bad
XCTAssertTrue(app.buttons["Sign In"].exists)

// Good
XCTAssertTrue(app.buttons["Sign In"].waitForExistence(timeout: 5))
```

#### "Keyboard is blocking element"
- **Cause**: Keyboard covers the button/field
- **Fix**: Dismiss keyboard before interacting

```swift
app.dismissKeyboard()
app.buttons["Submit"].tap()
```

#### "Test is flaky (passes sometimes, fails others)"
- **Cause**: Race conditions or timing issues
- **Fix**: Add explicit waits and use `XCTContext.runActivity` for better error messages

## Best Practices

### ✅ DO

- Use accessibility identifiers for all interactive elements
- Write descriptive test names
- Use `XCTContext.runActivity` to group related assertions
- Capture screenshots on failure
- Test both happy paths and error scenarios
- Measure performance of critical flows
- Test accessibility features

### ❌ DON'T

- Hardcode timeouts (use reasonable defaults)
- Test implementation details (test user-facing behavior)
- Make tests dependent on each other
- Leave commented-out test code
- Skip error handling in tests

## Metrics & Reporting

### Coverage Reports

View test coverage in Xcode:

1. Run tests with coverage enabled (`Cmd + U`)
2. Open **Report Navigator** (`Cmd + 9`)
3. Select the latest test run
4. Click **Coverage** tab

### Performance Baselines

Xcode automatically tracks performance test baselines:

- First run establishes the baseline
- Subsequent runs compare against baseline
- Tests fail if performance regresses > 10%

To reset baselines:
1. Right-click performance test
2. Select **Set Baseline**

## Milestone-Specific Notes

### Milestone 2: Auth & User Profiles

**Tests Requiring Backend:**
- `testCompleteOnboardingFlow` - Requires email confirmation disabled
- `testProfileCreationScreenElements` - Requires authenticated session

**Tests Ready for CI:**
- All validation tests (email, password, username)
- Navigation flow tests
- Accessibility tests
- Performance tests

**Known Limitations:**
- Apple Sign In requires a physical device (simulator returns placeholder)
- Some tests are marked with `throw XCTSkip` until backend configuration is complete

## Future Enhancements

- [ ] Implement network mocking for offline testing
- [ ] Add screenshot comparison tests
- [ ] Add localization tests
- [ ] Add dark mode tests
- [ ] Add VoiceOver simulation tests
- [ ] Add test data cleanup between runs
- [ ] Add parallel test execution

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [XCUITest Guide](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Accessibility Testing](https://developer.apple.com/documentation/xctest/user_interface_tests/testing_your_app_for_accessibility)

