//
//  BudgieApp.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/5/25.
//

import SwiftUI
import SwiftData

@main
struct BudgieApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ShoppingList.self,
            ShoppingListItem.self,
            Income.self,
            Expense.self,
            User.self,
            DatedFinancialEvent.self,
            IntermittentDate.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @Environment(\.scenePhase) var scenePhase
    @State private var updateMessage: String?
    @State private var showUpdateAlert = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
                .alert("Balance Updated", isPresented: $showUpdateAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(updateMessage ?? "")
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkForBalanceUpdates()
            }
        }
    }
    
    private func checkForBalanceUpdates() {
        Task { @MainActor in
            let context = sharedModelContainer.mainContext
            let descriptor = FetchDescriptor<User>()
            if let user = try? context.fetch(descriptor).first {
                if let message = BalanceManager.shared.updateBalanceForPassedEvents(user: user, modelContext: context) {
                    updateMessage = message
                    showUpdateAlert = true
                }
            }
        }
    }
}
