//
//  NotificationManager.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/26/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleNotifications(for items: [ShoppingListItem]) {
        // Remove all pending notifications first to avoid duplicates/stale data
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for item in items {
            guard let date = item.calculatedPurchaseDate,
                  !(item.isPurchased ?? false) else { continue }
            
            let purchaseDate = calendar.startOfDay(for: date)
            
            // Only schedule for today or future
            if purchaseDate >= today {
                let content = UNMutableNotificationContent()
                content.title = "Purchase Reminder"
                content.body = "It's time to buy \(item.name) for $\(String(format: "%.2f", item.price))!"
                content.sound = .default
                
                // Schedule for 8:00 AM on the purchase date
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: purchaseDate)
                dateComponents.hour = 8
                dateComponents.minute = 0
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification for \(item.name): \(error)")
                    }
                }
            }
        }
    }
}
