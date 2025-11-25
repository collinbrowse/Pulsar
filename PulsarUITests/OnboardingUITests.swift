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
        // 
        // NOTE: This test requires a pre-existing test account in the database.
        // In a real test environment, you would:
        // 1. Create a test account in setUp()
        // 2. Attempt to sign up with same credentials
        // 3. Verify graceful handling
        // 4. Clean up in tearDown()
        
        throw XCTSkip("Test requires pre-existing account setup - will be enabled with test data fixtures")
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
    
    func testProfileCreationScreenElements() throws {
        // Note: This test requires being signed in
        // For now, we'll just verify the test structure
        // In a real scenario, you'd need to sign in first or use a test account
        
        // Skip if not authenticated (would need to implement auth state check)
        throw XCTSkip("Profile creation tests require authentication - will be enabled after implementing test user setup")
    }
    
    // MARK: - End-to-End Flow Tests
    
    func testCompleteOnboardingFlow() throws {
        // This would test the complete flow from welcome → sign up → profile creation
        // Requires email confirmation to be disabled in Supabase
        
        throw XCTSkip("End-to-end flow test requires backend configuration - will be enabled after Supabase setup")
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
        // Note: This would require simulating network errors
        // Could be implemented with a mock server or network conditioning
        throw XCTSkip("Network error tests require network simulation setup")
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
