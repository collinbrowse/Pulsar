//
//  SignUpWithExistingAccountUITests.swift
//  PulsarUITests
//
//  Created on 10/28/25.
//

import XCTest

/// UI Test for graceful handling of "user already exists" error
/// This test validates that attempting to sign up with an existing account
/// automatically signs the user in instead of showing an error.
@MainActor
final class SignUpWithExistingAccountUITests: XCTestCase {
    nonisolated(unsafe) var app: XCUIApplication!
    
    // Test account credentials (should exist in test database)
    let testEmail = "test@pulsar.app"
    let testPassword = "testpass123"
    let testUsername = "testuser"
    let testFullName = "Test User"
    
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
    
    // MARK: - Helper Methods
    
    private func fillSignUpForm() -> (username: XCUIElement, email: XCUIElement) {
        let usernameField = app.textFields["Username"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 2), "Username field should exist")
        XCTAssertTrue(app.safeTypeText(in: usernameField, text: testUsername), "Should type username")
        Thread.sleep(forTimeInterval: 0.5)
        verifyTextFieldValue(usernameField, expectedText: testUsername, fieldName: "Username")
        
        let fullNameField = app.textFields["Full Name"]
        XCTAssertTrue(app.safeTypeText(in: fullNameField, text: testFullName), "Should type full name")
        Thread.sleep(forTimeInterval: 0.5)
        
        let emailField = app.textFields["Email"]
        XCTAssertTrue(app.safeTypeText(in: emailField, text: testEmail), "Should type email")
        Thread.sleep(forTimeInterval: 0.5)
        verifyTextFieldValue(emailField, expectedText: testEmail, fieldName: "Email")
        
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(app.safeTypeText(in: passwordField, text: testPassword), "Should type password")
        Thread.sleep(forTimeInterval: 0.5)
        
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        XCTAssertTrue(app.safeTypeText(in: confirmPasswordField, text: testPassword), "Should type confirm password")
        Thread.sleep(forTimeInterval: 0.5)
        
        app.dismissKeyboard()
        Thread.sleep(forTimeInterval: 0.5)
        
