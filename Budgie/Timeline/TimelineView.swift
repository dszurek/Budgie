//
//  TimelineView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/7/25.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @Query private var users: [User]
    @Query private var incomes: [Income]
    @Query private var expenses: [Expense]
    @Query private var shoppingLists: [ShoppingList]
    
    @State private var timelineEvents: [DatedFinancialEvent] = []
    @State private var isCalculating = false
    @State private var isRefreshing = false
    
    private let scheduler = PurchaseScheduler()
    
    var contentBackground: Color {
        colorScheme == .dark ? Color.black : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    var emptyStateText: Color {
        colorScheme == .dark ? Color(white: 0.6) : .secondary
    }
    
    var titleColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    @State private var timelineDays: [TimelineDay] = []
    @State private var selectedViewMode: ViewMode = .list
    @State private var selectedDay: TimelineDay?
    
    enum ViewMode: String, CaseIterable {
        case list = "List"
        case graph = "Graph"
    }
    
    private var allItems: [ShoppingListItem] {
        shoppingLists.flatMap { $0.items }
    }
    
    @State private var allTimelineDays: [TimelineDay] = []

    var body: some View {
        ZStack(alignment: .top) {
            // 0. Base Background (Removed to reveal ContentView header)

            
            // 1. Header Background (Handled in ContentView)
            
            // 2. Title (Fixed)
            VStack {
                Text("Timeline")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.top, 150) // Match BudgetView padding
                Spacer()
            }
            .ignoresSafeArea()
            
            // 3. Content
            GeometryReader { geometry in
                if selectedViewMode == .list {
                    ScrollView {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 140) // Spacer for Title
                            
                            VStack(spacing: 20) {
                                if !timelineDays.isEmpty {
                                    picker
                                }
                                
                                if timelineDays.isEmpty {
                                    emptyState
                                } else {
                                    LazyVStack(spacing: 16) {
                                        ForEach(timelineDays) { day in
                                            TimelineDayView(day: day, cardBackground: cardBackground)
                                                .onTapGesture {
                                                    selectedDay = day
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 100)
                                }
                            }
                            .frame(minHeight: geometry.size.height - 140)
                            .background(contentBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                        }
                    }
                    .scrollBounceBehavior(.always, axes: .vertical)
                    .refreshable {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        await refreshTimeline()
                    }
            } else {
                // Graph Mode: Fixed Layout (Non-scrolling)
                VStack(spacing: 0) {
                    Color.clear.frame(height: 140) // Spacer for Title
                    
                    VStack(spacing: 20) {
                        if !timelineDays.isEmpty {
                            picker
                        }
                        
                        if timelineDays.isEmpty {
                            emptyState
                        } else {
                            if let user = users.first {
                                TimelineGraphView(days: allTimelineDays, user: user)
                                    .padding(.bottom, 100)
                            }
                        }
                        Spacer()
                    }
                    .onChange(of: users.first?.currentBalance) {
                        calculateTimeline()
                    }
                    .onAppear {
                        calculateTimeline()
                    }
                    .background(contentBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                }
            }
        }
        
        // Loading Indicator (Overlay)
        if isCalculating {
            CustomLoadingView()
                .zIndex(2)
                .padding(.top, 100)
        }
    }
    .onAppear {
        if timelineDays.isEmpty {
            calculateTimeline()
        }
    }
        .onChange(of: incomes) { _, _ in calculateTimeline() }
        .onChange(of: expenses) { _, _ in calculateTimeline() }
        .onChange(of: allItems) { _, _ in calculateTimeline() }
        .onChange(of: users) { _, _ in calculateTimeline() } // Trigger on settings change
        .sheet(item: $selectedDay) { day in
            TimelineDayDetailView(day: day)
                .presentationDetents([.medium, .large])
        }
    }
    
    private func refreshTimeline() async {
        // Minimum delay for UX
        try? await Task.sleep(nanoseconds: 250_000_000) // 0.25s
        
        return await withCheckedContinuation { continuation in
            calculateTimeline {
                continuation.resume()
            }
        }
    }
    
    private func calculateTimeline(completion: (() -> Void)? = nil) {
        guard let user = users.first else { 
            completion?()
            return 
        }
        isCalculating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Get all events
            let events = scheduler.getFullProjectionTimeline(
                forUser: user,
                incomes: incomes,
                expenses: expenses,
                shoppingListItems: allItems,
                projectionStartDate: Date()
            )
            
            // 2. Group by Day
            let grouped = Dictionary(grouping: events) { Calendar.current.startOfDay(for: $0.date) }
            
            // 3. Create TimelineDay objects
            let sortedDates = grouped.keys.sorted()
            
            var currentBalance = user.currentBalance
            var days: [TimelineDay] = []
            
            if let firstDate = sortedDates.first, let lastDate = sortedDates.last {
                let calendar = Calendar.current
                var date = firstDate
                
                // Determine if we should ignore today's events (same logic as Algo.swift)
                let now = Date()
                let lastCheckpoint = user.lastCheckpointDate
                let isBalanceFresh = calendar.isDateInToday(lastCheckpoint) || lastCheckpoint > now
                
                while date <= lastDate {
                    let eventsForDay = grouped[date] ?? []
                    
                    // Apply events - but skip today's events if balance is fresh
                    for event in eventsForDay {
                        let isEventToday = calendar.isDate(event.date, inSameDayAs: now)
                        
                        // Skip today's events if the user manually updated their balance today
                        if isEventToday && isBalanceFresh {
                            // Don't apply this event - it's already accounted for in currentBalance
                            continue
                        }
                        
                        currentBalance += event.amount
                    }
                    
                    days.append(TimelineDay(date: date, events: eventsForDay, endOfDayBalance: currentBalance))
                    
                    guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
                    date = next
                }
            }
            
            // Filter out days with no events for the list view
            let filteredDays = days.filter { !$0.events.isEmpty }
            
            DispatchQueue.main.async {
                self.timelineEvents = events
                self.timelineDays = filteredDays
                self.allTimelineDays = days // Store all days for graph
                self.isCalculating = false
                
                // Schedule Notifications
                NotificationManager.shared.scheduleNotifications(for: self.allItems)
                
                // Save Widget Data
                let widgetRange = user.widgetTimeframe
                let calendar = Calendar.current
                let today = Date()
                var endDate: Date
                
                switch widgetRange {
                case "1 Week": endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: today)!
                case "1 Month": endDate = calendar.date(byAdding: .month, value: 1, to: today)!
                case "3 Months": endDate = calendar.date(byAdding: .month, value: 3, to: today)!
                case "6 Months": endDate = calendar.date(byAdding: .month, value: 6, to: today)!
                case "1 Year": endDate = calendar.date(byAdding: .year, value: 1, to: today)!
                default: endDate = days.last?.date ?? today // Full
                }
                
                let widgetDays = days.filter { $0.date <= endDate }
                
                // Dynamic sampling: Aim for ~30 points
                let step = max(1, widgetDays.count / 30)
                
                let widgetPoints = widgetDays.enumerated().compactMap { index, day -> WidgetData.Point? in
                    if index % step == 0 || index == widgetDays.count - 1 {
                        let purchase = day.events.first { $0.type == .purchase }
                        let hasPurchase = purchase != nil
                        let colorHex = purchase?.originalItem?.parentList?.colorHex
                        return WidgetData.Point(date: day.date, balance: day.endOfDayBalance, hasPurchase: hasPurchase, colorHex: colorHex)
                    }
                    return nil
                }
                WidgetData.save(points: widgetPoints)
                
                // Reload Widget
                WidgetReloader.reloadWidget()
                
                completion?()
            }
        }
    }

    
    func color(for event: DatedFinancialEvent) -> Color {
        switch event.type {
        case .income: return .green
        case .expense: return .red
        case .purchase: return .orange
        }
    }
    
    func eventIcon(for event: DatedFinancialEvent) -> String {
        switch event.type {
        case .income: return "arrow.up.right" // Swapped
        case .expense: return "arrow.down.left" // Swapped
        case .purchase: return "bag.fill"
        }
    }
    var picker: some View {
        Picker("View Mode", selection: $selectedViewMode) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onChange(of: selectedViewMode) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundColor(.purple.opacity(0.5))
            Text("No Timeline Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("Add incomes, expenses, or shopping items to see your financial future.")
                .foregroundColor(emptyStateText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

struct TimelineDay: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    var events: [DatedFinancialEvent]
    var endOfDayBalance: Double
    
    var dailyNet: Double {
        events.reduce(0) { $0 + $1.amount }
    }
    
    static func == (lhs: TimelineDay, rhs: TimelineDay) -> Bool {
        lhs.id == rhs.id
    }
}


