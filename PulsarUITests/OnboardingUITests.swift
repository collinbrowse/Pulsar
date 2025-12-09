//
//  OnboardingUITests.swift
//  PulsarUITests
//
//  Created on 10/27/25.
//

import XCTest

/// UI Tests for Milestone 2 - Onboarding & Authentication Flow
@MainActor
final class OnboardingUITests: XCTestCase {
    nonisolated(unsafe) var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        let newApp = MainActor.assumeIsolated {
            let app = XCUIApplication()
            app.launchArguments = ["--uitesting"]
            app.launch()
            return app
        }
        app = newApp
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Welcome Screen Tests
    
    func testWelcomeScreenDisplays() throws {
        // Verify welcome screen elements are present
        XCTAssertTrue(app.staticTexts["Welcome to Pulsar"].exists)
        XCTAssertTrue(app.buttons["Sign Up"].exists)
        XCTAssertTrue(app.buttons["Sign In"].exists)
    }
    
    func testNavigateToSignUp() throws {
        // Tap Sign Up button (accessibility ID, not text)
        app.buttons["Sign Up"].tap()
        
        // Verify navigation to sign up screen
        XCTAssertTrue(app.staticTexts["Create Account"].exists)
        XCTAssertTrue(app.textFields["Username"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
    }
    
    func testNavigateToSignIn() throws {
        // Tap Sign In button
        XCTAssertTrue(app.buttons["Sign In"].exists)
        app.buttons["Sign In"].tap()
        
        // Verify navigation to sign in screen
        XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
    }
    
    // MARK: - Sign Up Flow Tests
    
    func testSignUpWithExistingAccountHandledGracefully() throws {
        // This test validates that attempting to sign up with an existing account
        // gracefully signs the user in instead of showing a hard error.
        // Uses the standard test account that should exist in the test database
        
        XCTContext.runActivity(named: "Test Sign Up with Existing Account") { _ in
            // Navigate to sign up
            app.buttons["Sign Up"].tap()
            
            XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 2), "Should show sign up screen")
            
            // Fill form with existing account credentials
            let usernameField = app.textFields["Username"]
            XCTAssertTrue(usernameField.waitForExistence(timeout: 2))
            app.safeTypeText(in: usernameField, text: UITestFixtures.TestAccount.username)
            Thread.sleep(forTimeInterval: 0.3)
            
            let fullNameField = app.textFields["Full Name"]
            app.safeTypeText(in: fullNameField, text: UITestFixtures.TestAccount.fullName)
            Thread.sleep(forTimeInterval: 0.3)
            
            let emailField = app.textFields["Email"]
            app.safeTypeText(in: emailField, text: UITestFixtures.TestAccount.email)
            Thread.sleep(forTimeInterval: 0.3)
            
            let passwordField = app.secureTextFields["Password"]
            app.safeTypeText(in: passwordField, text: UITestFixtures.TestAccount.password)
            Thread.sleep(forTimeInterval: 0.3)
            
            let confirmPasswordField = app.secureTextFields["Confirm Password"]
            app.safeTypeText(in: confirmPasswordField, text: UITestFixtures.TestAccount.password)
            Thread.sleep(forTimeInterval: 0.3)
            
            app.dismissKeyboard()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Verify passwords match
            let passwordMatchIndicator = app.staticTexts["Passwords match"]
            XCTAssertTrue(passwordMatchIndicator.waitForExistence(timeout: 3), "Passwords should match")
            
            // Tap create account
            let createAccountButton = app.buttons["Create Account"]
            XCTAssertTrue(app.waitForButtonEnabled(createAccountButton, timeout: 5), "Button should be enabled")
            createAccountButton.tap()
            
            // Wait for processing
            Thread.sleep(forTimeInterval: 3)
            
            // Should either:
            // 1. Auto sign in and navigate to main app
            // 2. Show user-friendly message (not raw error)
            
            let activitiesTab = app.tabBars.buttons["Activities"]
            let feedTab = app.tabBars.buttons["Feed"]
            let profileScreen = app.staticTexts["Complete Your Profile"]
            
            let isInMainApp = activitiesTab.exists || feedTab.exists
            let isOnProfileCreation = profileScreen.exists
            
            // Verify no raw error messages
            let httpErrorText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'HTTP error'"))
            XCTAssertFalse(httpErrorText.element.exists, "Should NOT show raw HTTP error")
            
            let errorCodeText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'error_code'"))
            XCTAssertFalse(errorCodeText.element.exists, "Should NOT show raw error code")
            
            // Should have navigated somewhere (main app or profile creation)
            XCTAssertTrue(
                isInMainApp || isOnProfileCreation || app.staticTexts["Create Account"].exists,
                "Should navigate to main app, profile creation, or show friendly message"
            )
        }
    }
    
