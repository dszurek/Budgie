//
//  ShoppingListDetailView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/6/25.
//

import SwiftUI
import SwiftData

struct ShoppingListDetailView: View {
    @Environment(\.modelContext) private var context
    var list: ShoppingList
    
    #if os(iOS)
    @Environment(\.editMode) private var editMode
    #endif
    
    var body: some View {
        List {
            ForEach(list.items) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name)
                        Text("$\(item.price, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let date = item.calculatedPurchaseDate {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle(list.name)
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        #endif
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            context.delete(list.items[index])
        }
    }
}
