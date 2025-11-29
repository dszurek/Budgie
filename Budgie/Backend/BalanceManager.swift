//
//  BalanceManager.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/28/25.
//

import Foundation
import SwiftData

class BalanceManager {
    static let shared = BalanceManager()
    private let calendar = Calendar.current
    
    /// Updates the user's balance based on events that have passed since the last update.
    /// Returns a message describing the update, or nil if no update occurred.
    @MainActor
    func updateBalanceForPassedEvents(user: User, modelContext: ModelContext) -> String? {
        let now = Date()
        let lastUpdate = user.lastAutoUpdateDate
        
        // Only update if it's been at least a day or if we are debugging (for now, let's just check if dates are different days)
        if calendar.isDate(lastUpdate, inSameDayAs: now) {
            // Already updated today? Maybe we still want to check for missed events if the user opened the app later in the day?
            // For simplicity, let's just check if 'now' is after 'lastUpdate' by some margin, or just proceed.
            // Let's proceed but ensure we don't double count.
        }
        
        // We need to fetch all events.
        // Since we don't have direct access to the Query results here, we might need to fetch them using the context.
        // However, fetching everything might be heavy.
        // Ideally, we pass the arrays in. But for a global manager, fetching is safer.
        
        var netChange: Double = 0
        var eventsProcessed = 0
        
        do {
            // 1. Incomes
            let incomeDescriptor = FetchDescriptor<Income>()
            let incomes = try modelContext.fetch(incomeDescriptor)
            
            for income in incomes {
                let rule = RecurrenceRule(frequency: income.type)
                let netAmount = income.amount * (1 - (income.taxPercent / 100.0))
                
                // Generate events between lastUpdate and now
                // We use a helper similar to Algo's generateEvents but strictly for the past window
                let occurrences = generatePastEvents(
                    title: income.name,
                    amount: netAmount,
                    recurrenceRule: rule,
                    itemStartDate: income.startDate,
                    itemEndDate: income.endDate,
                    intermittentDates: income.intermittentDates,
                    windowStart: lastUpdate,
                    windowEnd: now
                )
                
                for _ in occurrences {
                    netChange += netAmount
                    eventsProcessed += 1
                }
            }
            
            // 2. Expenses
            let expenseDescriptor = FetchDescriptor<Expense>()
            let expenses = try modelContext.fetch(expenseDescriptor)
            
            for expense in expenses {
                let rule = RecurrenceRule(frequency: expense.type)
                let amount = -expense.cost
                
                let occurrences = generatePastEvents(
                    title: expense.name,
                    amount: amount,
                    recurrenceRule: rule,
                    itemStartDate: expense.startDate,
                    itemEndDate: expense.endDate,
                    intermittentDates: expense.intermittentDates,
                    windowStart: lastUpdate,
                    windowEnd: now
                )
                
                for _ in occurrences {
                    netChange += amount
                    eventsProcessed += 1
                }
            }
            
            // 3. Shopping Items (Purchases)
            // For shopping items, we only care if they were marked as purchased *automatically* or if we are simulating that.
            // BUT, the user requirement says: "If they have an income... listed balance should update".
            // For shopping items, usually the user marks them as purchased manually.
            // If we auto-deduct based on 'purchaseByDate', that might be wrong if they didn't buy it.
            // So we will SKIP shopping items for auto-updates unless they are explicitly marked "Auto-Buy" (which we don't have).
            // We will rely on the "Mark as Purchased" UI for shopping items.
            
        } catch {
            print("❌ BalanceManager: Failed to fetch data: \(error)")
            return nil
        }
        
        if eventsProcessed > 0 && abs(netChange) > 0.01 {
            // Apply update
            let newBalance = user.currentBalance + netChange
            
            // Create a checkpoint
            let checkpoint = BalanceCheckpoint(date: now, amount: newBalance)
            user.balanceCheckpoints.append(checkpoint)
            modelContext.insert(checkpoint)
            
            // Update timestamp
            user.lastAutoUpdateDate = now
            
            // Save
            try? modelContext.save()
            
            let formattedChange = netChange >= 0 ? "+\(String(format: "%.2f", netChange))" : "\(String(format: "%.2f", netChange))"
            return "Balance automatically updated: \(formattedChange) (\(eventsProcessed) events)"
        }
        
        // Even if no change, update the timestamp so we don't check this window again unnecessarily
        user.lastAutoUpdateDate = now
        try? modelContext.save()
        
        return nil
    }
    
