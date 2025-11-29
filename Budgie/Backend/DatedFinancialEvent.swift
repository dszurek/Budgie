//
//  DatedFinancialEvent.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/10/25.
//

import Foundation
import SwiftData

@Model
class DatedFinancialEvent: Identifiable, Hashable {
    
    enum In_Ex: String, CaseIterable, Identifiable, Codable {
        var id: String { rawValue }
        case income
        case expense
        case purchase // For shopping list items
    }
    
    @Attribute(.unique) var id: UUID = UUID()  // unique identifier
    var date: Date
    var amount: Double
    var type: In_Ex
    var title: String
    
    
    var originalItem: ShoppingListItem? // Optional reference to the source item
    
    init(date: Date, amount: Double, type: In_Ex, title: String, originalItem: ShoppingListItem? = nil) {
        self.date = date
        self.amount = amount
        self.type = type
        self.title = title
        self.originalItem = originalItem
    }

    // MARK: - Hashable conformance

    static func == (lhs: DatedFinancialEvent, rhs: DatedFinancialEvent) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

