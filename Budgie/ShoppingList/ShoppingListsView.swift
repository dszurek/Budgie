//
//  ShoppingListsView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/5/25.
//

import SwiftUI
import SwiftData

struct ShoppingListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @Query private var shoppingLists: [ShoppingList]
    @Query private var allItems: [ShoppingListItem]
    @Query private var incomes: [Income]
    @Query private var expenses: [Expense]
    @Query private var users: [User]
    
    @State private var showAddList = false
    @State private var newListName = ""
    @State private var showAddItem = false
    @State private var selectedList: ShoppingList?
    @State private var editingItem: ShoppingListItem?
    @State private var selectedItem: ShoppingListItem?
    @State private var itemToMarkPurchased: ShoppingListItem?
    @State private var showRenameList = false
    @State private var listToRename: ShoppingList?
    
    @State private var newItemName = ""
    @State private var newItemPrice = ""
    @State private var newItemDate = Date()
    @State private var newItemURL = ""
    @State private var isRefreshing = false
    
    private let scheduler = PurchaseScheduler()
    
    var contentBackground: Color {
        colorScheme == .dark ? Color.black : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    var emptyStateText: Color {
        colorScheme == .dark ? Color(white: 0.6) : .secondary
    }
    
    var titleColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 0. Base Background

            
            // 1. Header Background (Handled in ContentView)
            
            // 2. Title
            VStack {
                Text("Wish Lists")
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
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            // Loading Indicator
                            if isRefreshing {
                                CustomLoadingView()
                                    .padding(.top, 60) // Position below header
                                    .transition(.scale)
                                    .zIndex(1)
                            }
                            
                            // Transparent Spacer
                            Color.clear.frame(height: 140)
                            
                            // Content
                            VStack(alignment: .leading, spacing: 20) {
                                if shoppingLists.isEmpty {
                                    Text("No wish lists yet. Tap the list icon to create one!")
                                        .foregroundColor(emptyStateText)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(cardBackground)
                                        .cornerRadius(15)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                        .padding(.horizontal)
                                } else {
                                    LazyVStack(spacing: 16) {
                                        ForEach(shoppingLists) { list in
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Text(list.name)
                                                        .font(.title2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                    Button(action: {
                                                        selectedList = list
                                                        editingItem = nil // Reset for new item
                                                        newItemName = ""
                                                        newItemPrice = ""
                                                        newItemDate = Date()
                                                        newItemURL = ""
                                                        showAddItem = true
                                                    }) {
                                                        Image(systemName: "plus.circle.fill")
                                                            .foregroundColor(.blue)
                                                            .font(.title2)
                                                    }
                                                }
                                                
                                                if !list.items.isEmpty {
                                                    ForEach(list.items) { item in
                                                        Button(action: {
                                                            selectedItem = item
                                                        }) {
                                                            // Item Row
                                                            HStack {
                                                                VStack(alignment: .leading) {
                                                                    Text(item.name)
                                                                        .font(.headline)
                                                                        .strikethrough(item.isPurchased ?? false, color: .gray)
                                                                        .foregroundColor(item.isPurchased ?? false ? .gray : .primary)
                                                                    
                                                                    if let date = item.calculatedPurchaseDate, !(item.isPurchased ?? false) {
                                                                        HStack(spacing: 4) {
                                                                            Image(systemName: "calendar")
                                                                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                                                        }
                                                                        .font(.caption)
                                                                        .foregroundColor(.green) // Highlight if today
                                                                        .fontWeight(Calendar.current.isDateInToday(date) ? .bold : .regular)
                                                                    } else if let date = item.actualPurchaseDate, item.isPurchased ?? false {
                                                                        Text("Purchased: \(date.formatted(date: .abbreviated, time: .omitted))")
                                                                            .font(.caption)
                                                                            .foregroundColor(.green)
                                                                    } else if let _ = item.calculationError, !(item.isPurchased ?? false) {
                                                                        HStack(spacing: 4) {
                                                                            Image(systemName: "exclamationmark.triangle.fill")
                                                                            Text("Could not schedule")
                                                                        }
                                                                        .font(.caption)
                                                                        .foregroundColor(.orange)
                                                                            .foregroundColor(.red)
                                                                    }
                                                                }
                                                                
                                                                Spacer()
                                                                
                                                                Text(item.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                                                    .foregroundColor(item.isPurchased ?? false ? .gray : .primary)
                                                            }
                                                            .padding()
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 12)
                                                                    .fill(cardBackground)
                                                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                                            )
                                                            // Highlight border if scheduled for today and not purchased, otherwise thin outline
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 12)
                                                                    .stroke(
                                                                        (item.calculatedPurchaseDate != nil && Calendar.current.isDateInToday(item.calculatedPurchaseDate!) && !(item.isPurchased ?? false)) ? Color.orange : Color.primary.opacity(0.1),
                                                                        lineWidth: (item.calculatedPurchaseDate != nil && Calendar.current.isDateInToday(item.calculatedPurchaseDate!) && !(item.isPurchased ?? false)) ? 2 : 1
                                                                    )
                                                            )
                                                        }
                                                        .buttonStyle(.plain) // Keep list styling
                                                        .contextMenu {
                                                            Button(role: .destructive) {
                                                                modelContext.delete(item)
                                                                try? modelContext.save() // Ensure deletion is saved
                                                                runAlgorithm()
                                                            } label: {
                                                                Label("Delete", systemImage: "trash")
                                                            }
                                                            
                                                            if !(item.isPurchased ?? false) {
                                                                Button {
                                                                    itemToMarkPurchased = item
                                                                } label: {
                                                                    Label("Mark as Purchased", systemImage: "checkmark.circle")
                                                                }
                                                            } else {
                                                                Button {
                                                                    // Refund Logic
                                                                    if let user = users.first {
                                                                        let refundAmount = item.price
                                                                        let newBalance = user.currentBalance + refundAmount
                                                                        let refundCheckpoint = BalanceCheckpoint(date: Date(), amount: newBalance)
                                                                        user.balanceCheckpoints.append(refundCheckpoint)
                                                                        modelContext.insert(refundCheckpoint)
                                                                    }
                                                                    
                                                                    item.isPurchased = false
                                                                    item.actualPurchaseDate = nil
                                                                    try? modelContext.save()
                                                                    runAlgorithm()
                                                                } label: {
                                                                    Label("Mark as Unpurchased", systemImage: "arrow.uturn.backward")
                                                                }
                                                            }
                                                            
                                                            Button {
                                                                // Edit Item Logic
                                                                selectedList = list
                                                                newItemName = item.name
                                                                newItemPrice = String(item.price)
                                                                newItemDate = item.purchaseByDate
                                                                newItemURL = item.url?.absoluteString ?? ""
                                                                editingItem = item
                                                                showAddItem = true
                                                            } label: {
                                                                Label("Edit", systemImage: "pencil")
                                                            }
                                                        }
                                                        .swipeActions(edge: .leading) {
                                                            if !(item.isPurchased ?? false) {
                                                                Button {
                                                                    itemToMarkPurchased = item
                                                                } label: {
                                                                    Label("Purchased", systemImage: "checkmark.circle")
                                                                }
                                                                .tint(.green)
                                                            }
                                                        }
                                                    }
                                                } else {
                                                    Text("No items in this list")
                                                        .font(.caption)
                                                        .foregroundColor(emptyStateText)
                                                        .padding()
                                                }
                                            }
                                            .padding()
                                            .background(cardBackground)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color(hex: list.colorHex), lineWidth: 1.5) // Subtle border
                                                    .blur(radius: 3) // Inner glow effect
                                                    .offset(x: 0, y: 0)
                                            )
                                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    modelContext.delete(list)
                                                    try? modelContext.save()
                                                } label: {
                                                    Label("Delete List", systemImage: "trash")
                                                }
                                                
                                                Button {
                                                    listToRename = list
                                                } label: {
                                                    Label("Edit List", systemImage: "slider.horizontal.3")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 100)
                                }
                            }
                            .padding(.top, 20)
                            .frame(minHeight: geometry.size.height - 140, alignment: .top)
                            .background(contentBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                            
                            Spacer()
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .scrollBounceBehavior(.always, axes: .vertical)
                .refreshable {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    // Small delay to let the spinner show
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    runAlgorithm()
                }
            }
            
            // 4. Standard Floating Button
            StandardFloatingButton(
                icon: "list.bullet.clipboard",
                color: .blue,
                action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showAddList = true
                },
                accessibilityIdentifier: "Add List"
            )
        }
        .sheet(item: $selectedItem) { item in
            ShoppingListItemDetailView(item: item)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $itemToMarkPurchased) { item in
            if let user = users.first {
                MarkPurchasedSheet(item: item, user: user)
                    .presentationDetents([.medium])
                    .onDisappear {
                        runAlgorithm() // Re-run algo after sheet dismisses (in case of purchase)
                    }
            }
        }
        .onAppear {
            runAlgorithm()
        }
        .alert("New List", isPresented: $showAddList) {
            TextField("List Name", text: $newListName)
                .accessibilityIdentifier("ListNameField")
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                let newList = ShoppingList(name: newListName)
                modelContext.insert(newList)
                try? modelContext.save() // Explicit save to update UI immediately
                newListName = ""
            }
        }
        .sheet(item: $listToRename) { list in
            ListSettingsSheet(list: list)
                .presentationDetents([.fraction(0.4)])
        }
        .sheet(isPresented: $showAddItem) {
            AddItemSheet(
                selectedList: $selectedList,
                editingItem: $editingItem,
                newItemName: $newItemName,
                newItemPrice: $newItemPrice,
                newItemDate: $newItemDate,
                newItemURL: $newItemURL,
                showAddItem: $showAddItem,
                onAdd: { runAlgorithm() }
            )
        }
    }
    
    private func runAlgorithm() {
        guard let user = users.first else { return }
        // Filter out deleted items explicitly if needed, but SwiftData usually handles this.
        // However, if context hasn't saved, they might still be in allItems.
        // We'll use the items from the lists which are managed by SwiftData relationships.
        var items = shoppingLists.flatMap { $0.items }.filter { !$0.isDeleted }
        
        scheduler.calculateOptimalPurchaseDates(
            forUser: user,
            incomes: incomes,
            expenses: expenses,
            shoppingListItems: &items,
            projectionStartDate: Date()
        )
    }
}

