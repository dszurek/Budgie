//
//  BudgieUITests.swift
//  BudgieUITests
//
//  Created by Daniel Szurek on 5/5/25.
//

import XCTest

final class BudgieUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTabBarExists_SmokeTest() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Verify the Tab Bar exists
        // Note: Your custom BottomBar might be implemented as buttons, not a native UITabBar.
        // Assuming access via accessibility identifiers or static text for now.
        // If accessibility IDs aren't set, we look for the labels "Timeline", "Budget", "Wish Lists", "You"
        
        let timelineText = app.staticTexts["Timeline"]
        XCTAssertTrue(timelineText.waitForExistence(timeout: 5), "Timeline tab should be visible")
        
        let budgetText = app.staticTexts["Budget"]
        XCTAssertTrue(budgetText.exists, "Budget tab should be visible")
    }
}
