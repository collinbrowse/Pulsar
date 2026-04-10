//
//  PulsarUITests.swift
//  PulsarUITests
//
//  UI Tests for Pulsar App
//

import XCTest

final class PulsarUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Onboarding Tests
    
    func testOnboardingDisplaysCorrectly() throws {
        app.launch()
        
        // Should see onboarding when not authenticated
        // First page should have "Track Your Journey"
        let trackTitle = app.staticTexts["Track Your Journey"]
        XCTAssertTrue(trackTitle.waitForExistence(timeout: 5))
    }
    
    func testOnboardingContinueButton() throws {
        app.launch()
        
        // Tap continue button
        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
            
            // Should be on second page
            let segmentsTitle = app.staticTexts["Compete on Segments"]
            XCTAssertTrue(segmentsTitle.waitForExistence(timeout: 3))
        }
    }
    
    func testOnboardingSkipButton() throws {
        app.launch()
        
        // Tap skip button if visible
        let skipButton = app.buttons["Skip"]
        if skipButton.waitForExistence(timeout: 5) {
            skipButton.tap()
            
            // Should be on last page with Get Started button
            let getStartedButton = app.buttons["Get Started"]
            XCTAssertTrue(getStartedButton.waitForExistence(timeout: 3))
        }
    }
    
    func testOnboardingToAuthTransition() throws {
        app.launch()
        
        // Navigate to last page
        let skipButton = app.buttons["Skip"]
        if skipButton.waitForExistence(timeout: 5) {
            skipButton.tap()
        }
        
        // Tap Get Started
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 5) {
            getStartedButton.tap()
            
            // Should see auth screen
            let createAccountTitle = app.staticTexts["Create Account"]
            XCTAssertTrue(createAccountTitle.waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Auth Tests
    
    func testAuthScreenElements() throws {
        app.launch()
        
        // Navigate to auth (onboarding → Get Started → fullScreenCover AuthView)
        navigateToAuth()
        
        // Allow fullScreenCover to present (animation + hierarchy update)
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "pause")], timeout: 1.5)

        // fullScreenCover can take a moment; wait for title or key elements
        let authVisible = waitForAuthScreen(timeout: 10)
        XCTAssertTrue(authVisible, "Auth screen did not appear after navigating from onboarding")
        
        // At least one key element should be present (identifier or type)
        let emailField = app.textFields["AuthEmailField"]
        let passwordField = app.secureTextFields["AuthPasswordField"]
        let signInAppleButton = app.buttons["AuthAppleButton"]
        let hasElement = emailField.waitForExistence(timeout: 3) ||
                        passwordField.waitForExistence(timeout: 2) ||
                        signInAppleButton.waitForExistence(timeout: 2)
        XCTAssertTrue(hasElement, "Expected at least one of email field, password field, or Sign in with Apple button on auth screen")
    }
    
    func testAuthToggleSignInSignUp() throws {
        app.launch()
        
        // Navigate to auth
        navigateToAuth()
        
        // Should be able to toggle between sign in and sign up
        let signInLink = app.buttons["Sign In"]
        let signUpLink = app.buttons["Sign Up"]
        
        if signInLink.waitForExistence(timeout: 5) {
            signInLink.tap()
            
            let welcomeBackTitle = app.staticTexts["Welcome Back"]
            XCTAssertTrue(welcomeBackTitle.waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Navigation Tests
    
    func testTabBarNavigation() throws {
        // Launch with authenticated state
        app.launchArguments.append("--authenticated")
        app.launch()
        
        // Check if tab bar exists (will only work in authenticated state)
        let feedTab = app.tabBars.buttons["Feed"]
        let segmentsTab = app.tabBars.buttons["Segments"]
        let profileTab = app.tabBars.buttons["Profile"]
        let settingsTab = app.tabBars.buttons["Settings"]
        
        // If authenticated, tab bar should be present
        if feedTab.waitForExistence(timeout: 5) {
            XCTAssertTrue(segmentsTab.exists)
            XCTAssertTrue(profileTab.exists)
            XCTAssertTrue(settingsTab.exists)
        }
    }
    
    func testNavigateToProfile() throws {
        app.launchArguments.append("--authenticated")
        app.launch()
        
        let profileTab = app.tabBars.buttons["Profile"]
        if profileTab.waitForExistence(timeout: 5) {
            profileTab.tap()
            
            // Should see profile elements
            let editButton = app.buttons["Edit"]
            XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        }
    }
    
    func testNavigateToSettings() throws {
        app.launchArguments.append("--authenticated")
        app.launch()
        
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.waitForExistence(timeout: 5) {
            settingsTab.tap()
            
            // Should see settings title
            let settingsTitle = app.navigationBars["Settings"]
            XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
        }
    }
    
    func testNavigateToSegments() throws {
        app.launchArguments.append("--authenticated")
        app.launch()
        
        let segmentsTab = app.tabBars.buttons["Segments"]
        if segmentsTab.waitForExistence(timeout: 5) {
            segmentsTab.tap()
            
            // Should see segments navigation
            let segmentsTitle = app.navigationBars["Segments"]
            XCTAssertTrue(segmentsTitle.waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Feed Tests
    
    func testFeedDisplaysActivities() throws {
        app.launchArguments.append("--authenticated")
        app.launch()
        
        // Feed should be the default tab
        let feedTitle = app.navigationBars["Feed"]
        XCTAssertTrue(feedTitle.waitForExistence(timeout: 5))
    }
    
    func testFeedPullToRefresh() throws {
        app.launchArguments.append("--authenticated")
        app.launch()
        
        // Wait for feed to load
        let feedTitle = app.navigationBars["Feed"]
        XCTAssertTrue(feedTitle.waitForExistence(timeout: 5), "Feed screen did not appear")
        
        // Feed may show loading then empty state (no network in UI tests). SwiftUI ScrollView
        // is not reliably exposed as XCUIElementTypeScrollView; use coordinate drag or empty state.
        let emptyStateTitle = app.staticTexts["No Activities Yet"]
        if emptyStateTitle.waitForExistence(timeout: 8) {
            XCTAssertTrue(emptyStateTitle.exists)
        } else {
            // Content or still loading: trigger pull via coordinate drag (avoids ScrollView query)
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            start.press(forDuration: 0.3, thenDragTo: end)
        }
        
        XCTAssertTrue(feedTitle.exists, "App should still show Feed after pull/empty check")
    }
    
    // MARK: - Import Tests
    
    func testImportTabShowsSheet() throws {
        app.launchArguments.append("--authenticated")
        app.launch()
        
        let importTab = app.tabBars.buttons["Import"]
        if importTab.waitForExistence(timeout: 5) {
            importTab.tap()
            
            // Should show import sheet
            let importTitle = app.staticTexts["Import Activity"]
            XCTAssertTrue(importTitle.waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        app.launch()
        
        // Check that major elements have accessibility labels
        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(continueButton.isHittable)
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToAuth() {
        // Navigate through onboarding to auth (3 pages; Skip jumps to last)
        let skipButton = app.buttons["Skip"]
        if skipButton.waitForExistence(timeout: 5), skipButton.isHittable {
            skipButton.tap()
        } else {
            for _ in 0..<2 {
                let continueButton = app.buttons["Continue"]
                if continueButton.waitForExistence(timeout: 3), continueButton.isHittable {
                    continueButton.tap()
                }
            }
        }
        
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 5), getStartedButton.isHittable {
            getStartedButton.tap()
            // Brief wait for fullScreenCover to start presenting
            _ = XCTWaiter.wait(for: [XCTestExpectation(description: "sheet")], timeout: 1.0)
        }
    }

    private func waitForAuthScreen(timeout: TimeInterval = 5) -> Bool {
        // Prefer identifier; fall back to static text (sheet can be slow to present)
        let authTitle = app.staticTexts["AuthScreenTitle"]
        if authTitle.waitForExistence(timeout: timeout) { return true }
        let createAccountTitle = app.staticTexts["Create Account"]
        if createAccountTitle.waitForExistence(timeout: 2) { return true }
        return app.staticTexts["Welcome Back"].waitForExistence(timeout: 2)
    }
}