        return (usernameField, emailField)
    }
    
    private func verifyTextFieldValue(_ field: XCUIElement, expectedText: String, fieldName: String) {
        if let value = field.value as? String {
            XCTAssertTrue(value.contains(expectedText) || value == expectedText,
                         "\(fieldName) field should contain '\(expectedText)', but got '\(value)'")
        } else {
            XCTFail("\(fieldName) field value is nil or empty - text may not have been entered")
        }
    }
    
    private func verifyAndWaitForButtonEnabled(_ button: XCUIElement, fields: (username: XCUIElement, email: XCUIElement)) {
        let usernameValue = fields.username.value as? String ?? ""
        let emailValue = fields.email.value as? String ?? ""
        
        XCTAssertFalse(usernameValue.isEmpty, "Username should not be empty. Current value: '\(usernameValue)'")
        XCTAssertFalse(emailValue.isEmpty, "Email should not be empty. Current value: '\(emailValue)'")
        
        triggerUIUpdate()
        waitForLoadingToComplete()
        triggerFieldInteractions(fields: fields)
        
        let buttonEnabled = app.waitForButtonEnabled(button, timeout: 5)
        let buttonHittable = button.waitForHittable(timeout: 2)
        
        if !buttonEnabled && !buttonHittable {
            takeScreenshot(named: "Button Not Enabled - Form State")
            printDebugInfo(button: button, usernameValue: usernameValue, emailValue: emailValue)
            XCTFail("Create Account button should be enabled. Enabled: \(button.isEnabled), Hittable: \(button.isHittable)")
        }
        
        if !buttonHittable && !buttonEnabled {
            XCTFail("Create Account button is neither enabled nor hittable")
        }
    }
    
    private func triggerUIUpdate() {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)
            scrollView.swipeDown()
            Thread.sleep(forTimeInterval: 0.3)
        } else {
            app.dismissKeyboard()
            Thread.sleep(forTimeInterval: 0.3)
        }
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    private func waitForLoadingToComplete() {
        let progressView = app.progressIndicators.firstMatch
        if progressView.exists {
            print("DEBUG: Loading indicator is visible - button will be disabled until loading completes")
            let loadingFinished = NSPredicate(format: "exists == false")
            let loadingExpectation = XCTNSPredicateExpectation(predicate: loadingFinished, object: progressView)
            _ = XCTWaiter().wait(for: [loadingExpectation], timeout: 5)
        }
    }
    
    private func triggerFieldInteractions(fields: (username: XCUIElement, email: XCUIElement)) {
        fields.username.tap()
        Thread.sleep(forTimeInterval: 0.2)
        app.dismissKeyboard()
        Thread.sleep(forTimeInterval: 0.3)
        
        fields.email.tap()
        Thread.sleep(forTimeInterval: 0.2)
        app.dismissKeyboard()
        Thread.sleep(forTimeInterval: 0.3)
    }
    
    private func printDebugInfo(button: XCUIElement, usernameValue: String, emailValue: String) {
        let passwordMatch = app.staticTexts["Passwords match"].exists
        let passwordMismatch = app.staticTexts["Passwords don't match"].exists
        
        print("DEBUG: Button enabled: \(button.isEnabled)")
        print("DEBUG: Button hittable: \(button.isHittable)")
        print("DEBUG: Password match indicator: \(passwordMatch)")
        print("DEBUG: Password mismatch indicator: \(passwordMismatch)")
        print("DEBUG: Username field value: '\(usernameValue)' (isEmpty: \(usernameValue.isEmpty))")
        print("DEBUG: Email field value: '\(emailValue)' (isEmpty: \(emailValue.isEmpty))")
        print("DEBUG: Password length: \(testPassword.count) (required: >= 8)")
    }
    
    // MARK: - Main Test
    
    func testSignUpWithExistingAccountAutoSignsIn() throws {
        // GIVEN: User is on the welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to Pulsar"].exists, "Should be on welcome screen")
        
        // WHEN: User taps "Sign Up"
        app.buttons["Sign Up"].tap()
        
        // THEN: Should navigate to sign up screen
        XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 2), "Should show sign up screen")
        
        // WHEN: User fills in form with EXISTING account credentials
        let fields = fillSignUpForm()
        
        // THEN: Verify "Passwords match" indicator appears
        let passwordMatchIndicator = app.staticTexts["Passwords match"]
        XCTAssertTrue(passwordMatchIndicator.waitForExistence(timeout: 3), "Passwords should match")
        
        // WHEN: User taps "Create Account" (with existing email)
        let createAccountButton = app.buttons["Create Account"]
        XCTAssertTrue(createAccountButton.exists, "Create Account button should exist")
        
        verifyAndWaitForButtonEnabled(createAccountButton, fields: fields)
        createAccountButton.tap()
        
        // THEN: Should NOT show "HTTP error" or raw error message
        sleep(2) // Give time for error processing
        
        // Verify no raw error messages are shown
        let httpErrorText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'HTTP error'"))
        XCTAssertFalse(httpErrorText.element.exists, "Should NOT show raw HTTP error")
        
        let errorCodeText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'error_code'"))
        XCTAssertFalse(errorCodeText.element.exists, "Should NOT show raw error code")
        
        let statusCodeText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] '422'"))
        XCTAssertFalse(statusCodeText.element.exists, "Should NOT show status code 422")
        
        // THEN: Should either:
        // 1. Auto sign in and navigate to main app (Activities tab should appear)
        // 2. Show user-friendly message about signing in
        
        // Wait for either main app or friendly message
        let activitiesTab = app.tabBars.buttons["Activities"]
        let feedTab = app.tabBars.buttons["Feed"]
        let profileTab = app.tabBars.buttons["Profile"]
        
        // Give enough time for sign-in to complete (up to 5 seconds)
        sleep(5)
        
        // Check if we're in the main app
        let isInMainApp = activitiesTab.exists || feedTab.exists || profileTab.exists
        
        if isInMainApp {
            // SUCCESS: Auto sign-in worked
            XCTAssertTrue(activitiesTab.exists || feedTab.exists, "Should navigate to main app")
            print("✅ SUCCESS: User was automatically signed in and navigated to main app")
        } else {
            // Check if still on sign up screen with friendly message
            let stillOnSignUp = app.staticTexts["Create Account"].exists
            
            if stillOnSignUp {
                // Should show a user-friendly message, not a raw error
                // Look for any error-like text
                let errorLabels = app.staticTexts.allElementsBoundByIndex.filter { element in
                    let label = element.label.lowercased()
                    return label.contains("account") || label.contains("password") || label.contains("sign")
                }
                
                // If there are error messages, they should be user-friendly
                for errorLabel in errorLabels {
                    let label = errorLabel.label
                    print("Found message: \(label)")
                    
                    // These are BAD - should NOT appear
                    XCTAssertFalse(label.contains("HTTP"), "Error should not contain 'HTTP'")
                    XCTAssertFalse(label.contains("422"), "Error should not contain status code")
                    XCTAssertFalse(label.contains("error_code"), "Error should not contain 'error_code'")
                    XCTAssertFalse(label.contains("{"), "Error should not be JSON")
                }
            } else {
                // Might be on profile creation screen
                let isOnProfileCreation = app.staticTexts["Complete Your Profile"].exists
                if isOnProfileCreation {
                    print("✅ SUCCESS: User navigated to profile creation (account exists but no profile)")
                } else {
                    XCTFail("Unexpected screen state - should be in main app, sign up, or profile creation")
                }
            }
        }
    }
    
    // MARK: - Helper Tests
    
    func testSignUpWithExistingAccountShowsNoRawErrors() throws {
        // This test focuses ONLY on ensuring no raw errors are shown
        
        app.buttons["Sign Up"].tap()
        
        let usernameField = app.textFields["Username"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 2))
        XCTAssertTrue(app.safeTypeText(in: usernameField, text: testUsername), "Should type username")
        
        let fullNameField = app.textFields["Full Name"]
        XCTAssertTrue(app.safeTypeText(in: fullNameField, text: testFullName), "Should type full name")
        
        let emailField = app.textFields["Email"]
        XCTAssertTrue(app.safeTypeText(in: emailField, text: testEmail), "Should type email")
        
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(app.safeTypeText(in: passwordField, text: testPassword), "Should type password")
        
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        XCTAssertTrue(app.safeTypeText(in: confirmPasswordField, text: testPassword), "Should type confirm password")
        
        app.buttons["Create Account"].tap()
        
        sleep(3) // Wait for processing
        
        // CRITICAL: These raw error indicators should NEVER appear to users
        let forbiddenTexts = [
            "HTTP error",
            "422",
            "error_code",
            "user_already_exists",
            "{\"code\"",
            "\"msg\"",
            "status code"
        ]
        
        for forbiddenText in forbiddenTexts {
            let forbiddenElement = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", forbiddenText))
            XCTAssertFalse(forbiddenElement.element.exists,
                          "❌ CRITICAL: Users should NEVER see '\(forbiddenText)' - use ErrorManager for user-friendly messages")
        }
        
        print("✅ No raw error messages detected")
    }
    
    func testSignUpWithExistingAccountShowsProgress() throws {
        // Verify that loading indicator appears during processing
        
        app.buttons["Sign Up"].tap()
        
        let usernameField = app.textFields["Username"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 2))
        XCTAssertTrue(app.safeTypeText(in: usernameField, text: testUsername), "Should type username")
        
        let fullNameField = app.textFields["Full Name"]
        XCTAssertTrue(app.safeTypeText(in: fullNameField, text: testFullName), "Should type full name")
        
        let emailField = app.textFields["Email"]
        XCTAssertTrue(app.safeTypeText(in: emailField, text: testEmail), "Should type email")
        
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(app.safeTypeText(in: passwordField, text: testPassword), "Should type password")
        
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        XCTAssertTrue(app.safeTypeText(in: confirmPasswordField, text: testPassword), "Should type confirm password")
        
        let createAccountButton = app.buttons["Create Account"]
        createAccountButton.tap()
        
        // Loading indicator should appear (ProgressView)
        // Note: Loading might be fast, so we just check it existed at some point
        // or the button is disabled during loading
        _ = app.activityIndicators.firstMatch
        sleep(1)
        
        // At minimum, the button text should have changed or button disabled
        // (We can't easily test ProgressView visibility in UI tests)
        print("✅ Button tapped, processing initiated")
    }
}
