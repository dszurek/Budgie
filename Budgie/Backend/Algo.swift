//
//  Algo.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/10/25.
//
import Foundation
import SwiftData // Assuming your models are SwiftData @Model classes

// MARK: - Data Structures (Mirrors or uses your existing SwiftData models)

// Assuming User.swift exists with:
// @Model class User {
//     var startingBalance: Double
//     var rainCheckMin: Double // Renamed from rainCheckBalance for consistency with your User model
//     // ... other properties
// }

// Assuming Income.swift exists with:
// @Model class Income {
//     var id: UUID = UUID()
//     var name: String
//     var amount: Double
//     var type: Frequency // Your existing enum: weekly, biweekly, monthly, yearly, intermittent
//     var startDate: Date
//     var endDate: Date?
//     var intermittentDates: [Date]?
//     // ... other properties like taxPercent
// }

// Assuming Expense.swift exists with:
// @Model class Expense {
//     var id: UUID = UUID()
//     var name: String
//     var cost: Double
//     var type: Frequency // Your existing enum
//     var startDate: Date
//     var endDate: Date?
//     var intermittentDates: [Date]?
//     // ... other properties
// }

// Assuming ShoppingListItem.swift exists with:
// @Model class ShoppingListItem {
//     var id: UUID = UUID()
//     var name: String
//     var price: Double
//     var purchaseByDate: Date // Renamed from desiredPurchaseByDate for consistency
//     var isPurchased: Bool? // Default to false if nil
//     var calculatedPurchaseDate: Date?
//     // ... other properties
// }

// MARK: - Recurrence Rule Definition (Simplified for now)
// This can be expanded later to support more complex rules.
struct RecurrenceRule {
    enum Frequency {
        case weekly, biWeekly, monthly, yearly, intermittent, once // Added 'once' for non-recurring
    }

    var frequency: Frequency
    var interval: Int = 1 // e.g., every 1 week, or every 2 months
    var dayOfWeek: Int? // 1 for Sunday, 2 for Monday, etc. (relevant for weekly/biweekly if more specific than start date)
    var dayOfMonth: Int? // 1-31 (relevant for monthly if more specific than start date)
    // Add more properties as needed for complex rules (e.g., specific months for yearly, Nth weekday)

    // Initializer to map from your existing Income/Expense Frequency
    init(frequency: Income.Frequency) { // Or Expense.Frequency
        switch frequency {
        case .weekly: self.frequency = .weekly
        case .biweekly: self.frequency = .biWeekly; self.interval = 2 // Bi-weekly is every 2 weeks
        case .monthly: self.frequency = .monthly
        case .yearly: self.frequency = .yearly
        case .intermittent: self.frequency = .intermittent
        }
    }
    init(frequency: Expense.Frequency) { // Or Expense.Frequency
        switch frequency {
        case .weekly: self.frequency = .weekly
        case .biweekly: self.frequency = .biWeekly; self.interval = 2 // Bi-weekly is every 2 weeks
        case .monthly: self.frequency = .monthly
        case .yearly: self.frequency = .yearly
        case .intermittent: self.frequency = .intermittent
        }
    }
}

// MARK: - Purchase Scheduler Algorithm
class PurchaseScheduler {

    // NOTE ON MONETARY VALUES:
    // This implementation uses Double for monetary values as per your models.
    // For production financial applications, consider using 'Decimal' to avoid
    // potential floating-point precision issues. This would require updating
    // your SwiftData models and this algorithm accordingly.

    private let calendar = Calendar.current