struct AddItemSheet: View {
    @Binding var selectedList: ShoppingList?
    @Binding var editingItem: ShoppingListItem?
    
    @Binding var newItemName: String
    @Binding var newItemPrice: String
    @Binding var newItemDate: Date
    @Binding var newItemURL: String
    @Binding var showAddItem: Bool
    var onAdd: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
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
                
                VStack(spacing: 24) {
                    // Inputs
                    VStack(spacing: 24) {
                        // Details Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ITEM DETAILS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 0) {
                                // Name
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.purple)
                                        .frame(width: 24)
                                    TextField("Item Name", text: $newItemName)
                                }
                                .padding()
                                
                                Divider().padding(.leading, 48)
                                
                                // Price
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(.green)
                                        .frame(width: 24)
                                    TextField("Price", text: $newItemPrice)
                                        .keyboardType(.decimalPad)
                                }
                                .padding()
                                
                                Divider().padding(.leading, 48)
                                
                                // Date
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    Text("Desired Date")
                                    Spacer()
                                    DatePicker("", selection: $newItemDate, displayedComponents: .date)
                                        .labelsHidden()
                                }
                                .padding()
                                
                                Divider().padding(.leading, 48)
                                
                                // URL
                                HStack {
                                    Image(systemName: "link")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    TextField("Item URL (Optional)", text: $newItemURL)
                                        .keyboardType(.URL)
                                        .autocapitalization(.none)
                                }
                                .padding()
                            }
                            .background(cardBackground)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Error Display (if editing)
                        if let item = editingItem, let _ = item.calculationError {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Scheduling Issue")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    Text("Could not schedule")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle(editingItem != nil ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddItem = false
                        newItemName = ""
                        newItemPrice = ""
                        newItemURL = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingItem != nil ? "Save" : "Add") {
                        guard let price = Double(newItemPrice), !newItemName.isEmpty else { return }
                        
                        if let item = editingItem {
                            // Update existing
                            item.name = newItemName
                            item.price = price
                            item.purchaseByDate = newItemDate
                            item.url = URL(string: newItemURL)
                            // Reset error/date on edit so it recalculates fresh
                            item.calculatedPurchaseDate = nil
                            item.calculationError = nil
                        } else if let list = selectedList {
                            // Create new
                            let newItem = ShoppingListItem(name: newItemName, price: price, purchaseByDate: newItemDate, url: URL(string: newItemURL))
                            newItem.parentList = list
                            list.items.append(newItem)
                        }
                        
                        showAddItem = false
                        newItemName = ""
                        newItemPrice = ""
                        newItemURL = ""
                        onAdd()
                    }
                    .disabled(newItemName.isEmpty || newItemPrice.isEmpty)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}

