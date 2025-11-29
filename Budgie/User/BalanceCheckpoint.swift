//
//  BalanceCheckpoint.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/10/25.
//

import Foundation
import SwiftData

@Model
class BalanceCheckpoint: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var amount: Double
    
    // Relationship back to User (optional, but good for cascade delete if needed)
    // For now, we'll just keep it simple and let User hold the array.
    
    init(date: Date = Date(), amount: Double) {
        self.date = date
        self.amount = amount
    }
}
