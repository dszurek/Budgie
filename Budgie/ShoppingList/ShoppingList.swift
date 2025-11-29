//
//  ShoppingList.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/5/25.
//

import Foundation
import SwiftData

@Model
class ShoppingList {
    var name: String
    var timestamp: Date
    var lastAccessed: Date
    var items: [ShoppingListItem] = []
    var totalPrice: Double {
        items.reduce(0) { $0 + $1.price }
    }
    
    var colorHex: String = "#0000FF" // Default blue
    
    init(name: String, timestamp: Date = Date(), colorHex: String = "#0000FF") {
        self.name = name
        self.timestamp = timestamp
        self.lastAccessed = timestamp
        self.colorHex = colorHex
    }
    
}