    // Helper to generate events strictly within a past window
    // Window is (lastUpdate, now]
    private func generatePastEvents(
        title: String,
        amount: Double,
        recurrenceRule: RecurrenceRule,
        itemStartDate: Date,
        itemEndDate: Date?,
        intermittentDates: [IntermittentDate]?,
        windowStart: Date,
        windowEnd: Date
    ) -> [Date] {
        var eventDates: [Date] = []
        
        // We need to find occurrences that happened strictly AFTER windowStart and BEFORE or ON windowEnd.
        // Logic is similar to Algo but we filter differently.
        
        // Optimization: If item started after windowEnd, skip
        if itemStartDate > windowEnd { return [] }
        
        // Optimization: If item ended before windowStart, skip
        if let end = itemEndDate, end < windowStart { return [] }
        
        if recurrenceRule.frequency == .intermittent {
            if let dates = intermittentDates {
                for dateObj in dates {
                    let startOfDate = calendar.startOfDay(for: dateObj.date)
                    // Check if this specific date falls in the window
                    // We compare start of days to be safe, or exact times?
                    // User requirement implies "when tomorrow comes".
                    // Let's use start of day logic.
                    if startOfDate > calendar.startOfDay(for: windowStart) && startOfDate <= calendar.startOfDay(for: windowEnd) {
                         eventDates.append(startOfDate)
                    }
                }
            }
            return eventDates
        }
        
        if recurrenceRule.frequency == .once {
            let startOfItem = calendar.startOfDay(for: itemStartDate)
             if startOfItem > calendar.startOfDay(for: windowStart) && startOfItem <= calendar.startOfDay(for: windowEnd) {
                 eventDates.append(startOfItem)
             }
             return eventDates
        }
        
        // Recurring
        var currentDate = calendar.startOfDay(for: itemStartDate)
        let endOfWindow = calendar.startOfDay(for: windowEnd)
        let startOfWindow = calendar.startOfDay(for: windowStart)
        
        // Fast forward to window start
        // This is a naive fast forward, could be optimized math-wise but loop is fine for personal finance scale
        while currentDate <= startOfWindow {
             var nextDate: Date?
             let safeInterval = max(1, recurrenceRule.interval)
             switch recurrenceRule.frequency {
             case .weekly: nextDate = calendar.date(byAdding: .weekOfYear, value: safeInterval, to: currentDate)
             case .biWeekly: nextDate = calendar.date(byAdding: .weekOfYear, value: 2, to: currentDate)
             case .monthly: nextDate = calendar.date(byAdding: .month, value: safeInterval, to: currentDate)
             case .yearly: nextDate = calendar.date(byAdding: .year, value: safeInterval, to: currentDate)
             default: break
             }
             guard let next = nextDate else { break }
             currentDate = next
        }
        
        // Now collect events in window
        while currentDate <= endOfWindow && (itemEndDate == nil || currentDate <= (itemEndDate ?? Date.distantFuture)) {
            if currentDate > startOfWindow {
                eventDates.append(currentDate)
            }
            
            var nextDate: Date?
            let safeInterval = max(1, recurrenceRule.interval)
            switch recurrenceRule.frequency {
            case .weekly: nextDate = calendar.date(byAdding: .weekOfYear, value: safeInterval, to: currentDate)
            case .biWeekly: nextDate = calendar.date(byAdding: .weekOfYear, value: 2, to: currentDate)
            case .monthly: nextDate = calendar.date(byAdding: .month, value: safeInterval, to: currentDate)
            case .yearly: nextDate = calendar.date(byAdding: .year, value: safeInterval, to: currentDate)
            default: break
            }
            guard let next = nextDate, next > currentDate else { break }
            currentDate = next
        }
        
        return eventDates
    }
}
