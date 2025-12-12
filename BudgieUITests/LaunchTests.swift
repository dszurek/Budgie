//
//  LaunchTests.swift
//  BudgieUITests
//
//  Created by Budgie Assistant.
//

import XCTest

final class LaunchTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Simple launch test that verifies the app can start and show its main UI.
    /// This test will show a green checkmark when passed.
    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify the app is running in foreground
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10), "App should be running in foreground after launch")
        
        // Verify the app shows the main screen (Timeline is the default tab)
        let timelineTitle = app.staticTexts["Timeline"]
        XCTAssertTrue(timelineTitle.waitForExistence(timeout: 10), "App should show Timeline screen after launch")
    }
    
    /// Tests that the app launches and displays the bottom navigation bar.
    @MainActor
    func testBottomBarVisible() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to fully load
        sleep(2)
        
        // Check that all navigation labels are visible
        XCTAssertTrue(app.staticTexts["Timeline"].exists, "Timeline tab should be visible")
        XCTAssertTrue(app.staticTexts["Budget"].exists, "Budget tab should be visible")
        XCTAssertTrue(app.staticTexts["Wish Lists"].exists, "Wish Lists tab should be visible")
        XCTAssertTrue(app.staticTexts["You"].exists, "You tab should be visible")
    }
    
    /// Launch performance test - measures app startup time.
    /// Note: Performance tests in Xcode show as grey/neutral until baselines are established.
    /// This is normal behavior - you can set baselines in Xcode's Test navigator.
    @MainActor
    func testLaunchPerformance() throws {
        if #available(iOS 13.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