    // MARK: - Main Algorithm Function
    /// Calculates and updates the optimal purchase dates for shopping list items.
    /// - Parameters:
    ///   - user: The User object containing balance and settings.
    ///   - incomes: An array of Income objects.
    ///   - expenses: An array of Expense objects.
    ///   - shoppingListItems: An inout array of ShoppingListItem objects. Their `calculatedPurchaseDate` will be updated.
    ///   - projectionStartDate: The date to start the projection from (typically today).
    /// Calculates and updates the optimal purchase dates for shopping list items.
    /// - Parameters:
    ///   - user: The User object containing balance and settings.
    ///   - incomes: An array of Income objects.
    ///   - expenses: An array of Expense objects.
    ///   - shoppingListItems: An inout array of ShoppingListItem objects. Their `calculatedPurchaseDate` will be updated.
    ///   - projectionStartDate: The date to start the projection from (typically today).
    func calculateOptimalPurchaseDates(
        forUser user: User,
        incomes: [Income],
        expenses: [Expense],
        shoppingListItems: inout [ShoppingListItem], // Modifies items directly
        projectionStartDate: Date
    ) {
        // --- Phase A: Event Timeline Generation & Setup ---

        let effectiveProjectionEndDate = determineProjectionEndDate(
            forUser: user,
            incomes: incomes,
            expenses: expenses,
            shoppingListItems: shoppingListItems
        )

        var mandatoryEvents = generateMandatoryEventTimeline(
            incomes: incomes,
            expenses: expenses,
            projectionStart: projectionStartDate,
            projectionEnd: effectiveProjectionEndDate
        )
        mandatoryEvents.sort { $0.date < $1.date } // Ensure chronological order

        // Filter out already purchased items and sort pending ones
        var pendingShoppingItems = shoppingListItems.filter { !($0.isPurchased ?? false) }
        
        // Sort by desired date, then price
        pendingShoppingItems.sort {
            if $0.purchaseByDate != $1.purchaseByDate {
                return $0.purchaseByDate < $1.purchaseByDate
            }
            return $0.price < $1.price
        }
        
        // Reset calculated purchase dates
        for i in 0..<shoppingListItems.count {
            if !(shoppingListItems[i].isPurchased ?? false) {
                shoppingListItems[i].calculatedPurchaseDate = nil
                shoppingListItems[i].predictedBalanceAfterPurchase = nil
            }
        }

        // --- Phase B: Iterative Scheduling Logic with Search Window (OPTIMIZED) ---
        
        // Pre-calculate daily balances for the entire projection period
        var dailyBalances: [Date: Double] = [:]
        let currentBalance = user.currentBalance
        var currentDate = user.lastCheckpointDate == Date.distantPast ? projectionStartDate : user.lastCheckpointDate
        
        // Fast-forward to projection start if needed
        // CRITICAL FIX: Ensure we start from "Now" (Date()) to avoid double counting past events of today
        // if the user has already updated their balance manually.
        let now = Date()
        if currentDate < now {
            currentDate = now
        }
        
        // Determine if we should ignore today's events
        // If the last checkpoint was made TODAY (or later), then the user's balance is the "hard truth" for today.
        // Any income/expense scheduled for today (which defaults to 12:00 AM) should be ignored.
        let lastCheckpoint = user.lastCheckpointDate
        let isBalanceFresh = calendar.isDateInToday(lastCheckpoint) || lastCheckpoint > now
        
        var eventIndex = 0
        // Fast forward event index
        while eventIndex < mandatoryEvents.count {
            let eventDate = mandatoryEvents[eventIndex].date
            
            // If balance is fresh (updated today), we skip events that are strictly BEFORE now (which includes today's 12:00 AM events)
            // OR if the event is strictly today.
            if isBalanceFresh && calendar.isDateInToday(eventDate) {
                eventIndex += 1
                continue
            }
            
            if eventDate < currentDate {
                eventIndex += 1
            } else {
                break
            }
        }
        
        // Generate daily base balances (without shopping items)
        var tempDate = currentDate
        var tempBalance = currentBalance
        var tempEventIndex = eventIndex
        
        while tempDate <= effectiveProjectionEndDate {
            let startOfTempDate = calendar.startOfDay(for: tempDate)
            
            while tempEventIndex < mandatoryEvents.count &&
                  calendar.startOfDay(for: mandatoryEvents[tempEventIndex].date) == startOfTempDate {
                
                let eventDate = mandatoryEvents[tempEventIndex].date
                let isEventToday = calendar.isDateInToday(eventDate)
                
                // CRITICAL FIX:
                // 1. If event is strictly in the past (< now), skip it.
                // 2. OR, if the event is TODAY and our balance is "Fresh" (updated today), skip it.
                //    This treats the current balance as the "hard truth" for today.
                if eventDate < now || (isEventToday && isBalanceFresh) {
                    // Skip this event as it's already accounted for in the current balance
                    // print("  ⏭️ Skipping event: \(mandatoryEvents[tempEventIndex].title) (Already in balance)")
                } else {
                    tempBalance += mandatoryEvents[tempEventIndex].amount
                }
                tempEventIndex += 1
            }
            dailyBalances[startOfTempDate] = tempBalance
            
            guard let next = calendar.date(byAdding: .day, value: 1, to: tempDate) else { break }
            tempDate = next
        }
        
        // CRITICAL OPTIMIZATION: Pre-calculate minimum future balance for each day
        // This eliminates the O(N) scan per candidate date
        var minFutureBalance: [Date: Double] = [:]
        // Initialize with the final balance from the forward loop, which is a safe default for the end of projection
        var currentFinalBalance = tempBalance
        var minSoFar = currentFinalBalance
        
        print("🗓️ Effective Projection End Date: \(effectiveProjectionEndDate.formatted(date: .complete, time: .complete))")
        print("💰 Final Projected Balance: $\(tempBalance)")
        
        // Walk backwards from end to start
        var reverseDate = effectiveProjectionEndDate
        while reverseDate >= currentDate {
            let startOfReverseDate = calendar.startOfDay(for: reverseDate)
            
            // If dailyBalance is missing (e.g. end date alignment issue), use minSoFar (which starts as tempBalance)
            let balance = dailyBalances[startOfReverseDate] ?? minSoFar
            
            if balance < minSoFar {
                minSoFar = balance
                // Only log significant drops or low values
                if minSoFar < 100 {
                    print("📉 Low Future Balance detected: $\(minSoFar) on \(startOfReverseDate.formatted(.dateTime.month().day().year()))")
                }
            }
            minFutureBalance[startOfReverseDate] = minSoFar
            
            guard let prev = calendar.date(byAdding: .day, value: -1, to: reverseDate) else { break }
            reverseDate = prev
        }
        print("✅ Initial MinFutureBalance calculation complete. End Date: \(effectiveProjectionEndDate.formatted(.dateTime.month().day().year()))")
        
        // Determine effective rain check minimum
        // If user has disabled hard rain check, use 0 as minimum
        // Otherwise use their specified rainCheckMin (but never go below 0)
        let effectiveRainCheck = user.isRainCheckHardConstraint ? max(user.rainCheckMin, 0) : 0
        // print("🧮 Algorithm Parameters:")
        // print("   - effectiveRainCheck: $\(effectiveRainCheck)")
        // print("   - searchWindowMonths: \(user.searchWindowMonths)")
        // print("   - Pending items: \(pendingShoppingItems.count)")
        
        // Now schedule items
        // print("\n🛍️ Scheduling \(pendingShoppingItems.count) items...")
        for item in pendingShoppingItems {
            // print("\n  Item: '\(item.name)' - $\(item.price)")
            var desiredDate = calendar.startOfDay(for: item.purchaseByDate)
            
            // Handle past desired dates - move to today
            let today = calendar.startOfDay(for: Date())
            if desiredDate < today {
                // print("  ⚠️ Desired date is in the past, adjusting to today")
                desiredDate = today
            }
            
            // print("  Desired date: \(desiredDate.formatted(.dateTime.month().day().year()))")
            let windowMonths = user.searchWindowMonths
            
            // Define Search Window
            let windowStart = calendar.date(byAdding: .month, value: -windowMonths, to: desiredDate) ?? desiredDate
            let windowEnd = calendar.date(byAdding: .month, value: windowMonths, to: desiredDate) ?? desiredDate
            
            // Clamp window to projection range
            let searchStart = max(windowStart, projectionStartDate)
            let searchEnd = min(windowEnd, effectiveProjectionEndDate)
            // print("  Search window: \(searchStart.formatted(.dateTime.month().day())) to \(searchEnd.formatted(.dateTime.month().day()))")
            // print("  Days to check: \(calendar.dateComponents([.day], from: searchStart, to: searchEnd).day ?? 0)")
            
            var bestDate: Date?
            var bestScore: Double = -Double.infinity
            var rejectionReasons: [String] = []
            var datesChecked = 0
            
            // Iterate through search window
            // Helper to check a date range
            func checkRange(start: Date, end: Date) {
                var checkDate = start
                while checkDate <= end {
                    datesChecked += 1
                    let startOfCheckDate = calendar.startOfDay(for: checkDate)
                    
                    let baseBalance = dailyBalances[startOfCheckDate] ?? 0
                    let minFuture = minFutureBalance[startOfCheckDate] ?? baseBalance
                    
                    var isSafe = true
                    var rejectionReason = ""
                    
                    if (baseBalance - item.price) < effectiveRainCheck {
                        isSafe = false
                        rejectionReason = "Projected balance on \(startOfCheckDate.formatted(.dateTime.month().day())) ($\(String(format: "%.0f", baseBalance))) is insufficient. Needs $\(String(format: "%.0f", effectiveRainCheck + item.price)) (Item $\(String(format: "%.0f", item.price)) + Rain Check $\(String(format: "%.0f", effectiveRainCheck)))"
                    } else if (minFuture - item.price) < effectiveRainCheck {
                        isSafe = false
                        rejectionReason = "Future shortfall: Future min $\(String(format: "%.0f", minFuture)) drops below Rain Check after purchase"
                    }
                    
                    if !isSafe {
                        // Keep the first few reasons for debugging/display
                        if rejectionReasons.count < 3 {
                            rejectionReasons.append("\(startOfCheckDate.formatted(.dateTime.month().day())): \(rejectionReason)")
                        }
                        // Always track the last reason to show the user "how far we looked"
                        // lastRejectionReason = reason // Removed unused assignment
                    }
                    
                    if isSafe {
                        // Calculate Score
                        var score: Double = 0
                        
                        // A. Distance Score (Penalty for being far from desired date)
                        let daysDiff = abs(calendar.dateComponents([.day], from: desiredDate, to: startOfCheckDate).day ?? 0)
                        // Use a larger denominator for the extended search to avoid huge penalties
                        let maxDays = Double(windowMonths * 30)
                        let distanceScore = max(0, 100 * (1 - Double(daysDiff) / (maxDays * 2))) 
                        score += distanceScore
                        
                        // B. Savings Goal Score (Soft Constraint & Proximity Bonus)
                        // Only apply strong bonus if user prioritizes savings goal
                        if user.prioritizeSavingsGoal {
                            if baseBalance - item.price >= user.targetSavings {
                                score += 50 // Bonus for keeping above savings goal
                                
                                // Proximity Bonus: Higher score if we are close to the target (e.g. within 10% above)
                                // This encourages spending "excess" funds rather than hoarding far above the goal
                                let surplus = (baseBalance - item.price) - user.targetSavings
                                let target10Percent = max(user.targetSavings * 0.10, 100) // At least $100 range
                                
                                if surplus <= target10Percent {
                                    // We are in the "sweet spot" just above the target
                                    score += 50
                                }
                            }
                        } else {
                            // If not prioritized, give a much smaller bonus just for being positive/healthy
                            // but don't heavily penalize dipping into savings (unless hard constraint is on)
                            if baseBalance - item.price >= user.targetSavings {
                                score += 10 // Small bonus
                            }
                        }
                        
                        // C. Prioritize Earlier Dates
                        if user.prioritizeEarlierDates {
                            if checkDate < desiredDate {
                                // SIGNIFICANTLY increased weight for earlier dates
                                // We want to find the *earliest* safe date.
                                // Score based on how many days early it is.
                                let daysEarly = calendar.dateComponents([.day], from: checkDate, to: desiredDate).day ?? 0
                                // Cap the bonus to avoid overflowing logic, but make it very strong (e.g. 5 points per day)
                                score += Double(max(0, daysEarly)) * 5.0
                                score += 100 // Flat bonus for being early at all
                            }
                        }
                        
                        if score > bestScore {
                            bestScore = score
                            bestDate = startOfCheckDate
                        }
                    }
                    
                    guard let next = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
                    checkDate = next
                }
            }
            
            // 1. Primary Search: Within Window
            checkRange(start: searchStart, end: searchEnd)
            
            // 2. Secondary Search: Extended Range (if no date found)
            if bestDate == nil {
                print("  ⚠️ No date found in window, extending search to full projection...")
                // Search forward from window end
                if let nextStart = calendar.date(byAdding: .day, value: 1, to: searchEnd), nextStart <= effectiveProjectionEndDate {
                     checkRange(start: nextStart, end: effectiveProjectionEndDate)
                }
                // Search backward from window start (if valid)
                if let prevEnd = calendar.date(byAdding: .day, value: -1, to: searchStart), prevEnd >= projectionStartDate {
                    checkRange(start: projectionStartDate, end: prevEnd)
                }
            }
            
            // Schedule if found
            if let date = bestDate {
                print("  ✅ Found optimal date: \(date.formatted(.dateTime.month().day().year())) with score: \(bestScore)")
                if let originalIndex = shoppingListItems.firstIndex(where: { $0.id == item.id }) {
                    shoppingListItems[originalIndex].calculatedPurchaseDate = date
                    shoppingListItems[originalIndex].calculationError = nil // Clear error
                    
                    // Calculate predicted balance after purchase
                    let startOfDate = calendar.startOfDay(for: date)
                    if let balanceBefore = dailyBalances[startOfDate] {
                        shoppingListItems[originalIndex].predictedBalanceAfterPurchase = balanceBefore - item.price
                    }
                }
                
                // Update dailyBalances AND minFutureBalance for all future dates
                var updateDate = date
                while updateDate <= effectiveProjectionEndDate {
                    let startOfUpdateDate = calendar.startOfDay(for: updateDate)
                    if let current = dailyBalances[startOfUpdateDate] {
                        dailyBalances[startOfUpdateDate] = current - item.price
                    }
                    guard let next = calendar.date(byAdding: .day, value: 1, to: updateDate) else { break }
                    updateDate = next
                }
                
                // Update the tracked final balance
                currentFinalBalance -= item.price
                
                // Recalculate minFutureBalance from end of projection back to START of projection
                // This ensures that a purchase in the future (e.g. Dec 12) correctly lowers the minFutureBalance for earlier dates (e.g. Dec 10)
                reverseDate = effectiveProjectionEndDate
                // Initialize with the final balance (tempBalance logic) to be safe
                // We can re-use the logic from the initial pass:
                // Find the balance of the last day.
                // Find the balance of the last day.
                let lastDayStart = calendar.startOfDay(for: effectiveProjectionEndDate)
                // Use currentFinalBalance as the source of truth for the end of the timeline
                minSoFar = dailyBalances[lastDayStart] ?? currentFinalBalance
                
                while reverseDate >= projectionStartDate {
                    let startOfReverseDate = calendar.startOfDay(for: reverseDate)
                    let balance = dailyBalances[startOfReverseDate] ?? minSoFar
                    if balance < minSoFar {
                        minSoFar = balance
                    }
                    minFutureBalance[startOfReverseDate] = minSoFar
                    
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: reverseDate) else { break }
                    reverseDate = prev
                }
            } else {
                // print("  ❌ No valid date found for '\(item.name)'")
                // print("  Checked \(datesChecked) dates. Sample rejections:")
                // for reason in rejectionReasons.prefix(5) {
                //    print("     - \(reason)")
                // }
                
                // Set error on item
                if let originalIndex = shoppingListItems.firstIndex(where: { $0.id == item.id }) {
                    shoppingListItems[originalIndex].calculatedPurchaseDate = nil
                }
            }
        }
        print("\n✅ Algorithm complete\n")
    }


    // MARK: - Helper Functions

    func determineProjectionEndDate(
        forUser user: User,
        incomes: [Income],
        expenses: [Expense],
        shoppingListItems: [ShoppingListItem]
    ) -> Date {
        var maxDate = Date.distantPast

        incomes.forEach { income in
            if let endDate = income.endDate, endDate > maxDate {
                maxDate = endDate
            }
        }
        expenses.forEach { expense in
            if let endDate = expense.endDate, endDate > maxDate {
                maxDate = endDate
            }
        }
        shoppingListItems.forEach { item in
            if item.purchaseByDate > maxDate {
                maxDate = item.purchaseByDate
            }
        }

        // If no specific end dates are found, project at least a year from now.
        // Otherwise, add a 6-month buffer.
        let defaultProjection = calendar.date(byAdding: .month, value: user.projectionHorizonMonths, to: Date())!
        if maxDate == Date.distantPast {
            maxDate = defaultProjection
        } else {
            // Ensure we project AT LEAST as far as the user wants, or further if items exist
            let calculatedEnd = calendar.date(byAdding: .month, value: 6, to: maxDate) ?? defaultProjection
            maxDate = max(calculatedEnd, defaultProjection)
        }
        return maxDate
    }

    // MARK: - Public Helper for Timeline Visualization
    
    /// Generates a combined timeline of mandatory events (income/expense) and scheduled purchases.
    /// Useful for visualizing the financial future in the app.
    func getFullProjectionTimeline(
        forUser user: User,
        incomes: [Income],
        expenses: [Expense],
        shoppingListItems: [ShoppingListItem],
        projectionStartDate: Date
    ) -> [DatedFinancialEvent] {
        let effectiveProjectionEndDate = determineProjectionEndDate(
            forUser: user,
            incomes: incomes,
            expenses: expenses,
            shoppingListItems: shoppingListItems
        )
        
        // 1. Get mandatory events
        var events = generateMandatoryEventTimeline(
            incomes: incomes,
            expenses: expenses,
            projectionStart: projectionStartDate,
            projectionEnd: effectiveProjectionEndDate
        )
        
        // 2. Add scheduled purchases
        for item in shoppingListItems {
            if let purchaseDate = item.calculatedPurchaseDate {
                // Ensure we don't show purchased items unless you want history (here we focus on future/planned)
                if !(item.isPurchased ?? false) {
                    events.append(DatedFinancialEvent(
                        date: purchaseDate,
                        amount: -item.price,
                        type: .purchase, 
                        title: item.name,
                        originalItem: item
                    ))
                }
            }
        }
        
        // 3. Sort chronologically
        events.sort { $0.date < $1.date }
        
        return events
    }

    func generateMandatoryEventTimeline(
        incomes: [Income],
        expenses: [Expense],
        projectionStart: Date,
        projectionEnd: Date
    ) -> [DatedFinancialEvent] {
        var events: [DatedFinancialEvent] = []

        for income in incomes {
            let incomeRule = RecurrenceRule(frequency: income.type) // Map to our RecurrenceRule
            let netIncomeAmount = income.amount * (1 - (income.taxPercent / 100.0)) // Consider net after tax

            events.append(contentsOf: generateEvents(
                sourceId: income.id,
                title: income.name,
                amount: netIncomeAmount,
                recurrenceRule: incomeRule,
                itemStartDate: income.startDate,
                itemEndDate: income.endDate,
                intermittentDates: income.intermittentDates,
                eventType: .income,
                projectionStart: projectionStart,
                projectionEnd: projectionEnd
            ))
        }

        for expense in expenses {
            let expenseRule = RecurrenceRule(frequency: expense.type)
            events.append(contentsOf: generateEvents(
                sourceId: expense.id,
                title: expense.name,
                amount: -expense.cost, // Expenses are negative amounts
                recurrenceRule: expenseRule,
                itemStartDate: expense.startDate,
                itemEndDate: expense.endDate,
                intermittentDates: expense.intermittentDates,
                eventType: .expense,
                projectionStart: projectionStart,
                projectionEnd: projectionEnd
            ))
        }
        return events
    }

    /// Generates specific date occurrences for a single recurring item.
    /// TODO: Enhance this function for more complex recurrence rules (e.g., "1st of month", "Nth weekday").
    func generateEvents(
        sourceId: UUID,
        title: String,
        amount: Double,
        recurrenceRule: RecurrenceRule,
        itemStartDate: Date,
        itemEndDate: Date?,
        intermittentDates: [IntermittentDate]?,
        eventType: DatedFinancialEvent.In_Ex,
        projectionStart: Date,
        projectionEnd: Date
    ) -> [DatedFinancialEvent] {
        var occurrences: [DatedFinancialEvent] = []
        let startOfProjection = calendar.startOfDay(for: projectionStart)
        let endOfProjection = calendar.startOfDay(for: projectionEnd)
        let startOfItem = calendar.startOfDay(for: itemStartDate)
        let endOfItem = itemEndDate != nil ? calendar.startOfDay(for: itemEndDate!) : nil

        if recurrenceRule.frequency == .intermittent {
            if let dates = intermittentDates {
                for dateObj in dates {
                    let startOfDate = calendar.startOfDay(for: dateObj.date)
                    if startOfDate >= startOfProjection && startOfDate <= endOfProjection &&
                       startOfDate >= startOfItem && (endOfItem == nil || startOfDate <= endOfItem!) {
                        occurrences.append(DatedFinancialEvent(date: startOfDate, amount: amount, type: eventType, title: title))
                    }
                }
            }
            return occurrences
        }
        
        if recurrenceRule.frequency == .once { // Handle 'once' frequency
             if startOfItem >= startOfProjection && startOfItem <= endOfProjection &&
                 (endOfItem == nil || startOfItem <= endOfItem!) {
                 occurrences.append(DatedFinancialEvent(date: startOfItem, amount: amount, type: eventType, title: title))
             }
             return occurrences
         }


        var currentDate = startOfItem
        var iterations = 0
        let maxIterations = 10000 // Safety break
        
        while currentDate <= endOfProjection && (endOfItem == nil || currentDate <= endOfItem!) {
            iterations += 1
            if iterations > maxIterations {
                print("⚠️ Algo Safety Break: Exceeded max iterations for \(title)")
                break
            }
            
            if currentDate >= startOfProjection { // Only add events within the projection window
                occurrences.append(DatedFinancialEvent(date: currentDate, amount: amount, type: eventType, title: title))
            }

            // Advance currentDate based on frequency and interval
            var nextDate: Date?
            let safeInterval = max(1, recurrenceRule.interval) // Ensure interval is at least 1
            
            switch recurrenceRule.frequency {
            case .weekly:
                nextDate = calendar.date(byAdding: .weekOfYear, value: safeInterval, to: currentDate)
            case .biWeekly: // This is handled by interval = 2 with .weekly
                 nextDate = calendar.date(byAdding: .weekOfYear, value: 2, to: currentDate) // Explicit for clarity
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: safeInterval, to: currentDate)
            case .yearly:
                nextDate = calendar.date(byAdding: .year, value: safeInterval, to: currentDate)
            case .intermittent, .once: // Should have been handled above
                break
            }
            
            guard let next = nextDate, next > currentDate else {
                print("⚠️ Algo Safety Break: Date failed to advance for \(title)")
                break
            }
            currentDate = next
        }
        return occurrences
    }



}


