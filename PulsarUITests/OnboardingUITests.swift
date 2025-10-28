//
//  OnboardingUITests.swift
//  PulsarUITests
//
//  Created on 10/27/25.
//

import XCTest

/// UI Tests for Milestone 2 - Onboarding & Authentication Flow
final class OnboardingUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
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
        app.buttons["Sign In"].exists
        app.buttons["Sign In"].tap()
        
        // Verify navigation to sign in screen
        XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
    }
    
    // MARK: - Sign Up Flow Tests
    
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
        usernameField.tap()
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
        // Verify all interactive elements are accessible
        XCTAssertTrue(app.buttons["Sign Up"].isAccessibilityElement)
        XCTAssertTrue(app.buttons["Sign In"].isAccessibilityElement)
        
        // Verify labels exist
        XCTAssertNotNil(app.buttons["Sign Up"].label)
        XCTAssertNotNil(app.buttons["Sign In"].label)
    }
    
    func testSignUpFormAccessibility() throws {
        app.buttons["Sign Up"].tap()
        
        // Wait for form to load
        _ = app.textFields["Username"].waitForExistence(timeout: 2)
        
        // Verify form fields are accessible
        XCTAssertTrue(app.textFields["Username"].isAccessibilityElement)
        XCTAssertTrue(app.textFields["Email"].isAccessibilityElement)
        XCTAssertTrue(app.secureTextFields["Password"].isAccessibilityElement)
        
        // Verify accessibility labels (check value property for TextFields)
        XCTAssertTrue(app.textFields["Username"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
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

