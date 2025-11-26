# Skipped UI Tests Documentation

This document explains why certain UI tests are skipped and what needs to be implemented to enable them.

## Currently Skipped Tests

### 1. `testProfileCreationScreenElements` (OnboardingUITests.swift)

**Status**: ✅ Enabled  
**Location**: `PulsarUITests/OnboardingUITests.swift:287`

**Implementation:**
- Uses `UITestFixtures.createTestAccountViaUI()` to create a new test account
- Automatically navigates to profile creation screen after account creation
- Verifies all form elements: username, full name, gender picker, birth year, weight, Complete Profile button, and avatar picker

**Test Coverage:**
- Header text and subtitle
- Username field (read-only)
- Full Name field (editable)
- Gender picker
- Birth Year field (optional)
- Weight field (optional)
- Complete Profile button
- Choose Photo button (avatar picker)

---

### 2. `testCompleteOnboardingFlow` (OnboardingUITests.swift)

**Status**: Skipped  
**Location**: `PulsarUITests/OnboardingUITests.swift:242`

**Why it's skipped:**
- Requires full end-to-end flow: Welcome → Sign Up → Profile Creation → Main App
- Needs backend configuration to allow seamless flow without email confirmation

**What needs to be implemented:**
1. Create test account via UI (sign up flow)
2. Navigate through profile creation
3. Verify navigation to main app
4. Verify user is authenticated and can access main app features

**Estimated effort**: Medium (2-4 hours)
- Requires careful coordination of multiple UI flows
- May need to handle email confirmation if not disabled

**Dependencies:**
- Backend email confirmation must be disabled for test accounts
- Or test accounts must be pre-confirmed
- Test database must be properly configured

**Example implementation:**
```swift
func testCompleteOnboardingFlow() throws {
    // Start at welcome screen
    XCTAssertTrue(app.staticTexts["Welcome to Pulsar"].exists)
    
    // Sign up
    try await UITestFixtures.createTestAccountViaUI(in: app)
    
    // Wait for profile creation
    let profileScreen = app.staticTexts["Complete Your Profile"]
    XCTAssertTrue(profileScreen.waitForExistence(timeout: 10))
    
    // Complete profile (optional fields can be skipped)
    let completeButton = app.buttons["Complete Profile"]
    completeButton.tap()
    
    // Verify navigation to main app
    let activitiesTab = app.tabBars.buttons["Activities"]
    XCTAssertTrue(activitiesTab.waitForExistence(timeout: 10))
}
```

---

### 3. `testNetworkErrorHandling` (OnboardingUITests.swift)

**Status**: Skipped  
**Location**: `PulsarUITests/OnboardingUITests.swift:296`

**Why it's skipped:**
- Requires network simulation to test error handling
- Need to simulate network failures, timeouts, and server errors

**What needs to be implemented:**
1. Network simulation setup using one of:
   - URLProtocol mocking (mock URLSession responses)
   - Network Link Conditioner (macOS/iOS system tool)
   - Custom network proxy/server
2. Test scenarios:
   - Network unavailable (airplane mode simulation)
   - Slow network (timeout scenarios)
   - Server errors (500, 503, etc.)
   - Invalid responses

**Estimated effort**: High (4-8 hours)
- Requires setting up network simulation infrastructure
- Need to mock Supabase API responses
- Complex to maintain and debug

**Dependencies:**
- Network simulation framework or tool
- Mock server or URLProtocol implementation
- Test infrastructure for network conditioning

**Implementation options:**

**Option 1: URLProtocol Mocking (Recommended)**
```swift
class MockURLProtocol: URLProtocol {
    static var mockResponses: [URL: (data: Data?, response: URLResponse?, error: Error?)] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let url = request.url,
           let mock = Self.mockResponses[url] {
            if let error = mock.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                if let response = mock.response {
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if let data = mock.data {
                    client?.urlProtocol(self, didLoad: data)
                }
                client?.urlProtocolDidFinishLoading(self)
            }
        }
    }
    
    override func stopLoading() {}
}
```

**Option 2: Network Link Conditioner**
- Use macOS Network Link Conditioner
- Configure slow/unreliable network profiles
- Less control but easier setup

**Option 3: Test Server**
- Set up local test server
- Control responses and timing
- Most flexible but most complex

**Example test:**
```swift
func testNetworkErrorHandling() throws {
    // Configure mock to return network error
    MockURLProtocol.mockResponses[signUpURL] = (
        data: nil,
        response: nil,
        error: URLError(.notConnectedToInternet)
    )
    
    // Attempt sign up
    app.buttons["Sign Up"].tap()
    // ... fill form ...
    app.buttons["Create Account"].tap()
    
    // Verify user-friendly error message (not raw error)
    let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'network'"))
    XCTAssertTrue(errorMessage.element.exists, "Should show network error message")
}
```

---

## Summary

| Test | Status | Effort | Priority | Can Enable Now? |
|------|--------|--------|----------|-----------------|
| `testProfileCreationScreenElements` | Skipped | Low | Medium | ✅ Yes (with UITestFixtures) |
| `testCompleteOnboardingFlow` | Skipped | Medium | High | ⚠️ Maybe (needs backend config) |
| `testNetworkErrorHandling` | Skipped | High | Low | ❌ No (needs network simulation) |

## Recommendations

1. **Enable `testProfileCreationScreenElements`** - Can be done now with existing fixtures
2. **Enable `testCompleteOnboardingFlow`** - Should be enabled once backend email confirmation is configured for tests
3. **Defer `testNetworkErrorHandling`** - Low priority, complex to implement, consider manual testing instead

## Notes

- All skipped tests have been documented with clear requirements
- Tests that can be enabled now should use `UITestFixtures` helper
- Network error testing might be better suited for unit tests with mocked services
- Consider using integration tests for end-to-end flows instead of UI tests

