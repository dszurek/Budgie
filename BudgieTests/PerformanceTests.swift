//
//  PerformanceTests.swift
//  BudgieTests
//
//  Created by Daniel Szurek on 5/10/25.
//

import XCTest
import SwiftData
@testable import Budgie

final class PerformanceTests: XCTestCase {
    
    var scheduler: PurchaseScheduler!
    var user: User!
    
    @MainActor
    override func setUpWithError() throws {
        scheduler = PurchaseScheduler()
        user = TestHelpers.createDummyUser()
    }
    
    @MainActor
    func testAlgorithmPerformance_StandardLoad() {
        // Standard Load: 5 years of projection, 10 incomes, 10 expenses, 50 items
        let start = Date()
        var incomes: [Income] = []
        var expenses: [Expense] = []
        var items: [ShoppingListItem] = []
        
        for _ in 0..<10 {
            incomes.append(TestHelpers.createMonthlyIncome(amount: 1000, start: start))
            expenses.append(TestHelpers.createMonthlyExpense(cost: 200, start: start))
        }
        
        for i in 0..<50 {
            let targetDate = Calendar.current.date(byAdding: .day, value: i*5, to: start)!
            items.append(TestHelpers.createShoppingItem(name: "Item \(i)", price: 100, date: targetDate))
        }
        
        measure {
            scheduler.calculateOptimalPurchaseDates(
                forUser: user,
                incomes: incomes,
                expenses: expenses,
                shoppingListItems: &items,
                projectionStartDate: start
            )
        }
    }
    
    @MainActor
    func testAlgorithmPerformance_HeavyLoad() {
        // Stress Test: 100 High frequency recurring events, 1000 items
        let start = Date()
        var incomes: [Income] = []
        var expenses: [Expense] = []
        var items: [ShoppingListItem] = []
        
        // High frequency weekly events
        for _ in 0..<50 {
            let inc = TestHelpers.createMonthlyIncome(amount: 500, start: start)
            inc.type = .weekly // More computations
            incomes.append(inc)
            
            let exp = TestHelpers.createMonthlyExpense(cost: 100, start: start)
            exp.type = .weekly
            expenses.append(exp)
        }
        
        // 1000 Items
        for i in 0..<1000 {
            // Spread them out over 2 years
            let dayOffset = Int.random(in: 1...700)
            let targetDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: start)!
            items.append(TestHelpers.createShoppingItem(name: "Heavy Item \(i)", price: Double.random(in: 10...500), date: targetDate))
        }
        
        let expectation = self.expectation(description: "Heavy load calculation")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        scheduler.calculateOptimalPurchaseDates(
            forUser: user,
            incomes: incomes,
            expenses: expenses,
            shoppingListItems: &items,
            projectionStartDate: start
        )
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        print("⚡️ Heavy Load Duration: \(duration) seconds")
        
        // Assert it finishes reasonable fast (e.g. under 3 seconds for this load on a dev machine)
        // Adjust based on real world metrics, but this prevents infinite loops or O(n^3) regressions.
        XCTAssertLessThan(duration, 10.0, "Heavy load calculation took too long!")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
}
