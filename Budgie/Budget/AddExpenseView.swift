//
//  AddExpenseView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/6/25.
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var expenseToEdit: Expense?
    
    @State private var name: String = ""
    @State private var cost: String = ""
    @State private var type: Expense.Frequency = .monthly
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var hasEndDate: Bool = false
    
    init(expenseToEdit: Expense? = nil) {
        self.expenseToEdit = expenseToEdit
    }
    
    @State private var selectedDayOfWeek: Int = 1 // 1 = Sunday
    @State private var selectedDayOfMonth: Int = 1
    
    var contentBackground: Color {
        colorScheme == .dark ? Color.black : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                contentBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Expense Details Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EXPENSE DETAILS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 0) {
                                // Name
                                HStack {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.purple)
                                        .frame(width: 24)
                                    TextField("Name (e.g. Rent)", text: $name)
                                }
                                .padding()
                                
                                Divider().padding(.leading, 48)
                                
                                // Cost
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(.red)
                                        .frame(width: 24)
                                    TextField("Cost", text: $cost)
                                        .keyboardType(.decimalPad)
                                        .toolbar {
                                            ToolbarItemGroup(placement: .keyboard) {
                                                Spacer()
                                                Button("Done") {
                                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                                }
                                            }
                                        }
                                }
                                .padding()
                                
                                Divider().padding(.leading, 48)
                                
                                // Frequency
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    Text("Frequency")
                                    Spacer()
                                    Picker("Frequency", selection: $type) {
                                        ForEach(Expense.Frequency.allCases) { frequency in
                                            Text(frequency.rawValue.capitalized).tag(frequency)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                    .accentColor(.primary)
                                }
                                .padding()
                            }
                            .background(cardBackground)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        // Schedule Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SCHEDULE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 0) {
                                // Dynamic Date Picker
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.red)
                                        .frame(width: 24)
                                    
                                    if type == .intermittent {
                                        VStack(alignment: .leading) {
                                            Text("Select Dates")
                                            if #available(iOS 16.0, *) {
                                                MultiDatePicker("Dates", selection: $selectedDates)
                                                    .frame(height: 300)
                                            } else {
                                                Text("Multi-date selection requires iOS 16+")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    } else {
                                        DatePicker(
                                            "Next Occurrence",
                                            selection: $startDate,
                                            displayedComponents: .date
                                        )
                                    }
                                }
                                .padding()
                                
                                Divider().padding(.leading, 48)
                                
                                // End Date Toggle
                                if type != .intermittent {
                                    Toggle(isOn: $hasEndDate) {
                                        HStack {
                                            Image(systemName: "stop.circle.fill")
                                                .foregroundColor(.gray)
                                                .frame(width: 24)
                                            Text("Has End Date?")
                                        }
                                    }
                                    .padding()
                                    
                                    if hasEndDate {
                                        Divider().padding(.leading, 48)
                                        
                                        HStack {
                                            Image(systemName: "calendar.badge.exclamationmark")
                                                .foregroundColor(.gray)
                                                .frame(width: 24)
                                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                        }
                                        .padding()
                                    }
                                }
                            }
                            .background(cardBackground)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle(expenseToEdit == nil ? "New Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(name.isEmpty || cost.isEmpty)
                }
            }
        }
        .onAppear {
            if let expense = expenseToEdit {
                name = expense.name
                cost = String(expense.cost)
                type = expense.type
                startDate = expense.startDate
                
                if let dates = expense.intermittentDates {
                    let calendar = Calendar.current
                    for dateObj in dates {
                        let components = calendar.dateComponents([.calendar, .era, .year, .month, .day], from: dateObj.date)
                        selectedDates.insert(components)
                    }
                }
                
                if let end = expense.endDate {
                    endDate = end
                    hasEndDate = true
                }
            }
        }
    }
    
    @State private var selectedDates: Set<DateComponents> = []
    
    private func saveExpense() {
        guard let costValue = Double(cost), !name.isEmpty else { return }
        
        var finalIntermittentDates: [IntermittentDate]? = nil
        
        if type == .intermittent {
            let calendar = Calendar.current
            finalIntermittentDates = selectedDates.compactMap { components in
                guard let date = calendar.date(from: components) else { return nil }
                return IntermittentDate(date: date)
            }
        }
        
        if let expense = expenseToEdit {
            expense.name = name
            expense.cost = costValue
            expense.type = type
            expense.startDate = startDate
            expense.endDate = (hasEndDate && type != .intermittent) ? endDate : nil
            
            // Update intermittent dates
            if type == .intermittent {
                expense.intermittentDates = finalIntermittentDates
            } else {
                expense.intermittentDates = nil
            }
            
        } else {
            let newExpense = Expense(
                name: name,
                cost: costValue,
                type: type,
                startDate: startDate,
                endDate: (hasEndDate && type != .intermittent) ? endDate : nil,
                intermittentDates: finalIntermittentDates
            )
            modelContext.insert(newExpense)
        }
        try? modelContext.save()
        dismiss()
    }
}
