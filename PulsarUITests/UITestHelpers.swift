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
        // Try to get focus first
        element.tap()
        Thread.sleep(forTimeInterval: 0.2)
        
        // Try long press to show context menu
        element.press(forDuration: 1.0)
        Thread.sleep(forTimeInterval: 0.3)
        
        let selectAll = self.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 1) {
            selectAll.tap()
            Thread.sleep(forTimeInterval: 0.2)
            
            let cut = self.menuItems["Cut"]
            if cut.exists {
                cut.tap()
            } else {
                // If cut doesn't exist, try delete key
                element.typeText(XCUIKeyboardKey.delete.rawValue)
            }
        } else {
            // If select all menu doesn't appear, try triple tap
            element.tap()
            Thread.sleep(forTimeInterval: 0.1)
            element.tap()
            Thread.sleep(forTimeInterval: 0.1)
            element.tap()
            Thread.sleep(forTimeInterval: 0.2)
            
            // Try cut again
            let cut = self.menuItems["Cut"]
            if cut.waitForExistence(timeout: 0.5) {
                cut.tap()
            } else {
                // Last resort: type delete multiple times
                for _ in 0..<50 {
                    element.typeText(XCUIKeyboardKey.delete.rawValue)
                }
            }
        }
    }
    
    /// Types text into a field, clearing existing text first
    func typeText(in element: XCUIElement, text: String) {
        clearText(in: element)
        element.typeText(text)
    }
    
    /// Prepares element for typing (scrolls into view, waits for hittable)
    private func prepareElementForTyping(_ element: XCUIElement) {
        activate()
        Thread.sleep(forTimeInterval: 0.2)
        
        if !element.isHittable {
            let startCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            let endCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
            Thread.sleep(forTimeInterval: 0.3)
        }
        
        let hittablePredicate = NSPredicate(format: "isHittable == true")
        let hittableExpectation = XCTNSPredicateExpectation(predicate: hittablePredicate, object: element)
        _ = XCTWaiter().wait(for: [hittableExpectation], timeout: 2)
    }
    
    /// Attempts to type text with focus strategy
    private func attemptTypingWithStrategy(
        element: XCUIElement,
        text: String,
        strategy: () -> Bool
    ) -> Bool {
        let keyboard = keyboards.element
        if strategy() && keyboard.waitForExistence(timeout: 1.5) {
            Thread.sleep(forTimeInterval: 0.2)
            element.typeText(text)
            Thread.sleep(forTimeInterval: 0.3)
            return verifyTextEntered(element: element, text: text)
        }
        return false
    }
    
    /// Verifies text was entered (for non-secure fields)
    private func verifyTextEntered(element: XCUIElement, text: String) -> Bool {
        if element.elementType == .textField {
            if let value = element.value as? String {
                return value.contains(text) || value == text
            }
        }
        return true // For secure fields, assume success
    }
    
    /// Safely types text into a text field, ensuring it has focus first
    /// This method handles the common UI test issue where fields don't have keyboard focus
    /// - Parameters:
    ///   - element: The text field or secure text field to type into
    ///   - text: The text to type
    ///   - timeout: Maximum time to wait for element to exist (default: 5 seconds)
    /// - Returns: True if element existed and typing was attempted, false if element didn't exist
    @discardableResult
    func safeTypeText(in element: XCUIElement, text: String, timeout: TimeInterval = 5) -> Bool {
        guard element.waitForExistence(timeout: timeout) else {
            return false
        }
        
        prepareElementForTyping(element)
        
        // Strategy 1: Direct tap with clear
        if attemptTypingWithStrategy(element: element, text: text, strategy: {
            element.tap()
            Thread.sleep(forTimeInterval: 0.4)
            clearTextWithMenu(in: element)
            return true
        }) {
            return true
        }
        
        // Strategy 2: Coordinate-based tap
        if attemptTypingWithStrategy(element: element, text: text, strategy: {
            let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
            Thread.sleep(forTimeInterval: 0.4)
            return true
        }) {
            return true
        }
        
        // Strategy 3: Long press
        if attemptTypingWithStrategy(element: element, text: text, strategy: {
            element.press(forDuration: 0.5)
            Thread.sleep(forTimeInterval: 0.4)
            return true
        }) {
            return true
        }
        
        // Strategy 4: Double tap
        if attemptTypingWithStrategy(element: element, text: text, strategy: {
            element.doubleTap()
            Thread.sleep(forTimeInterval: 0.4)
            return true
        }) {
            return true
        }
        
        // Final attempt: just type
        element.tap()
        Thread.sleep(forTimeInterval: 0.5)
        element.typeText(text)
        Thread.sleep(forTimeInterval: 0.3)
        return verifyTextEntered(element: element, text: text)
    }
    
    /// Clears text using long press menu
    private func clearTextWithMenu(in element: XCUIElement) {
        element.press(forDuration: 1.0)
        Thread.sleep(forTimeInterval: 0.3)
        
        let selectAll = menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 1) {
            selectAll.tap()
            Thread.sleep(forTimeInterval: 0.2)
            
            let cut = menuItems["Cut"]
            if cut.waitForExistence(timeout: 0.5) {
                cut.tap()
            } else {
                for _ in 0..<20 {
                    element.typeText("\u{8}") // Backspace
                }
            }
        }
        Thread.sleep(forTimeInterval: 0.2)
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
    
    /// Waits for a button to become enabled
    /// - Parameters:
    ///   - button: The button element to wait for
    ///   - timeout: Maximum time to wait (default: 5 seconds)
    /// - Returns: True if button became enabled, false otherwise
    @discardableResult
    func waitForButtonEnabled(_ button: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: button)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}

/// Extension for XCUIElement to add waitForHittable
extension XCUIElement {
    /// Waits for the element to become hittable
    /// - Parameter timeout: Maximum time to wait (default: 2 seconds)
    /// - Returns: True if element became hittable, false otherwise
    @discardableResult
    func waitForHittable(timeout: TimeInterval = 2) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
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
    @MainActor
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
    @MainActor
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
    @MainActor
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
    @MainActor
    func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
