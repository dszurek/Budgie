//
//  TimelineDayView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/7/25.
//

import SwiftUI

struct TimelineDayView: View {
    let day: TimelineDay
    let cardBackground: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Date and Balance
            HStack {
                VStack(alignment: .leading) {
                    Text(day.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                    Text(day.date.formatted(.dateTime.weekday(.wide)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(day.endOfDayBalance, format: .currency(code: "USD"))
                        .font(.headline)
                        .foregroundColor(day.endOfDayBalance >= 0 ? .primary : .red)
                    
                    Text("Daily Net: \(day.dailyNet, format: .currency(code: "USD"))")
                        .font(.caption)
                        .foregroundColor(day.dailyNet >= 0 ? .green : .red)
                }
            }
            
            if !day.events.isEmpty {
                Divider()
                
                // Events Preview (first 3)
                ForEach(day.events.prefix(3)) { event in
                    HStack {
                        Image(systemName: eventIcon(for: event))
                            .foregroundColor(color(for: event))
                            .accessibilityHidden(true)
                        Text(event.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Text(event.amount, format: .currency(code: "USD"))
                            .font(.subheadline)
                            .foregroundColor(color(for: event))
                    }
                }
                
                if day.events.count > 3 {
                    Text("+ \(day.events.count - 3) more events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
        case .income: return "arrow.up.right"
        case .expense: return "arrow.down.left"
        case .purchase: return "bag.fill"
        }
    }
}
