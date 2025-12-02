//
//  UITestFixtures.swift
//  PulsarUITests
//
//  Created on 11/24/25.
//

import XCTest

/// Helper for managing test accounts and data in UI tests
/// Note: UI tests run in a separate process and cannot directly access app code.
/// This helper provides utilities for test account management via UI interactions.
@MainActor
struct UITestFixtures {
    /// Generates a unique test email address
    static func generateTestEmail() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "test+\(timestamp)@pulsar.test"
    }
    
    /// Standard test account credentials for tests that need existing accounts
    struct TestAccount {
        static let email = "test@pulsar.app"
        static let password = "testpass123"
        static let username = "testuser"
        static let fullName = "Test User"
    }
    
    /// Creates a test account via UI interactions
    /// This method navigates through the sign up flow to create an account
    static func createTestAccountViaUI(
        in app: XCUIApplication,
        email: String? = nil,
        password: String = "TestPassword123!",
        username: String? = nil,
        fullName: String? = nil
    ) async throws {
        let testEmail = email ?? generateTestEmail()
        let testUsername = username ?? "testuser\(Int(Date().timeIntervalSince1970))"
        let testFullName = fullName ?? "Test User"
        
        // Navigate to sign up
        let signUpButton = app.buttons["Sign Up"]
        guard signUpButton.waitForExistence(timeout: 5) else {
            throw UITestFixtureError.signUpButtonNotFound
        }
        signUpButton.tap()
        
        // Wait for sign up screen
        guard app.staticTexts["Create Account"].waitForExistence(timeout: 5) else {
            throw UITestFixtureError.signUpScreenNotFound
        }
        
        // Fill in form
        let usernameField = app.textFields["Username"]
        guard usernameField.waitForExistence(timeout: 2) else {
            throw UITestFixtureError.usernameFieldNotFound
        }
        app.safeTypeText(in: usernameField, text: testUsername)
        Thread.sleep(forTimeInterval: 0.3)
        
        if let fullName = testFullName {
            let fullNameField = app.textFields["Full Name"]
            if fullNameField.exists {
                app.safeTypeText(in: fullNameField, text: fullName)
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
        
        let emailField = app.textFields["Email"]
        app.safeTypeText(in: emailField, text: testEmail)
        Thread.sleep(forTimeInterval: 0.3)
        
        let passwordField = app.secureTextFields["Password"]
        app.safeTypeText(in: passwordField, text: password)
        Thread.sleep(forTimeInterval: 0.3)
        
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        app.safeTypeText(in: confirmPasswordField, text: password)
        Thread.sleep(forTimeInterval: 0.3)
        
        app.dismissKeyboard()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Wait for button to be enabled
        let createAccountButton = app.buttons["Create Account"]
        let buttonEnabled = app.waitForButtonEnabled(createAccountButton, timeout: 5)
        
        guard buttonEnabled || createAccountButton.isHittable else {
            throw UITestFixtureError.createAccountButtonNotEnabled
        }
        
        // Tap create account
        createAccountButton.tap()
        
        // Wait for navigation (either to profile creation or main app)
        // Give time for account creation and navigation
        Thread.sleep(forTimeInterval: 2)
    }
    
    /// Signs in with existing test account via UI
    static func signInTestAccountViaUI(
        in app: XCUIApplication,
        email: String = TestAccount.email,
        password: String = TestAccount.password
    ) async throws {
        // Navigate to sign in
        let signInButton = app.buttons["Sign In"]
        guard signInButton.waitForExistence(timeout: 5) else {
            throw UITestFixtureError.signInButtonNotFound
        }
        signInButton.tap()
        
        // Wait for sign in screen
        guard app.staticTexts["Welcome Back"].waitForExistence(timeout: 5) else {
            throw UITestFixtureError.signInScreenNotFound
        }
        
        // Fill in form
        let emailField = app.textFields["Email"]
        guard emailField.waitForExistence(timeout: 2) else {
            throw UITestFixtureError.emailFieldNotFound
        }
        app.safeTypeText(in: emailField, text: email)
        Thread.sleep(forTimeInterval: 0.3)
        
        let passwordField = app.secureTextFields["Password"]
        app.safeTypeText(in: passwordField, text: password)
        Thread.sleep(forTimeInterval: 0.3)
        
        app.dismissKeyboard()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Tap sign in
        let signInSubmitButton = app.buttons["Sign In"]
        guard signInSubmitButton.waitForExistence(timeout: 2) else {
            throw UITestFixtureError.signInSubmitButtonNotFound
        }
        signInSubmitButton.tap()
        
        // Wait for navigation (either to profile creation or main app)
        Thread.sleep(forTimeInterval: 2)
    }
    
    /// Signs out the current user via UI
    static func signOutViaUI(in app: XCUIApplication) async throws {
        // This would navigate to profile/settings and sign out
        // Implementation depends on app structure
        // For now, this is a placeholder
    }
    
    /// Checks if user is signed in by looking for main app indicators
    static func isSignedIn(in app: XCUIApplication) -> Bool {
        // Check for main app indicators (tabs, activities view, etc.)
        let activitiesTab = app.tabBars.buttons["Activities"]
        let feedTab = app.tabBars.buttons["Feed"]
        let profileTab = app.tabBars.buttons["Profile"]
        
        return activitiesTab.exists || feedTab.exists || profileTab.exists
    }
    
    /// Waits for user to be signed in
    static func waitForSignIn(in app: XCUIApplication, timeout: TimeInterval = 10) -> Bool {
        let activitiesTab = app.tabBars.buttons["Activities"]
        let feedTab = app.tabBars.buttons["Feed"]
        let profileTab = app.tabBars.buttons["Profile"]
        
        return activitiesTab.waitForExistence(timeout: timeout) ||
               feedTab.waitForExistence(timeout: timeout) ||
               profileTab.waitForExistence(timeout: timeout)
    }
}

/// Errors for UITestFixtures
enum UITestFixtureError: Error, LocalizedError {
    case signUpButtonNotFound
    case signUpScreenNotFound
    case signInButtonNotFound
    case signInScreenNotFound
    case usernameFieldNotFound
    case emailFieldNotFound
    case createAccountButtonNotEnabled
    case signInSubmitButtonNotFound
    
    var errorDescription: String? {
        switch self {
        case .signUpButtonNotFound:
            return "Sign Up button not found on welcome screen"
        case .signUpScreenNotFound:
            return "Sign Up screen did not appear"
        case .signInButtonNotFound:
            return "Sign In button not found on welcome screen"
        case .signInScreenNotFound:
            return "Sign In screen did not appear"
        case .usernameFieldNotFound:
            return "Username field not found on sign up form"
        case .emailFieldNotFound:
            return "Email field not found on sign in form"
        case .createAccountButtonNotEnabled:
            return "Create Account button is not enabled"
        case .signInSubmitButtonNotFound:
            return "Sign In submit button not found"
        }
    }
}