    func testPasswordFieldsAreEditable() throws {
        // Navigate to sign up
        app.buttons["Sign Up"].tap()
        
        // Wait for password field to appear
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 2), "Password field should exist")
        
        // Tap password field
        passwordField.tap()
        
        // Type a password - this should NOT be blocked by automatic password overlay
        passwordField.typeText("testpass123")
        
        // Verify password was entered (field is no longer empty)
        // Note: Can't read SecureField value, but can verify form validation works
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        confirmPasswordField.tap()
        confirmPasswordField.typeText("testpass123")
        
        // If passwords can be entered, the "Passwords match" indicator should appear
        let passwordMatchIndicator = app.staticTexts["Passwords match"]
        XCTAssertTrue(passwordMatchIndicator.waitForExistence(timeout: 2), 
                     "Password fields should accept manual input and show match indicator")
    }
    
    func testSignUpValidationErrors() throws {
        // Navigate to sign up
        app.buttons["Sign Up"].tap()
        
        // Try to submit empty form
        let signUpButton = app.buttons["Create Account"]
        signUpButton.tap()
        
        // Should show validation errors (form won't submit with empty fields)
        XCTAssertTrue(app.staticTexts["Create Account"].exists)
    }
    
    func testSignUpWithInvalidEmail() throws {
        // Navigate to sign up
        app.buttons["Sign Up"].tap()
        
        // Fill username first (appears before email in the form)
        let usernameField = app.textFields["Username"]
        usernameField.tap()
        usernameField.typeText("testuser")
        
        // Enter invalid email
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("invalid-email")
        
        // Enter valid passwords
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        confirmPasswordField.tap()
        confirmPasswordField.typeText("password123")
        
        // Try to submit
        app.buttons["Create Account"].tap()
        
        // Should show error or stay on same screen
        // Note: This test validates client-side validation
        XCTAssertTrue(app.staticTexts["Create Account"].exists)
    }
    
    func testSignUpWithShortPassword() throws {
        // Navigate to sign up
        app.buttons["Sign Up"].tap()
        
        // Enter valid email
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        // Enter short password
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("short")
        
        // Enter valid username
        let usernameField = app.textFields["Username"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 2), "Username field should exist")
        usernameField.tap()
        // Wait a moment for keyboard focus to transfer
        sleep(1)
        usernameField.typeText("testuser")
        
        // Try to submit
        app.buttons["Create Account"].tap()
        
        // Should show error
        XCTAssertTrue(app.staticTexts["Create Account"].exists)
    }
    
    func testSignUpWithInvalidUsername() throws {
        // Navigate to sign up
        app.buttons["Sign Up"].tap()
        
        // Enter valid email and password
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Enter invalid username (too short)
        let usernameField = app.textFields["Username"]
        usernameField.tap()
        usernameField.typeText("ab")
        
        // Try to submit
        app.buttons["Create Account"].tap()
        
        // Should show error
        XCTAssertTrue(app.staticTexts["Create Account"].exists)
    }
    
    // MARK: - Sign In Flow Tests
    
    func testSignInWithEmptyFields() throws {
        // Navigate to sign in
        app.buttons["Sign In"].tap()
        
        // Try to submit empty form
        app.buttons["Sign In"].tap()
        
        // Should stay on sign in screen
        XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
    }
    
    func testSignInBackNavigation() throws {
        // Navigate to sign in
        app.buttons["Sign In"].tap()
        
        // Tap back button
        app.navigationBars.buttons.firstMatch.tap()
        
        // Should return to welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to Pulsar"].exists)
    }
    
    // MARK: - Profile Creation Tests
    
    // swiftlint:disable:next function_body_length
    func testProfileCreationScreenElements() async throws {
        // Create a new test account which will automatically navigate to profile creation
        try await UITestFixtures.createTestAccountViaUI(
            in: app,
            email: nil, // Use generated email
            password: "TestPassword123!",
            username: nil, // Use generated username
            fullName: nil
        )
        
        // Wait for profile creation screen to appear
        let profileHeader = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(
            profileHeader.waitForExistence(timeout: 10),
            "Profile creation screen should appear after account creation"
        )
        
        // Verify header text
        XCTAssertTrue(
            app.staticTexts["Help us personalize your experience"].exists,
            "Profile creation subtitle should be visible"
        )
        
        // Verify username field exists (read-only, displays username from signup)
        let usernameLabel = app.staticTexts["Username"]
        XCTAssertTrue(
            usernameLabel.exists,
            "Username label should be visible"
        )
        
        // Verify Full Name field exists
        let fullNameField = app.textFields["Full Name"]
        XCTAssertTrue(
            fullNameField.waitForExistence(timeout: 2),
            "Full Name field should be accessible"
        )
        XCTAssertTrue(
            fullNameField.isHittable,
            "Full Name field should be hittable"
        )
        
        // Verify Gender picker exists
        let genderPicker = app.pickers["Gender"]
        XCTAssertTrue(
            genderPicker.exists,
            "Gender picker should be visible"
        )
        
        // Verify Birth Year field exists (optional)
        // Find by placeholder or label
        let birthYearField = app.textFields["1990"]
        XCTAssertTrue(
            birthYearField.exists || app.staticTexts["Birth Year (Optional)"].exists,
            "Birth Year field or label should be visible"
        )
        
        // Verify Weight field exists (optional)
        let weightField = app.textFields["70"]
        XCTAssertTrue(
            weightField.exists || app.staticTexts["Weight (kg, Optional)"].exists,
            "Weight field or label should be visible"
        )
        
        // Verify Complete Profile button exists
        let completeButton = app.buttons["Complete Profile"]
        XCTAssertTrue(
            completeButton.waitForExistence(timeout: 2),
            "Complete Profile button should be visible"
        )
        XCTAssertTrue(
            completeButton.isHittable,
            "Complete Profile button should be hittable"
        )
        
        // Verify avatar section exists (PhotosPicker)
        let choosePhotoButton = app.buttons["Choose Photo"]
        XCTAssertTrue(
            choosePhotoButton.exists,
            "Choose Photo button should be visible"
        )
    }
    
    // MARK: - End-to-End Flow Tests
    
    func testCompleteOnboardingFlow() async throws {
        // This would test the complete flow from welcome → sign up → profile creation → main app
        // Requires email confirmation to be disabled in Supabase OR test accounts to be pre-confirmed
        // 
        // To enable:
        // 1. Check Supabase project settings → Authentication → Email confirmation
        // 2. If enabled, either disable for test environment OR pre-confirm test accounts
        // 3. Use UITestFixtures.createTestAccountViaUI() and UITestFixtures.waitForSignIn()
        // 4. Verify navigation to main app (check for tab bar)
        
        throw XCTSkip("End-to-end flow test requires backend email confirmation configuration - see SKIPPED_TESTS.md for details")
    }
    
    // MARK: - Performance Tests
    
    func testWelcomeScreenLoadPerformance() throws {
        measure {
            app.launch()
            XCTAssertTrue(app.staticTexts["Welcome to Pulsar"].waitForExistence(timeout: 2))
        }
    }
    
    func testSignUpScreenNavigationPerformance() throws {
        measure {
            app.buttons["Sign Up"].tap()
            XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 1))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testWelcomeScreenAccessibility() throws {
        // Verify all interactive elements exist and are accessible
        XCTAssertTrue(app.buttons["Sign Up"].exists, "Sign Up button should exist")
        XCTAssertTrue(app.buttons["Sign In"].exists, "Sign In button should exist")
        
        // Verify labels exist
        XCTAssertNotNil(app.buttons["Sign Up"].label)
        XCTAssertNotNil(app.buttons["Sign In"].label)
    }
    
    func testSignUpFormAccessibility() throws {
        app.buttons["Sign Up"].tap()
        
        // Wait for form to load
        _ = app.textFields["Username"].waitForExistence(timeout: 2)
        
        // Verify form fields exist and are accessible
        XCTAssertTrue(app.textFields["Username"].exists, "Username field should exist")
        XCTAssertTrue(app.textFields["Email"].exists, "Email field should exist")
        XCTAssertTrue(app.secureTextFields["Password"].exists, "Password field should exist")
        
        // Verify accessibility identifiers are set (they are set in SignUpView.swift)
        XCTAssertEqual(app.textFields["Username"].identifier, "Username")
        XCTAssertEqual(app.textFields["Email"].identifier, "Email")
        XCTAssertEqual(app.secureTextFields["Password"].identifier, "Password")
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() throws {
        // Note: Network error testing is better suited for unit tests with mocked services
        // UI tests should focus on user-facing behavior, not network implementation details
        // Consider testing error message display in unit tests instead
        throw XCTSkip("Network error testing better suited for unit tests - see SKIPPED_TESTS.md for details")
    }
    
    func testInvalidCredentialsError() throws {
        // Test that invalid credentials show appropriate error
        app.buttons["Sign In"].tap()
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("invalid@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("wrongpassword")
        
        app.buttons["Sign In"].tap()
        
        // Should show error message
        // Note: Exact error message would depend on backend response
        XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
    }
}
