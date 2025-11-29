//
//  IntermittentDate.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/7/25.
//

import Foundation
import SwiftData

@Model
class IntermittentDate: Identifiable {
    var id: UUID = UUID()
    var date: Date
    
    init(date: Date) {
        self.date = date
    }
}
