//
//  AddShoppingListItemView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/5/25.
//


import SwiftUI
import SwiftData

//TODO: Add webpage parsing functionality, automatic from webpage URL addition function

struct AddShoppingListItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var parentList: ShoppingList

    @State private var name = ""
    @State private var priceString = ""
    @State private var urlString = ""
    @State private var purchaseDate = Date()

    var body: some View {
        NavigationView {
            Form {
                TextField("Item Name", text: $name)
                TextField("Price", text: $priceString)
                    .keyboardType(.decimalPad)
                TextField("Product URL (optional)", text: $urlString)
                DatePicker(
                    "Purchase By Date", // Simpler label
                    selection: $purchaseDate,
                    displayedComponents: .date
                )
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addItem() {
        guard !name.isEmpty else { return }
        let price = Double(priceString) ?? 0.0
        let url = URL(string: urlString)

        let newItem = ShoppingListItem(name: name, price: price, purchaseByDate: purchaseDate, url: url)
        newItem.parentList = parentList
        parentList.items.append(newItem)
        modelContext.insert(newItem)
        try? modelContext.save()
    }
}
