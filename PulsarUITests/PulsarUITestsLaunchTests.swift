//
//  PulsarUITestsLaunchTests.swift
//  PulsarUITests
//
//  Launch Performance Tests for Pulsar App
//

import XCTest

final class PulsarUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // Measures time to launch. Do not terminate the app inside the block—
            // that can cause the test runner to exit before the metric is recorded.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                let app = XCUIApplication()
                app.launchArguments = ["--uitesting"]
                app.launch()
            }
        }
    }
    
    func testLaunchDarkMode() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-UITraitCollectionUserInterfaceStyleDark", "2"]
        app.launch()
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Dark Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testLaunchLightMode() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-UITraitCollectionUserInterfaceStyleLight", "1"]
        app.launch()
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Light Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testLaunchLargeText() throws {
        let app = XCUIApplication()
        // Test with accessibility large text
        app.launchArguments = ["--uitesting", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
        app.launch()
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Large Text"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
