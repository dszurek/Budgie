//
//  User.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/7/25.
//

import Foundation
import SwiftData

@Model
class User{
    var id: UUID = UUID()       // to make it uniquely identifiable
    var name: String
    var targetSavings: Double
    var rainCheckMin: Double
    var startingBalance: Double
    // For the profile pic, you could store a URL or Data; here we'll keep it simple:
    var profileImageData: Data?
    var lastAutoUpdateDate: Date = Date() // Track last auto-update
    
    @Relationship(deleteRule: .cascade) var balanceCheckpoints: [BalanceCheckpoint] = []

    var currentBalance: Double {
        // Return the amount of the latest checkpoint, or startingBalance if none exist
        if let latest = balanceCheckpoints.sorted(by: { $0.date > $1.date }).first {
            return latest.amount
        }
        return startingBalance
    }
    
    var lastCheckpointDate: Date {
        if let latest = balanceCheckpoints.sorted(by: { $0.date > $1.date }).first {
            return latest.date
        }
        return Date.distantPast // Or some initial date
    }

 
    // Algorithm Settings
    // Algorithm Settings
    var searchWindowMonths: Int = 3
    var prioritizeEarlierDates: Bool = true
    var isRainCheckHardConstraint: Bool = true
    var projectionHorizonMonths: Int = 12
    var widgetTimeframe: String = "3 Months"
    var prioritizeSavingsGoal: Bool = true // New setting for savings goal priority

    init(name: String = "Your Name",
         targetSavings: Double = 0,
         rainCheckMin: Double = 0,
         startingBalance: Double = 0,
         profileImageData: Data? = nil,
         searchWindowMonths: Int = 3,
         prioritizeEarlierDates: Bool = true,
         isRainCheckHardConstraint: Bool = true,
         projectionHorizonMonths: Int = 12,

         widgetTimeframe: String = "3 Months",
         prioritizeSavingsGoal: Bool = true
    ) {
        self.name = name
        self.targetSavings = targetSavings
        self.rainCheckMin = rainCheckMin
        self.startingBalance = startingBalance
        self.profileImageData = profileImageData
        self.searchWindowMonths = searchWindowMonths
        self.prioritizeEarlierDates = prioritizeEarlierDates
        self.isRainCheckHardConstraint = isRainCheckHardConstraint
        self.projectionHorizonMonths = projectionHorizonMonths
        self.widgetTimeframe = widgetTimeframe
        self.prioritizeSavingsGoal = prioritizeSavingsGoal
    }
}
