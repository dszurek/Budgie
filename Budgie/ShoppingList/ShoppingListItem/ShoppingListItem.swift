//
//  ShoppingListItem.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/5/25.
//

import Foundation
import SwiftData

@Model
class ShoppingListItem: Identifiable, Hashable {
    @Attribute(.unique) var id: UUID = UUID()  // unique identifier
    var name: String
    var price: Double
    var purchaseByDate: Date
    var url: URL?
    var imageURL: URL?
    var parentList: ShoppingList?
    var isPurchased: Bool?
    var calculatedPurchaseDate: Date?
    var predictedBalanceAfterPurchase: Double?
    var calculationError: String?
    var actualPurchaseDate: Date? // Track when it was actually bought
    
    init(name: String, price: Double = 0.0, purchaseByDate: Date, url: URL? = nil, imageURL: URL? = nil) {
        self.name = name
        self.price = price
        self.purchaseByDate = purchaseByDate
        self.url = url
        self.imageURL = imageURL
    }

    // MARK: - Hashable conformance

    static func == (lhs: ShoppingListItem, rhs: ShoppingListItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
