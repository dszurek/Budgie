//
//  AddIncomeView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/6/25.
//

import SwiftUI
import SwiftData

struct AddIncomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var incomeToEdit: Income?
    
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var type: Income.Frequency = .monthly
    @State private var taxPercent: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var hasEndDate: Bool = false
    
    init(incomeToEdit: Income? = nil) {
        self.incomeToEdit = incomeToEdit
    }
    
    @State private var selectedDayOfWeek: Int = 1 // 1 = Sunday, 2 = Monday, etc.
    @State private var selectedDayOfMonth: Int = 1
    @State private var selectedMonth: Int = 1
    
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
                        // Income Details Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("INCOME DETAILS")
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
                                    TextField("Name (e.g. Salary)", text: $name)
                                }
                                .padding()
                                
                                Divider().padding(.leading, 48)
                                
                                // Amount
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(.green)
                                        .frame(width: 24)
                                    TextField("Amount", text: $amount)
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
                                        ForEach(Income.Frequency.allCases) { frequency in
                                            Text(frequency.rawValue.capitalized).tag(frequency)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                    .accentColor(.primary)
                                }
                                .padding()
                                
                                Divider().padding(.leading, 48)
                                
                                // Tax %
                                HStack {
                                    Image(systemName: "percent")
                                        .foregroundColor(.orange)
                                        .frame(width: 24)
                                    TextField("Tax % (Optional)", text: $taxPercent)
                                        .keyboardType(.decimalPad)
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
            .navigationTitle(incomeToEdit == nil ? "New Income" : "Edit Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIncome()
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
        }
        .onAppear {
            if let income = incomeToEdit {
                name = income.name
                amount = String(income.amount)
                type = income.type
                taxPercent = income.taxPercent > 0 ? String(income.taxPercent) : ""
                startDate = income.startDate
                
                if let dates = income.intermittentDates {
                    let calendar = Calendar.current
                    for dateObj in dates {
                        let components = calendar.dateComponents([.calendar, .era, .year, .month, .day], from: dateObj.date)
                        selectedDates.insert(components)
                    }
                }
                
                if let end = income.endDate {
                    endDate = end
                    hasEndDate = true
                }
            }
        }
    }
    
    @State private var selectedDates: Set<DateComponents> = []
    
    private func saveIncome() {
        guard let amountValue = Double(amount), !name.isEmpty else { return }
        let taxValue = Double(taxPercent) ?? 0.0
        
        var finalIntermittentDates: [IntermittentDate]? = nil
        
        if type == .intermittent {
            let calendar = Calendar.current
            finalIntermittentDates = selectedDates.compactMap { components in
                guard let date = calendar.date(from: components) else { return nil }
                return IntermittentDate(date: date)
            }
        }
        
        if let income = incomeToEdit {
            income.name = name
            income.amount = amountValue
            income.type = type
            income.taxPercent = taxValue
            income.startDate = startDate
            income.endDate = (hasEndDate && type != .intermittent) ? endDate : nil
            
            // Update intermittent dates
            if type == .intermittent {
                income.intermittentDates = finalIntermittentDates
            } else {
                income.intermittentDates = nil
            }
            
        } else {
            let newIncome = Income(
                name: name,
                amount: amountValue,
                type: type,
                taxPercent: taxValue,
                startDate: startDate,
                endDate: (hasEndDate && type != .intermittent) ? endDate : nil,
                intermittentDates: finalIntermittentDates
            )
            modelContext.insert(newIncome)
        }
        try? modelContext.save()
        dismiss()
    }
}
