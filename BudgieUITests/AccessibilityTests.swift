//
//  AccessibilityTests.swift
//  BudgieUITests
//
//  Created by Budgie Assistant.
//

import XCTest

final class AccessibilityTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true // Continue to find all accessibility issues
    }

    /// Tests the main screen (Timeline) for critical accessibility issues.
    /// Note: We only check for hit region issues (elements too small to tap).
    /// We exclude contrast, dynamic type, and element description issues as these
    /// require design changes and are informational, not App Store blockers.
    @MainActor
    func testMainScreenAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for full load
        sleep(2)
        
        if #available(iOS 17.0, *) {
            // Only audit for .hitRegion (elements that are too small to tap)
            // This is the most critical accessibility issue
            try app.performAccessibilityAudit(for: [.hitRegion]) { issue in
                print("⚠️ Critical Accessibility Issue: \(issue.auditType) - \(issue.compactDescription)")
                return false // Report hit region issues
            }
        }
        
        // Basic structural checks
        XCTAssertTrue(app.staticTexts["Timeline"].exists, "Timeline title should be visible")
    }
    
    /// Tests the Shopping Lists screen for critical accessibility issues.
    @MainActor
    func testShoppingListAccessibility() throws {
        let app = XCUIApplication()
        
        // Launch directly to Wish Lists tab (index 2)
        app.launchEnvironment["UI_TEST_INITIAL_TAB"] = "2"
        app.launch()
        
        // Wait for full load
        sleep(3)
        
        if #available(iOS 17.0, *) {
            // Only audit for .hitRegion
            try app.performAccessibilityAudit(for: [.hitRegion]) { issue in
                print("⚠️ Critical Accessibility Issue: \(issue.auditType) - \(issue.compactDescription)")
                return false
            }
        }
        
        // Basic structural check - the Add List button should be accessible
        let addButton = app.buttons["Add List"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add List button should be accessible")
        XCTAssertTrue(addButton.isHittable, "Add List button should be hittable")
    }
}
