//
//  Income.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/6/25.
//

import Foundation
import SwiftData

@Model
class Income: Identifiable, Hashable{
    enum Frequency: String, CaseIterable, Identifiable, Codable {
      var id: String { rawValue }
      case weekly, biweekly, monthly, yearly, intermittent
    }
    
    @Attribute(.unique) var id: UUID = UUID()  // unique identifier
    
    var name: String
    var amount: Double
    var type: Frequency
    var taxPercent: Double
    var startDate: Date
    var endDate: Date?        // nil = never ends
    @Relationship(deleteRule: .cascade) var intermittentDates: [IntermittentDate]? // only if type == .intermittent
    
    init(
        name: String,
        amount: Double,
        type: Frequency = .monthly,
        taxPercent: Double = 0.0,
        startDate: Date = Date(),
        endDate: Date? = nil,
        intermittentDates: [IntermittentDate]? = nil
    ){
        self.name = name
        self.amount = amount
        self.type = type
        self.taxPercent = taxPercent
        self.startDate = startDate
        self.endDate = endDate
        self.intermittentDates = intermittentDates
    }
    
    var monthlyNet: Double {
        let grossMonthly: Double = {
          switch type {
          case .weekly:     return amount * 52/12
          case .biweekly:   return amount * 26/12
          case .monthly:    return amount
          case .yearly:     return amount/12
          case .intermittent:
              return 0
          }
        }()
        return grossMonthly * (1 - taxPercent/100)
      }
    
    static func == (lhs: Income, rhs: Income) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
