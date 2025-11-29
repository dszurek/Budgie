//
//  BudgetView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/6/25.
//

import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @Query(sort: \Income.name) private var incomes: [Income]
    @Query(sort: \Expense.name) private var expenses: [Expense]
    @Query private var users: [User]
    
    var currentUser: User? {
        users.first
    }
    
    @State private var showAddIncome = false
    @State private var showAddExpense = false
    @State private var showUpdateBalance = false
    @State private var newBalanceAmount: String = ""
    @State private var isMenuOpen = false
    
    // Edit States
    @State private var selectedIncome: Income?
    @State private var selectedExpense: Expense?
    
    let impact = UIImpactFeedbackGenerator(style: .medium)
    
    var contentBackground: Color {
        colorScheme == .dark ? Color.black : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    var emptyStateText: Color {
        colorScheme == .dark ? Color(white: 0.6) : .secondary
    }
    
    var titleColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 0. Base Background

            
            // 1. Header Background (Handled in ContentView)
            
            // 2. Title
            VStack {
                Text("Budget")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.top, 150) // Increased padding
                Spacer()
            }
            .ignoresSafeArea()
            
            // 3. Scrollable Content
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Transparent Spacer
                        Color.clear.frame(height: 140)
                        
                        // Content
                        VStack(spacing: 20) {
                            // Current Balance Card
                            if let user = currentUser {
                                BalanceCard(
                                    user: user,
                                    cardBackground: cardBackground,
                                    onUpdate: {
                                        newBalanceAmount = String(format: "%.2f", user.currentBalance)
                                        showUpdateBalance = true
                                    }
                                )
                            }
                            
                            // Incomes Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Incomes")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                
                                if incomes.isEmpty {
                                    EmptyStateView(text: "No incomes added yet. Tap the + button to add one!", cardBackground: cardBackground, textColor: emptyStateText)
                                } else {
                                    ForEach(incomes) { income in
                                        IncomeRow(income: income, cardBackground: cardBackground)
                                            .onTapGesture {
                                                selectedIncome = income
                                            }
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    modelContext.delete(income)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                            
                            // Expenses Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Expenses")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                
                                if expenses.isEmpty {
                                    EmptyStateView(text: "No expenses added yet. Tap the + button to add one!", cardBackground: cardBackground, textColor: emptyStateText)
                                } else {
                                    ForEach(expenses) { expense in
                                        ExpenseRow(expense: expense, cardBackground: cardBackground)
                                            .onTapGesture {
                                                selectedExpense = expense
                                            }
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    modelContext.delete(expense)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 120)
                        .frame(maxWidth: .infinity)
                        .background(contentBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
            
            // 4. Standard Floating Button
            StandardFloatingButton(
                icon: "plus",
                color: .green,
                action: {
                    impact.impactOccurred()
                    // Action handled by menu binding
                },
                isOpen: $isMenuOpen,
                menuItems: [
                    StandardFloatingMenuItem(icon: "dollarsign.circle", title: "Income", color: .green) {
                        showAddIncome = true
                    },
                    StandardFloatingMenuItem(icon: "creditcard.fill", title: "Expense", color: .red) {
                        showAddExpense = true
                    }
                ]
            )
        }
        .onAppear {
            if users.isEmpty {
                let newUser = User(startingBalance: 0)
                modelContext.insert(newUser)
            }
        }
        .sheet(isPresented: $showAddIncome) { AddIncomeView() }
        .sheet(isPresented: $showAddExpense) { AddExpenseView() }
        .sheet(item: $selectedIncome) { income in
            AddIncomeView(incomeToEdit: income)
        }
        .sheet(item: $selectedExpense) { expense in
            AddExpenseView(expenseToEdit: expense)
        }
        .alert("Update Balance", isPresented: $showUpdateBalance) {
            TextField("Amount", text: $newBalanceAmount)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { }
            Button("Update") {
                if let amount = Double(newBalanceAmount), let user = currentUser {
                    let checkpoint = BalanceCheckpoint(amount: amount)
                    user.balanceCheckpoints.append(checkpoint)
                }
            }
        } message: {
            Text("Enter your current actual balance to correct the projection.")
        }
    }
}

struct BalanceCard: View {
    let user: User
    let cardBackground: Color
    let onUpdate: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Current Balance")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            HStack {
                Text("$\(user.currentBalance, specifier: "%.2f")")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                
                Button(action: onUpdate) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green.opacity(0.7))
                }
            }
            
            Text("Updated: \(user.lastCheckpointDate == Date.distantPast ? "Never" : user.lastCheckpointDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct IncomeRow: View {
    let income: Income
    let cardBackground: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(income.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(income.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("+$\(income.amount, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
    }
}

struct ExpenseRow: View {
    let expense: Expense
    let cardBackground: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(expense.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("-$\(expense.cost, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(.red)
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
    }
}

struct EmptyStateView: View {
    let text: String
    let cardBackground: Color
    let textColor: Color
    
    var body: some View {
        Text(text)
            .foregroundColor(textColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
