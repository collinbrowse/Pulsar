//
//  UITestHelpers.swift
//  PulsarUITests
//
//  Created on 10/27/25.
//

import XCTest

/// Helper extensions and utilities for UI testing
extension XCUIApplication {
    /// Clears text from a text field
    func clearText(in element: XCUIElement) {
        element.tap()
        element.press(forDuration: 1.0)
        
        let selectAll = self.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 1) {
            selectAll.tap()
            
            let cut = self.menuItems["Cut"]
            if cut.exists {
                cut.tap()
            }
        }
    }
    
    /// Types text into a field, clearing existing text first
    func typeText(in element: XCUIElement, text: String) {
        clearText(in: element)
        element.typeText(text)
    }
    
    /// Waits for an element to exist and be hittable
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// Dismisses the keyboard
    func dismissKeyboard() {
        // Tap outside of keyboard area
        let coordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        coordinate.tap()
    }
}

/// Mock user data for testing
struct TestUser {
    let email: String
    let password: String
    let username: String
    let fullName: String?
    
    static func generateUnique() -> TestUser {
        let timestamp = Int(Date().timeIntervalSince1970)
        return TestUser(
            email: "test+\(timestamp)@pulsar.test",
            password: "TestPassword123!",
            username: "testuser\(timestamp)",
            fullName: "Test User"
        )
    }
    
    static let validTest = TestUser(
        email: "test@pulsar.test",
        password: "ValidPassword123!",
        username: "validuser",
        fullName: "Valid User"
    )
    
    static let invalidEmail = TestUser(
        email: "invalid-email",
        password: "ValidPassword123!",
        username: "testuser",
        fullName: nil
    )
    
    static let shortPassword = TestUser(
        email: "test@pulsar.test",
        password: "short",
        username: "testuser",
        fullName: nil
    )
    
    static let invalidUsername = TestUser(
        email: "test@pulsar.test",
        password: "ValidPassword123!",
        username: "ab",
        fullName: nil
    )
}

/// Test scenario helpers
extension XCTestCase {
    /// Performs a complete sign up flow
    func performSignUp(in app: XCUIApplication, user: TestUser, waitForSuccess: Bool = true) {
        app.buttons["Sign Up"].tap()
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText(user.email)
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText(user.password)
        
        let usernameField = app.textFields["Username"]
        usernameField.tap()
        usernameField.typeText(user.username)
        
        if let fullName = user.fullName, app.textFields["Full Name"].exists {
            let fullNameField = app.textFields["Full Name"]
            fullNameField.tap()
            fullNameField.typeText(fullName)
        }
        
        app.dismissKeyboard()
        app.buttons["Create Account"].tap()
        
        if waitForSuccess {
            // Wait for profile creation screen or main app
            _ = app.staticTexts["Complete Your Profile"].waitForExistence(timeout: 5)
        }
    }
    
    /// Performs a complete sign in flow
    func performSignIn(in app: XCUIApplication, email: String, password: String, waitForSuccess: Bool = true) {
        app.buttons["Sign In"].tap()
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText(email)
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText(password)
        
        app.dismissKeyboard()
        app.buttons["Sign In"].tap()
        
        if waitForSuccess {
            // Wait for profile creation screen or main app
            _ = app.staticTexts["Complete Your Profile"].waitForExistence(timeout: 5)
        }
    }
    
    /// Completes profile creation
    func completeProfileCreation(in app: XCUIApplication, username: String? = nil, fullName: String? = nil) {
        if let username = username {
            let usernameField = app.textFields["Username"]
            if usernameField.exists {
                app.typeText(in: usernameField, text: username)
            }
        }
        
        if let fullName = fullName {
            let fullNameField = app.textFields["Full Name"]
            if fullNameField.exists {
                fullNameField.tap()
                fullNameField.typeText(fullName)
            }
        }
        
        app.dismissKeyboard()
        app.buttons["Complete Profile"].tap()
    }
}

/// Screenshot helpers for debugging failed tests
extension XCTestCase {
    /// Takes a screenshot and attaches it to the test
    func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

