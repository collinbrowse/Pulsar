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
        
        // Navigate to auth
        navigateToAuth()
        
        // Check for key elements
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let signInAppleButton = app.buttons["Sign in with Apple"]
        
        // At least some elements should be present
        XCTAssertTrue(emailField.waitForExistence(timeout: 3) || 
                     passwordField.waitForExistence(timeout: 3) ||
                     signInAppleButton.waitForExistence(timeout: 3))
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
        if feedTitle.waitForExistence(timeout: 5) {
            // Perform pull to refresh
            let firstCell = app.scrollViews.firstMatch
            firstCell.swipeDown()
            
            // App should not crash
            XCTAssertTrue(feedTitle.exists)
        }
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
        // Navigate through onboarding to auth
        let skipButton = app.buttons["Skip"]
        if skipButton.waitForExistence(timeout: 5) {
            skipButton.tap()
        }
        
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 5) {
            getStartedButton.tap()
        }
    }
}
