//
//  TestHelpers.swift
//  BudgieTests
//
//  Created by Daniel Szurek on 5/10/25.
//

import Foundation
import SwiftData
@testable import Budgie

class TestHelpers {
    
    @MainActor
    static func createInMemoryContainer() -> ModelContainer {
        let schema = Schema([
            ShoppingList.self,
            ShoppingListItem.self,
            Income.self,
            Expense.self,
            User.self,
            DatedFinancialEvent.self,
            IntermittentDate.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    static func createDummyUser() -> User {
        return User(
            name: "Test User",
            targetSavings: 1000.0,
            rainCheckMin: 500.0,
            startingBalance: 2000.0
        )
    }
    
    static func createMonthlyIncome(amount: Double, start: Date) -> Income {
        return Income(
            name: "Salary",
            amount: amount,
            type: .monthly,
            taxPercent: 0.0,
            startDate: start,
            endDate: nil
        )
    }
    
    static func createMonthlyExpense(cost: Double, start: Date) -> Expense {
        return Expense(
            name: "Rent",
            cost: cost,
            type: .monthly,
            startDate: start,
            endDate: nil
        )
    }
    
    static func createShoppingItem(name: String, price: Double, date: Date) -> ShoppingListItem {
        return ShoppingListItem(
            name: name,
            price: price,
            purchaseByDate: date
        )
    }
}
