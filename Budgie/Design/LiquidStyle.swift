//
//  LiquidStyle.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/10/25.
//

import SwiftUI

// MARK: - Colors & Gradients
extension Color {
    static let liquidBackgroundTop = Color(hex: "e0c3fc")
    static let liquidBackgroundBottom = Color(hex: "8ec5fc")
    static let liquidAccent = Color(hex: "ffffff").opacity(0.3)
    static let liquidShadow = Color.black.opacity(0.1)
}

extension LinearGradient {
    static let liquidMesh = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "A9F1DF"),
            Color(hex: "FFBBBB")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let liquidBackground = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "e0c3fc"),
            Color(hex: "8ec5fc")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Modifiers

struct LiquidCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .liquidShadow, radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.4), lineWidth: 1)
            )
    }
}

struct LiquidButtonModifier: ViewModifier {
    var color: Color = .blue
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(color.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
    }
}

struct LiquidTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Extensions

extension View {
    func liquidCard() -> some View {
        self.modifier(LiquidCardModifier())
    }
    
    func liquidButton(color: Color = .blue) -> some View {
        self.modifier(LiquidButtonModifier(color: color))
    }
    
    func liquidTextField() -> some View {
        self.modifier(LiquidTextFieldModifier())
    }
    
    func liquidBackground() -> some View {
        self.background(
            ZStack {
                LinearGradient.liquidBackground
                    .ignoresSafeArea()
                
                // Abstract Orbs
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -150)
                
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: 100, y: 150)
            }
        )
    }
}

// MARK: - Helper for Hex Colors
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
    
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
