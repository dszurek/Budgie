//
//  ListItemDetailView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/5/25.
//

import SwiftUI
import SwiftData

struct ListItemDetailView: View {
    @Bindable var listItem: ShoppingListItem
    
    @Environment(\.modelContext) private var modelContext
    @State private var localEditMode: EditMode = .inactive  // Local edit mode state
    @State private var priceString: String = ""             // Temporary state for editable price
    @State private var tempDate: Date = Date()
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Name Field / Label
                if localEditMode == .active {
                    TextField("Enter item name", text: $listItem.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 200)
                } else {
                    Text(listItem.name)
                        .font(.headline)
                }
                
                // Price Field / Label
                if localEditMode == .active {
                    TextField("Enter item price", text: $priceString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 200)
                        .keyboardType(.decimalPad)
                } else {
                    Text(String(format: "$%.2f", listItem.price))
                }
                
                // URL Field / Link
                if localEditMode == .active {
                    TextField("Enter URL", text: Binding(
                        get: { listItem.url?.absoluteString ?? "" },
                        set: { listItem.url = URL(string: $0) }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 300)
                } else {
                    if let url = listItem.url {
                        Link("Open Product Page", destination: url)
                            .foregroundColor(.blue)
                            .underline()
                    } else {
                        Text("No URL provided")
                            .foregroundColor(.gray)
                    }
                }
                
                if localEditMode == .active {
                    DatePicker("Purchase By", selection: $tempDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .frame(maxWidth: 250)
                } else {
                    Text("Purchase By: \(listItem.purchaseByDate.formatted(date: .long, time: .omitted))")
                }
                Section("Purchase Planning") {
                    HStack {
                        Text("Optimal Purchase Date:")
                            .fontWeight(.semibold)
                        Spacer()
                        if let calculatedDate = listItem.calculatedPurchaseDate {
                            Text(calculatedDate, formatter: dateFormatter)
                                .foregroundColor(.green) // Highlight if scheduled
                        } else {
                            Text("Not yet scheduled")
                                .foregroundColor(.orange)
                        }
                    }
                    // You could add more info here, e.g., why it's not scheduled if you store that.
                }
                
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localEditMode == .active ? "Done" : "Edit") {
                        if localEditMode == .active {
                            // When leaving edit mode, call saveChanges to update and save the price
                            saveChanges()
                        } else {
                            // When entering edit mode, initialize priceString with the current raw value
                            priceString = String(listItem.price)
                        }
                        localEditMode = (localEditMode == .active) ? .inactive : .active
                    }
                }
            }
        }
        .environment(\.editMode, $localEditMode)
    }

    private func saveChanges() {
        // Convert the unformatted price string to a Double.
        if let newPrice = Double(priceString) {
            listItem.price = newPrice
        }
        do {
            try modelContext.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}
