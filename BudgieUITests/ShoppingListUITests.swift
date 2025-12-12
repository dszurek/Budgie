//
//  ShoppingListUITests.swift
//  BudgieUITests
//
//  Created by Daniel Szurek on 5/10/25.
//

import XCTest

final class ShoppingListUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddShoppingList() throws {
        let app = XCUIApplication()
        
        // Launch directly to Wish Lists tab (index 2) via environment variable
        app.launchEnvironment["UI_TEST_INITIAL_TAB"] = "2"
        app.launch()
        
        // Wait for app to fully load on the Shopping Lists view
        sleep(3)
        
        // The "Add List" button should now be visible and hittable since we launched directly to this tab
        let addButton = app.buttons["Add List"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10), "Add List button not found")
        
        // Verify the button is actually hittable (not behind another view)
        XCTAssertTrue(addButton.isHittable, "Add List button is not hittable - view may not have switched correctly")
        addButton.tap()
        
        // Wait for alert to appear
        sleep(1)
        
        // Try multiple ways to find the text field in the alert
        // SwiftUI alerts create system alerts which may have different identifiers
        var textField = app.textFields["List Name"]
        
        if !textField.waitForExistence(timeout: 3) {
            // Try by accessibility identifier if placeholder didn't work
            textField = app.textFields["ListNameField"]
        }
        
        if !textField.waitForExistence(timeout: 2) {
            // Try finding any text field in the alert
            textField = app.alerts.textFields.firstMatch
        }
        
        XCTAssertTrue(textField.exists, "List Name TextField not found in Alert")
        textField.tap()
        textField.typeText("Groceries")
        
        // Tap Create button
        let createButton = app.buttons["Create"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 3), "Create button not found")
        createButton.tap()
        
        // Wait for alert to dismiss and list to update
        sleep(1)
        
        // Verify list creation - wait for the new list to appear
        let listText = app.staticTexts["Groceries"]
        XCTAssertTrue(listText.waitForExistence(timeout: 5), "New list 'Groceries' not found")
    }
}
