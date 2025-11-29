//
//  TimelineGraphView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/7/25.
//

import SwiftUI
import Charts

struct TimelineGraphView: View {
    let days: [TimelineDay]
    let user: User
    @Environment(\.colorScheme) var colorScheme
    
    // Helper to find min/max for Y-axis scaling
    var yAxisDomain: ClosedRange<Double> {
        let balances = days.map { $0.endOfDayBalance }
        let minBalance = min(balances.min() ?? 0, user.rainCheckMin, 0)
        let maxBalance = max(balances.max() ?? 0, user.targetSavings * 1.1) // Give some headroom
        return minBalance...maxBalance
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Split Chart: Static Y-Axis + Scrollable Content
                HStack(spacing: 0) {
                    // 1. Static Y-Axis
                    Chart {
                        // Invisible marks to force scale
                        RuleMark(y: .value("Min", yAxisDomain.lowerBound)).foregroundStyle(.clear)
                        RuleMark(y: .value("Max", yAxisDomain.upperBound)).foregroundStyle(.clear)
                    }
                    .chartYScale(domain: yAxisDomain)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let balance = value.as(Double.self) {
                                    Text("$\(Int(balance))")
                                        .font(.caption2)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        // Reserve space for X-axis labels to match main chart height
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel {
                                VStack(spacing: 2) {
                                    Text(" ").font(.caption2).fontWeight(.bold)
                                    Text(" ").font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(width: 40) // Fixed width for Y-axis
                    .padding(.leading, 16) // Increased padding
                    
                    // 2. Scrollable Content
                    ScrollView(.horizontal, showsIndicators: false) {
                        Chart {
                            rainCheckMark
                            savingsGoalMark
                            balanceLineMarks
                            purchasePointMarks
                        }
                        .chartXScale(domain: days.first!.date...days.last!.date)
                        .chartYScale(domain: yAxisDomain)
                        .chartXSelection(value: $selectedDate) // Track selection
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 2)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        VStack(spacing: 2) {
                                            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                            Text(date.formatted(.dateTime.day()))
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                }
                                AxisGridLine()
                                    .foregroundStyle(Color.gray.opacity(0.1))
                            }
                        }
                        .chartYAxis {
                            // Grid lines only, no labels
                            AxisMarks(position: .leading) { _ in
                                AxisGridLine()
                                    .foregroundStyle(Color.gray.opacity(0.1))
                            }
                        }
                        // 40pt per day ensures ~10 days fit on a standard screen (approx 1.5 weeks)
                        .frame(width: max(CGFloat(days.count) * 40, geometry.size.width - 48)) // Adjust for Y-axis width
                        .padding(.horizontal, 20) // Prevent cutoff of first/last points
                    }
                    .onChange(of: selectedDate) {
                        if let date = selectedDate {
                            // Find the cluster for this date
                            if let cluster = purchaseClusters.first(where: { Calendar.current.isDate($0.day.date, inSameDayAs: date) }) {
                                selectedCluster = cluster
                            }
                            // Reset selection immediately so we can tap again?
                        }
                    }
                    .sheet(item: $selectedCluster) { (cluster: PurchaseCluster) in
                        // Show details for all items on this day
                        VStack {
                            Text("Scheduled Purchases")
                                .font(.headline)
                                .padding()
                            
                            ScrollView {
                                VStack(spacing: 16) {
                                    ForEach(cluster.purchases) { purchase in
                                        if let item = purchase.originalItem {
                                            ShoppingListItemDetailView(item: item, isEmbedded: true)
                                        } else {
                                            Text(purchase.title)
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        .presentationDetents([.medium, .large])
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ChartContentBuilder
    var rainCheckMark: some ChartContent {
        if user.rainCheckMin > 0 {
            RuleMark(y: .value("Rain Check", user.rainCheckMin))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .foregroundStyle(.red.opacity(0.6))
                .annotation(position: .top, alignment: .leading) {
                    Text("Rain Check")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .padding(4)
                }
        }
    }
    
    @ChartContentBuilder
    var savingsGoalMark: some ChartContent {
        if user.targetSavings > 0 {
            RuleMark(y: .value("Savings Goal", user.targetSavings))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .foregroundStyle(.green.opacity(0.6))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Goal")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(4)
                }
        }
    }
    
    @ChartContentBuilder
    var balanceLineMarks: some ChartContent {
        ForEach(days) { day in
            LineMark(
                x: .value("Date", day.date),
                y: .value("Balance", day.endOfDayBalance)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.purple, .purple.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", day.date),
                y: .value("Balance", day.endOfDayBalance)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.purple.opacity(0.3), .purple.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
    }
    
    struct PurchaseCluster: Identifiable {
        let id = UUID()
        let day: TimelineDay
        let purchases: [DatedFinancialEvent]
    }
    
    var purchaseClusters: [PurchaseCluster] {
        days.compactMap { day -> PurchaseCluster? in
            let purchases = day.events.filter { $0.type == .purchase }
            if purchases.isEmpty { return nil }
            return PurchaseCluster(day: day, purchases: purchases)
        }
    }
    
    @State private var selectedCluster: PurchaseCluster?
    
    @ChartContentBuilder
    var purchasePointMarks: some ChartContent {
        ForEach(purchaseClusters) { cluster in
            // Transparent bar for better tap target - Increased opacity slightly to ensure hit testing works reliably
            BarMark(
                x: .value("Date", cluster.day.date),
                yStart: .value("Min", yAxisDomain.lowerBound),
                yEnd: .value("Max", yAxisDomain.upperBound)
            )
            .foregroundStyle(Color.white.opacity(0.05)) // Slightly more visible for better hit detection 
            
            // Determine color(s)
            let colors = cluster.purchases.compactMap { $0.originalItem?.parentList?.colorHex }.map { Color(hex: $0) }
            let uniqueColors = Array(Set(colors))
            
            if uniqueColors.count > 1 {
                // Multiple lists: Use a Gradient
                PointMark(
                    x: .value("Date", cluster.day.date),
                    y: .value("Balance", cluster.day.endOfDayBalance)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: uniqueColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolSize(100)
                .annotation(position: .top, spacing: 4) {
                    PurchaseAnnotationView(purchaseNames: ["\(cluster.purchases.count) Items"])
                }
            } else {
                // Single list (or single item)
                PointMark(
                    x: .value("Date", cluster.day.date),
                    y: .value("Balance", cluster.day.endOfDayBalance)
                )
                .foregroundStyle(uniqueColors.first ?? .orange)
                .symbolSize(100)
                .annotation(position: .top, spacing: 4) {
                    if cluster.purchases.count > 1 {
                        PurchaseAnnotationView(purchaseNames: ["\(cluster.purchases.count) Items"])
                    } else {
                        PurchaseAnnotationView(purchaseNames: [cluster.purchases.first?.title ?? "Item"])
                    }
                }
            }
        }
    }
    
    // ... (rest of view)
    
    // We need to wrap the Chart in a way to handle selection.
    
    @State private var selectedDate: Date?

}

struct PurchaseAnnotationView: View {
    let purchaseNames: [String]
    
    var body: some View {
        VStack(spacing: 2) {
            VStack(spacing: 2) {
                ForEach(purchaseNames, id: \.self) { name in
                    Text(name)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .padding(4)
            .background(Color(UIColor.systemBackground).opacity(0.8)) // Better for light mode
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 1, height: 15)
        }
    }
}
