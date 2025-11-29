//
//  WidgetData.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/26/25.
//

import Foundation

struct WidgetData: Codable {
    struct Point: Codable {
        let date: Date
        let balance: Double
        let hasPurchase: Bool
        let colorHex: String? // Optional color for the dot
    }
    
    let points: [Point]
    let lastUpdated: Date
    
    // IMPORTANT: You must enable App Groups in Xcode for both the App and Widget Extension targets.
    // Replace "group.com.yourcompany.budgie" with your actual App Group ID.
    static let appGroupID = "group.com.danielszurek.budgie"
    static let fileName = "widgetData.json"
    
    static func fileURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?.appendingPathComponent(fileName)
    }
    
    static func save(points: [Point]) {
        // print("💾 WidgetData: Attempting to save \(points.count) points to App Group: \(appGroupID)")
        
        guard let url = fileURL() else {
            print("❌ WidgetData: Failed to get App Group container URL. Check App Group configuration.")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(WidgetData(points: points, lastUpdated: Date()))
            try data.write(to: url)
            // print("✅ WidgetData: Successfully saved data to file: \(url.path)")
        } catch {
            print("❌ WidgetData: Failed to save/encode data: \(error)")
        }
    }
    
    static func load() -> WidgetData? {
        guard let url = fileURL() else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}
