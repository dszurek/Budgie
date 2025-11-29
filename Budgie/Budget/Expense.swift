//
//  Expense.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/6/25.
//

import Foundation
import SwiftData

@Model
class Expense: Identifiable, Hashable {
    enum Frequency: String, CaseIterable, Identifiable, Codable {
      var id: String { rawValue }
      case weekly, biweekly, monthly, yearly, intermittent
    }
    
    @Attribute(.unique) var id: UUID = UUID()  // unique identifier
    
  var name: String
  var cost: Double
  var type: Frequency
  var startDate: Date
  var endDate: Date?
  @Relationship(deleteRule: .cascade) var intermittentDates: [IntermittentDate]?
  
  init(name: String,
       cost: Double,
       type: Frequency = .monthly,
       startDate: Date = Date(),
       endDate: Date? = nil,
       intermittentDates: [IntermittentDate]? = nil)
  {
    self.name = name
    self.cost = cost
    self.type = type
    self.startDate = startDate
    self.endDate = endDate
    self.intermittentDates = intermittentDates
  }
  
  var monthlyCost: Double {
    switch type {
    case .weekly:     return cost * 52/12
    case .biweekly:   return cost * 26/12
    case .monthly:    return cost
    case .yearly:     return cost/12
    case .intermittent:
      return 0
    }
  }
    
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}
