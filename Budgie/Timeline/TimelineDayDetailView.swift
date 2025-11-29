//
//  TimelineDayDetailView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/7/25.
//

import SwiftUI

struct TimelineDayDetailView: View {
    let day: TimelineDay
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Starting Balance")
                            .foregroundColor(.secondary)
                        Spacer()
                        // Calculate start balance (End - Net)
                        Text("$\(day.endOfDayBalance - day.dailyNet, specifier: "%.2f")")
                    }
                    
                    HStack {
                        Text("Net Change")
                            .foregroundColor(day.dailyNet >= 0 ? .green : .red)
                        Spacer()
                        Text((day.dailyNet >= 0 ? "+" : "") + String(format: "$%.2f", day.dailyNet))
                            .fontWeight(.bold)
                            .foregroundColor(day.dailyNet >= 0 ? .green : .red)
                    }
                    
                    HStack {
                        Text("End Balance")
                            .font(.headline)
                        Spacer()
                        Text("$\(day.endOfDayBalance, specifier: "%.2f")")
                            .font(.headline)
                    }
                } header: {
                    Text("Summary")
                }
                
                Section {
                    if day.events.isEmpty {
                        Text("No events for this day")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(day.events) { event in
                            HStack {
                                Image(systemName: eventIcon(for: event))
                                    .foregroundColor(eventColor(for: event))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading) {
                                    Text(event.title)
                                        .font(.body)
                                    Text(event.type == .purchase ? "Purchase" : (event.type == .income ? "Income" : "Expense"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(event.amount >= 0 ? "+$\(event.amount, specifier: "%.2f")" : "-$\(abs(event.amount), specifier: "%.2f")")
                                    .foregroundColor(eventColor(for: event))
                            }
                        }
                    }
                } header: {
                    Text("Transactions")
                }
            }
            .navigationTitle(day.date.formatted(date: .complete, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func eventColor(for event: DatedFinancialEvent) -> Color {
        switch event.type {
        case .income: return .green
        case .expense: return .red
        case .purchase: return .orange
        }
    }
    
    func eventIcon(for event: DatedFinancialEvent) -> String {
        switch event.type {
        case .income: return "arrow.up.right" // Swapped as requested
        case .expense: return "arrow.down.left" // Swapped as requested
        case .purchase: return "bag.fill"
        }
    }
}
