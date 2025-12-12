//
//  Algo.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/10/25.
//
import Foundation
import SwiftData // Assuming your models are SwiftData @Model classes

// MARK: - Data Structures (Mirrors or uses your existing SwiftData models)


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
        // --- Setup & Pre-calculations ---
        let startOfProjection = calendar.startOfDay(for: projectionStartDate)
        let effectiveProjectionEndDate = determineProjectionEndDate(
            forUser: user,
            incomes: incomes,
            expenses: expenses,
            shoppingListItems: shoppingListItems
        )
        let endOfProjection = calendar.startOfDay(for: effectiveProjectionEndDate)
        
        // Calculate total days for array sizing
        let totalDays = calendar.dateComponents([.day], from: startOfProjection, to: endOfProjection).day ?? 365
        let safeTotalDays = max(totalDays + 1, 1) // Ensure at least 1
        
        // --- Phase A: Event Timeline Direct Array Population ---
        
        // dailyChanges[i] = Net income/expense change on day i
        var dailyChanges = Array(repeating: 0.0, count: safeTotalDays)
        
        let mandatoryEvents = generateMandatoryEventTimeline(
            incomes: incomes,
            expenses: expenses,
            projectionStart: startOfProjection,
            projectionEnd: endOfProjection
        )
        
        let now = Date()
        let lastCheckpoint = user.lastCheckpointDate
        let isBalanceFresh = calendar.isDateInToday(lastCheckpoint) || lastCheckpoint > now
        
        for event in mandatoryEvents {
            let eventStart = calendar.startOfDay(for: event.date)
            // Skip events that are effectively already in the balance
            let isEventToday = calendar.isDateInToday(eventStart)
            if event.date < now || (isEventToday && isBalanceFresh) {
                continue
            }
            
            if let dayIndex = calendar.dateComponents([.day], from: startOfProjection, to: eventStart).day,
               dayIndex >= 0, dayIndex < safeTotalDays {
                dailyChanges[dayIndex] += event.amount
            }
        }
        
        // --- Calculate Daily Balances Array ---
        // dailyBalances[i] = End of day balance for day i
        var dailyBalances = Array(repeating: 0.0, count: safeTotalDays)
        
        // Determine where we start applying changes
        let trackingStartDate = (user.lastCheckpointDate == Date.distantPast ? startOfProjection : user.lastCheckpointDate)
        let effectiveStart = trackingStartDate < now ? now : trackingStartDate
        let startOfEffective = calendar.startOfDay(for: effectiveStart)
        
        let effectiveStartIndex = max(0, calendar.dateComponents([.day], from: startOfProjection, to: startOfEffective).day ?? 0)
        
        var currentRunningBalance = user.currentBalance
        
        for i in 0..<safeTotalDays {
            if i >= effectiveStartIndex {
                currentRunningBalance += dailyChanges[i]
            }
            dailyBalances[i] = currentRunningBalance
        }
        
        // --- Min Future Balance Array ---
        // minFutureBalance[i] = min(dailyBalances[k]) for all k >= i
        var minFutureBalance = Array(repeating: dailyBalances.last ?? 0.0, count: safeTotalDays)
        var minSoFar = dailyBalances.last ?? 0.0
        
        for i in (0..<safeTotalDays).reversed() {
            let bal = dailyBalances[i]
            if bal < minSoFar {
                minSoFar = bal
            }
            minFutureBalance[i] = minSoFar
        }
        
        print("🗓️ Effective Projection End Date: \(endOfProjection.formatted(date: .complete, time: .complete))")
        print("💰 Final Projected Balance: $\(currentRunningBalance)")
        
        // --- Phase B: Iterative Scheduling Logic with Array Indexing ---
        
        var pendingShoppingItems = shoppingListItems.filter { !($0.isPurchased ?? false) }
        
        // Sort
        pendingShoppingItems.sort {
            if $0.purchaseByDate != $1.purchaseByDate {
                return $0.purchaseByDate < $1.purchaseByDate
            }
            return $0.price < $1.price
        }
        
        // Reset calculated fields
        for i in 0..<shoppingListItems.count {
            if !(shoppingListItems[i].isPurchased ?? false) {
                shoppingListItems[i].calculatedPurchaseDate = nil
                shoppingListItems[i].predictedBalanceAfterPurchase = nil
            }
        }
        
        let effectiveRainCheck = user.isRainCheckHardConstraint ? max(user.rainCheckMin, 0) : 0
        let windowDays = user.searchWindowMonths * 30
        let today = calendar.startOfDay(for: Date())
        
        for item in pendingShoppingItems {
            let desiredDateRaw = item.purchaseByDate
            let desiredStart = calendar.startOfDay(for: desiredDateRaw)
            
            // Handle past desired dates - move to today
            let effectiveDesiredDate = desiredStart < today ? today : desiredStart
            
            // Map to index
            guard let desiredIndex = calendar.dateComponents([.day], from: startOfProjection, to: effectiveDesiredDate).day else { continue }
            
            // Ensure within bounds (unlikely to fail if projection calculated correctly but stay safe)
            let clampedDesiredIndex = min(max(0, desiredIndex), safeTotalDays - 1)
            
            // Search Window Indices
            let searchStartIndex = max(0, clampedDesiredIndex - windowDays)
            let searchEndIndex = min(safeTotalDays - 1, clampedDesiredIndex + windowDays)
            
            var bestIndex: Int?
            var bestScore: Double = -Double.infinity
            
            // Helper to check range
            func checkIndexRange(start: Int, end: Int) {
                guard start <= end else { return }
                
                for i in start...end {
                    let base = dailyBalances[i]
                    let minFut = minFutureBalance[i]
                    
                    if (base - item.price) >= effectiveRainCheck && (minFut - item.price) >= effectiveRainCheck {
                        // Safe to buy
                        var score: Double = 0
                        
                        // A. Distance Score
                        let dist = abs(i - clampedDesiredIndex)
                        let maxDist = Double(windowDays * 2)
                        // Normalize dist calculation
                        let distScore = max(0, 100 * (1 - Double(dist) / (maxDist + 1)))
                        score += distScore
                        
                        // B. Savings Goal
                        if user.prioritizeSavingsGoal {
                            if (base - item.price) >= user.targetSavings {
                                score += 50
                                let surplus = (base - item.price) - user.targetSavings
                                if surplus <= max(user.targetSavings * 0.10, 100) {
                                    score += 50
                                }
                            }
                        } else {
                            if (base - item.price) >= user.targetSavings {
                                score += 10
                            }
                        }
                        
                        // C. Earlier Dates
                        if user.prioritizeEarlierDates {
                            if i < clampedDesiredIndex {
                                let daysEarly = clampedDesiredIndex - i
                                score += Double(daysEarly) * 5.0
                                score += 100
                            }
                        }
                        
                        if score > bestScore {
                            bestScore = score
                            bestIndex = i
                        }
                    }
                }
            }
            
            // 1. Primary Search
            checkIndexRange(start: searchStartIndex, end: searchEndIndex)
            
            // 2. Secondary Search (Extended)
            if bestIndex == nil {
                // Forward
                if searchEndIndex + 1 < safeTotalDays {
                    checkIndexRange(start: searchEndIndex + 1, end: safeTotalDays - 1)
                }
                // Backward
                if bestIndex == nil && searchStartIndex - 1 >= 0 {
                    checkIndexRange(start: 0, end: searchStartIndex - 1)
                }
            }
            
            // Schedule if found
            if let index = bestIndex {
                // Update Item
                if let originalIndex = shoppingListItems.firstIndex(where: { $0.id == item.id }) {
                    let date = calendar.date(byAdding: .day, value: index, to: startOfProjection)!
                    shoppingListItems[originalIndex].calculatedPurchaseDate = date
                    shoppingListItems[originalIndex].calculationError = nil
                    shoppingListItems[originalIndex].predictedBalanceAfterPurchase = dailyBalances[index] - item.price
                }
                
                // Update Arrays - FAST
                let price = item.price
                
                // Update futures (daily balance decreases for all subsequent days)
                for i in index..<safeTotalDays {
                    dailyBalances[i] -= price
                    minFutureBalance[i] -= price
                }
                
                // Back-propagate min future impact
                // Since minFuture[i] = min(daily[i], minFuture[i+1])
                // We just lowered everything >= index.
                // We need to check if minFutureBalance[index] (NEW) becomes the new min for predecessors.
                if index > 0 {
                    // Back-propagate impact
                    for i in (0..<index).reversed() {
                        let bal = dailyBalances[i]
                        // Logic: minFuture[i] is min(bal, minFuture[i+1])
                        // We compare against the (potentially lowered) neighbor.
                        let neighborMin = minFutureBalance[i+1] // We just updated this or it's from loop above
                        
                        // But wait, accessing i+1 in loop is safe because we go reversed.
                        // Optimization:
                        // minFuture[i] = min(bal, minFuture[i+1])
                        // But we can just propagate the specific change?
                        // Using the standard min definition is robust.
                        minFutureBalance[i] = min(bal, neighborMin)
                    }
                }
                
            } else {
                if let originalIndex = shoppingListItems.firstIndex(where: { $0.id == item.id }) {
                    shoppingListItems[originalIndex].calculatedPurchaseDate = nil
                    // More specific error message could be derived but keeping it simple for perf
                    shoppingListItems[originalIndex].calculationError = "Insufficient funds/buffers within projection"
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


