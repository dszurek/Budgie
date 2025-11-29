//
//  graphWidget.swift
//  graphWidget
//
//  Created by Daniel Szurek on 5/26/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), points: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        print("📱 WidgetProvider: getSnapshot called")
        let data = WidgetData.load()
        if let data = data {
            print("📱 WidgetProvider: Loaded \(data.points.count) points from UserDefaults")
        } else {
            print("📱 WidgetProvider: Failed to load data or data is nil")
        }
        let entry = SimpleEntry(date: Date(), points: data?.points ?? [])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        print("📱 WidgetProvider: getTimeline called")
        let data = WidgetData.load()
        if let data = data {
            print("📱 WidgetProvider: Loaded \(data.points.count) points from UserDefaults")
        } else {
            print("📱 WidgetProvider: Failed to load data or data is nil")
        }
        let entry = SimpleEntry(date: Date(), points: data?.points ?? [])
        
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let points: [WidgetData.Point]
}

struct graphWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading) {
            Text("Budgie Projection")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            if entry.points.isEmpty {
                VStack(alignment: .leading) {
                    Text("No data found")
                    if let url = WidgetData.fileURL() {
                        if FileManager.default.fileExists(atPath: url.path) {
                            if let attr = try? FileManager.default.attributesOfItem(atPath: url.path),
                               let size = attr[.size] as? Int {
                                Text("File: \(size) bytes")
                            } else {
                                Text("File exists")
                            }
                        } else {
                            Text("File missing")
                        }
                    } else {
                        Text("Invalid App Group:")
                        Text(WidgetData.appGroupID)
                            .font(.system(size: 8))
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            } else {
                GeometryReader { geometry in
                    Path { path in
                        let points = entry.points
                        guard points.count > 1 else { return }
                        
                        let minBalance = points.map { $0.balance }.min() ?? 0
                        let maxBalance = points.map { $0.balance }.max() ?? 1
                        let range = maxBalance - minBalance
                        
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        let stepX = width / CGFloat(points.count - 1)
                        
                        for (index, point) in points.enumerated() {
                            let x = CGFloat(index) * stepX
                            // Normalize balance to 0-1, then flip for Y (0 is top)
                            let normalizedY = (point.balance - minBalance) / (range == 0 ? 1 : range)
                            let y = height - (CGFloat(normalizedY) * height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                    
                    // Purchase Dots Overlay
                    ForEach(Array(entry.points.enumerated()), id: \.offset) { index, point in
                        if point.hasPurchase {
                            let minBalance = entry.points.map { $0.balance }.min() ?? 0
                            let maxBalance = entry.points.map { $0.balance }.max() ?? 1
                            let range = maxBalance - minBalance
                            
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let stepX = width / CGFloat(entry.points.count - 1)
                            
                            let x = CGFloat(index) * stepX
                            let normalizedY = (point.balance - minBalance) / (range == 0 ? 1 : range)
                            let y = height - (CGFloat(normalizedY) * height)
                            
                            Circle()
                                .fill(Color(hex: point.colorHex ?? "#FFA500"))
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                        }
                    }
                }
            }
            
            Spacer()
            
            if let first = entry.points.first, let last = entry.points.last {
                HStack(alignment: .bottom) {
                    // Start Date
                    Text(first.date.formatted(.dateTime.month().day()))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // End Date + Value
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(last.date.formatted(.dateTime.month().day().year()))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.0f", last.balance))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(white: 0.15) // Dark background
        }
    }
}

struct graphWidget: Widget {
    let kind: String = "graphWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                graphWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                graphWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Budgie Graph")
        .description("View your projected balance trend.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    graphWidget()
} timeline: {
    SimpleEntry(date: .now, points: [
        WidgetData.Point(date: Date(), balance: 1000, hasPurchase: false, colorHex: nil),
        WidgetData.Point(date: Date().addingTimeInterval(86400), balance: 1200, hasPurchase: true, colorHex: "#00FF00"),
        WidgetData.Point(date: Date().addingTimeInterval(86400*2), balance: 800, hasPurchase: false, colorHex: nil),
        WidgetData.Point(date: Date().addingTimeInterval(86400*3), balance: 1500, hasPurchase: true, colorHex: "#FF0000")
    ])
}

// Helper for Hex Colors (Duplicated here if LiquidStyle isn't shared)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
