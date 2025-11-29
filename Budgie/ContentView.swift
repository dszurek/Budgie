//
//  ContentView.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/5/25.
//

import SwiftUI
import BottomBar_SwiftUI

let navBarItems: [BottomBarItem] = [
    BottomBarItem(icon: "calendar", title: "Timeline", color: .purple),
    BottomBarItem(icon: "dollarsign", title: "Budget", color: .green),
    BottomBarItem(icon: "cart", title: "Wish Lists", color: .blue),
    BottomBarItem(icon: "person", title: "You", color: .pink)
]

struct ContentView: View {
    @State private var selectedIndex: Int = 0
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Background that matches content
            (colorScheme == .dark ? Color.black : Color(red: 0.95, green: 0.95, blue: 0.97))
                .ignoresSafeArea()
            
            // Live Header Background
            VStack {
                LiveHeaderBackground(color: navBarItems[selectedIndex].color)
                    .animation(.easeInOut(duration: 0.5), value: selectedIndex)
                Spacer()
            }
            .ignoresSafeArea()
            
            ZStack(alignment: .bottom) {
                // Main Content with animation
                // Main Content with ZStack for instant switching and crossfade
                ZStack {
                    TimelineView()
                        .opacity(selectedIndex == 0 ? 1 : 0)
                        .disabled(selectedIndex != 0) // Disable interaction when hidden
                    
                    BudgetView()
                        .opacity(selectedIndex == 1 ? 1 : 0)
                        .disabled(selectedIndex != 1)
                    
                    ShoppingListsView()
                        .opacity(selectedIndex == 2 ? 1 : 0)
                        .disabled(selectedIndex != 2)
                    
                    UserView()
                        .opacity(selectedIndex == 3 ? 1 : 0)
                        .disabled(selectedIndex != 3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.2), value: selectedIndex)
                .onChange(of: selectedIndex) { _, _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                
                // BottomBar
                BottomBar(selectedIndex: $selectedIndex, items: navBarItems)
                    .background(.ultraThinMaterial)
                    .background(
                        colorScheme == .dark 
                            ? Color.white.opacity(0.1) 
                            : Color.white.opacity(0.5)
                    )
                    .cornerRadius(30)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    // Removed overlay stroke as requested
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ShoppingList.self, ShoppingListItem.self, Income.self, Expense.self, User.self, DatedFinancialEvent.self], inMemory: true)
}
