//
//  BalanceManagerTests.swift
//  BudgieTests
//
//  Created by Daniel Szurek on 5/10/25.
//

import XCTest
import SwiftData
@testable import Budgie

final class BalanceManagerTests: XCTestCase {

    var container: ModelContainer!
    var user: User!
    
    @MainActor
    override func setUpWithError() throws {
        container = TestHelpers.createInMemoryContainer()
        user = TestHelpers.createDummyUser()
        
        // Ensure user starts fresh
        user.lastAutoUpdateDate = Date.distantPast
        user.startingBalance = 1000
        
        container.mainContext.insert(user)
    }

    @MainActor
    func testBalanceAutoUpdate() throws {
        // Setup:
        // Last update was 30 days ago
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        user.lastAutoUpdateDate = thirtyDaysAgo
        
        // Add a monthly income that started 2 months ago (so it definitely occurred in the last 30 days)
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: now)!
        let income = TestHelpers.createMonthlyIncome(amount: 500, start: twoMonthsAgo)
        container.mainContext.insert(income)
        
        // Act
        let message = BalanceManager.shared.updateBalanceForPassedEvents(user: user, modelContext: container.mainContext)
        
        // Assert
        XCTAssertNotNil(message, "Should return an update message")
        // Calculated: Started $1000. +$500 once in the last 30 day window.
        // BalanceCheckpoints should have been added.
        XCTAssertEqual(user.currentBalance, 1500, "Balance should increase by one income event")
        XCTAssertTrue(Calendar.current.isDateInToday(user.lastAutoUpdateDate), "Last update date should be set to today")
    }
    
    @MainActor
    func testBalanceNoUpdateNeeded() throws {
        // Setup: Last update was just now
        user.lastAutoUpdateDate = Date()
        
        // Act
        let message = BalanceManager.shared.updateBalanceForPassedEvents(user: user, modelContext: container.mainContext)
        
        // Assert
        XCTAssertNil(message, "Should not update if already up to date")
        XCTAssertEqual(user.currentBalance, 1000, "Balance should remain unchanged")
    }
}
