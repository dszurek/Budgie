//
//  MarkPurchasedSheet.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/28/25.
//

import SwiftUI
import SwiftData

struct MarkPurchasedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var item: ShoppingListItem
    @Bindable var user: User
    
    @State private var purchaseDate: Date = Date()
    @State private var purchasePrice: Double
    
    init(item: ShoppingListItem, user: User) {
        self.item = item
        self.user = user
        _purchasePrice = State(initialValue: item.price)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    Text(item.name)
                        .font(.headline)
                    
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("Amount", value: $purchasePrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("When did you buy it?")) {
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }
                
                Section(footer: Text("This will deduct $\(String(format: "%.2f", purchasePrice)) from your current balance.")) {
                    Button(action: confirmPurchase) {
                        Text("Confirm Purchase")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    .listRowInsets(EdgeInsets()) // Full width button
                }
            }
            .navigationTitle("Mark as Purchased")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func confirmPurchase() {
        // 1. Update Item
        item.isPurchased = true
        item.actualPurchaseDate = purchaseDate
        item.price = purchasePrice // Update price if it changed
        
        // 2. Update Balance
        // We create a checkpoint for the purchase date (or now? Usually now/date of purchase)
        // If purchase date is in the past, strictly speaking the balance should have been lower since then.
        // But for simplicity and safety, we deduct from the *current* balance effective on the purchase date.
        // If the user selects a past date, we'll add a checkpoint there.
        // However, User.currentBalance uses the *latest* checkpoint.
        // So if we add a checkpoint in the past, it won't affect the current balance if there's a newer checkpoint.
        // To ensure the balance is updated NOW, we should probably add the checkpoint for NOW (or max(now, purchaseDate)).
        // OR, we assume the user wants to correct the record.
        // Let's stick to the requirement: "update the current balance based on that purchase date".
        
        // Logic:
        // If purchase date is Today/Future -> Checkpoint at Purchase Date.
        // If purchase date is Past -> We need to adjust the "current" balance.
        // The safest way to "deduct" is to take the current balance and subtract.
        // But we need to record WHEN it happened.
        
        // Let's create a checkpoint at the purchaseDate.
        // BUT, we also need to make sure this deduction propagates to "now".
        // If we only add a checkpoint in the past, and there are newer checkpoints, this one might be ignored by `currentBalance` logic.
        // `User.currentBalance` takes the `latest` checkpoint.
        
        // If we want to deduct from the *running* balance, we might need to adjust *all* checkpoints after that date? That's complex.
        // Simplified approach:
        // 1. Create a checkpoint at `purchaseDate` with `currentBalance - price`.
        // WAIT, `currentBalance` is the balance *now*.
        // If I bought something yesterday, my balance yesterday was X.
        // If I add a checkpoint yesterday = X - price.
        // If I have a checkpoint today = Y.
        // My current balance stays Y. That's wrong if Y didn't account for the purchase.
        
        // DECISION: To ensure the user sees the deduction, we will add the checkpoint at `max(purchaseDate, Date())` (basically "Now" or future).
        // If they select a past date, we mark the item as bought in the past, but we deduct the money *now* (conceptually "I am recording this transaction now").
        // This prevents messing up historical checkpoints or having the deduction be invisible.
        
        let deductionDate = Date() // Always deduct "now" for safety/visibility
        let newBalance = user.currentBalance - purchasePrice
        
        let checkpoint = BalanceCheckpoint(date: deductionDate, amount: newBalance)
        user.balanceCheckpoints.append(checkpoint)
        modelContext.insert(checkpoint)
        
        try? modelContext.save()
        dismiss()
    }
}
