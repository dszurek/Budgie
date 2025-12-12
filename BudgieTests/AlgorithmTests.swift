//
//  AlgorithmTests.swift
//  BudgieTests
//
//  Created by Daniel Szurek on 5/10/25.
//

import XCTest
import SwiftData
@testable import Budgie

final class AlgorithmTests: XCTestCase {

    var container: ModelContainer!
    var user: User!
    var scheduler: PurchaseScheduler!

    @MainActor
    override func setUpWithError() throws {
        container = TestHelpers.createInMemoryContainer()
        user = TestHelpers.createDummyUser()
        container.mainContext.insert(user)
        scheduler = PurchaseScheduler()
    }

    @MainActor
    func testBasicProjection() throws {
        // Setup: $2000 start, +$5000 income, -$1000 rent monthly
        let start = Date()
        let income = TestHelpers.createMonthlyIncome(amount: 5000, start: start)
        let expense = TestHelpers.createMonthlyExpense(cost: 1000, start: start)
        
        container.mainContext.insert(income)
        container.mainContext.insert(expense)
        
        // Act: Generate timeline for 30 days
        let end = Calendar.current.date(byAdding: .day, value: 30, to: start)!
        let events = scheduler.generateMandatoryEventTimeline(
            incomes: [income],
            expenses: [expense],
            projectionStart: start,
            projectionEnd: end
        )
        
        // Assert: Should have at least one income and one expense event in a 30 day window
        let incomeEvents = events.filter { $0.type == .income }
        let expenseEvents = events.filter { $0.type == .expense }
        
        XCTAssertFalse(incomeEvents.isEmpty, "Should generate income events")
        XCTAssertFalse(expenseEvents.isEmpty, "Should generate expense events")
        XCTAssertEqual(incomeEvents.first?.amount, 5000, "Income amount should match")
        XCTAssertEqual(expenseEvents.first?.amount, -1000, "Expense amount should match (negative)")
    }

    @MainActor
    func testPurchaseScheduling_Success() throws {
        // Setup: Healthy surplus ($4000/mo net)
        let start = Date()
        let income = TestHelpers.createMonthlyIncome(amount: 5000, start: start)
        let expense = TestHelpers.createMonthlyExpense(cost: 1000, start: start)
        
        // Item to buy: $500, desired in 20 days
        let targetDate = Calendar.current.date(byAdding: .day, value: 20, to: start)!
        let item = TestHelpers.createShoppingItem(name: "New Phone", price: 500, date: targetDate)
        var items = [item] // mutable array
        
        // Act
        scheduler.calculateOptimalPurchaseDates(
            forUser: user,
            incomes: [income],
            expenses: [expense],
            shoppingListItems: &items,
            projectionStartDate: start
        )
        
        // Assert
        let updatedItem = items[0]
        XCTAssertNotNil(updatedItem.calculatedPurchaseDate, "Should find a viable purchase date")
        // It likely won't be exactly targetDate depending on logic, but should be set.
    }

    @MainActor
    func testPurchaseScheduling_InsufficientFunds() throws {
        // Setup: Poor finances (Start $0, Net -$1000/mo)
        user.startingBalance = 0
        user.rainCheckMin = 0
        // No income, just rent
        let start = Date()
        let expense = TestHelpers.createMonthlyExpense(cost: 1000, start: start)
        
        // Item: $500
        let targetDate = Calendar.current.date(byAdding: .day, value: 20, to: start)!
        let item = TestHelpers.createShoppingItem(name: "Luxury Item", price: 500, date: targetDate)
        var items = [item]
        
        // Act
        scheduler.calculateOptimalPurchaseDates(
            forUser: user,
            incomes: [],
            expenses: [expense],
            shoppingListItems: &items,
            projectionStartDate: start
        )
        
        // Assert
        let updatedItem = items[0]
        XCTAssertNil(updatedItem.calculatedPurchaseDate, "Should NOT schedule item when projected balance is negative")
    }
}
